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

#import "MMGridLayout.h"

@interface MMGridLayout ()

@property (nonatomic, assign) NSInteger gridRowCount;
@property (nonatomic, assign) NSInteger gridColumnCount;

@property (nonatomic, strong) NSMutableArray *widths;
@property (nonatomic, strong) NSMutableArray *heights;

@end

@implementation MMGridLayout
{
	CGFloat _cellSpacing;
}
@dynamic cellSpacing;

- (instancetype)init {
	if((self = [super init])) {
		_cellSpacing = 1.0f;
	}
	return self;
}

- (CGFloat)cellSpacing {
	return _cellSpacing;
}
- (void)setCellSpacing:(CGFloat)cellSpacing {
	_cellSpacing = cellSpacing;
	[self invalidateLayout];
}

- (void)prepareLayout {
	[super prepareLayout];

	self.gridRowCount = [self.collectionView numberOfSections];
	self.gridColumnCount = [self.collectionView numberOfItemsInSection:0];
	if(_gridColumnCount == 0 || _gridRowCount == 0) {  // DFH added _gridRowCount == 0
		return; // No data to show
	}

	if (!_isInitialized) {
		self.widths = [NSMutableArray arrayWithCapacity:_gridColumnCount];
		self.heights = [NSMutableArray arrayWithCapacity:_gridRowCount];
		id<UICollectionViewDelegateFlowLayout> delegate = (id)self.collectionView.delegate;

		for (NSInteger i = 0; i < _gridColumnCount; i++) {
			CGSize size = [delegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
			[_widths addObject:@(size.width + _cellSpacing)];
		}

		for (NSInteger i = 0; i < _gridRowCount; i++) {
			CGSize size = [delegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:i]];
			[_heights addObject:@(size.height + _cellSpacing)];
		}

		self.isInitialized = YES;
	}
}

- (CGSize)collectionViewContentSize {
	if (!_isInitialized) {
		[self prepareLayout];
	}

	CGFloat sumWidth = 0;
	CGFloat sumHeight = 0;
	for (NSNumber *w in _widths) {
		sumWidth += (CGFloat)[w doubleValue];
	}
	for (NSNumber *h in _heights) {
		sumHeight += (CGFloat)[h doubleValue];
	}

	CGSize size = CGSizeMake(sumWidth, sumHeight);
	// NSLog(@"CONTENT SIZE %@ col=%d row=%d", NSStringFromCGSize(size), (int)_gridColumnCount, (int)_gridRowCount);
	return size;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
	if(_gridColumnCount == 0 || _gridRowCount == 0) { // DFH added _gridRowCount == 0
		return [NSArray array]; // No data to show
	}

	NSInteger startCol = -1;
	NSInteger endCol = _gridColumnCount - 1; 	// Had to do this to avoid some bizarre crash
	{
		CGFloat widthSum = 0;
		for (NSInteger i = 0; i < _gridColumnCount; i++) {
			widthSum += (CGFloat)[_widths[i] doubleValue];

			if (widthSum > rect.origin.x && startCol < 0) {
				startCol = i;
			}

			if (widthSum >= CGRectGetMaxX(rect)) {
				endCol = i+1;
				break;
			}
		}
		endCol = MIN(_gridColumnCount - 1, endCol);
	}
	//NSLog(@"COL: %d %d", (int)startCol, (int)endCol);


	NSInteger startRow = -1;
	NSInteger endRow = _gridRowCount - 1;	// Had to do this to avoid some bizarre crash
	{
		CGFloat heightSum = 0;
		for (NSInteger i = 0; i < _gridRowCount; i++) {
			heightSum += (CGFloat)[_heights[i] doubleValue];
			//NSLog(@"TEST: %lf to %lf MAXY %lf", (double)heightSum, (double)rect.origin.y, (double)CGRectGetMaxY(rect));

			if (heightSum > rect.origin.y && startRow < 0) {
				startRow = i;
			}

			if (heightSum >= CGRectGetMaxY(rect)) {
				endRow = i+1;
				break;
			}
		}
		endRow = MIN(_gridRowCount - 1, endRow);
	}
	//NSLog(@"NEW ROW: %d %d", (int)startRow, (int)endRow);
	//startRow = lround( floorf(rect.origin.y / [_heights[0] doubleValue]) );
	//endRow = MIN(_gridRowCount - 1, ceilf(CGRectGetMaxY(rect) / [_heights[0] doubleValue]));
	//NSLog(@"GOOD ROW: %d %d", (int)startRow, (int)endRow);


	NSInteger capacity = (1+endRow-startRow)*(1+endCol-startCol);
	NSMutableArray *attributes = [NSMutableArray arrayWithCapacity:capacity];
	for (NSUInteger row = startRow; row <= endRow; row++) {
		for (NSUInteger col = startCol; col <=	endCol; col++) {
			NSIndexPath *indexPath = [NSIndexPath indexPathForItem:col inSection:row];
			UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath:indexPath];
			[attributes addObject:layoutAttributes];
		}
	}
	return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];


	CGFloat widthSum = 0;
	{
		for (NSInteger i = 0; i < indexPath.item; i++) {
			widthSum += (CGFloat)[_widths[i] doubleValue];
		}
	}

	CGFloat heightSum = 0;
	{
		for (NSInteger i = 0; i < indexPath.section; i++) {
			heightSum += (CGFloat)[_heights[i] doubleValue];
		}
	}

	CGFloat width = (CGFloat)[_widths[indexPath.item] doubleValue] - _cellSpacing;
	CGFloat height = (CGFloat)[_heights[indexPath.section] doubleValue] - _cellSpacing;
	attributes.frame = CGRectMake(widthSum, heightSum, width, height);
	return attributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
	return NO;
}

- (CGPoint)snapToGrid:(CGPoint)startingPoint {

	CGFloat x = startingPoint.x;
	{
		CGFloat rx=0;
		CGFloat lx=0;
		for(NSInteger i=0; i<_gridColumnCount; ++i) {
			CGFloat width = (CGFloat)[_widths[i] doubleValue];
			rx += width;
			if(startingPoint.x < rx) {
				CGFloat rounder = (CGFloat)round((startingPoint.x - lx)/width) * width;
				x = lx + rounder;
				break;
			}
			lx = rx;
		}
	}

	CGFloat y = startingPoint.y;
	{
		CGFloat ry=0;
		CGFloat ly=0;
		for(NSInteger i=0; i<_gridRowCount; ++i) {
			CGFloat height = (CGFloat)[_heights[i] doubleValue];
			ry += height;
			if(startingPoint.y < ry) {
				CGFloat rounder = (CGFloat)round((startingPoint.y - ly)/height) * height;
				y = ly + rounder;
				break;
			}
			ly = ry;
		}
	}

	CGPoint r = CGPointMake(x, y);
	return r;
}

@end
