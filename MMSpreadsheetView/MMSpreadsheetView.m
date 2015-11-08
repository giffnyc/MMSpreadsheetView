// Copyright (c) 2013 Mutual Mobile (http://mutualmobile.com/)
// Copyright (c) 2015 David Hoerl
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

typedef NS_ENUM(NSInteger, MMSpreadsheetViewCollection) {
	MMSpreadsheetViewCollectionUpperLeft = 1,
	MMSpreadsheetViewCollectionUpperRight,
	MMSpreadsheetViewCollectionLowerLeft,
	MMSpreadsheetViewCollectionLowerRight,
	MMSpreadsheetViewCollectionOverLay,
};

typedef NS_ENUM(NSInteger, MMSpreadsheetHeaderConfiguration) {
	MMSpreadsheetHeaderConfigurationNone = 0,
	MMSpreadsheetHeaderConfigurationColumnOnly,
	MMSpreadsheetHeaderConfigurationRowOnly,
	MMSpreadsheetHeaderConfigurationBoth,
};

const static CGFloat MMSpreadsheetViewGridSpace = 1.0f;

@interface MMScrollView : UIScrollView
@property (nonatomic, strong, readwrite) UIScrollView *shadowScrollView;
@end

@interface MMSpreadsheetView () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>

@property (nonatomic, assign) NSUInteger headerRowCount;
@property (nonatomic, assign) NSUInteger headerColumnCount;
@property (nonatomic, assign) MMSpreadsheetHeaderConfiguration spreadsheetHeaderConfiguration;
@property (nonatomic, strong) UIScrollView *controllingScrollView;
@property (nonatomic, strong) MMScrollView *overlayScrollView;

@property (nonatomic, strong) UIView *upperLeftContainerView;
@property (nonatomic, strong) UIView *upperRightContainerView;
@property (nonatomic, strong) UIView *lowerLeftContainerView;
@property (nonatomic, strong) UIView *lowerRightContainerView;

@property (nonatomic, strong) UICollectionView *upperLeftCollectionView;
@property (nonatomic, strong) UICollectionView *upperRightCollectionView;
@property (nonatomic, strong) UICollectionView *lowerLeftCollectionView;
@property (nonatomic, strong) UICollectionView *lowerRightCollectionView;
@property (nonatomic, strong) NSArray<UICollectionView *> *collectionViews;

//@property (nonatomic, assign, getter = isUpperRightBouncing) BOOL upperRightBouncing;
//@property (nonatomic, assign, getter = isLowerLeftBouncing) BOOL lowerLeftBouncing;
//@property (nonatomic, assign, getter = isLowerRightBouncing) BOOL lowerRightBouncing;

@property (nonatomic, strong) UICollectionView *selectedItemCollectionView;
@property (nonatomic, strong) NSIndexPath *selectedItemIndexPath;

@property (nonatomic, assign) BOOL openingRefreshControl;
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
		// Call below in viewDidLoad
		//[self commonInitWithNumberOfHeaderRows:0 numberOfHeaderColumns:0];
	}

	return self;
}

#pragma mark - MMSpreadsheetView designated initializer

- (instancetype)initWithNumberOfHeaderRows:(NSUInteger)headerRowCount numberOfHeaderColumns:(NSUInteger)headerColumnCount frame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
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

	self.overlayScrollView = [[MMScrollView alloc] initWithFrame:self.bounds];
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_overlayScrollView.delegate = self;
	_overlayScrollView.contentSize = CGSizeMake(self.bounds.size.width, self.bounds.size.height);
	_overlayScrollView.scrollEnabled = YES;
	_overlayScrollView.tag = 99;

	// Defaults, need here because need overlay defined first
	self.bounces = YES;
	self.horizontalBounce = YES;
	self.verticalBounce = YES;
	self.scrollsToTop = YES;

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
	[self addSubview:_overlayScrollView];

	// sets proper inset for translucent tab bar if scrolling underneath it
	[self hideTabBar:NO withAnimationDuration: 0 coordinator: nil];

}

- (void)correctContentOffset:(BOOL)wasAtMax {
	CGFloat maxLeftOffset = [self maxOffset:_lowerLeftCollectionView withInset:_lowerLeftCollectionView.contentInset];
	CGFloat maxRightOffset = [self maxOffset:_lowerRightCollectionView withInset:_lowerRightCollectionView.contentInset];
	CGPoint contentOffsetLeft = _lowerLeftCollectionView.contentOffset;
	CGPoint contentOffsetRight = _lowerRightCollectionView.contentOffset;
	if(contentOffsetLeft.y > maxLeftOffset || wasAtMax) {
		contentOffsetLeft.y = maxLeftOffset;
		_lowerLeftCollectionView.contentOffset = contentOffsetLeft;
	}
	if(contentOffsetRight.y > maxRightOffset || wasAtMax) {
		contentOffsetRight.y = maxRightOffset;
		_lowerRightCollectionView.contentOffset = contentOffsetRight;
	}
}


- (void)hideTabBar:(BOOL)hide withAnimationDuration:(CGFloat)animateDuration coordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	UITabBarController *tabBarController = _navigationController.tabBarController;
	UITabBar *tabBar = tabBarController.tabBar;
	if(tabBar.translucent) {
		CGFloat offset = hide ? 0 : tabBar.frame.size.height;

		UIEdgeInsets loadingInsetLeft = _lowerLeftCollectionView.contentInset; // lowerLeftCollectionView.contentInset
		UIEdgeInsets loadingInsetRight = _lowerRightCollectionView.contentInset;

		CGPoint contentOffsetLeft = _lowerLeftCollectionView.contentOffset;
		CGPoint contentOffsetRight = _lowerRightCollectionView.contentOffset;

		BOOL lowerLeftAtMax = fabs(contentOffsetLeft.y - [self maxOffset:_lowerLeftCollectionView withInset:loadingInsetLeft]) < 3; // possible rounding so make it close
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
			self.overlayScrollView.contentInset = loadingInsetLeft;
			self.overlayScrollView.contentOffset = contentOffsetRight;
			self.overlayScrollView.scrollIndicatorInsets = loadingInsetLeft;
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
	for(UICollectionView *cv in _collectionViews) {
		[cv registerClass:cellClass forCellWithReuseIdentifier:identifier];
	}
}

- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
	NSIndexPath *collectionViewIndexPath = [self collectionViewIndexPathFromDataSourceIndexPath:indexPath];
	UICollectionView *collectionView = [self collectionViewForDataSourceIndexPath:indexPath];
	NSAssert(collectionView, @"No collectionView Returned!");
	[collectionView deselectItemAtIndexPath:collectionViewIndexPath animated:animated];
}

- (void)reloadData {
	for(UICollectionView *cv in _collectionViews) {
		[cv reloadData];
	}
	[self setNeedsLayout];	// In case transition between some "data" rows and none
}

- (void)flashScrollIndicators {
	[_overlayScrollView flashScrollIndicators];
}

#pragma mark - View Setup functions

- (void)setupSubviews {
	switch (_spreadsheetHeaderConfiguration) {
	case MMSpreadsheetHeaderConfigurationNone:
		[self setupLowerRightView];
		self.collectionViews = @[ _lowerRightCollectionView];
		break;
		
	case MMSpreadsheetHeaderConfigurationColumnOnly:
		[self setupLowerLeftView];
		[self setupLowerRightView];
		self.collectionViews = @[ _lowerLeftCollectionView, _lowerRightCollectionView];
		break;
		
	case MMSpreadsheetHeaderConfigurationRowOnly:
		[self setupUpperRightView];
		[self setupLowerRightView];
		self.collectionViews = @[ _upperRightCollectionView, _lowerRightCollectionView];
		break;
		
	case MMSpreadsheetHeaderConfigurationBoth:
		[self setupUpperLeftView];
		[self setupUpperRightView];
		[self setupLowerLeftView];
		[self setupLowerRightView];
		self.collectionViews = @[ _upperLeftCollectionView, _upperRightCollectionView, _lowerLeftCollectionView, _lowerRightCollectionView];
		break;
		
	default:
		NSAssert(NO, @"What have you done?");
		break;
	}
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

	collectionView.scrollEnabled = NO;
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
	[self setupContainerSubview:_upperLeftContainerView
				 collectionView:_upperLeftCollectionView
							tag:MMSpreadsheetViewCollectionUpperLeft];
	//_upperLeftCollectionView.scrollEnabled = NO;
}

- (void)setupUpperRightView {
	self.upperRightContainerView = [[UIView alloc] initWithFrame:CGRectZero];
	self.upperRightCollectionView = [self setupCollectionViewWithGridLayout];
//[_upperRightCollectionView.panGestureRecognizer addTarget:self action:@selector(handleUpperRightPanGesture:)];
	[self setupContainerSubview:_upperRightContainerView
				 collectionView:_upperRightCollectionView
							tag:MMSpreadsheetViewCollectionUpperRight];

	//_upperRightCollectionView.scrollEnabled = NO;
	//_upperRightCollectionView.alwaysBounceVertical = NO;
}

- (void)setupLowerLeftView {
	self.lowerLeftContainerView = [[UIView alloc] initWithFrame:CGRectZero];
	self.lowerLeftCollectionView = [self setupCollectionViewWithGridLayout];
//[_lowerLeftCollectionView.panGestureRecognizer addTarget:self action:@selector(handleLowerLeftPanGesture:)];

	[self setupContainerSubview:_lowerLeftContainerView
				 collectionView:_lowerLeftCollectionView
							tag:MMSpreadsheetViewCollectionLowerLeft];
}

- (void)setupLowerRightView {
	self.lowerRightContainerView = [[UIView alloc] initWithFrame:CGRectZero];
	self.lowerRightCollectionView = [self setupCollectionViewWithGridLayout];
//[_lowerRightCollectionView.panGestureRecognizer addTarget:self action:@selector(handleLowerRightPanGesture:)];

	[self setupContainerSubview:_lowerRightContainerView
				 collectionView:_lowerRightCollectionView
							tag:MMSpreadsheetViewCollectionLowerRight];
}

/*
	for(UICollectionView *cv in _collectionViews) {
		[cv registerClass:cellClass forCellWithReuseIdentifier:identifier];
	}

*/
- (void)layoutSubviews {
	if(_openingRefreshControl) return;	// setting bounds for refreshControl
	[super layoutSubviews];

	NSIndexPath *indexPathZero = [NSIndexPath indexPathForItem:0 inSection:0];

	CGRect bounds = self.bounds;
	CGSize boundsSize = bounds.size;

	switch (_spreadsheetHeaderConfiguration) {
	case MMSpreadsheetHeaderConfigurationNone:
		_lowerRightContainerView.frame = self.bounds;
		break;
		
	case MMSpreadsheetHeaderConfigurationColumnOnly: {
		CGSize size = _lowerLeftCollectionView.collectionViewLayout.collectionViewContentSize;
		CGSize cellSize = [self collectionView:_lowerRightCollectionView
										layout:_lowerRightCollectionView.collectionViewLayout
						sizeForItemAtIndexPath:indexPathZero];
		CGFloat maxLockDistance = boundsSize.width - cellSize.width;
		if (size.width > maxLockDistance) {
			NSAssert(NO, @"Width of header too large! Reduce the number of header columns.");
		}
		_lowerLeftContainerView.frame = CGRectMake(0.0f,
													   0.0f,
													   size.width,
													   boundsSize.height);
		_lowerRightContainerView.frame = CGRectMake(size.width + MMSpreadsheetViewGridSpace,
														0.0f,
														boundsSize.width - size.width - MMSpreadsheetViewGridSpace,
														boundsSize.height);
	}	break;

	case MMSpreadsheetHeaderConfigurationRowOnly: {
		CGSize size = _upperRightCollectionView.collectionViewLayout.collectionViewContentSize;
		CGSize cellSize = [self collectionView:_lowerRightCollectionView
										layout:_lowerRightCollectionView.collectionViewLayout
						sizeForItemAtIndexPath:indexPathZero];
		CGFloat maxLockDistance = boundsSize.height - cellSize.height;
		if (size.height > maxLockDistance) {
			NSAssert(NO, @"Height of header too large! Reduce the number of header rows.");
		}
		_upperRightContainerView.frame = CGRectMake(0.0f,
														0.0f,
														boundsSize.width,
														size.height);
		_lowerRightContainerView.frame = CGRectMake(0.0f,
														size.height + MMSpreadsheetViewGridSpace,
														boundsSize.width,
														boundsSize.height - size.height - MMSpreadsheetViewGridSpace);
	}	break;

	case MMSpreadsheetHeaderConfigurationBoth: {
		CGSize size = _upperLeftCollectionView.collectionViewLayout.collectionViewContentSize;
#if 0 // trying to be helpful, maybe in portrait it won't show a whole data cell, well then rotate it it would. Bottom line: test on a 4s!
		CGSize cellSize = [self collectionView:_lowerRightCollectionView
										layout:_lowerRightCollectionView.collectionViewLayout
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
		_upperLeftContainerView.frame = CGRectMake(0.0f,
														0.0f,
														size.width,
														size.height);
		_upperRightContainerView.frame = CGRectMake(size.width + MMSpreadsheetViewGridSpace,
														0.0f,
														boundsSize.width - size.width - MMSpreadsheetViewGridSpace,
														size.height);
		_lowerLeftContainerView.frame = CGRectMake(0.0f,
														size.height + MMSpreadsheetViewGridSpace,
														size.width,
														boundsSize.height - size.height - MMSpreadsheetViewGridSpace);
		_lowerRightContainerView.frame = CGRectMake(size.width + MMSpreadsheetViewGridSpace,
														size.height + MMSpreadsheetViewGridSpace,
														boundsSize.width - size.width - MMSpreadsheetViewGridSpace,
														boundsSize.height - size.height - MMSpreadsheetViewGridSpace);

		// Effective size of Secret Scroll View is the bounds of what you can see, plus the unviewable content of the bottomRight
		CGSize topLeft = _upperLeftContainerView.bounds.size;
		CGSize botRight = _lowerRightCollectionView.contentSize;
		_overlayScrollView.contentSize = CGSizeMake(topLeft.width + botRight.width, topLeft.height + botRight.height);
	}	break;

	default:
		NSAssert(NO, @"What have you done?");
		break;
	}
}

#pragma mark - UIPanGestureRecognizer callbacks

//- (void)handleUpperRightPanGesture:(UIPanGestureRecognizer *)recognizer {
//	if (recognizer.state == UIGestureRecognizerStateBegan) {
//		_lowerLeftContainerView.userInteractionEnabled = NO;
//		_lowerRightContainerView.userInteractionEnabled = NO;
//	}
//	else if (recognizer.state == UIGestureRecognizerStateEnded) {
//		if (self.isUpperRightBouncing == NO) {
//			_lowerLeftContainerView.userInteractionEnabled = YES;
//			_lowerRightContainerView.userInteractionEnabled = YES;
//		}
//	}
//}
//
//- (void)handleLowerLeftPanGesture:(UIPanGestureRecognizer *)recognizer {
//	if (recognizer.state == UIGestureRecognizerStateBegan) {
//		_upperRightContainerView.userInteractionEnabled = NO;
//		_lowerRightContainerView.userInteractionEnabled = NO;
//	}
//	else if (recognizer.state == UIGestureRecognizerStateEnded) {
//		if (self.isLowerLeftBouncing == NO) {
//			_upperRightContainerView.userInteractionEnabled = YES;
//			_lowerRightContainerView.userInteractionEnabled = YES;
//		}
//	}
//}
//
//- (void)handleLowerRightPanGesture:(UIPanGestureRecognizer *)recognizer {
//	if (recognizer.state == UIGestureRecognizerStateBegan) {
//		// NSLog(@"BEGAN!!! %@", NSStringFromCGPoint([recognizer velocityInView:self]));
//		_upperRightContainerView.userInteractionEnabled = NO;
//		_lowerLeftContainerView.userInteractionEnabled = NO;
//	}
//	else if (recognizer.state == UIGestureRecognizerStateEnded) {
//		if (self.isLowerRightBouncing == NO) {
//			_upperRightContainerView.userInteractionEnabled = YES;
//			_lowerLeftContainerView.userInteractionEnabled = YES;
//		}
//	}
//}

#pragma mark - OverLay scroll property setter

- (void)setBounces:(BOOL)bounces {
	_bounces = bounces;
	_overlayScrollView.bounces = bounces;
}
- (void)setHorizontalBounce:(BOOL)bounces {
	_horizontalBounce = bounces;
	_overlayScrollView.alwaysBounceHorizontal = bounces;
}
- (void)setVerticalBounce:(BOOL)bounces {
	_verticalBounce = bounces;
	_overlayScrollView.alwaysBounceVertical = bounces;
}
- (void)setDirectionalLockEnabled:(BOOL)enabled {
	_directionalLockEnabled = enabled;
	_overlayScrollView.directionalLockEnabled = enabled;
}
- (void)setScrollsToTop:(BOOL)scrollsToTop {
	_scrollsToTop = scrollsToTop;
	_overlayScrollView.scrollsToTop = scrollsToTop;
}

#pragma mark - DataSource property setter

- (void)setDataSource:(id<MMSpreadsheetViewDataSource>)dataSource {
	_dataSource = dataSource;
	if (_upperLeftCollectionView) {
		[self initializeCollectionViewLayoutItemSize:_upperLeftCollectionView name:@"Left Corner"];
	}
	if (_upperRightCollectionView) {
		[self initializeCollectionViewLayoutItemSize:_upperRightCollectionView name:@"Column Labels"];
	}
	if (_lowerLeftCollectionView) {
		[self initializeCollectionViewLayoutItemSize:_lowerLeftCollectionView name:@"Row Labels"];
	}
	if (_lowerRightCollectionView) {
		[self initializeCollectionViewLayoutItemSize:_lowerRightCollectionView name:@"Data Cells"];
	}

	// Validate dataSource & header configuration
	NSInteger maxRows = [_dataSource numberOfRowsInSpreadsheetView:self];
	NSInteger maxCols = [_dataSource numberOfColumnsInSpreadsheetView:self];
	
	NSAssert(_headerColumnCount <= maxCols, @"Invalid configuration: number of header columns must be less than or equal to (dataSource) numberOfColumnsInSpreadsheetView");
	NSAssert(_headerRowCount <= maxRows, @"Invalid configuration: number of header rows must be less than or equal to (dataSource) numberOfRowsInSpreadsheetView");
}

- (void)initializeCollectionViewLayoutItemSize:(UICollectionView *)collectionView name:(NSString*)name {
	MMGridLayout *layout = (MMGridLayout *)collectionView.collectionViewLayout;
	layout.name = name;
}

#pragma mark - Custom functions that don't go anywhere else

- (UICollectionView *)collectionViewForDataSourceIndexPath:(NSIndexPath *)indexPath {
	UICollectionView *collectionView = nil;
	switch (_spreadsheetHeaderConfiguration) {
	case MMSpreadsheetHeaderConfigurationNone:
		collectionView = _lowerRightCollectionView;
		break;
		
	case MMSpreadsheetHeaderConfigurationColumnOnly:
		if (indexPath.mmSpreadsheetColumn >= _headerColumnCount) {
			collectionView = _lowerRightCollectionView;
		} else {
			collectionView = _lowerLeftCollectionView;
		}
		break;
		
	case MMSpreadsheetHeaderConfigurationRowOnly:
		if (indexPath.mmSpreadsheetRow >= _headerRowCount) {
			collectionView = _lowerRightCollectionView;
		}
		else {
			collectionView = _upperRightCollectionView;
		}
		break;
		
	case MMSpreadsheetHeaderConfigurationBoth:
		if (indexPath.mmSpreadsheetRow >= _headerRowCount) {
			if (indexPath.mmSpreadsheetColumn >= _headerColumnCount) {
				collectionView = _lowerRightCollectionView;
			} else {
				collectionView = _lowerLeftCollectionView;
			}
		}
		else {
			if (indexPath.mmSpreadsheetColumn >= _headerColumnCount) {
				collectionView = _upperRightCollectionView;
			} else {
				collectionView = _upperLeftCollectionView;
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
			mmSpreadsheetColumn += _headerColumnCount;
			break;
			
		case MMSpreadsheetViewCollectionLowerLeft:
			mmSpreadsheetRow += _headerRowCount;
			break;
			
		case MMSpreadsheetViewCollectionLowerRight:
			mmSpreadsheetRow += _headerRowCount;
			mmSpreadsheetColumn += _headerColumnCount;
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
		mmSpreadsheetColumn -= _headerColumnCount;
		break;
		
	case MMSpreadsheetViewCollectionLowerLeft:
		mmSpreadsheetRow -= _headerRowCount;
		break;
		
	case MMSpreadsheetViewCollectionLowerRight:
		mmSpreadsheetRow -= _headerRowCount;
		mmSpreadsheetColumn -= _headerColumnCount;
		break;
		
	default:
		NSAssert(NO, @"What have you done?");
		break;
	}
	return [NSIndexPath indexPathForItem:mmSpreadsheetColumn inSection:mmSpreadsheetRow];
}

//- (void)setScrollEnabledValue:(BOOL)scrollEnabled scrollView:(UIScrollView *)scrollView {
//	switch (scrollView.tag) {
//	case MMSpreadsheetViewCollectionUpperLeft:
//		// Don't think we need to do anything here
//		break;
//		
//	case MMSpreadsheetViewCollectionUpperRight:
//		_lowerLeftCollectionView.scrollEnabled = scrollEnabled;
//		_lowerRightCollectionView.scrollEnabled = scrollEnabled;
//		break;
//		
//	case MMSpreadsheetViewCollectionLowerLeft:
//		_upperRightCollectionView.scrollEnabled = scrollEnabled;
//		_lowerRightCollectionView.scrollEnabled = scrollEnabled;
//		break;
//		
//	case MMSpreadsheetViewCollectionLowerRight:
//		_upperRightCollectionView.scrollEnabled = scrollEnabled;
//		_lowerLeftCollectionView.scrollEnabled = scrollEnabled;
//		break;
//	}
//}

- (void)checkRefreshControlWithOpen:(BOOL)andOpen {
	CGRect r = _refreshControl.frame;
	r.origin.y = _upperLeftContainerView.frame.origin.y - r.size.height;
	_refreshControl.frame = r;

	if(andOpen && !_openingRefreshControl && (r.origin.y > -r.size.height/2)) {
		startValue = r.origin.y;
		ratio = r.size.height/(startValue + r.size.height);
		_openingRefreshControl = YES;

		if([_delegate respondsToSelector:@selector(refreshControlActive:)]) {
			dispatch_async(dispatch_get_main_queue(), ^
				{
					[_refreshControl startRefresh];
					[_delegate refreshControlActive:_refreshControl];
				});
		}
	}
	if(_openingRefreshControl) {
		CGRect rr = self.bounds;
		CGFloat diff =	r.origin.y - startValue;
		rr.origin.y = (CGFloat)round(diff*ratio);
		self.bounds = rr;
	}
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	NSIndexPath *dataSourceIndexPath = [self dataSourceIndexPathFromCollectionView:collectionView indexPath:indexPath];
	CGSize size = [_dataSource spreadsheetView:self sizeForItemAtIndexPath:dataSourceIndexPath];
	return size;
}

#pragma mark - UICollectionViewDataSource pass-through

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	NSInteger rowCount = [_dataSource numberOfRowsInSpreadsheetView:self];
	NSInteger adjustedRows = 1;
	
	switch (collectionView.tag) {
	case MMSpreadsheetViewCollectionUpperLeft:
	case MMSpreadsheetViewCollectionUpperRight:
		adjustedRows = _headerRowCount;
		break;

	case MMSpreadsheetViewCollectionLowerLeft:
	case MMSpreadsheetViewCollectionLowerRight:
		adjustedRows = rowCount - _headerRowCount;
		break;

	default:
		NSAssert(NO, @"What have you done?");
		break;
	}
	return adjustedRows == 0 ? 1 : adjustedRows; // No "data"
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	NSInteger columnCount = [_dataSource numberOfColumnsInSpreadsheetView:self];
	NSInteger rowCount = [_dataSource numberOfRowsInSpreadsheetView:self];

	NSInteger items = 0;
	switch (collectionView.tag) {
	case MMSpreadsheetViewCollectionUpperLeft:
		items = _headerColumnCount;
		break;
		
	case MMSpreadsheetViewCollectionUpperRight:
		items = columnCount - _headerColumnCount;
		break;
		
	case MMSpreadsheetViewCollectionLowerLeft:
		items = rowCount == _headerRowCount ? 0 : _headerColumnCount; // No "data"
		break;
		
	case MMSpreadsheetViewCollectionLowerRight:
		items = rowCount == _headerRowCount ? 0 : (columnCount - _headerColumnCount); // No "data"
		break;
		
	default:
		NSAssert(NO, @"What have you done?");
		break;
	}

	return items;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	NSIndexPath *dataSourceIndexPath = [self dataSourceIndexPathFromCollectionView:collectionView indexPath:indexPath];
	UICollectionViewCell *cell = [_dataSource spreadsheetView:self cellForItemAtIndexPath:dataSourceIndexPath];
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
	if (_selectedItemCollectionView != nil) {
		if (collectionView == _selectedItemCollectionView) {
			_selectedItemIndexPath = indexPath;
		} else {
			[_selectedItemCollectionView deselectItemAtIndexPath:_selectedItemIndexPath animated:NO];
			_selectedItemCollectionView = collectionView;
			_selectedItemIndexPath = indexPath;
		}
	} else {
		_selectedItemCollectionView = collectionView;
		_selectedItemIndexPath = indexPath;
	}

	NSIndexPath *dataSourceIndexPath = [self dataSourceIndexPathFromCollectionView:collectionView indexPath:indexPath];
	if ([_delegate respondsToSelector:@selector(spreadsheetView:didSelectItemAtIndexPath:)]) {
		[_delegate spreadsheetView:self didSelectItemAtIndexPath:dataSourceIndexPath];
	}
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	NSIndexPath *dataSourceIndexPath = [self dataSourceIndexPathFromCollectionView:collectionView indexPath:indexPath];
	if ([_delegate respondsToSelector:@selector(spreadsheetView:shouldShowMenuForItemAtIndexPath:)]) {
		return [_delegate spreadsheetView:self shouldShowMenuForItemAtIndexPath:dataSourceIndexPath];
	}
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	NSIndexPath *dataSourceIndexPath = [self dataSourceIndexPathFromCollectionView:collectionView indexPath:indexPath];
	if ([_delegate respondsToSelector:@selector(spreadsheetView:canPerformAction:forItemAtIndexPath:withSender:)]) {
		return [_delegate spreadsheetView:self canPerformAction:action forItemAtIndexPath:dataSourceIndexPath withSender:sender];
	}
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	NSIndexPath *dataSourceIndexPath = [self dataSourceIndexPathFromCollectionView:collectionView indexPath:indexPath];
	if ([_delegate respondsToSelector:@selector(spreadsheetView:performAction:forItemAtIndexPath:withSender:)]) {
		return [_delegate spreadsheetView:self performAction:action forItemAtIndexPath:dataSourceIndexPath withSender:sender];
	}
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)sv {
	UIScrollView *scrollView;
	if(sv == _overlayScrollView) {

//NSLog(@"SV DID : offset %@ shadow=%d",
//NSStringFromCGPoint(secretScrollView.contentOffset),
//(int)secretScrollView.shadowScrollView.tag
//);
		scrollView = _overlayScrollView.shadowScrollView;
		if(!scrollView) return; // early setup
		scrollView.contentOffset = _overlayScrollView.contentOffset;
		//[scrollView setContentOffset:secretScrollView.contentOffset animated:NO];
	} else {
		scrollView = sv;
	}

	if (scrollView == _controllingScrollView) {
//NSLog(@"	Controlling");
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
	[_lowerRightCollectionView setContentOffset:CGPointMake(_lowerRightCollectionView.contentOffset.x, scrollView.contentOffset.y) animated:NO];
//	  [self updateVerticalScrollIndicator];

	if (scrollView.contentOffset.y <= 0.0f) {
		CGRect rect = _upperLeftContainerView.frame;
		rect.origin.y = 0-scrollView.contentOffset.y;
		_upperLeftContainerView.frame = rect;
		
		rect = _upperRightContainerView.frame;
		rect.origin.y = 0-scrollView.contentOffset.y;
		_upperRightContainerView.frame = rect;
	} else {
		CGRect rect = _upperLeftContainerView.frame;
		rect.origin.y = 0.0f;
		_upperLeftContainerView.frame = rect;
		
		rect = _upperRightContainerView.frame;
		rect.origin.y = 0.0f;
		_upperRightContainerView.frame = rect;
	}
}

- (void)upperRightCollectionViewDidScrollForScrollView:(UIScrollView *)scrollView {
	[_lowerRightCollectionView setContentOffset:CGPointMake(scrollView.contentOffset.x, _lowerRightCollectionView.contentOffset.y) animated:NO];
//	  [self updateHorizontalScrollIndicator];

	if (scrollView.contentOffset.x <= 0.0f) {
		CGRect rect = _upperLeftContainerView.frame;
		rect.origin.x = 0-scrollView.contentOffset.x;
		_upperLeftContainerView.frame = rect;
		
		rect = _lowerLeftContainerView.frame;
		rect.origin.x = 0-scrollView.contentOffset.x;
		_lowerLeftContainerView.frame = rect;
	} else {
		CGRect rect = _upperLeftContainerView.frame;
		rect.origin.x = 0.0f;
		_upperLeftContainerView.frame = rect;
		
		rect = _lowerLeftContainerView.frame;
		rect.origin.x = 0.0f;
		_lowerLeftContainerView.frame = rect;
	}
}

- (void)lowerRightCollectionViewDidScrollForScrollView:(UIScrollView *)scrollView {
	CGPoint offset = CGPointMake(0.0f, scrollView.contentOffset.y);
	[_lowerLeftCollectionView setContentOffset:offset animated:NO];
	offset = CGPointMake(scrollView.contentOffset.x, 0.0f);
	[_upperRightCollectionView setContentOffset:offset animated:NO];
	
	if (scrollView.contentOffset.y <= 0.0f) {
		CGRect rect = _upperLeftContainerView.frame;
		rect.origin.y = 0-scrollView.contentOffset.y;
		_upperLeftContainerView.frame = rect;
		
		rect = _upperRightContainerView.frame;
		rect.origin.y = 0-scrollView.contentOffset.y;
		_upperRightContainerView.frame = rect;
	} else {
		CGRect rect = _upperLeftContainerView.frame;
		rect.origin.y = 0.0f;
		_upperLeftContainerView.frame = rect;
		
		rect = _upperRightContainerView.frame;
		rect.origin.y = 0.0f;
		_upperRightContainerView.frame = rect;
	}
	
	if (scrollView.contentOffset.x <= 0.0f) {
		CGRect rect = _upperLeftContainerView.frame;
		rect.origin.x = 0-scrollView.contentOffset.x;
		
		_upperLeftContainerView.frame = rect;
		rect = _lowerLeftContainerView.frame;
		rect.origin.x = 0-scrollView.contentOffset.x;
		_lowerLeftContainerView.frame = rect;
	} else {
		CGRect rect = _upperLeftContainerView.frame;
		rect.origin.x = 0.0f;
		
		_upperLeftContainerView.frame = rect;
		rect = _lowerLeftContainerView.frame;
		rect.origin.x = 0.0f;
		_lowerLeftContainerView.frame = rect;
	}
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)sv {
	_isScrolling = YES;

	UIScrollView *scrollView;
	if(sv == _overlayScrollView) {
		scrollView = _overlayScrollView.shadowScrollView;
		if(!scrollView) return;
		scrollView.contentOffset = _overlayScrollView.contentOffset;
		//[scrollView setContentOffset:secretScrollView.contentOffset animated:NO];
	} else {
		assert(!"Impossible");
	}

NSLog(@"SV WILL BEGIN");
	_controllingScrollView = scrollView;

//	[self setScrollEnabledValue:NO scrollView:scrollView];
	
//	if (_controllingScrollView != scrollView) {
//		// TOD0: What does this original code do? Maybe in case it was animating, to force it to stop???
//		[_upperLeftCollectionView setContentOffset:_upperLeftCollectionView.contentOffset animated:NO];
//		[_lowerLeftCollectionView setContentOffset:_lowerLeftCollectionView.contentOffset animated:NO];
//		[_upperRightCollectionView setContentOffset:_upperRightCollectionView.contentOffset animated:NO];
//		[_lowerRightCollectionView setContentOffset:_lowerRightCollectionView.contentOffset animated:NO];
//	}
//	  [self showScrollIndicators];

//	[self setScrollEnabledValue:YES scrollView:scrollView];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)sv withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
	// Block UI if we're in a bounce.
	// Without this, you can lock the scroll views in a scroll which looks weird.

	UIScrollView *scrollView;
	if(sv == _overlayScrollView) {
		scrollView = _overlayScrollView.shadowScrollView;
		if(!scrollView) return;
		scrollView.contentOffset = _overlayScrollView.contentOffset;
		//[scrollView setContentOffset:secretScrollView.contentOffset animated:NO];
	} else {
		assert(!"Impossible");
	}

	CGPoint toffset = *targetContentOffset;
	switch (scrollView.tag) {
	case MMSpreadsheetViewCollectionLowerLeft: {
		BOOL willBouncePastZeroY = velocity.y < 0.0f && !(toffset.y > 0.0f);
		BOOL willBouncePastMaxY = toffset.y > _lowerLeftCollectionView.contentSize.height - _lowerLeftCollectionView.frame.size.height - 0.1f && velocity.y > 0.0f;
		if (willBouncePastZeroY || willBouncePastMaxY) {
//			_upperRightContainerView.userInteractionEnabled = NO;
//			_lowerRightContainerView.userInteractionEnabled = NO;
//			_lowerLeftBouncing = YES;
		}
		else if(_snapToGrid) {
			*targetContentOffset = [self alignOffset:toffset collectionView:_lowerLeftCollectionView];
		}
	}	break;

	case MMSpreadsheetViewCollectionUpperRight: {
		BOOL willBouncePastZeroX = velocity.x < 0.0f && !(toffset.x > 0.0f);
		BOOL willBouncePastMaxX = toffset.x > _upperRightCollectionView.contentSize.width - _upperRightCollectionView.frame.size.width - 0.1f && velocity.x > 0.0f;
		if (willBouncePastZeroX || willBouncePastMaxX) {
//			_lowerRightContainerView.userInteractionEnabled = NO;
//			_lowerLeftContainerView.userInteractionEnabled = NO;
//			_upperRightBouncing = YES;
		}
		else if(_snapToGrid) {
			*targetContentOffset = [self alignOffset:toffset collectionView:_upperRightCollectionView];
		}
	}	break;

	case MMSpreadsheetViewCollectionLowerRight: {
		BOOL willBouncePastZeroX = velocity.x < 0.0f && !(toffset.x > 0.0f);
		BOOL willBouncePastMaxX = toffset.x > _upperRightCollectionView.contentSize.width - _upperRightCollectionView.frame.size.width - 0.1f && velocity.x > 0.0f;
		BOOL willBouncePastZeroY = velocity.y < 0.0f && !(toffset.y > 0.0f);
		BOOL willBouncePastMaxY = toffset.y > _lowerLeftCollectionView.contentSize.height - _lowerLeftCollectionView.frame.size.height - 0.1f && velocity.y > 0.0f;
		if (willBouncePastZeroX || willBouncePastMaxX ||
			willBouncePastZeroY || willBouncePastMaxY) {
//			_upperRightContainerView.userInteractionEnabled = NO;
//			_lowerLeftContainerView.userInteractionEnabled = NO;
//			_lowerRightBouncing = YES;
		}
		else if(_snapToGrid) {
			*targetContentOffset = [self alignOffset:toffset collectionView:_lowerRightCollectionView];
		}
	}	break;
	}
	// NSLog(@"%@scrollViewDidEndDragging : withVelocity", _isScrolling ? @"" : @"-");
}

- (CGPoint)alignOffset:(CGPoint)pt collectionView:(UICollectionView *)collectionView {
	if(collectionView.numberOfSections == 0) {
		// Don't think this is possible but just in case...
		return pt;
	}
	MMGridLayout *layout = (MMGridLayout *)collectionView.collectionViewLayout;

	return [layout snapToGrid:pt];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)sv willDecelerate:(BOOL)decelerate
{
	UIScrollView *scrollView;
	if(sv == _overlayScrollView) {
		scrollView = _overlayScrollView.shadowScrollView;
		if(!scrollView) return;
		scrollView.contentOffset = _overlayScrollView.contentOffset;
		//[scrollView setContentOffset:secretScrollView.contentOffset animated:NO];
	} else {
		assert(!"Impossible");
	}

	if(_wantRefreshControl) {
		[self checkRefreshControlWithOpen:YES];
	}
	if(!decelerate) {
		[self scrollViewDidStop:scrollView];
	}
	//NSLog(@"%@scrollViewDidEndDragging : willDecelerate", _isScrolling ? @"" : @"-");
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)sv {

	UIScrollView *scrollView;
	if(sv == _overlayScrollView) {
		scrollView = _overlayScrollView.shadowScrollView;
		if(!scrollView) return;
		scrollView.contentOffset = _overlayScrollView.contentOffset;
		//[scrollView setContentOffset:secretScrollView.contentOffset animated:NO];
	} else {
		assert(!"Impossible");
	}

	[self scrollViewDidStop:scrollView];
}

// Helper function, not a delegate
- (void)scrollViewDidStop:(UIScrollView *)scrollView {
	if(!_isScrolling) return;

//	_upperRightContainerView.userInteractionEnabled = YES;
//	_lowerRightContainerView.userInteractionEnabled = YES;
//	_lowerLeftContainerView.userInteractionEnabled = YES;
//	_upperRightBouncing = NO;
//	_lowerLeftBouncing = NO;
//	_lowerRightBouncing = NO;

	// The problem with isTracking is that dragging the view around then letting up will still register isTracking (Apple bug?)
	if (!scrollView.isDecelerating && !scrollView.isDragging/* && !scrollView.isTracking*/) {
		[self setNeedsLayout];

//		NSLog(@"OFFSET: %@ size %@ FrameSize %@",
//		NSStringFromCGPoint(_overlayScrollView.contentOffset),
//		NSStringFromCGSize(_overlayScrollView.contentSize),
//		NSStringFromCGSize(_overlayScrollView.bounds.size)
//		);

		_overlayScrollView.shadowScrollView = nil;

		_isScrolling = NO;

		if([_delegate respondsToSelector:@selector(scrollViewFinishedScrolling)]) {
			[_delegate scrollViewFinishedScrolling];
		}
	}
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
	return _scrollsToTop;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)sv
{
NSLog(@"SCROLL TO TOP!!!");
	UIScrollView *scrollView;
	if(sv == _overlayScrollView) {
		scrollView = _overlayScrollView.shadowScrollView;
		if(scrollView) {
			[scrollView setContentOffset:_overlayScrollView.contentOffset animated:NO];
		}
	} else {
		scrollView = sv;
	}

	[self scrollViewDidStop:scrollView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)sv
{
	UIScrollView *scrollView;
	if(sv == _overlayScrollView) {
		assert(_overlayScrollView.shadowScrollView);
		scrollView = _overlayScrollView.shadowScrollView;
		[scrollView setContentOffset:_overlayScrollView.contentOffset animated:NO];
	} else {
		scrollView = sv;
		NSLog(@"HHHHHHHH scrollViewDidEndScrollingAnimation scrollViewDidEndScrollingAnimation scrollViewDidEndScrollingAnimation");
	}

	[self scrollViewDidStop:scrollView];
}

@end

@interface MMRefreshControl ()
@property (nonatomic, strong, readwrite) UILabel *textLabel;
@property (nonatomic, strong, readwrite) UIActivityIndicatorView *indicator;

@end

@implementation MMScrollView
@synthesize shadowScrollView=__shadowScrollView;	// Make it harder to use directly with single '_'

- (void)setShadowScrollView:(UIScrollView *)shadowScrollView {
	__shadowScrollView = shadowScrollView;

	MMSpreadsheetView *ss = (MMSpreadsheetView *)self.superview;

	CGSize topLeft = ss.upperLeftContainerView.bounds.size;
	CGSize botRight = ss.lowerRightCollectionView.contentSize;

	if(shadowScrollView == ss.upperRightCollectionView) {
		self.contentSize = CGSizeMake(topLeft.width + botRight.width, topLeft.height);
		self.contentOffset = shadowScrollView.contentOffset;
	} else
	if(shadowScrollView == ss.lowerLeftCollectionView) {
		self.contentSize = CGSizeMake(topLeft.width, topLeft.height + botRight.height);
		self.contentOffset = shadowScrollView.contentOffset;
	} else {
		self.contentSize = CGSizeMake(topLeft.width + botRight.width, topLeft.height + botRight.height);
		self.contentOffset = ss.lowerRightCollectionView.contentOffset;
	}
}

// Idea came from the WWDC 2014 ScrollView presentation by Eliza
- (UIView *)hitTest:(CGPoint)pt withEvent:(UIEvent *)event {
	UIView *v = [super hitTest:pt withEvent:event];

	MMSpreadsheetView *ss = (MMSpreadsheetView *)self.superview;
	CGPoint mmPt = [self convertPoint:pt toView:ss];

	if(CGRectContainsPoint(ss.upperRightContainerView.frame, mmPt)) {
		self.shadowScrollView = ss.upperRightCollectionView;
		self.alwaysBounceVertical = NO;
	} else
	if(CGRectContainsPoint(ss.lowerLeftContainerView.frame, mmPt)) {
		self.shadowScrollView = ss.lowerLeftCollectionView;
		self.alwaysBounceVertical = YES;
	} else
	if(CGRectContainsPoint(ss.lowerRightContainerView.frame, mmPt)) {
		self.shadowScrollView = ss.lowerRightCollectionView;
		self.alwaysBounceVertical = YES;
	} else {
		self.shadowScrollView = nil;
	}
	//if(wasNull) NSLog(@"Secret Tag is %d", (int)_shadowScrollView.tag);

	return v;
}

@end

@implementation MMRefreshControl

- (instancetype) initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		NSLayoutConstraint *c;

		self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		_indicator.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:_indicator];
		// TODO: NSLayoutAnchor
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

