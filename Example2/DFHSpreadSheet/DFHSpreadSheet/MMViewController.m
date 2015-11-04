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

#import "MMViewController.h"
#import "MMSpreadsheetView.h"
#import "MMGridCell.h"
#import "MMTopRowCell.h"
#import "MMLeftColumnCell.h"
#import "NSIndexPath+MMSpreadsheetView.h"

@interface MMViewController () <MMSpreadsheetViewDataSource, MMSpreadsheetViewDelegate>

@property (nonatomic, strong) NSMutableSet *selectedGridCells;
@property (nonatomic, strong) NSMutableArray *tableData;
@property (nonatomic, strong) NSString *cellDataBuffer;

@end

#define NUM_HEADER_ROWS 1
#define NUM_HEADER_COLS 1

@implementation MMViewController
{
    NSUInteger rows;
    NSUInteger cols;
	MMSpreadsheetView *spreadSheetView;
	MMRefreshControl *refreshControl;
	UITabBarController *c;

}

//- (BOOL)hidesBottomBarWhenPushed {
//	return YES;
//}

- (void)viewDidLoad {
    [super viewDidLoad];

	self.navigationController.navigationBar.translucent = NO;
	self.tabBarController.tabBar.translucent = NO;

	self.navigationController.hidesBarsWhenVerticallyCompact = YES;
	self.navigationController.hidesBarsOnSwipe = YES;

	rows = 11;
	cols = 9;

    // Create some fake grid data for the demo.
    self.tableData = [NSMutableArray array];
	for (NSUInteger rowNumber = 0; rowNumber < rows; rowNumber++) {
		NSMutableArray *row = [NSMutableArray array];
		for (NSUInteger columnNumber = 0; columnNumber < cols; columnNumber++) {
			[row addObject:[NSString stringWithFormat:@"R%lu:C%lu", (unsigned long)rowNumber, (unsigned long)columnNumber]];
//NSLog(@"ROW %d", (int)rowNumber);
		}
		[self.tableData addObject:row];
		
	}
	//[spreadSheetView reloadData];

#if 0
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1000 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^
	{
		NSLog(@"BOT GUIDE %d", (int)self.bottomLayoutGuide.length);
		NSLog(@"FRAME %@", NSStringFromCGRect(self.view.frame));
//		CGRect r = self.tabBarController.tabBar.frame;
//		r.origin.y += r.size.height;
//		r.size.height = 0;
//		self.tabBarController.tabBar.frame = r;
		[self.tabBarController.tabBar setHidden:YES];
		[self.view setNeedsLayout];
		[self.view setNeedsDisplay];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1000 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^
		{
			NSLog(@"BOT GUIDE %d", (int)self.bottomLayoutGuide.length);
			NSLog(@"FRAME %@", NSStringFromCGRect(self.view.frame));
		});
	});
#endif

#if 0
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2000 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^
		{
			for (NSUInteger rowNumber = 0; rowNumber < rows; rowNumber++) {
				NSMutableArray *row = [NSMutableArray array];
				for (NSUInteger columnNumber = 0; columnNumber < cols; columnNumber++) {
					[row addObject:[NSString stringWithFormat:@"R%lu:C%lu", (unsigned long)rowNumber, (unsigned long)columnNumber]];
//NSLog(@"ROW %d", (int)rowNumber);
				}
				[self.tableData addObject:row];
				
			}
			NSLog(@"RELOAD");
			[spreadSheetView reloadData];
		});

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4000 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^
		{
			[self.tableData removeAllObjects];

			NSLog(@"RELOAD 2");
			[spreadSheetView reloadData];
		});

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 6000 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^
		{
			for (NSUInteger rowNumber = 0; rowNumber < rows; rowNumber++) {
				NSMutableArray *row = [NSMutableArray array];
				for (NSUInteger columnNumber = 0; columnNumber < cols; columnNumber++) {
					[row addObject:[NSString stringWithFormat:@"R%lu:C%lu", (unsigned long)rowNumber, (unsigned long)columnNumber]];
//NSLog(@"ROW %d", (int)rowNumber);
				}
				[self.tableData addObject:row];
				
			}
			NSLog(@"RELOAD 3");
			[spreadSheetView reloadData];
		});

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 8000 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^
		{
			[self.tableData removeAllObjects];

			NSLog(@"RELOAD 4");
			[spreadSheetView reloadData];
			//[spreadSheetView setNeedsDisplay];
		});
#endif

    self.selectedGridCells = [NSMutableSet set];

#ifdef DFHSpreadSheet
	spreadSheetView = (MMSpreadsheetView *)self.view;
	spreadSheetView.navigationController = self.navigationController;
	spreadSheetView.wantRefreshControl = YES;

	[spreadSheetView commonInitWithNumberOfHeaderRows:NUM_HEADER_ROWS numberOfHeaderColumns:NUM_HEADER_COLS];
	spreadSheetView.bounces = YES;
	spreadSheetView.horizontalBounce = NO;
	spreadSheetView.verticalBounce = YES;
	spreadSheetView.directionalLockEnabled = YES;
	spreadSheetView.snapToGrid = YES;

	spreadSheetView.backgroundColor = [UIColor grayColor];
#else
    // Create the spreadsheet in code.
    spreadSheetView = [[MMSpreadsheetView alloc] initWithNumberOfHeaderRows:NUM_HEADER_ROWS numberOfHeaderColumns:NUM_HEADER_COLS frame:self.view.bounds];
    // Add the spreadsheet view as a subview.
    [self.view addSubview:spreadSheetView];
#endif
    // Register your cell classes.
    [spreadSheetView registerCellClass:[MMGridCell class] forCellWithReuseIdentifier:@"GridCell"];
    [spreadSheetView registerCellClass:[MMTopRowCell class] forCellWithReuseIdentifier:@"TopRowCell"];
    [spreadSheetView registerCellClass:[MMLeftColumnCell class] forCellWithReuseIdentifier:@"LeftColumnCell"];

    // Set the delegate & datasource for the spreadsheet view.
    spreadSheetView.delegate = self;
    spreadSheetView.dataSource = self;

	spreadSheetView.snapToGrid = YES;
	spreadSheetView.directionalLockEnabled = YES;
}

//- (void)viewDidLayoutSubviews {
//	[super viewDidLayoutSubviews];
//	NSLog(@"viewDidLayoutSubviews %d", (int)self.bottomLayoutGuide.length);
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	for(c in [self.view constraintsAffectingLayoutForAxis:UILayoutConstraintAxisVertical]) {
		NSLog(@"C: %@", c);
	}
}

- (void)refreshControlActive:(MMRefreshControl *)control {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2000 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^
	{
		[spreadSheetView.refreshControl stopRefresh];
	});
}


//- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
//	UITabBar *tBar = self.tabBarController.tabBar;
//	BOOL hide = newCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact;
//	BOOL changeState = (hide && !tBar.isHidden) || (!hide && tBar.isHidden);
//	if(changeState) [tBar setHidden:hide];
////	if(changeState) {
////		[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
////			[tBar setHidden:hide];
////		} completion:nil];
////	}
//}

#pragma mark - MMSpreadsheetViewDataSource

- (CGSize)spreadsheetView:(MMSpreadsheetView *)spreadsheetView sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat leftColumnWidth = 220.0f;
    CGFloat topRowHeight = 150.0f;
    CGFloat gridCellWidth = 124.0f;
    CGFloat gridCellHeight = 103.0f;

    // Upper left.
    if (indexPath.mmSpreadsheetRow == 0 && indexPath.mmSpreadsheetColumn == 0) {
        return CGSizeMake(leftColumnWidth, topRowHeight);
    }
    
    // Upper right.
    if (indexPath.mmSpreadsheetRow == 0 && indexPath.mmSpreadsheetColumn > 0) {
        return CGSizeMake(gridCellWidth + (indexPath.mmSpreadsheetColumn - NUM_HEADER_COLS ) * 10, topRowHeight);
    }
    
    // Lower left.
    if (indexPath.mmSpreadsheetRow > 0 && indexPath.mmSpreadsheetColumn == 0) {
        return CGSizeMake(leftColumnWidth, gridCellHeight);
    }
    
    return CGSizeMake(gridCellWidth  + (indexPath.mmSpreadsheetColumn - NUM_HEADER_COLS ) * 10, gridCellHeight);
}

- (NSInteger)numberOfRowsInSpreadsheetView:(MMSpreadsheetView *)spreadsheetView {
    NSInteger num = [self.tableData count] + NUM_HEADER_COLS;
    return num;
}

- (NSInteger)numberOfColumnsInSpreadsheetView:(MMSpreadsheetView *)spreadsheetView {
//    NSArray *rowData = [self.tableData firstObject];
//    NSInteger cols = [rowData count];
    return cols + NUM_HEADER_COLS;
}

- (UICollectionViewCell *)spreadsheetView:(MMSpreadsheetView *)spreadsheetView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = nil;
    if (indexPath.mmSpreadsheetRow == 0 && indexPath.mmSpreadsheetColumn == 0) {
        // Upper left.
        cell = [spreadsheetView dequeueReusableCellWithReuseIdentifier:@"GridCell" forIndexPath:indexPath];
        MMGridCell *gc = (MMGridCell *)cell;
        UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mm_logo"]];
        [gc.contentView addSubview:logo];
        logo.center = gc.contentView.center;
        gc.textLabel.numberOfLines = 0;
        cell.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
    }
    else if (indexPath.mmSpreadsheetRow == 0 && indexPath.mmSpreadsheetColumn > 0) {
        // Upper right.
        cell = [spreadsheetView dequeueReusableCellWithReuseIdentifier:@"TopRowCell" forIndexPath:indexPath];
        MMTopRowCell *tr = (MMTopRowCell *)cell;
        tr.textLabel.text = [NSString stringWithFormat:@"COL: %li", (long)indexPath.mmSpreadsheetColumn - NUM_HEADER_COLS];
        cell.backgroundColor = [UIColor whiteColor];
    }
    else if (indexPath.mmSpreadsheetRow > 0 && indexPath.mmSpreadsheetColumn == 0) {
        // Lower left.
        cell = [spreadsheetView dequeueReusableCellWithReuseIdentifier:@"LeftColumnCell" forIndexPath:indexPath];
        MMLeftColumnCell *lc = (MMLeftColumnCell *)cell;
        lc.textLabel.text = [NSString stringWithFormat:@"Row: %li", (long)indexPath.mmSpreadsheetRow - NUM_HEADER_ROWS];
        BOOL isDarker = (indexPath.mmSpreadsheetRow - NUM_HEADER_ROWS) % 2 == 0;
        if (isDarker) {
            cell.backgroundColor = [UIColor colorWithRed:222.0f / 255.0f green:243.0f / 255.0f blue:250.0f / 255.0f alpha:1.0f];
        } else {
            cell.backgroundColor = [UIColor colorWithRed:233.0f / 255.0f green:247.0f / 255.0f blue:252.0f / 255.0f alpha:1.0f];
        }
    }
    else {
        // Lower right.
        cell = [spreadsheetView dequeueReusableCellWithReuseIdentifier:@"GridCell" forIndexPath:indexPath];
        MMGridCell *gc = (MMGridCell *)cell;
        NSArray *colData = [self.tableData objectAtIndex:indexPath.mmSpreadsheetRow - NUM_HEADER_ROWS];
        NSString *rowData = [colData objectAtIndex:indexPath.mmSpreadsheetColumn - NUM_HEADER_COLS];
        gc.textLabel.text = rowData;
        BOOL isDarker = (indexPath.mmSpreadsheetRow - NUM_HEADER_ROWS) % 2 == 0;
        if (isDarker) {
            cell.backgroundColor = [UIColor colorWithRed:242.0f / 255.0f green:242.0f / 255.0f blue:242.0f / 255.0f alpha:1.0f];
        } else {
            cell.backgroundColor = [UIColor colorWithRed:250.0f / 255.0f green:250.0f / 255.0f blue:250.0f / 255.0f alpha:1.0f];
        }
    }

    return cell;
}

#pragma mark - MMSpreadsheetViewDelegate

- (void)spreadsheetView:(MMSpreadsheetView *)spreadsheetView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.selectedGridCells containsObject:indexPath]) {
        [self.selectedGridCells removeObject:indexPath];
        [spreadsheetView deselectItemAtIndexPath:indexPath animated:YES];
    } else {
        [self.selectedGridCells removeAllObjects];
        [self.selectedGridCells addObject:indexPath];
    }
}

- (BOOL)spreadsheetView:(MMSpreadsheetView *)spreadsheetView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)spreadsheetView:(MMSpreadsheetView *)spreadsheetView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    
    /*
     These are the selectors the sender (a UIMenuController) sends by default.
     
     _insertImage:
     cut:
     copy:
     select:
     selectAll:
     paste:
     delete:
     _promptForReplace:
     _showTextStyleOptions:
     _define:
     _addShortcut:
     _accessibilitySpeak:
     _accessibilitySpeakLanguageSelection:
     _accessibilityPauseSpeaking:
     makeTextWritingDirectionRightToLeft:
     makeTextWritingDirectionLeftToRight:
     
     We're only interested in 3 of them at this point
     */
    if (action == @selector(cut:) ||
        action == @selector(copy:) ||
        action == @selector(paste:)) {
        return YES;
    }
    return NO;
}

- (void)spreadsheetView:(MMSpreadsheetView *)spreadsheetView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    NSMutableArray *rowData = [self.tableData objectAtIndex:indexPath.mmSpreadsheetRow];
    if (action == @selector(cut:)) {
        self.cellDataBuffer = [rowData objectAtIndex:indexPath.row];
        [rowData replaceObjectAtIndex:indexPath.row withObject:@""];
        [spreadsheetView reloadData];
    } else if (action == @selector(copy:)) {
        self.cellDataBuffer = [rowData objectAtIndex:indexPath.row];
    } else if (action == @selector(paste:)) {
        if (self.cellDataBuffer) {
            [rowData replaceObjectAtIndex:indexPath.row withObject:self.cellDataBuffer];
            [spreadsheetView reloadData];
        }
    }
}

@end
