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

#import "MMGridLayout.h"
#import "MMSpreadsheetView.h"

@interface MMGridLayout ()

@property (nonatomic, assign) NSInteger gridRowCount;
@property (nonatomic, assign) NSInteger gridColumnCount;
@property (nonatomic, assign) BOOL isInitialized;
#ifndef ORIGINAL
@property (nonatomic, strong) NSMutableArray *widths;
#endif

@end

@implementation MMGridLayout
{
    CGFloat _cellSpacing;
}
@dynamic cellSpacing;

- (id)init {
    self = [super init];
    if (self) {
        _cellSpacing = 1.0f;
        _itemSize = CGSizeMake(120.0f, 120.0f);
    }
    return self;
}

- (void)setItemSize:(CGSize)itemSize {
    _itemSize = CGSizeMake(itemSize.width + self.cellSpacing, itemSize.height + self.cellSpacing);
    [self invalidateLayout];
}

- (CGFloat)cellSpacing {
    return _cellSpacing;
}
- (void)setCellSpacing:(CGFloat)cellSpacing {
    _cellSpacing = cellSpacing;
    [self invalidateLayout];
}

#ifdef ORIGINAL
- (void)prepareLayout {
    [super prepareLayout];
    self.gridRowCount = [self.collectionView numberOfSections];
    self.gridColumnCount = [self.collectionView numberOfItemsInSection:0];

    if (!_isInitialized) {
        id<UICollectionViewDelegateFlowLayout> delegate = (id)self.collectionView.delegate;
        CGSize size = [delegate collectionView:self.collectionView
                                        layout:self
                        sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        self.itemSize = size;
        self.isInitialized = YES;
    }
}

- (CGSize)collectionViewContentSize {
    if (!_isInitialized) {
        [self prepareLayout];
    }
    CGSize size = CGSizeMake(_gridColumnCount * _itemSize.width, _gridRowCount * _itemSize.height);
    NSLog(@"CONTENT SIZE %@ col=%d row=%d", NSStringFromCGSize(size), (int)_gridColumnCount, (int)_gridRowCount);
    return size;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *attributes = [NSMutableArray array];
    NSUInteger startRow = floorf(rect.origin.y / _itemSize.height);
    NSUInteger startCol = floorf(rect.origin.x / _itemSize.width);
    NSUInteger endRow = MIN(_gridRowCount - 1, ceilf(CGRectGetMaxY(rect) / _itemSize.height));
    NSUInteger endCol = MIN(_gridColumnCount - 1, ceilf(CGRectGetMaxX(rect) / _itemSize.width));
    NSParameterAssert(_gridRowCount > 0);
    NSParameterAssert(_gridColumnCount > 0);
    
    for (NSUInteger row = startRow; row <= endRow; row++) {
        for (NSUInteger col = startCol; col <=  endCol; col++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:col inSection:row];
            UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath:indexPath];
            [attributes addObject:layoutAttributes];
        }
    }
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    attributes.frame = CGRectMake(indexPath.item * _itemSize.width, indexPath.section * _itemSize.height, _itemSize.width-_cellSpacing, _itemSize.height-_cellSpacing);
    return attributes;
}

#else

- (void)prepareLayout {
    [super prepareLayout];
    self.gridRowCount = [self.collectionView numberOfSections];
    self.gridColumnCount = [self.collectionView numberOfItemsInSection:0];


    if (!_isInitialized) {
        self.widths = [NSMutableArray arrayWithCapacity:_gridColumnCount];
        id<UICollectionViewDelegateFlowLayout> delegate = (id)self.collectionView.delegate;

        CGSize size = CGSizeMake(0, 0);
        for (NSInteger i = 0; i < _gridColumnCount; i++) {
            size = [delegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
            [_widths addObject:@(size.width + _cellSpacing)];
        }
        self.itemSize = size;
        self.isInitialized = YES;
    }
}

- (CGSize)collectionViewContentSize {
    if (!_isInitialized) {
        [self prepareLayout];
    }

    float sumWidth = 0;
    for (NSNumber *w in _widths) {
        sumWidth += [w floatValue];
    }

    CGSize size = CGSizeMake(sumWidth, _gridRowCount * _itemSize.height);
    return size;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSUInteger startRow = floorf(rect.origin.y / _itemSize.height);
    NSUInteger endRow = MIN(_gridRowCount - 1, ceilf(CGRectGetMaxY(rect) / _itemSize.height));

    NSInteger startCol = -1;
    NSInteger endCol = 0;
    float widthsum = 0;
    for (int i = 0; i < _gridColumnCount; i++) {
        widthsum += [_widths[i] floatValue];

        if (widthsum > rect.origin.x && startCol < 0) {
            startCol = i;
        }

        if (widthsum >= CGRectGetMaxX(rect)) {
            endCol = i+1;
            break;
        }
    }
    endCol = MIN(_gridColumnCount - 1, endCol);

    NSParameterAssert(_gridRowCount > 0);
    NSParameterAssert(_gridColumnCount > 0);
    
    NSMutableArray *attributes = [NSMutableArray arrayWithCapacity:(1+endRow-startRow)*(1+endCol-startCol)];
    for (NSUInteger row = startRow; row <= endRow; row++) {
        for (NSUInteger col = startCol; col <=  endCol; col++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:col inSection:row];
            UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath:indexPath];
            [attributes addObject:layoutAttributes];
        }
    }
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    float widthsum = 0;
    for (int i = 0; i < indexPath.item; i++) {
        widthsum += [_widths[i] floatValue];
    }
    CGRect frame = CGRectMake(widthsum, indexPath.section * _itemSize.height, [_widths[indexPath.item] floatValue] - _cellSpacing, _itemSize.height-_cellSpacing);
    attributes.frame = frame;
    return attributes;
}

#endif

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return NO;
}

@end
