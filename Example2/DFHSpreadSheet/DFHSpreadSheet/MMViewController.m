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

	BOOL tabBarHidden;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	rows = 11;
	cols = 4; // 9;

    self.tableData = [NSMutableArray array];

#if 1	// test that it works with no row data
    // Create some fake grid data for the demo.
	for (NSUInteger rowNumber = 0; rowNumber < rows; rowNumber++) {
		NSMutableArray *row = [NSMutableArray array];
		for (NSUInteger columnNumber = 0; columnNumber < cols; columnNumber++) {
			[row addObject:[NSString stringWithFormat:@"R%lu:C%lu", (unsigned long)rowNumber, (unsigned long)columnNumber]];
//NSLog(@"ROW %d", (int)rowNumber);
		}
		[self.tableData addObject:row];
		
	}
	//[spreadSheetView reloadData];
#endif

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



	self.navigationController.navigationBar.translucent = YES;
	self.navigationController.hidesBarsWhenVerticallyCompact = YES;
	self.navigationController.hidesBarsOnSwipe = YES;
	self.navigationController.hidesBarsOnTap = YES;

	spreadSheetView = (MMSpreadsheetView *)self.view;
	spreadSheetView.navigationController = self.navigationController;
	spreadSheetView.wantRefreshControl = YES;

	[spreadSheetView commonInitWithNumberOfHeaderRows:NUM_HEADER_ROWS numberOfHeaderColumns:NUM_HEADER_COLS];
	spreadSheetView.bounces = YES;
	spreadSheetView.alwaysBounceHorizontal = YES;
	spreadSheetView.alwaysBounceVertical = YES;
	spreadSheetView.directionalLockEnabled = YES;
	spreadSheetView.scrollsToTop = YES;
	spreadSheetView.snapToGrid = YES;

	spreadSheetView.backgroundColor = [UIColor grayColor];

    // Register your cell classes.
    [spreadSheetView registerCellClass:[MMGridCell class] forCellWithReuseIdentifier:@"GridCell"];
    [spreadSheetView registerCellClass:[MMTopRowCell class] forCellWithReuseIdentifier:@"TopRowCell"];
    [spreadSheetView registerCellClass:[MMLeftColumnCell class] forCellWithReuseIdentifier:@"LeftColumnCell"];

    // Set the delegate & datasource for the spreadsheet view.
    spreadSheetView.spreadsheetDelegate = self;
    spreadSheetView.dataSource = self;

//[NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(timer:) userInfo:nil repeats:YES];

}

//- (void)timer:(NSTimer *)t {
//	NSLog(@"didSelectItemAtIndexPath FRAME: %@ BOUNDS %@ RF %@", NSStringFromCGRect(spreadSheetView.frame), NSStringFromCGRect(spreadSheetView.bounds), NSStringFromCGRect(spreadSheetView.refreshControl.frame));
//}

- (IBAction)toggleTabBar:(UIBarButtonItem *)sender {
	if(tabBarHidden) {
		tabBarHidden = NO;
		[spreadSheetView hideTabBar:NO withAnimationDuration:0.250 coordinator:nil];
	} else {
		tabBarHidden = YES;
		[spreadSheetView hideTabBar:YES withAnimationDuration:0.250 coordinator:nil];
	}
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	BOOL shouldHide = newCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact;
	self.navigationController.hidesBarsWhenVerticallyCompact = YES;

	UITabBar *tBar = self.tabBarController.tabBar;
	BOOL changeState = (shouldHide && !tBar.isHidden) || (!shouldHide && tBar.isHidden);
	if(changeState) {
		// Hide or unhide the Tab Bar on a phone (device with some compact dimension)
		[spreadSheetView  hideTabBar:shouldHide withAnimationDuration:0 coordinator:coordinator];
	}
//	UIView *vF = [coordinator viewForKey:UITransitionContextFromViewKey];
//	UIView *vT = [coordinator viewForKey:UITransitionContextToViewKey];
//NSLog(@" Views %@ %@", vF, vT);
//
//NSLog(@"START FRAME: %@", NSStringFromCGRect(vF.frame));
//NSLog(@"FINAL FRAME: %@", NSStringFromCGRect(vT.frame));
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];

	dispatch_async(dispatch_get_main_queue(), ^{
		// Prevents taps in the view from showing the nav bar in compact environments
		self.navigationController.hidesBarsWhenVerticallyCompact = NO;
	});
}

/*
	override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
		super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)

		print("will TransitionToTraitCollection")
		if super.traitCollection.horizontalSizeClass == .Compact && newCollection.horizontalSizeClass == .Regular {
			//iPhone 6 Plus!
			lie = true
			coordinator.animateAlongsideTransition(nil, completion: { (context: UIViewControllerTransitionCoordinatorContext) -> Void in
				dispatch_async(dispatch_get_main_queue()) {
					// Need to defer just a bit longer, so that Split View sees the Compact indicator
					self.lie = false
				}
			})
		}
	}
	override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)

		print("DID TransitionToTraitCollection")
	}

*/

- (void)refreshControlActive:(MMRefreshControl *)control {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2000 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^
	{
		[control stopRefresh];
	});
}

#pragma mark - MMSpreadsheetViewDataSource

- (CGSize)spreadsheetView:(MMSpreadsheetView *)spreadsheetView sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat leftColumnWidth = 120.0f;
    CGFloat topRowHeight = 150.0f;
    CGFloat gridCellWidth = 124.0f;
    CGFloat gridCellHeight = 103.0f;

    // Upper left.
    if (indexPath.mmSpreadsheetRow < NUM_HEADER_ROWS && indexPath.mmSpreadsheetColumn == 0) {
        return CGSizeMake(leftColumnWidth, topRowHeight);
    }
    
    // Upper right.
    if (indexPath.mmSpreadsheetRow < NUM_HEADER_ROWS && indexPath.mmSpreadsheetColumn > 0) {
		return CGSizeMake(gridCellWidth + (indexPath.mmSpreadsheetColumn - NUM_HEADER_COLS ) * 10, topRowHeight);
    }
    
    // Lower left.
    if (indexPath.mmSpreadsheetRow >= NUM_HEADER_ROWS && indexPath.mmSpreadsheetColumn == 0) {
		CGFloat width = leftColumnWidth;
		CGFloat height = (indexPath.mmSpreadsheetRow % 2) ? gridCellHeight : (gridCellHeight/2);
        return CGSizeMake(width, height); // indexPath
    }

	// Lower right
	{
		CGFloat width = gridCellWidth  + (indexPath.mmSpreadsheetColumn - NUM_HEADER_COLS ) * 10;
		CGFloat height = (indexPath.mmSpreadsheetRow % 2) ? gridCellHeight : (gridCellHeight/2);
        return CGSizeMake(width, height); // indexPath
	}
}

- (NSInteger)numberOfRowsInSpreadsheetView:(MMSpreadsheetView *)spreadsheetView {
    NSInteger num = [self.tableData count] + NUM_HEADER_ROWS;
    return num;
}

- (NSInteger)numberOfColumnsInSpreadsheetView:(MMSpreadsheetView *)spreadsheetView {
    return cols + NUM_HEADER_COLS;
}

- (UICollectionViewCell *)spreadsheetView:(MMSpreadsheetView *)spreadsheetView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = nil;
    if (indexPath.mmSpreadsheetRow < NUM_HEADER_ROWS && indexPath.mmSpreadsheetColumn == 0) {
        // Upper left.
        cell = [spreadsheetView dequeueReusableCellWithReuseIdentifier:@"GridCell" forIndexPath:indexPath];
        MMGridCell *gc = (MMGridCell *)cell;
        UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mm_logo"]];
        [gc.contentView addSubview:logo];
        logo.center = gc.contentView.center;
        gc.textLabel.numberOfLines = 0;
        cell.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
    }
    else if (indexPath.mmSpreadsheetRow < NUM_HEADER_ROWS && indexPath.mmSpreadsheetColumn > 0) {
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
//NSLog(@"didSelectItemAtIndexPath FRAME: %@ BOUNDS %@", NSStringFromCGRect(spreadsheetView.frame), NSStringFromCGRect(spreadsheetView.bounds));

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
