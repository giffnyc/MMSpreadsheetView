// Copyright (c) 2013 Mutual Mobile (http://mutualmobile.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MMSpreadsheetView.h"
#import <QuartzCore/QuartzCore.h>
#import "MMGridLayout.h"
#import "NSIndexPath+MMSpreadsheetView.h"

typedef NS_ENUM(NSUInteger, MMSpreadsheetViewCollection) {
    MMSpreadsheetViewCollectionUpperLeft = 1,
    MMSpreadsheetViewCollectionUpperRight,
    MMSpreadsheetViewCollectionLowerLeft,
    MMSpreadsheetViewCollectionLowerRight,
};

typedef NS_ENUM(NSUInteger, MMSpreadsheetHeaderConfiguration) {
    MMSpreadsheetHeaderConfigurationNone = 0,
    MMSpreadsheetHeaderConfigurationColumnOnly,
    MMSpreadsheetHeaderConfigurationRowOnly,
    MMSpreadsheetHeaderConfigurationBoth,
};

const static CGFloat MMSpreadsheetViewGridSpace = 1.0f;
const static CGFloat MMSpreadsheetViewScrollIndicatorWidth = 5.0f;
const static CGFloat MMSpreadsheetViewScrollIndicatorSpace = 3.0f;
const static CGFloat MMSpreadsheetViewScrollIndicatorMinimum = 25.0f;
const static CGFloat MMScrollIndicatorDefaultInsetSpace = 2.0f;
const static NSUInteger MMScrollIndicatorTag = 12345;

@interface MMSpreadsheetView () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>

@property (nonatomic, assign) NSUInteger headerRowCount;
@property (nonatomic, assign) NSUInteger headerColumnCount;
@property (nonatomic, assign) MMSpreadsheetHeaderConfiguration spreadsheetHeaderConfiguration;
@property (nonatomic, strong) UIScrollView *controllingScrollView;

@property (nonatomic, strong) UIView *upperLeftContainerView;
@property (nonatomic, strong) UIView *upperRightContainerView;
@property (nonatomic, strong) UIView *lowerLeftContainerView;
@property (nonatomic, strong) UIView *lowerRightContainerView;

@property (nonatomic, strong) UICollectionView *upperLeftCollectionView;
@property (nonatomic, strong) UICollectionView *upperRightCollectionView;
@property (nonatomic, strong) UICollectionView *lowerLeftCollectionView;
@property (nonatomic, strong) UICollectionView *lowerRightCollectionView;

@property (nonatomic, assign, getter = isUpperRightBouncing) BOOL upperRightBouncing;
@property (nonatomic, assign, getter = isLowerLeftBouncing) BOOL lowerLeftBouncing;
@property (nonatomic, assign, getter = isLowerRightBouncing) BOOL lowerRightBouncing;

@property (nonatomic, strong) UIView *verticalScrollIndicator;
@property (nonatomic, strong) UIView *horizontalScrollIndicator;

@property (nonatomic, strong) UICollectionView *selectedItemCollectionView;
@property (nonatomic, strong) NSIndexPath *selectedItemIndexPath;

@property (nonatomic, assign) BOOL openingRefreshControl;
@property (nonatomic, strong) UIView *blockingView;

@end


@implementation MMSpreadsheetView
{
	CGFloat ratio;
	CGFloat startValue;
}

- (instancetype)init {
    return [self initWithNumberOfHeaderRows:0 numberOfHeaderColumns:0 frame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		// Call below in viewDidLoad
		//[self commonInitWithNumberOfHeaderRows:0 numberOfHeaderColumns:0];
	}
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	if((self = [super initWithCoder:coder])) {
		// Apple bug iOS9.1 (weirdness) - the first view gets hosed by iOS during view loading/presentation - may not be necessary here
//		UIView *v = [UIView new];
//		[self addSubview:v];

		// Call below in viewDidLoad
		//[self commonInitWithNumberOfHeaderRows:0 numberOfHeaderColumns:0];
	}

    return self;
}

#pragma mark - MMSpreadsheetView designated initializer

- (instancetype)initWithNumberOfHeaderRows:(NSUInteger)headerRowCount numberOfHeaderColumns:(NSUInteger)headerColumnCount frame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {

//		Apple bug iOS9.1 (weirdness) - the first view gets hosed by iOS during view loading/presentation - may not be necessary here
//		UIView *v = [UIView new];
//		[self addSubview:v];

		[self commonInitWithNumberOfHeaderRows:headerRowCount numberOfHeaderColumns:headerColumnCount];
	}
    return self;
}

- (void)commonInitWithNumberOfHeaderRows:(NSUInteger)headerRowCount numberOfHeaderColumns:(NSUInteger)headerColumnCount {
	_scrollIndicatorInsets = UIEdgeInsetsZero;
	_showsVerticalScrollIndicator = YES;
	_showsHorizontalScrollIndicator = YES;
	_headerRowCount = headerRowCount;
	_headerColumnCount = headerColumnCount;

//		Apple bug iOS9.1 (weirdness) - the first view gets hosed by iOS during view loading/presentation - may not be necessary here
//		UIView *v = [UIView new];
//		[self addSubview:v];

	if(_wantRefreshControl) {
		// 88 is the height of a standard UIRefreshControl. The left/right offsets are to hide the layer border (see initWithFrame)
		self.refreshControl = [[MMRefreshControl alloc] initWithFrame:CGRectMake(-1, -88, self.bounds.size.width+2, 88)];
		_refreshControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self addSubview:_refreshControl];
	}

	if (headerColumnCount == 0 && headerRowCount == 0) {
		_spreadsheetHeaderConfiguration = MMSpreadsheetHeaderConfigurationNone;
	}
	else if (headerColumnCount > 0 && headerRowCount == 0) {
		_spreadsheetHeaderConfiguration = MMSpreadsheetHeaderConfigurationColumnOnly;
	}
	else if (headerColumnCount == 0 && headerRowCount > 0) {
		_spreadsheetHeaderConfiguration = MMSpreadsheetHeaderConfigurationRowOnly;
	}
	else if (headerColumnCount > 0 && headerRowCount > 0) {
		_spreadsheetHeaderConfiguration = MMSpreadsheetHeaderConfigurationBoth;
	}
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.backgroundColor = [UIColor grayColor];

	[self setupSubviews];

	[self hideTabBar:NO withAnimationDuration: 0 coordinator: nil];	// sets proper inset for translucent tab bar if scrolling underneath it
}

- (void)hideTabBar:(BOOL)hide withAnimationDuration:(CGFloat)animateDuration coordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	UITabBarController *tabBarController = _navigationController.tabBarController;
	UITabBar *tabBar = tabBarController.tabBar;
	if(tabBar.translucent) {
		CGFloat offset = hide ? 0 : tabBar.frame.size.height;

		UIEdgeInsets loadingInsetLeft = _lowerLeftCollectionView.contentInset;
		UIEdgeInsets loadingInsetRight = _lowerRightCollectionView.contentInset;

		CGPoint contentOffsetLeft = _lowerLeftCollectionView.contentOffset;
		CGPoint contentOffsetRight = _lowerRightCollectionView.contentOffset;

		BOOL lowerLeftAtMax = fabs(contentOffsetLeft.y - [self maxOffset:_lowerLeftCollectionView withInset:loadingInsetLeft]) < 3;	// possible rounding so make it close
		BOOL lowerRightAtMax = fabs(contentOffsetRight.y - [self maxOffset:_lowerRightCollectionView withInset:loadingInsetRight]) < 3;

		loadingInsetLeft.bottom = offset;
		loadingInsetRight.bottom = offset;

		if(!coordinator) {
			CGFloat maxLeftOffset = [self maxOffset:_lowerLeftCollectionView withInset:loadingInsetLeft];
			CGFloat maxRightOffset = [self maxOffset:_lowerRightCollectionView withInset:loadingInsetRight];

			if(hide) {
				contentOffsetLeft.y = MIN(contentOffsetLeft.y, maxLeftOffset);
				contentOffsetRight.y = MIN(contentOffsetRight.y, maxRightOffset);
			} else {
				if(lowerLeftAtMax) contentOffsetLeft.y = maxLeftOffset;
				if(lowerRightAtMax) contentOffsetRight.y = maxRightOffset;
			}
		}
		dispatch_block_t code = ^{
			self.lowerLeftCollectionView.contentInset = loadingInsetLeft;
			self.lowerRightCollectionView.contentInset = loadingInsetRight;
			self.lowerLeftCollectionView.contentOffset = contentOffsetLeft;
			self.lowerRightCollectionView.contentOffset = contentOffsetRight;
		};

		if(animateDuration > 0 || coordinator) {
			CGRect r = tabBar.frame;
			if(!hide) {
				[tabBar setHidden:NO];
				r.origin.y += r.size.height;
				tabBar.frame = r;
			}

			dispatch_block_t startBlock = ^{
				code();
				CGRect tabFrame = r;
				if(hide) {
					tabFrame.origin.y += tabFrame.size.height;
				} else {
					tabFrame.origin.y -= tabFrame.size.height;
				}
				tabBar.frame = tabFrame;
			};
			void (^completionBlock)(BOOL) = ^void(BOOL finished) {
				if(hide) {
					CGRect r = tabBar.frame;
					r.origin.y -= r.size.height;
					tabBar.frame = r;
					[tabBar setHidden:YES];
				}
				[self correctContentOffset:lowerLeftAtMax];
			};

			if(coordinator) {
				[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
					startBlock();
				} completion: ^(id<UIViewControllerTransitionCoordinatorContext> context) {
					completionBlock(YES);
				}];
			} else {
				[UIView animateWithDuration:animateDuration animations:startBlock completion:completionBlock];
			}
		} else {
			code();
			[tabBar setHidden:hide];
		}
		_scrollIndicatorInsets.bottom = offset;
	}
}

- (void)correctContentOffset:(BOOL)wasAtMax {
	CGFloat maxLeftOffset = [self maxOffset:self.lowerLeftCollectionView withInset:self.lowerLeftCollectionView.contentInset];
	CGFloat maxRightOffset = [self maxOffset:self.lowerRightCollectionView withInset:self.lowerRightCollectionView.contentInset];
	CGPoint contentOffsetLeft = self.lowerLeftCollectionView.contentOffset;
	CGPoint contentOffsetRight = self.lowerRightCollectionView.contentOffset;
	if(contentOffsetLeft.y > maxLeftOffset || wasAtMax) {
		contentOffsetLeft.y = maxLeftOffset;
		self.lowerLeftCollectionView.contentOffset = contentOffsetLeft;
	}
	if(contentOffsetRight.y > maxRightOffset || wasAtMax) {
		contentOffsetRight.y = maxRightOffset;
		self.lowerRightCollectionView.contentOffset = contentOffsetRight;
	}
}

- (CGFloat)maxOffset:(UIScrollView *)scrollView withInset:(UIEdgeInsets)insets {
	CGFloat h1 = scrollView.contentSize.height;
	CGFloat h2 = scrollView.bounds.size.height;
	CGFloat maxOffset = h1 - h2 + insets.top + insets.bottom;
	//NSLog(@"MAX-OFFSET: h1=%d h2=%d top=%d bot=%d ====> %d", (int)h1, (int)h2, (int)insets.top, (int)insets.bottom, (int)maxOffset);
	if(maxOffset < 0) maxOffset = 0;
	return maxOffset;
}

#pragma mark - Public Functions

- (UICollectionViewCell *)dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *collectionViewIndexPath = [self collectionViewIndexPathFromDataSourceIndexPath:indexPath];
    UICollectionView *collectionView = [self collectionViewForDataSourceIndexPath:indexPath];
    NSAssert(collectionView, @"No collectionView Returned!");
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:collectionViewIndexPath];
    return cell;
}

- (void)registerCellClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier {
    [self.upperLeftCollectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
    [self.upperRightCollectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
    [self.lowerLeftCollectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
    [self.lowerRightCollectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
}

- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
    NSIndexPath *collectionViewIndexPath = [self collectionViewIndexPathFromDataSourceIndexPath:indexPath];
    UICollectionView *collectionView = [self collectionViewForDataSourceIndexPath:indexPath];
    NSAssert(collectionView, @"No collectionView Returned!");
    [collectionView deselectItemAtIndexPath:collectionViewIndexPath animated:animated];
}

- (void)reloadData {
    [self.upperLeftCollectionView reloadData];
    [self.upperRightCollectionView reloadData];
    [self.lowerLeftCollectionView reloadData];
    [self.lowerRightCollectionView reloadData];
	[self setNeedsLayout];	// In case transition between some "data" rows and none
}

- (void)flashScrollIndicators {
    [self showScrollIndicators];
    [self performSelector:@selector(hideScrollIndicators) withObject:nil afterDelay:1];
}

#pragma mark - View Setup functions

- (void)setupSubviews {
    switch (self.spreadsheetHeaderConfiguration) {
        case MMSpreadsheetHeaderConfigurationNone:
            [self setupLowerRightView];
            break;
            
        case MMSpreadsheetHeaderConfigurationColumnOnly:
            [self setupLowerLeftView];
            [self setupLowerRightView];
            break;
            
        case MMSpreadsheetHeaderConfigurationRowOnly:
            [self setupUpperRightView];
            [self setupLowerRightView];
            break;
            
        case MMSpreadsheetHeaderConfigurationBoth:
            [self setupUpperLeftView];
            [self setupUpperRightView];
            [self setupLowerLeftView];
            [self setupLowerRightView];
            break;
            
        default:
            NSAssert(NO, @"What have you done?");
            break;
    }
    self.verticalScrollIndicator = [self setupScrollIndicator];
    self.horizontalScrollIndicator = [self setupScrollIndicator];
}

- (void)setupContainerSubview:(UIView *)container collectionView:(UICollectionView *)collectionView tag:(NSInteger)tag {
    container.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:container];

    collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.tag = tag;
    collectionView.delegate = self;
    collectionView.dataSource = self;
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.showsVerticalScrollIndicator = NO;

    [container addSubview:collectionView];
}

- (UICollectionView *)setupCollectionViewWithGridLayout {
    MMGridLayout *layout = [[MMGridLayout alloc] init];
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];

    return collectionView;
}

- (void)setupUpperLeftView {
    self.upperLeftContainerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.upperLeftCollectionView = [self setupCollectionViewWithGridLayout];
    [self setupContainerSubview:self.upperLeftContainerView
                 collectionView:self.upperLeftCollectionView
                            tag:MMSpreadsheetViewCollectionUpperLeft];
    self.upperLeftCollectionView.scrollEnabled = NO;
}

- (void)setupUpperRightView {
    self.upperRightContainerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.upperRightCollectionView = [self setupCollectionViewWithGridLayout];
    [self.upperRightCollectionView.panGestureRecognizer addTarget:self
                                                           action:@selector(handleUpperRightPanGesture:)];
    [self setupContainerSubview:self.upperRightContainerView
                 collectionView:self.upperRightCollectionView
                            tag:MMSpreadsheetViewCollectionUpperRight];

	self.upperRightCollectionView.alwaysBounceVertical = NO;
}

- (void)setupLowerLeftView {
    self.lowerLeftContainerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.lowerLeftCollectionView = [self setupCollectionViewWithGridLayout];
	[self.lowerLeftCollectionView.panGestureRecognizer addTarget:self action:@selector(handleLowerLeftPanGesture:)];

    [self setupContainerSubview:self.lowerLeftContainerView
                 collectionView:self.lowerLeftCollectionView
                            tag:MMSpreadsheetViewCollectionLowerLeft];
}

- (void)setupLowerRightView {
    self.lowerRightContainerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.lowerRightCollectionView = [self setupCollectionViewWithGridLayout];
	[self.lowerRightCollectionView.panGestureRecognizer addTarget:self action:@selector(handleLowerRightPanGesture:)];

    [self setupContainerSubview:self.lowerRightContainerView
                 collectionView:self.lowerRightCollectionView
                            tag:MMSpreadsheetViewCollectionLowerRight];
}

- (void)layoutSubviews {
	if(_openingRefreshControl) return;	// setting bounds for refreshControl

    [super layoutSubviews];

    NSIndexPath *indexPathZero = [NSIndexPath indexPathForItem:0 inSection:0];
    switch (self.spreadsheetHeaderConfiguration) {
        case MMSpreadsheetHeaderConfigurationNone:
            self.lowerRightContainerView.frame = self.bounds;
            break;
            
        case MMSpreadsheetHeaderConfigurationColumnOnly: {
            CGSize size = self.lowerLeftCollectionView.collectionViewLayout.collectionViewContentSize;
            CGSize cellSize = [self collectionView:self.lowerRightCollectionView
                                            layout:self.lowerRightCollectionView.collectionViewLayout
                            sizeForItemAtIndexPath:indexPathZero];
            CGFloat maxLockDistance = self.bounds.size.width - cellSize.width;
            if (size.width > maxLockDistance) {
                NSAssert(NO, @"Width of header too large! Reduce the number of header columns.");
            }
            self.lowerLeftContainerView.frame = CGRectMake(0.0f,
                                                           0.0f,
                                                           size.width,
                                                           self.bounds.size.height);
            self.lowerRightContainerView.frame = CGRectMake(size.width + MMSpreadsheetViewGridSpace,
                                                            0.0f,
                                                            self.bounds.size.width - size.width - MMSpreadsheetViewGridSpace,
                                                            self.bounds.size.height);
            break;
        }
            
        case MMSpreadsheetHeaderConfigurationRowOnly: {
            CGSize size = self.upperRightCollectionView.collectionViewLayout.collectionViewContentSize;
            CGSize cellSize = [self collectionView:self.lowerRightCollectionView
                                            layout:self.lowerRightCollectionView.collectionViewLayout
                            sizeForItemAtIndexPath:indexPathZero];
            CGFloat maxLockDistance = self.bounds.size.height - cellSize.height;
            if (size.height > maxLockDistance) {
                NSAssert(NO, @"Height of header too large! Reduce the number of header rows.");
            }
            self.upperRightContainerView.frame = CGRectMake(0.0f,
                                                            0.0f,
                                                            self.bounds.size.width,
                                                            size.height);
            self.lowerRightContainerView.frame = CGRectMake(0.0f,
                                                            size.height + MMSpreadsheetViewGridSpace,
                                                            self.bounds.size.width,
                                                            self.bounds.size.height - size.height - MMSpreadsheetViewGridSpace);
            break;
        }
            
        case MMSpreadsheetHeaderConfigurationBoth: {
            CGSize size = self.upperLeftCollectionView.collectionViewLayout.collectionViewContentSize;
			CGSize boundsSize = self.bounds.size;
#if 0 // trying to be helpful, maybe in portrait it won't show a whole data cell, well then rotate it it would. Bottom line: test on a 4s!
            CGSize cellSize = [self collectionView:self.lowerRightCollectionView
                                            layout:self.lowerRightCollectionView.collectionViewLayout
                            sizeForItemAtIndexPath:indexPathZero];
            CGFloat maxLockDistance = boundsSize.height - cellSize.height;
            if (size.height > maxLockDistance) {
                NSAssert(NO, @"Height of header too large! Reduce the number of header rows.");
            }
            maxLockDistance = boundsSize.width - cellSize.width;
            if (size.width > maxLockDistance) {
                NSAssert(NO, @"Width of header too large! Reduce the number of header columns.");
            }
#endif
            self.upperLeftContainerView.frame = CGRectMake(0.0f,
                                                           0.0f,
                                                           size.width,
                                                           size.height);
            self.upperRightContainerView.frame = CGRectMake(size.width + MMSpreadsheetViewGridSpace,
                                                            0.0f,
                                                            boundsSize.width - size.width - MMSpreadsheetViewGridSpace,
                                                            size.height);
            self.lowerLeftContainerView.frame = CGRectMake(0.0f,
                                                           size.height + MMSpreadsheetViewGridSpace,
                                                           size.width,
                                                           boundsSize.height - size.height - MMSpreadsheetViewGridSpace);
            self.lowerRightContainerView.frame = CGRectMake(size.width + MMSpreadsheetViewGridSpace,
                                                            size.height + MMSpreadsheetViewGridSpace,
                                                            boundsSize.width - size.width - MMSpreadsheetViewGridSpace,
                                                            boundsSize.height - size.height - MMSpreadsheetViewGridSpace);
            break;
        }
            
        default:
            NSAssert(NO, @"What have you done?");
            break;
    }
    
    // Resize the indicators.
    self.verticalScrollIndicator.frame = CGRectMake(self.frame.size.width - MMSpreadsheetViewScrollIndicatorWidth - self.scrollIndicatorInsets.right - MMScrollIndicatorDefaultInsetSpace,
                                                    self.scrollIndicatorInsets.top + MMSpreadsheetViewScrollIndicatorSpace,
                                                    MMSpreadsheetViewScrollIndicatorWidth,
                                                    self.frame.size.height - self.scrollIndicatorInsets.top - self.scrollIndicatorInsets.bottom - 4*MMSpreadsheetViewScrollIndicatorSpace);
    [self updateVerticalScrollIndicator];

    self.horizontalScrollIndicator.frame = CGRectMake(self.scrollIndicatorInsets.left + MMSpreadsheetViewScrollIndicatorSpace,
                                                      self.frame.size.height - MMSpreadsheetViewScrollIndicatorWidth - self.scrollIndicatorInsets.bottom - MMScrollIndicatorDefaultInsetSpace,
                                                      self.frame.size.width - self.scrollIndicatorInsets.left - 4*MMSpreadsheetViewScrollIndicatorSpace,
                                                      MMSpreadsheetViewScrollIndicatorWidth);
    [self updateHorizontalScrollIndicator];
}

#pragma mark - UIPanGestureRecognizer callbacks

- (void)handleUpperRightPanGesture:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.lowerLeftContainerView.userInteractionEnabled = NO;
        self.lowerRightContainerView.userInteractionEnabled = NO;
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (self.isUpperRightBouncing == NO) {
            self.lowerLeftContainerView.userInteractionEnabled = YES;
            self.lowerRightContainerView.userInteractionEnabled = YES;
        }
    }
}

- (void)handleLowerLeftPanGesture:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.upperRightContainerView.userInteractionEnabled = NO;
        self.lowerRightContainerView.userInteractionEnabled = NO;
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (self.isLowerLeftBouncing == NO) {
            self.upperRightContainerView.userInteractionEnabled = YES;
            self.lowerRightContainerView.userInteractionEnabled = YES;
        }
    }
}

- (void)handleLowerRightPanGesture:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
		// NSLog(@"BEGAN!!! %@", NSStringFromCGPoint([recognizer velocityInView:self]));
        self.upperRightContainerView.userInteractionEnabled = NO;
        self.lowerLeftContainerView.userInteractionEnabled = NO;
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (self.isLowerRightBouncing == NO) {
            self.upperRightContainerView.userInteractionEnabled = YES;
            self.lowerLeftContainerView.userInteractionEnabled = YES;
        }
    }
}

#pragma mark - bounces property setter

- (void)setBounces:(BOOL)bounces {
    _bounces = bounces;
    self.upperLeftCollectionView.bounces = bounces;
    self.upperRightCollectionView.bounces = bounces;
    self.lowerLeftCollectionView.bounces = bounces;
    self.lowerRightCollectionView.bounces = bounces;
}
- (void)setHorizontalBounce:(BOOL)bounces {
	_horizontalBounce = bounces;
    self.upperLeftCollectionView.alwaysBounceHorizontal = bounces;
    self.upperRightCollectionView.alwaysBounceHorizontal = bounces;
    self.lowerLeftCollectionView.alwaysBounceHorizontal = bounces;
    self.lowerRightCollectionView.alwaysBounceHorizontal = bounces;
}
- (void)setVerticalBounce:(BOOL)bounces {
	_verticalBounce = bounces;
    self.upperLeftCollectionView.alwaysBounceVertical = NO;
    self.upperRightCollectionView.alwaysBounceVertical = NO;
    self.lowerLeftCollectionView.alwaysBounceVertical = bounces;
    self.lowerRightCollectionView.alwaysBounceVertical = bounces;
}
- (void)setDirectionalLockEnabled:(BOOL)enabled {
    _directionalLockEnabled = enabled;
    self.upperLeftCollectionView.directionalLockEnabled = enabled;
    self.upperRightCollectionView.directionalLockEnabled = enabled;
    self.lowerLeftCollectionView.directionalLockEnabled = enabled;
    self.lowerRightCollectionView.directionalLockEnabled = enabled;
}

#pragma mark - DataSource property setter

- (void)setDataSource:(id<MMSpreadsheetViewDataSource>)dataSource {
    _dataSource = dataSource;
    if (self.upperLeftCollectionView) {
        [self initializeCollectionViewLayoutItemSize:self.upperLeftCollectionView name:@"Left Corner"];
    }
    if (self.upperRightCollectionView) {
        [self initializeCollectionViewLayoutItemSize:self.upperRightCollectionView name:@"Column Labels"];
    }
    if (self.lowerLeftCollectionView) {
        [self initializeCollectionViewLayoutItemSize:self.lowerLeftCollectionView name:@"Row Labels"];
    }
    if (self.lowerRightCollectionView) {
        [self initializeCollectionViewLayoutItemSize:self.lowerRightCollectionView name:@"Data Cells"];
    }

    // Validate dataSource & header configuration
    NSInteger maxRows = [_dataSource numberOfRowsInSpreadsheetView:self];
    NSInteger maxCols = [_dataSource numberOfColumnsInSpreadsheetView:self];
    
    NSAssert(self.headerColumnCount <= maxCols, @"Invalid configuration: number of header columns must be less than or equal to (dataSource) numberOfColumnsInSpreadsheetView");
    NSAssert(self.headerRowCount <= maxRows, @"Invalid configuration: number of header rows must be less than or equal to (dataSource) numberOfRowsInSpreadsheetView");
}

- (void)initializeCollectionViewLayoutItemSize:(UICollectionView *)collectionView name:(NSString*)name {
    MMGridLayout *layout = (MMGridLayout *)collectionView.collectionViewLayout;
    layout.name = name;
}

#pragma mark - Scroll Indicator

- (UIView *)setupScrollIndicator {
    UIView *scrollIndicator = [[UIView alloc] initWithFrame:CGRectZero];
    scrollIndicator.alpha = 0.0f;
    scrollIndicator.layer.cornerRadius = MMSpreadsheetViewScrollIndicatorWidth/2;
    scrollIndicator.clipsToBounds = YES;
    [self addSubview:scrollIndicator];
    
    UIView *scrollIndicatorSegment = [[UIView alloc] initWithFrame:CGRectZero];
    scrollIndicatorSegment.backgroundColor = [UIColor colorWithWhite:0.44f alpha:1.0f];
    scrollIndicatorSegment.layer.cornerRadius = MMSpreadsheetViewScrollIndicatorWidth/2;
    scrollIndicatorSegment.tag = MMScrollIndicatorTag;
    [scrollIndicator addSubview:scrollIndicatorSegment];
    
    return scrollIndicator;
}

- (void)showScrollIndicators {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideScrollIndicators) object:nil];
    [UIView animateWithDuration:0.4f animations:^{
        self.verticalScrollIndicator.alpha = self.showsVerticalScrollIndicator ? 1.0f : 0.0f;
        self.horizontalScrollIndicator.alpha = self.showsHorizontalScrollIndicator ? 1.0f : 0.0f;
    }];
}

- (void)hideScrollIndicators {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showScrollIndicators) object:nil];
    [UIView animateWithDuration:0.5f animations:^{
        self.verticalScrollIndicator.alpha = 0.0f;
        self.horizontalScrollIndicator.alpha = 0.0f;
    }];
}

- (void)updateVerticalScrollIndicator {
    if (self.showsVerticalScrollIndicator) {
        UIView *scrollIndicator = self.verticalScrollIndicator;
        UIView *indicatorView = [scrollIndicator viewWithTag:MMScrollIndicatorTag];
        UICollectionView *collectionView = self.lowerRightCollectionView;
        CGSize contentSize = collectionView.collectionViewLayout.collectionViewContentSize;
        CGRect collectionViewFrame = collectionView.frame;

        if (collectionViewFrame.size.height > contentSize.height) {
            indicatorView.frame = CGRectZero;
        } else {
            CGFloat indicatorHeight = collectionViewFrame.size.height / contentSize.height * scrollIndicator.frame.size.height;
            if (indicatorHeight < MMSpreadsheetViewScrollIndicatorMinimum) {
                indicatorHeight = MMSpreadsheetViewScrollIndicatorMinimum;
            }
            CGFloat divideByZeroOffset = fabs(contentSize.height - collectionViewFrame.size.height) < 1.0 ? 1.0f : 0.0f;
            CGFloat indicatorOffsetY = collectionView.contentOffset.y / (contentSize.height - collectionViewFrame.size.height + divideByZeroOffset) * (scrollIndicator.frame.size.height - indicatorHeight);
            indicatorView.frame = CGRectMake(0.0f,
                                             indicatorOffsetY,
                                             MMSpreadsheetViewScrollIndicatorWidth,
                                             indicatorHeight);
        }
    }
}

- (void)updateHorizontalScrollIndicator {
    if (self.showsHorizontalScrollIndicator) {
        UIView *scrollIndicator = self.horizontalScrollIndicator;
        UIView *indicatorView = [scrollIndicator viewWithTag:MMScrollIndicatorTag];
        UICollectionView *collectionView = self.lowerRightCollectionView;
        CGSize contentSize = collectionView.collectionViewLayout.collectionViewContentSize;
        CGRect collectionViewFrame = collectionView.frame;

        if (collectionView.frame.size.width > contentSize.width) {
            indicatorView.frame = CGRectZero;
        } else {
            CGFloat indicatorWidth = collectionViewFrame.size.width/contentSize.width * scrollIndicator.frame.size.width;
            if (indicatorWidth < MMSpreadsheetViewScrollIndicatorMinimum) {
                indicatorWidth = MMSpreadsheetViewScrollIndicatorMinimum;
            }
            CGFloat divideByZeroOffset = fabs(contentSize.width - collectionViewFrame.size.width) ? 1.0f : 0.0f;
            CGFloat indicatorOffsetX = collectionView.contentOffset.x / (contentSize.width - collectionViewFrame.size.width + divideByZeroOffset) * (scrollIndicator.frame.size.width-indicatorWidth);
            indicatorView.frame = CGRectMake(indicatorOffsetX,
                                             0.0f,
                                             indicatorWidth,
                                             MMSpreadsheetViewScrollIndicatorWidth);
        }
    }
}

#pragma mark - Custom functions that don't go anywhere else

- (UICollectionView *)collectionViewForDataSourceIndexPath:(NSIndexPath *)indexPath {
    UICollectionView *collectionView = nil;
    switch (self.spreadsheetHeaderConfiguration) {
        case MMSpreadsheetHeaderConfigurationNone:
            collectionView = self.lowerRightCollectionView;
            break;
            
        case MMSpreadsheetHeaderConfigurationColumnOnly:
            if (indexPath.mmSpreadsheetColumn >= self.headerColumnCount) {
                collectionView = self.lowerRightCollectionView;
            } else {
                collectionView = self.lowerLeftCollectionView;
            }
            break;
            
        case MMSpreadsheetHeaderConfigurationRowOnly:
            if (indexPath.mmSpreadsheetRow >= self.headerRowCount) {
                collectionView = self.lowerRightCollectionView;
            }
            else {
                collectionView = self.upperRightCollectionView;
            }
            break;
            
        case MMSpreadsheetHeaderConfigurationBoth:
            if (indexPath.mmSpreadsheetRow >= self.headerRowCount) {
                if (indexPath.mmSpreadsheetColumn >= self.headerColumnCount) {
                    collectionView = self.lowerRightCollectionView;
                } else {
                    collectionView = self.lowerLeftCollectionView;
                }
            }
            else {
                if (indexPath.mmSpreadsheetColumn >= self.headerColumnCount) {
                    collectionView = self.upperRightCollectionView;
                } else {
                    collectionView = self.upperLeftCollectionView;
                }
            }
            break;
            
        default:
            NSAssert(NO, @"What have you done?");
            break;
    }
    return collectionView;
}

- (NSIndexPath *)dataSourceIndexPathFromCollectionView:(UICollectionView *)collectionView indexPath:(NSIndexPath *)indexPath {
    NSInteger mmSpreadsheetRow = indexPath.mmSpreadsheetRow;
    NSInteger mmSpreadsheetColumn = indexPath.mmSpreadsheetColumn;

    if (collectionView != nil) {
        switch (collectionView.tag) {
            case MMSpreadsheetViewCollectionUpperLeft:
                break;
                
            case MMSpreadsheetViewCollectionUpperRight:
                mmSpreadsheetColumn += self.headerColumnCount;
                break;
                
            case MMSpreadsheetViewCollectionLowerLeft:
                mmSpreadsheetRow += self.headerRowCount;
                break;
                
            case MMSpreadsheetViewCollectionLowerRight:
                mmSpreadsheetRow += self.headerRowCount;
                mmSpreadsheetColumn += self.headerColumnCount;
                break;
                
            default:
                NSAssert(NO, @"What have you done?");
                break;
        }
    }
    return [NSIndexPath indexPathForItem:mmSpreadsheetColumn inSection:mmSpreadsheetRow];
}

- (NSIndexPath *)collectionViewIndexPathFromDataSourceIndexPath:(NSIndexPath *)indexPath {
    UICollectionView *collectionView = [self collectionViewForDataSourceIndexPath:indexPath];
    NSAssert(collectionView, @"No collectionView Returned!");
    
    NSInteger mmSpreadsheetRow = indexPath.mmSpreadsheetRow;
    NSInteger mmSpreadsheetColumn = indexPath.mmSpreadsheetColumn;
    
    switch (collectionView.tag) {
        case MMSpreadsheetViewCollectionUpperLeft:
            // Don't think we need to do anything here
            break;
            
        case MMSpreadsheetViewCollectionUpperRight:
            mmSpreadsheetColumn -= self.headerColumnCount;
            break;
            
        case MMSpreadsheetViewCollectionLowerLeft:
            mmSpreadsheetRow -= self.headerRowCount;
            break;
            
        case MMSpreadsheetViewCollectionLowerRight:
            mmSpreadsheetRow -= self.headerRowCount;
            mmSpreadsheetColumn -= self.headerColumnCount;
            break;
            
        default:
            NSAssert(NO, @"What have you done?");
            break;
    }
    return [NSIndexPath indexPathForItem:mmSpreadsheetColumn inSection:mmSpreadsheetRow];
}

- (void)setScrollEnabledValue:(BOOL)scrollEnabled scrollView:(UIScrollView *)scrollView {
    switch (scrollView.tag) {
        case MMSpreadsheetViewCollectionUpperLeft:
            // Don't think we need to do anything here
            break;
            
        case MMSpreadsheetViewCollectionUpperRight:
            self.lowerLeftCollectionView.scrollEnabled = scrollEnabled;
            self.lowerRightCollectionView.scrollEnabled = scrollEnabled;
            break;
            
        case MMSpreadsheetViewCollectionLowerLeft:
            self.upperRightCollectionView.scrollEnabled = scrollEnabled;
            self.lowerRightCollectionView.scrollEnabled = scrollEnabled;
            break;
            
        case MMSpreadsheetViewCollectionLowerRight:
            self.upperRightCollectionView.scrollEnabled = scrollEnabled;
            self.lowerLeftCollectionView.scrollEnabled = scrollEnabled;
            break;
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *dataSourceIndexPath = [self dataSourceIndexPathFromCollectionView:collectionView indexPath:indexPath];
    CGSize size = [self.dataSource spreadsheetView:self sizeForItemAtIndexPath:dataSourceIndexPath];
    return size;
}

#pragma mark - UICollectionViewDataSource pass-through

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    NSInteger rowCount = [self.dataSource numberOfRowsInSpreadsheetView:self];
    NSInteger adjustedRows = 1;
    
    switch (collectionView.tag) {
            
        case MMSpreadsheetViewCollectionUpperLeft:
            adjustedRows = self.headerRowCount;
            break;
            
        case MMSpreadsheetViewCollectionUpperRight:
            adjustedRows = self.headerRowCount;
            break;
            
        case MMSpreadsheetViewCollectionLowerLeft:
            adjustedRows = rowCount - self.headerRowCount;
            break;
            
        case MMSpreadsheetViewCollectionLowerRight:
            adjustedRows = rowCount - self.headerRowCount;
            break;
            
        default:
            NSAssert(NO, @"What have you done?");
            break;
    }
    return adjustedRows == 0 ? 1 : adjustedRows; // No "data"
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger items = 0;
    NSInteger columnCount = [self.dataSource numberOfColumnsInSpreadsheetView:self];
    NSInteger rowCount = [self.dataSource numberOfRowsInSpreadsheetView:self];

    switch (collectionView.tag) {
        case MMSpreadsheetViewCollectionUpperLeft:
            items = self.headerColumnCount;
            break;
            
        case MMSpreadsheetViewCollectionUpperRight:
            items = columnCount - self.headerColumnCount;
            break;
            
        case MMSpreadsheetViewCollectionLowerLeft:
            items = rowCount == self.headerRowCount ? 0 : self.headerColumnCount; // No "data"
            break;
            
        case MMSpreadsheetViewCollectionLowerRight:
            items = rowCount == self.headerRowCount ? 0 : (columnCount - self.headerColumnCount); // No "data"
            break;
            
        default:
            NSAssert(NO, @"What have you done?");
            break;
    }

    return items;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *dataSourceIndexPath = [self dataSourceIndexPathFromCollectionView:collectionView indexPath:indexPath];
    UICollectionViewCell *cell = [self.dataSource spreadsheetView:self cellForItemAtIndexPath:dataSourceIndexPath];
    return cell;
}

- (UICollectionViewCell *)cellForItemAtDataSourceIndexPath:(NSIndexPath *)dataSourceIndexPath
{
	UICollectionView *collectionView = [self collectionViewForDataSourceIndexPath:dataSourceIndexPath];
	NSIndexPath *indexPath = [self collectionViewIndexPathFromDataSourceIndexPath: dataSourceIndexPath];

	return [collectionView cellForItemAtIndexPath:indexPath];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.selectedItemCollectionView != nil) {
        if (collectionView == self.selectedItemCollectionView) {
            self.selectedItemIndexPath = indexPath;
        } else {
            [self.selectedItemCollectionView deselectItemAtIndexPath:self.selectedItemIndexPath animated:NO];
            self.selectedItemCollectionView = collectionView;
            self.selectedItemIndexPath = indexPath;
        }
    } else {
        self.selectedItemCollectionView = collectionView;
        self.selectedItemIndexPath = indexPath;
    }

    NSIndexPath *dataSourceIndexPath = [self dataSourceIndexPathFromCollectionView:collectionView indexPath:indexPath];
    if ([self.delegate respondsToSelector:@selector(spreadsheetView:didSelectItemAtIndexPath:)]) {
        [self.delegate spreadsheetView:self didSelectItemAtIndexPath:dataSourceIndexPath];
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *dataSourceIndexPath = [self dataSourceIndexPathFromCollectionView:collectionView indexPath:indexPath];
    if ([self.delegate respondsToSelector:@selector(spreadsheetView:shouldShowMenuForItemAtIndexPath:)]) {
        return [self.delegate spreadsheetView:self shouldShowMenuForItemAtIndexPath:dataSourceIndexPath];
    }
    return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    NSIndexPath *dataSourceIndexPath = [self dataSourceIndexPathFromCollectionView:collectionView indexPath:indexPath];
    if ([self.delegate respondsToSelector:@selector(spreadsheetView:canPerformAction:forItemAtIndexPath:withSender:)]) {
        return [self.delegate spreadsheetView:self canPerformAction:action forItemAtIndexPath:dataSourceIndexPath withSender:sender];
    }
    return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    NSIndexPath *dataSourceIndexPath = [self dataSourceIndexPathFromCollectionView:collectionView indexPath:indexPath];
    if ([self.delegate respondsToSelector:@selector(spreadsheetView:performAction:forItemAtIndexPath:withSender:)]) {
        return [self.delegate spreadsheetView:self performAction:action forItemAtIndexPath:dataSourceIndexPath withSender:sender];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.controllingScrollView) {
    
        switch (scrollView.tag) {
            case MMSpreadsheetViewCollectionLowerLeft:
                [self lowerLeftCollectionViewDidScrollForScrollView:scrollView];
                break;
                
            case MMSpreadsheetViewCollectionUpperRight:
                [self upperRightCollectionViewDidScrollForScrollView:scrollView];
                break;
                
            case MMSpreadsheetViewCollectionLowerRight:
                [self lowerRightCollectionViewDidScrollForScrollView:scrollView];
                break;
        }
		if(_wantRefreshControl) {
			[self checkRefreshControlWithOpen:NO];
		}
    } else {
        [scrollView setContentOffset:scrollView.contentOffset animated:NO];
    }
}

- (void)lowerLeftCollectionViewDidScrollForScrollView:(UIScrollView *)scrollView {
    [self.lowerRightCollectionView setContentOffset:CGPointMake(self.lowerRightCollectionView.contentOffset.x, scrollView.contentOffset.y) animated:NO];
    [self updateVerticalScrollIndicator];

    if (scrollView.contentOffset.y <= 0.0f) {
        CGRect rect = self.upperLeftContainerView.frame;
        rect.origin.y = 0-scrollView.contentOffset.y;
        self.upperLeftContainerView.frame = rect;
        
        rect = self.upperRightContainerView.frame;
        rect.origin.y = 0-scrollView.contentOffset.y;
        self.upperRightContainerView.frame = rect;
    } else {
        CGRect rect = self.upperLeftContainerView.frame;
        rect.origin.y = 0.0f;
        self.upperLeftContainerView.frame = rect;
        
        rect = self.upperRightContainerView.frame;
        rect.origin.y = 0.0f;
        self.upperRightContainerView.frame = rect;
    }
}

- (void)upperRightCollectionViewDidScrollForScrollView:(UIScrollView *)scrollView {
    [self.lowerRightCollectionView setContentOffset:CGPointMake(scrollView.contentOffset.x, self.lowerRightCollectionView.contentOffset.y) animated:NO];
    [self updateHorizontalScrollIndicator];
    
    if (scrollView.contentOffset.x <= 0.0f) {
        CGRect rect = self.upperLeftContainerView.frame;
        rect.origin.x = 0-scrollView.contentOffset.x;
        self.upperLeftContainerView.frame = rect;
        
        rect = self.lowerLeftContainerView.frame;
        rect.origin.x = 0-scrollView.contentOffset.x;
        self.lowerLeftContainerView.frame = rect;
    } else {
        CGRect rect = self.upperLeftContainerView.frame;
        rect.origin.x = 0.0f;
        self.upperLeftContainerView.frame = rect;
        
        rect = self.lowerLeftContainerView.frame;
        rect.origin.x = 0.0f;
        self.lowerLeftContainerView.frame = rect;
    }
}

- (void)lowerRightCollectionViewDidScrollForScrollView:(UIScrollView *)scrollView {
    [self updateVerticalScrollIndicator];
    [self updateHorizontalScrollIndicator];

    CGPoint offset = CGPointMake(0.0f, scrollView.contentOffset.y);
    [self.lowerLeftCollectionView setContentOffset:offset animated:NO];
    offset = CGPointMake(scrollView.contentOffset.x, 0.0f);
    [self.upperRightCollectionView setContentOffset:offset animated:NO];
    
    if (scrollView.contentOffset.y <= 0.0f) {
        CGRect rect = self.upperLeftContainerView.frame;
        rect.origin.y = 0-scrollView.contentOffset.y;
        self.upperLeftContainerView.frame = rect;
        
        rect = self.upperRightContainerView.frame;
        rect.origin.y = 0-scrollView.contentOffset.y;
        self.upperRightContainerView.frame = rect;
    } else {
        CGRect rect = self.upperLeftContainerView.frame;
        rect.origin.y = 0.0f;
        self.upperLeftContainerView.frame = rect;
        
        rect = self.upperRightContainerView.frame;
        rect.origin.y = 0.0f;
        self.upperRightContainerView.frame = rect;
    }
    
    if (scrollView.contentOffset.x <= 0.0f) {
        CGRect rect = self.upperLeftContainerView.frame;
        rect.origin.x = 0-scrollView.contentOffset.x;
        
        self.upperLeftContainerView.frame = rect;
        rect = self.lowerLeftContainerView.frame;
        rect.origin.x = 0-scrollView.contentOffset.x;
        self.lowerLeftContainerView.frame = rect;
    } else {
        CGRect rect = self.upperLeftContainerView.frame;
        rect.origin.x = 0.0f;
        
        self.upperLeftContainerView.frame = rect;
        rect = self.lowerLeftContainerView.frame;
        rect.origin.x = 0.0f;
        self.lowerLeftContainerView.frame = rect;
    }
}

- (void)checkRefreshControlWithOpen:(BOOL)andOpen {
	CGRect r = _refreshControl.frame;
	r.origin.y = self.upperLeftContainerView.frame.origin.y - r.size.height;
	_refreshControl.frame = r;

	if(andOpen && !_openingRefreshControl && (r.origin.y > -r.size.height/2)) {
		startValue = r.origin.y;
		ratio = r.size.height/(startValue + r.size.height);
		self.blockingView = [[UIView alloc] initWithFrame:self.bounds];
		_blockingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_blockingView.backgroundColor = [UIColor clearColor];
		_blockingView.userInteractionEnabled = YES;

		[self addSubview:_blockingView];

		_openingRefreshControl = YES;


		if([_delegate respondsToSelector:@selector(refreshControlActive:)]) {
			dispatch_async(dispatch_get_main_queue(), ^
				{
					[self.refreshControl startRefresh];
					[self.delegate refreshControlActive:_refreshControl];
				});
		}
	}
	if(_openingRefreshControl) {
		CGRect rr = self.bounds;
		CGFloat diff =  r.origin.y - startValue;
		rr.origin.y = (CGFloat)round(diff*ratio);
		self.bounds = rr;
	}
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	self.isScrolling = YES;

    [self setScrollEnabledValue:NO scrollView:scrollView];
    
    if (self.controllingScrollView != scrollView) {
//        TOD0: What does this original code do????
//        [self.upperLeftCollectionView setContentOffset:self.upperLeftCollectionView.contentOffset animated:NO];
//        [self.lowerLeftCollectionView setContentOffset:self.lowerLeftCollectionView.contentOffset animated:NO];
//        [self.upperRightCollectionView setContentOffset:self.upperRightCollectionView.contentOffset animated:NO];
//        [self.lowerRightCollectionView setContentOffset:self.lowerRightCollectionView.contentOffset animated:NO];
        self.controllingScrollView = scrollView;
    }
    [self showScrollIndicators];

    [self setScrollEnabledValue:YES scrollView:scrollView];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    // Block UI if we're in a bounce.
    // Without this, you can lock the scroll views in a scroll which looks weird.
    CGPoint toffset = *targetContentOffset;
    switch (scrollView.tag) {
        case MMSpreadsheetViewCollectionLowerLeft: {
            BOOL willBouncePastZeroY = velocity.y < 0.0f && !(toffset.y > 0.0f);
            BOOL willBouncePastMaxY = toffset.y > self.lowerLeftCollectionView.contentSize.height - self.lowerLeftCollectionView.frame.size.height - 0.1f && velocity.y > 0.0f;
            if (willBouncePastZeroY || willBouncePastMaxY) {
                self.upperRightContainerView.userInteractionEnabled = NO;
                self.lowerRightContainerView.userInteractionEnabled = NO;
                self.lowerLeftBouncing = YES;
            }
			else if(self.snapToGrid) {
				*targetContentOffset = [self alignOffset:toffset collectionView:self.lowerLeftCollectionView];
			}
            break;
        }
            
        case MMSpreadsheetViewCollectionUpperRight: {
            BOOL willBouncePastZeroX = velocity.x < 0.0f && !(toffset.x > 0.0f);
            BOOL willBouncePastMaxX = toffset.x > self.upperRightCollectionView.contentSize.width - self.upperRightCollectionView.frame.size.width - 0.1f && velocity.x > 0.0f;
            if (willBouncePastZeroX || willBouncePastMaxX) {
                self.lowerRightContainerView.userInteractionEnabled = NO;
                self.lowerLeftContainerView.userInteractionEnabled = NO;
                self.upperRightBouncing = YES;
            }
			else if(self.snapToGrid) {
				*targetContentOffset = [self alignOffset:toffset collectionView:self.upperRightCollectionView];
			}
            break;
        }
            
        case MMSpreadsheetViewCollectionLowerRight: {
            BOOL willBouncePastZeroX = velocity.x < 0.0f && !(toffset.x > 0.0f);
            BOOL willBouncePastMaxX = toffset.x > self.upperRightCollectionView.contentSize.width - self.upperRightCollectionView.frame.size.width - 0.1f && velocity.x > 0.0f;
            BOOL willBouncePastZeroY = velocity.y < 0.0f && !(toffset.y > 0.0f);
            BOOL willBouncePastMaxY = toffset.y > self.lowerLeftCollectionView.contentSize.height - self.lowerLeftCollectionView.frame.size.height - 0.1f && velocity.y > 0.0f;
            if (willBouncePastZeroX || willBouncePastMaxX ||
                willBouncePastZeroY || willBouncePastMaxY) {
                self.upperRightContainerView.userInteractionEnabled = NO;
                self.lowerLeftContainerView.userInteractionEnabled = NO;
                self.lowerRightBouncing = YES;
            }
			else if(self.snapToGrid) {
				*targetContentOffset = [self alignOffset:toffset collectionView:self.lowerRightCollectionView];
			}
            break;
        }
    }
	// NSLog(@"%@scrollViewDidEndDragging : withVelocity", self.isScrolling ? @"" : @"-");
}

- (CGPoint)alignOffset:(CGPoint)pt collectionView:(UICollectionView *)collectionView {
	if(collectionView.numberOfSections == 0) {
		// Don't think this is possible but just in case...
		return pt;
	}
    MMGridLayout *layout = (MMGridLayout *)collectionView.collectionViewLayout;

	return [layout snapToGrid:pt];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if(_wantRefreshControl) {
		[self checkRefreshControlWithOpen:YES];
	}
	if(!decelerate) {
		[self scrollViewDidStop:scrollView];
	}
	//NSLog(@"%@scrollViewDidEndDragging : willDecelerate", self.isScrolling ? @"" : @"-");
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self scrollViewDidStop:scrollView];
}

- (void)scrollViewDidStop:(UIScrollView *)scrollView {
	if(!self.isScrolling) return;
	//NSLog(@"scrollViewDidStop !!!!!!!!!");

    self.upperRightContainerView.userInteractionEnabled = YES;
    self.lowerRightContainerView.userInteractionEnabled = YES;
    self.lowerLeftContainerView.userInteractionEnabled = YES;
    self.upperRightBouncing = NO;
    self.lowerLeftBouncing = NO;
    self.lowerRightBouncing = NO;

	// The problem with isTracking is that dragging the view around then letting up will still register isTracking (Apple bug?)
    if (!scrollView.isDecelerating && !scrollView.isDragging/* && !scrollView.isTracking*/) {
        [self setNeedsLayout];
        [self hideScrollIndicators];
		self.isScrolling = NO;
	}
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{	
	[self scrollViewDidStop:scrollView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
	[self scrollViewDidStop:scrollView];
}

@end

@interface MMRefreshControl ()
@property (nonatomic, strong, readwrite) UILabel *textLabel;
@property (nonatomic, strong, readwrite) UIActivityIndicatorView *indicator;

@end

@implementation MMRefreshControl

- (instancetype) initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		NSLayoutConstraint *c;

		self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		_indicator.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:_indicator];
		c = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_indicator attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
		[self addConstraint:c];
		c = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_indicator attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
		[self addConstraint:c];

		_indicator.color = [UIColor blackColor];
		_indicator.hidesWhenStopped = NO;

		self.textLabel = [UILabel new];
		_textLabel.translatesAutoresizingMaskIntoConstraints = NO;
		_textLabel.text = @"Refreshing…";
		_textLabel.font = [UIFont boldSystemFontOfSize:17];
		[self addSubview:_textLabel];

		c = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_textLabel attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
		[self addConstraint:c];
		c = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_textLabel attribute:NSLayoutAttributeBottom multiplier:1 constant:4];
		[self addConstraint:c];
		[_textLabel sizeToFit];

		self.backgroundColor = [UIColor whiteColor];

		CALayer *layer = self.layer;
		layer.borderWidth = 0.5;
		layer.borderColor = [UIColor grayColor].CGColor;
	}
	return self;
}

- (void)startRefresh {
	[_indicator startAnimating];
}

- (void)stopRefresh {
	MMSpreadsheetView *ssv = (MMSpreadsheetView *)self.superview;

	[ssv.blockingView removeFromSuperview];
	ssv.blockingView = nil;
	ssv.openingRefreshControl = NO;
	[ssv setNeedsLayout];

	CGRect bounds = ssv.bounds;
	bounds.origin.y = 0;

	[UIView animateWithDuration:0.250 animations:^{
		ssv.bounds = bounds;
	} completion:^(BOOL finished)
	{
		[_indicator stopAnimating];
	}];
}

@end

