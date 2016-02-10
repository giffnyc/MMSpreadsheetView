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
#import "MMGridLayout.h"
#import "NSIndexPath+MMSpreadsheetView.h"

typedef NS_ENUM(NSInteger, MMSpreadsheetViewCollection) {
	MMSpreadsheetViewCollectionUpperLeft=1,
	MMSpreadsheetViewCollectionUpperRight,
	MMSpreadsheetViewCollectionLowerLeft,
	MMSpreadsheetViewCollectionLowerRight,
	MMSpreadsheetViewCollectionBase
};

typedef NS_ENUM(NSInteger, MMSpreadsheetHeaderConfiguration) {
	MMSpreadsheetHeaderConfigurationNone = 0,
	MMSpreadsheetHeaderConfigurationColumnOnly,
	MMSpreadsheetHeaderConfigurationRowOnly,
	MMSpreadsheetHeaderConfigurationBoth
};

const static CGFloat MMSpreadsheetViewGridSpace = 1.0f;

@interface MMSpreadsheetView () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, assign) NSUInteger headerRowCount;
@property (nonatomic, assign) NSUInteger headerColumnCount;
@property (nonatomic, assign) MMSpreadsheetHeaderConfiguration spreadsheetHeaderConfiguration;
@property (nonatomic, strong, readwrite) UIScrollView *shadowScrollView;

@property (nonatomic, strong) UIView *containerView;	// size of top/left, and the full contentSize of the lower right

@property (nonatomic, strong) UICollectionView *upperLeftCollectionView;
@property (nonatomic, strong) UICollectionView *upperRightCollectionView;
@property (nonatomic, strong) UICollectionView *lowerLeftCollectionView;
@property (nonatomic, strong) UICollectionView *lowerRightCollectionView;
@property (nonatomic, strong) NSArray<UICollectionView *> *collectionViews;
@property (nonatomic, strong) NSArray<NSString *> *collectionNames;
@property (nonatomic, strong) NSArray<UICollectionView *> *collectionColViews;
@property (nonatomic, strong) NSArray<UICollectionView *> *collectionRowViews;

@property (nonatomic, strong) UICollectionView *selectedItemCollectionView;
@property (nonatomic, strong) NSIndexPath *selectedItemIndexPath;

@property (nonatomic, assign) BOOL openingRefreshControl;

@end

static CGPoint maxContentOffset(UIScrollView *sv, UIEdgeInsets insets) {
	CGPoint pt =	CGPointMake(
						MAX(sv.contentSize.width - sv.bounds.size.width + insets.left + insets.right, 0),
						MAX(sv.contentSize.height - sv.bounds.size.height + insets.top + insets.bottom, 0)
					);
	return pt;
}


@implementation MMSpreadsheetView
{
	CGFloat ratio;
	CGFloat startValue;
	BOOL hidesBarsOnSwipe;
}
@synthesize shadowScrollView=__shadowScrollView;	// Make it harder to use directly with single '_'
@synthesize cellSpacing=_cellSpacing;

- (instancetype)init {
	return [self initWithNumberOfHeaderRows:0 numberOfHeaderColumns:0 frame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		// Call in viewDidLoad
		//[self commonInitWithNumberOfHeaderRows:0 numberOfHeaderColumns:0];
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	if((self = [super initWithCoder:coder])) {
		// Call in viewDidLoad
		//[self commonInitWithNumberOfHeaderRows:0 numberOfHeaderColumns:0];
	}
	return self;
}


- (void)setShadowScrollView:(UIScrollView *)shadowScrollView {
	__shadowScrollView = shadowScrollView;
	//NSLog(@"setShadowScrollView %d", (int)shadowScrollView.tag);

	CGSize topLeft = _upperLeftCollectionView.bounds.size;
	CGSize botRight = _lowerRightCollectionView.contentSize;
	botRight.height += self.contentInset.top + self.contentInset.bottom + MMSpreadsheetViewGridSpace;

	CGRect frame = _containerView.frame;
	CGSize contentSize = shadowScrollView.contentSize;
	CGPoint origin = CGPointZero;

	BOOL adjustWidth = NO;
	BOOL adjustHeight = NO;
	switch(shadowScrollView.tag) {
	case MMSpreadsheetViewCollectionUpperLeft:
		origin = CGPointZero;
		break;
	case MMSpreadsheetViewCollectionUpperRight:
		origin = CGPointMake(shadowScrollView.contentOffset.x, 0);
		adjustWidth = YES;
		break;
	case MMSpreadsheetViewCollectionLowerLeft:
		origin = CGPointMake(0, shadowScrollView.contentOffset.y);
		adjustHeight = YES;
		break;
	case MMSpreadsheetViewCollectionLowerRight:
		origin = shadowScrollView.contentOffset;
		adjustWidth = YES;
		adjustHeight = YES;
		break;
	case MMSpreadsheetViewCollectionBase:	// this never happens here for completeness
	default:
		//NSLog(@"Switch back to primary: hidden=%d ========================================", self.navigationController.navigationBar.isHidden);
		origin = CGPointMake(0, 1); // So tap on Status Bar is recognized
		self.contentOffset = origin;
		contentSize = CGSizeMake(	self.bounds.size.width  - self.contentInset.left - self.contentInset.right,
									self.bounds.size.height - self.contentInset.top - self.contentInset.bottom);
		frame.size = self.bounds.size; // CGSizeMake(topLeft.width + botRight.width + MMSpreadsheetViewGridSpace, topLeft.height + botRight.height + MMSpreadsheetViewGridSpace);

		if(self.navigationController.hidesBarsOnSwipe) hidesBarsOnSwipe = YES;
		if(self.navigationController.navigationBar.isHidden) {
			// Hysteresis - so its not showing/hiding all the time
			self.navigationController.hidesBarsOnSwipe = _lowerRightCollectionView.contentOffset.y > 3 ? NO : hidesBarsOnSwipe;
			[_refreshControl setHidden:YES];
		} else {
			[_refreshControl setHidden:NO];
		}
		break;
	}
	frame.origin = origin;
	_containerView.frame = frame;

	self.contentOffset = origin;
	if(adjustWidth) {
		contentSize.width += topLeft.width;		// adjust for cheating on the view size
	}
	if(adjustHeight) {
		contentSize.height += topLeft.height;	// adjust for cheating on the view size
	}
	// NSLog(@"SET CS TO %@", NSStringFromCGSize(contentSize));
	self.contentSize = contentSize;
}


- (void)adjustSubviewsForScroll {
	CGRect frame = _containerView.frame;
	// NSLog(@"adjustSubviewsForScroll");

	CGPoint contentOffset = self.contentOffset;
	CGPoint maxOffset = maxContentOffset(self.shadowScrollView, self.shadowScrollView.contentInset);
	//NSLog(@"CS %@ CO %@ MAX %@", NSStringFromCGSize(self.contentSize), NSStringFromCGPoint(contentOffset), NSStringFromCGPoint(maxOffset));

	BOOL adjustCols = NO;
	BOOL adjustRows = NO;

	switch(self.shadowScrollView.tag) {
	case MMSpreadsheetViewCollectionUpperLeft:
		break;
	case MMSpreadsheetViewCollectionUpperRight:
		adjustCols = YES;
		break;
	case MMSpreadsheetViewCollectionLowerLeft:
		adjustRows = YES;
		break;
	case MMSpreadsheetViewCollectionLowerRight:
		adjustCols = YES;
		adjustRows = YES;
		break;
	default:
		assert(!"Impossible");
	}

	if(adjustCols) {
		for(UICollectionView *cv in _collectionColViews) {
			CGPoint currentOffset = cv.contentOffset;
			CGPoint newContentOffset;
			if(contentOffset.x >= 0 && contentOffset.x <= maxOffset.x) {
				newContentOffset = CGPointMake(contentOffset.x, currentOffset.y);
				if(cv == self.shadowScrollView) {
					frame.origin = newContentOffset;
					_containerView.frame = frame;
				}
			} else
			if(contentOffset.x < 0) {
				currentOffset.x = 0;
				newContentOffset = currentOffset;
			} else
			if(contentOffset.x > maxOffset.x) {
				newContentOffset = CGPointMake(maxOffset.x, currentOffset.y);
			} else {
				newContentOffset = CGPointZero;
				assert("Mathematically impossible!");
			}
			cv.contentOffset = newContentOffset;
		}
	}
	if(adjustRows) {
		for(UICollectionView *cv in _collectionRowViews) {
			CGPoint currentOffset = cv.contentOffset;
			CGPoint newContentOffset;
			if(contentOffset.y >= 0 && contentOffset.y <= maxOffset.y) {
				newContentOffset = CGPointMake(currentOffset.x, contentOffset.y);
				if(cv == self.shadowScrollView) {
					frame.origin = newContentOffset;
					_containerView.frame = frame;
				}
			} else
			if(contentOffset.y < 0) {
				currentOffset.y = 0;
				newContentOffset = currentOffset;
			} else
			if(contentOffset.y > maxOffset.y) {
				newContentOffset = CGPointMake(currentOffset.x, maxOffset.y);
			} else {
				newContentOffset = CGPointZero;
				assert("Mathematically impossible!");
			}
			cv.contentOffset = newContentOffset;
		}
	}
	//NSLog(@"-CS %@ CO %@ MAX %@", NSStringFromCGSize(self.contentSize), NSStringFromCGPoint(contentOffset), NSStringFromCGPoint(maxOffset));
}

#pragma mark - MMSpreadsheetView designated initializer

- (instancetype)initWithNumberOfHeaderRows:(NSUInteger)headerRowCount numberOfHeaderColumns:(NSUInteger)headerColumnCount frame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		[self commonInitWithNumberOfHeaderRows:headerRowCount numberOfHeaderColumns:headerColumnCount];
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	}
	return self;
}

- (void)commonInitWithNumberOfHeaderRows:(NSUInteger)headerRowCount numberOfHeaderColumns:(NSUInteger)headerColumnCount {
	self.scrollIndicatorInsets = UIEdgeInsetsZero;
	self.showsVerticalScrollIndicator = YES;
	self.showsHorizontalScrollIndicator = YES;
	self.tag = MMSpreadsheetViewCollectionBase;
	_headerRowCount = headerRowCount;
	_headerColumnCount = headerColumnCount;

	self.delegate = self;
	self.contentSize = CGSizeMake(self.bounds.size.width, self.bounds.size.height);
	self.scrollEnabled = YES;

	if(headerColumnCount == 0 && headerRowCount == 0) {
		_spreadsheetHeaderConfiguration = MMSpreadsheetHeaderConfigurationNone;
	}
	else if(headerColumnCount > 0 && headerRowCount == 0) {
		_spreadsheetHeaderConfiguration = MMSpreadsheetHeaderConfigurationColumnOnly;
	}
	else if(headerColumnCount == 0 && headerRowCount > 0) {
		_spreadsheetHeaderConfiguration = MMSpreadsheetHeaderConfigurationRowOnly;
	}
	else if(headerColumnCount > 0 && headerRowCount > 0) {
		_spreadsheetHeaderConfiguration = MMSpreadsheetHeaderConfigurationBoth;
	}
	self.backgroundColor = [UIColor grayColor];

	[self setupSubviews];

	if(_wantRefreshControl) {
		// 88 is the height of a standard UIRefreshControl. The left/right offsets are to hide the layer border (see initWithFrame)
		self.refreshControl = [[MMRefreshControl alloc] initWithFrame:CGRectMake(-1, -88, _containerView.bounds.size.width+2, 88)];
		_refreshControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[_containerView insertSubview:_refreshControl atIndex:0];
	}
}

- (void)correctContentOffset:(BOOL)wasAtMax {
	CGFloat maxRightOffset = maxContentOffset(_lowerRightCollectionView, _lowerRightCollectionView.contentInset).y;
	CGPoint contentOffsetLeft = _lowerLeftCollectionView.contentOffset;
	CGPoint contentOffsetRight = _lowerRightCollectionView.contentOffset;
	if(contentOffsetRight.y > maxRightOffset || wasAtMax) {
		contentOffsetLeft.y = maxRightOffset;
		_lowerLeftCollectionView.contentOffset = contentOffsetLeft;

		contentOffsetRight.y = maxRightOffset;
		_lowerRightCollectionView.contentOffset = contentOffsetRight;
	}
}

#pragma mark - Public Functions

- (void)hideTabBar:(BOOL)hide withAnimationDuration:(CGFloat)animateDuration coordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	UITabBarController *tabBarController = _navigationController.tabBarController;
	UITabBar *tabBar = tabBarController.tabBar;
	if(tabBar.translucent) {
		CGFloat offset = hide ? 0 : tabBar.frame.size.height;
		UIEdgeInsets loadingInsetRight = _lowerRightCollectionView.contentInset;
		CGPoint contentOffsetRight = _lowerRightCollectionView.contentOffset;
		BOOL lowerRightAtMax = fabs(contentOffsetRight.y - maxContentOffset(_lowerRightCollectionView, loadingInsetRight).y) < 3;
		loadingInsetRight.bottom = offset;

		if(!coordinator) {
			CGFloat maxRightOffset = maxContentOffset(_lowerRightCollectionView, loadingInsetRight).y;
			if(hide) {
				contentOffsetRight.y = MIN(contentOffsetRight.y, maxRightOffset);
			} else {
				if(lowerRightAtMax) contentOffsetRight.y = maxRightOffset;
			}
		}
		dispatch_block_t code = ^{
			self.lowerLeftCollectionView.contentInset = loadingInsetRight;
			self.lowerRightCollectionView.contentInset = loadingInsetRight;
			self.lowerLeftCollectionView.contentOffset = contentOffsetRight;
			self.lowerRightCollectionView.contentOffset = contentOffsetRight;
			self.contentInset = loadingInsetRight;
			self.contentOffset = contentOffsetRight;
			self.scrollIndicatorInsets = loadingInsetRight;

			[self setNeedsLayout];
			[self setNeedsDisplay];
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
				[self correctContentOffset:lowerRightAtMax];
			};
			void (^completionBlock)(BOOL) = ^void(BOOL finished) {
				if(hide) {
					CGRect r = tabBar.frame;
					r.origin.y -= r.size.height;
					tabBar.frame = r;
					[tabBar setHidden:YES];
				}
				[self setNeedsLayout];
				[self setNeedsDisplay];
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
		UIEdgeInsets insets = self.scrollIndicatorInsets;
		insets.bottom = offset;
		self.scrollIndicatorInsets = insets;
	}
}

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

-  (void)invalidateLayout {
	for(UICollectionView *cv in _collectionViews) {
		MMGridLayout *layout = (MMGridLayout *)cv.collectionViewLayout;
		layout.isInitialized = NO;
		[layout invalidateLayout];
		[cv reloadData];
	}
}

- (void)flashScrollIndicators {
	[self flashScrollIndicators];
}

- (CGFloat)cellSpacing {
	return _cellSpacing;
}
- (void)setCellSpacing:(CGFloat)cellSpacing {
	_cellSpacing = cellSpacing;

	[_collectionViews enumerateObjectsUsingBlock:^(UICollectionView * _Nonnull cv, NSUInteger idx, BOOL * _Nonnull stop) {
		MMGridLayout *gl = (MMGridLayout *)cv.collectionViewLayout;
		gl.cellSpacing = _cellSpacing;
	} ];

}

#pragma mark - View Setup functions

- (void)setupSubviews {
	self.containerView = [[UIView alloc] initWithFrame:CGRectZero];
	_containerView.autoresizingMask = UIViewAutoresizingNone;
	[self addSubview:_containerView];

	switch(_spreadsheetHeaderConfiguration) {
	case MMSpreadsheetHeaderConfigurationNone:
		[self setupLowerRightView];
		self.collectionViews = @[_lowerRightCollectionView];
		self.collectionRowViews = _collectionViews;
		self.collectionColViews = _collectionViews;
		break;
		
	case MMSpreadsheetHeaderConfigurationColumnOnly:
		[self setupLowerLeftView];
		[self setupLowerRightView];
		self.collectionViews = @[_lowerLeftCollectionView, _lowerRightCollectionView];
		self.collectionColViews = @[ _lowerRightCollectionView];
		self.collectionRowViews = _collectionViews;
		break;
		
	case MMSpreadsheetHeaderConfigurationRowOnly:
		[self setupUpperRightView];
		[self setupLowerRightView];
		self.collectionViews = @[_upperRightCollectionView, _lowerRightCollectionView];
		self.collectionColViews = _collectionViews;
		self.collectionRowViews = @[_lowerRightCollectionView];
		break;
		
	case MMSpreadsheetHeaderConfigurationBoth:
		[self setupUpperLeftView];
		[self setupUpperRightView];
		[self setupLowerLeftView];
		[self setupLowerRightView];
		self.collectionNames = @[@"Left Corner", @"Column Labels", @"Row Labels", @"Data Cells"];
		self.collectionViews = @[ _upperLeftCollectionView, _upperRightCollectionView, _lowerLeftCollectionView, _lowerRightCollectionView];
		self.collectionColViews = @[_upperRightCollectionView, _lowerRightCollectionView];
		self.collectionRowViews = @[_lowerLeftCollectionView, _lowerRightCollectionView];
		break;
		
	default:
		NSAssert(NO, @"What have you done?");
		break;
	}
}

- (void)setupCollectionView:(UICollectionView *)collectionView tag:(NSInteger)tag {
	collectionView.autoresizingMask = UIViewAutoresizingNone;
	collectionView.backgroundColor = [UIColor clearColor];
	collectionView.tag = tag;
	collectionView.delegate = self;
	collectionView.dataSource = self;
	collectionView.showsHorizontalScrollIndicator = NO;
	collectionView.showsVerticalScrollIndicator = NO;
	collectionView.scrollEnabled = NO;
	collectionView.scrollsToTop = NO;
	[_containerView addSubview:collectionView];
}

- (UICollectionView *)setupCollectionViewWithGridLayout {
	MMGridLayout *layout = [[MMGridLayout alloc] init];
	UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
	return collectionView;
}

- (void)setupUpperLeftView {
	self.upperLeftCollectionView = [self setupCollectionViewWithGridLayout];
	[self setupCollectionView:_upperLeftCollectionView tag:MMSpreadsheetViewCollectionUpperLeft];
}

- (void)setupUpperRightView {
	self.upperRightCollectionView = [self setupCollectionViewWithGridLayout];
	[self setupCollectionView:_upperRightCollectionView tag:MMSpreadsheetViewCollectionUpperRight];
}

- (void)setupLowerLeftView {
	self.lowerLeftCollectionView = [self setupCollectionViewWithGridLayout];
	[self setupCollectionView:_lowerLeftCollectionView tag:MMSpreadsheetViewCollectionLowerLeft];
}

- (void)setupLowerRightView {
	self.lowerRightCollectionView = [self setupCollectionViewWithGridLayout];
	[self setupCollectionView:_lowerRightCollectionView tag:MMSpreadsheetViewCollectionLowerRight];
}

- (void)layoutSubviews {
	if(self.shadowScrollView) return;	// scrolling
	[super layoutSubviews];

	NSIndexPath *indexPathZero = [NSIndexPath indexPathForItem:0 inSection:0];

	CGRect bounds = self.bounds;
	CGSize boundsSize = bounds.size;
	boundsSize.height -= self.contentInset.top + self.contentInset.bottom;

	switch(_spreadsheetHeaderConfiguration) {
	case MMSpreadsheetHeaderConfigurationNone:
		_containerView.frame = self.bounds;
		break;
		
	case MMSpreadsheetHeaderConfigurationColumnOnly: {
		CGSize size = _lowerLeftCollectionView.collectionViewLayout.collectionViewContentSize;
		CGSize cellSize = [self collectionView:_lowerRightCollectionView
										layout:_lowerRightCollectionView.collectionViewLayout
						sizeForItemAtIndexPath:indexPathZero];
		CGFloat maxLockDistance = boundsSize.width - cellSize.width;
		if(size.width > maxLockDistance) {
			NSAssert(NO, @"Width of header too large! Reduce the number of header columns.");
		}
// TODO: fix me
//		_containerView.frame = CGRectMake(0.0f,
//													   0.0f,
//													   size.width,
//													   boundsSize.height);
//		_lowerRightContainerView.frame = CGRectMake(size.width + MMSpreadsheetViewGridSpace,
//														0.0f,
//														boundsSize.width - size.width - MMSpreadsheetViewGridSpace,
//														boundsSize.height);
	}	break;

	case MMSpreadsheetHeaderConfigurationRowOnly: {
		CGSize size = _upperRightCollectionView.collectionViewLayout.collectionViewContentSize;
		CGSize cellSize = [self collectionView:_lowerRightCollectionView
										layout:_lowerRightCollectionView.collectionViewLayout
						sizeForItemAtIndexPath:indexPathZero];
		CGFloat maxLockDistance = boundsSize.height - cellSize.height;
		if(size.height > maxLockDistance) {
			NSAssert(NO, @"Height of header too large! Reduce the number of header rows.");
		}
// TODO: fix me
//		_upperRightContainerView.frame = CGRectMake(0.0f,
//														0.0f,
//														boundsSize.width,
//														size.height);
//		_lowerRightContainerView.frame = CGRectMake(0.0f,
//														size.height + MMSpreadsheetViewGridSpace,
//														boundsSize.width,
//														boundsSize.height - size.height - MMSpreadsheetViewGridSpace);
	}	break;

	case MMSpreadsheetHeaderConfigurationBoth: {
		CGSize topLeft = _upperLeftCollectionView.collectionViewLayout.collectionViewContentSize;
		//CGSize botRight = _lowerRightCollectionView.collectionViewLayout.collectionViewContentSize;


		_upperLeftCollectionView.frame = CGRectMake(	0.0f,
														0.0f,
														topLeft.width,
														topLeft.height);
//		assert(boundsSize.width > _upperLeftCollectionView.bounds.size.width);
//		assert(boundsSize.height > _upperLeftCollectionView.bounds.size.height);

		_upperRightCollectionView.frame = CGRectMake(	topLeft.width + MMSpreadsheetViewGridSpace,
														0.0f,
														boundsSize.width - topLeft.width - MMSpreadsheetViewGridSpace,
														topLeft.height);


		_lowerLeftCollectionView.frame = CGRectMake(	0,
														topLeft.height + MMSpreadsheetViewGridSpace,
														topLeft.width,
														boundsSize.height - topLeft.height - MMSpreadsheetViewGridSpace);

		_lowerRightCollectionView.frame = CGRectMake(	topLeft.width + MMSpreadsheetViewGridSpace,
														topLeft.height + MMSpreadsheetViewGridSpace,
														boundsSize.width - topLeft.width - MMSpreadsheetViewGridSpace,
														boundsSize.height - topLeft.height - MMSpreadsheetViewGridSpace);

		if(self.shadowScrollView == nil) {
			self.shadowScrollView = nil;	// sets up the containingView and our contentSize etc
		}
	}	break;

	default:
		NSAssert(NO, @"What have you done?");
		break;
	}
}

// Idea came from the WWDC 2014 ScrollView presentation by Eliza
- (UIView *)hitTest:(CGPoint)pt withEvent:(UIEvent *)event {
//	Interesting Idea, but it just won't work in my case
//	if(CGRectContainsPoint(_upperLeftCollectionView.frame, pt)) {
//		self.navigationController.hidesBarsOnTap = YES;
//		dispatch_async(dispatch_get_main_queue(), ^
//			{
//				[self setNeedsLayout];
//				[self setNeedsDisplay];
//			});
//	} else {
//		self.navigationController.hidesBarsOnTap = NO;
//	}

	UIView *v = [super hitTest:pt withEvent:event];
	for(UIScrollView *cv in _collectionViews) {
		CGRect frame = [cv convertRect:cv.bounds toView:self];
		if(CGRectContainsPoint(frame, pt)) {
			self.shadowScrollView = cv;
			break;
		}
	}
	return v;
}

#pragma mark - DataSource property setter

- (void)setDataSource:(id<MMSpreadsheetViewDataSource>)dataSource {
	_dataSource = dataSource;

	for(NSInteger i=0; i<[_collectionViews count]; ++i) {
		[self initializeCollectionViewLayoutItemSize:_collectionViews[i] name: _collectionNames[i]];
	}

	// Validate dataSource & header configuration

	NSAssert(_headerColumnCount <= [_dataSource numberOfColumnsInSpreadsheetView:self],
		@"Invalid configuration: number of header columns must be less than or equal to (dataSource) numberOfColumnsInSpreadsheetView");
	NSAssert(_headerRowCount <= [_dataSource numberOfRowsInSpreadsheetView:self],
		@"Invalid configuration: number of header rows must be less than or equal to (dataSource) numberOfRowsInSpreadsheetView");
}

- (void)initializeCollectionViewLayoutItemSize:(UICollectionView *)collectionView name:(NSString*)name {
	MMGridLayout *layout = (MMGridLayout *)collectionView.collectionViewLayout;
	layout.name = name;
}

#pragma mark - Custom functions that don't go anywhere else

- (UICollectionView *)collectionViewForDataSourceIndexPath:(NSIndexPath *)indexPath {
	UICollectionView *collectionView = nil;
	switch(_spreadsheetHeaderConfiguration) {
	case MMSpreadsheetHeaderConfigurationNone:
		collectionView = _lowerRightCollectionView;
		break;
		
	case MMSpreadsheetHeaderConfigurationColumnOnly:
		collectionView = indexPath.mmSpreadsheetColumn >= _headerColumnCount ? _lowerRightCollectionView : _lowerLeftCollectionView;
		break;
		
	case MMSpreadsheetHeaderConfigurationRowOnly:
		collectionView = indexPath.mmSpreadsheetRow >= _headerRowCount? _lowerRightCollectionView : _upperRightCollectionView;
		break;
		
	case MMSpreadsheetHeaderConfigurationBoth:
		if(indexPath.mmSpreadsheetRow >= _headerRowCount) {
			collectionView = indexPath.mmSpreadsheetColumn >= _headerColumnCount ? _lowerRightCollectionView : _lowerLeftCollectionView;
		} else {
			collectionView = indexPath.mmSpreadsheetColumn >= _headerColumnCount ? _upperRightCollectionView : _upperLeftCollectionView;
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

	if(collectionView) {
		switch(collectionView.tag) {
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
	
	switch(collectionView.tag) {
	case MMSpreadsheetViewCollectionUpperLeft:
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
	
	switch(collectionView.tag) {
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
	switch(collectionView.tag) {
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

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	BOOL ret = YES;
	NSIndexPath *dataSourceIndexPath = [self dataSourceIndexPathFromCollectionView:collectionView indexPath:indexPath];
	if([_spreadsheetDelegate respondsToSelector:@selector(spreadsheetView:shouldSelectItemAtIndexPath:)]) {
		ret = [_spreadsheetDelegate spreadsheetView:self shouldSelectItemAtIndexPath:dataSourceIndexPath];
	}
	return ret;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	if(_selectedItemCollectionView != nil) {
		if(collectionView == _selectedItemCollectionView) {
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
	if([_spreadsheetDelegate respondsToSelector:@selector(spreadsheetView:didSelectItemAtIndexPath:)]) {
		[_spreadsheetDelegate spreadsheetView:self didSelectItemAtIndexPath:dataSourceIndexPath];
	}
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	NSIndexPath *dataSourceIndexPath = [self dataSourceIndexPathFromCollectionView:collectionView indexPath:indexPath];
	if([_spreadsheetDelegate respondsToSelector:@selector(spreadsheetView:shouldShowMenuForItemAtIndexPath:)]) {
		return [_spreadsheetDelegate spreadsheetView:self shouldShowMenuForItemAtIndexPath:dataSourceIndexPath];
	}
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	NSIndexPath *dataSourceIndexPath = [self dataSourceIndexPathFromCollectionView:collectionView indexPath:indexPath];
	if([_spreadsheetDelegate respondsToSelector:@selector(spreadsheetView:canPerformAction:forItemAtIndexPath:withSender:)]) {
		return [_spreadsheetDelegate spreadsheetView:self canPerformAction:action forItemAtIndexPath:dataSourceIndexPath withSender:sender];
	}
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	NSIndexPath *dataSourceIndexPath = [self dataSourceIndexPathFromCollectionView:collectionView indexPath:indexPath];
	if([_spreadsheetDelegate respondsToSelector:@selector(spreadsheetView:performAction:forItemAtIndexPath:withSender:)]) {
		return [_spreadsheetDelegate spreadsheetView:self performAction:action forItemAtIndexPath:dataSourceIndexPath withSender:sender];
	}
}

#pragma mark - UIScrollViewDelegate

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
	//NSLog(@"scrollViewShouldScrollToTop %@", NSStringFromCGPoint(scrollView.contentOffset));

	if(_isScrolling == false) {
		[_lowerLeftCollectionView setContentOffset:CGPointMake(0, 0) animated:YES];
		CGFloat x = _lowerRightCollectionView.contentOffset.x;
		[_lowerRightCollectionView setContentOffset:CGPointMake(x, 0) animated:YES];
	}

	return !_isScrolling;
}
- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
	//if(scrollView != self) return;
	// NSLog(@"scrollViewDidScrollToTop");
	//NSLog(@"scrollViewDidScrollToTop %@", NSStringFromCGPoint(scrollView.contentOffset));
	//	[self scrollViewDidStop];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	// NSLog(@"scrollViewDidScroll: tag=%d %@", (int)self.shadowScrollView.tag, NSStringFromCGPoint(scrollView.contentOffset));
	if(scrollView != self || self.shadowScrollView == nil) return;

	if(_wantRefreshControl && !_navigationController.navigationBar.isHidden) {
		[self checkRefreshControlWithOpen:NO];
	}
	[self adjustSubviewsForScroll];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	_isScrolling = YES;
	// NSLog(@"scrollViewWillBeginDragging");
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
	// NSLog(@"%@scrollViewDidEndDragging : withVelocity", _isScrolling ? @"" : @"-");

	CGPoint toffset = *targetContentOffset;
	if(_snapToGrid) {
		*targetContentOffset = [self alignOffset:toffset collectionView:(UICollectionView *)self.shadowScrollView];
	}
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
	//NSLog(@"%@scrollViewDidEndDragging : willDecelerate", _isScrolling ? @"" : @"-");
	if(_wantRefreshControl && !_navigationController.navigationBar.isHidden) {
		[self checkRefreshControlWithOpen:YES];
	}
	if(!decelerate) {
		[self scrollViewDidStop];
	}
}

- (void)checkRefreshControlWithOpen:(BOOL)andOpen {
	CGRect r = _refreshControl.frame;
	r.origin.y = (-self.contentOffset.y) - r.size.height;
	if(andOpen && !_openingRefreshControl && (r.origin.y > -r.size.height/2)) {
		startValue = r.origin.y;
		ratio = r.size.height/(startValue + r.size.height);

		_openingRefreshControl = YES;

		if([_spreadsheetDelegate respondsToSelector:@selector(refreshControlActive:)]) {
			dispatch_async(dispatch_get_main_queue(), ^
				{
					[self.refreshControl startRefresh];
					[self.spreadsheetDelegate refreshControlActive:_refreshControl];
				});
		}
	}
	if(_openingRefreshControl) {
		CGRect rr = _containerView.bounds;
		CGFloat diff =  r.origin.y - startValue;
		rr.origin.y = (CGFloat)round(diff*ratio);
		_containerView.bounds = rr;
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	if(scrollView != self) return;
	// NSLog(@"scrollViewDidEndDecelerating");

	[self scrollViewDidStop];
}

// Helper function, not a delegate
- (void)scrollViewDidStop {
	if(!_isScrolling) {
		return;
	}

	// NSLog(@"scrollViewDidStop");

//	NSLog(@"scrollViewDidStop: isDecel=%d isDragging=%d isTracking=%d", (int)self.isDecelerating, (int)self.isDragging, (int)self.isTracking);
//	dispatch_async(dispatch_get_main_queue(), ^
//	{
//		NSLog(@"SCROLLVIEW DID STOP: isDecel=%d isDragging=%d isTracking=%d", (int)self.isDecelerating, (int)self.isDragging, (int)self.isTracking);
//
//	});

	// The problem with isTracking is that dragging the view around then letting up will still register isTracking (Apple bug?)
	if(!self.isDecelerating && !self.isDragging/* && !self.isTracking*/) {
		self.shadowScrollView = nil;
		_isScrolling = NO;

		if([_spreadsheetDelegate respondsToSelector:@selector(scrollViewFinishedScrolling)]) {
			[_spreadsheetDelegate scrollViewFinishedScrolling];
		}
	}
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
	if(scrollView != self) return;
	//	NSLog(@"scrollViewDidEndScrollingAnimation");
	//	self.contentOffset = CGPointMake(0, 0.01);
	[self scrollViewDidStop];
}

@end

@interface MMRefreshControl ()
@property (nonatomic, strong, readwrite) UILabel *textLabel;
@property (nonatomic, strong, readwrite) UIActivityIndicatorView *indicator;

@end

@implementation MMRefreshControl

- (instancetype) initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {

		self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		_indicator.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:_indicator];
		// TODO: NSLayoutAnchor

		[self.centerXAnchor constraintEqualToAnchor:_indicator.centerXAnchor].active = YES;
		[self.centerYAnchor constraintEqualToAnchor:_indicator.centerYAnchor].active = YES;

		_indicator.color = [UIColor blackColor];
		_indicator.hidesWhenStopped = NO;

		self.textLabel = [UILabel new];
		_textLabel.translatesAutoresizingMaskIntoConstraints = NO;
		_textLabel.text = @"Refreshing…";
		_textLabel.font = [UIFont boldSystemFontOfSize:17];
		[self addSubview:_textLabel];

		[self.centerXAnchor constraintEqualToAnchor:_textLabel.centerXAnchor].active = YES;
		[self.bottomAnchor constraintEqualToAnchor:_textLabel.bottomAnchor constant:4].active = YES;
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

- (BOOL)isRefreshing {
	return _indicator.isAnimating;
}

- (void)stopRefresh {
	MMSpreadsheetView *ssv = (MMSpreadsheetView *)self.superview.superview;
	ssv.openingRefreshControl = NO;
	[ssv setNeedsLayout];

	CGRect bounds = ssv.containerView.bounds;
	bounds.origin.y = 0;

	[UIView animateWithDuration:0.250 animations:^{
		ssv.containerView.bounds = bounds;
	} completion:^(BOOL finished)
	{
		ssv.shadowScrollView = nil; // resets the container bounds
		[_indicator stopAnimating];
	}];
}

@end
