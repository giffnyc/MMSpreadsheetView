#Mutual Mobile Spreadsheet View
`MMSpreadsheetView` is a configurable spreadsheet-like view. Depending on the initial header row or column configuration, up to four collection views will be coordinated to provide the user interface. Although originally designed for use on iPad in full-screen, it scales down well for use in smaller views.

<p align="center" >
<img src="http://mutualmobile.github.io/MMSpreadsheetView/ExampleImages/Example.png"/>
</p>

---

Notes from dhoerl:

Sept 2015
* Added variable width columns using the patch file listed in the "Issues" section of the original repository. 
* Added protective code to prevent crashes due to exact dimension matches (another original project Issue)
* Added 'names' to each layout object to assist in debugging.
* Ported code posted on original github site to support variable widths
* Modified the demo project to use variable widths (each column is 10 pixels wider than the one to the left)

Nov 2015
* Added Objective C annotation to better support use in Swift apps (as I am doing)
* Support for "initWithCoder:" so you can now put the view in a Storyboard
* Added variable heights
* SnapToGrid option for the bottom/right collection to snap to its top/left or bottom or right
* Allow for the case of no row data in the lower section (it use to crash the project)
* Added support for showing/hiding a navigation bar as normal TableViews do
* Added a built in "UIRefreshControl" like view to support "Pull To Refresh"
* Hide a tab bar when rotating to landscape on a "Compact Vertical" device (and reshow it later)
* Added a completely new Example Project (Example2 folder) which puts the spreadsheet in a nav controller in a tab view and demos all the new features
* New Demo is Universal (can be used on phone or iPad)
---

##Documentation
Official appledoc documentation can be found at [CocoaDocs](http://cocoadocs.org/docsets/MMSpreadsheetView/).

---

##Installing MMSpreadsheetView
[![Badge w/ Version](https://cocoapod-badges.herokuapp.com/v/MMSpreadsheetView/badge.png)](https://cocoadocs.org/docsets/MMSpreadsheetView)
[![Badge w/ Platform](https://cocoapod-badges.herokuapp.com/p/MMSpreadsheetView/badge.svg)](https://cocoadocs.org/docsets/MMSpreadsheetView)
You can install MMSpreadsheetView in your project by using [CocoaPods](https://github.com/cocoapods/cocoapods):

```Ruby
pod 'MMSpreadsheetView', '~> 0.0.3'
```

---

##Initializing a Spreadsheet View
The designated initializer for `MMSpreadsheetView` requires passing in the number of header rows and columns as well as the initial bounds rect. Register the cell classes you will be using and set the delegate and dataSource. Finally, add the view as a subview.

```Objective-C
// Create the spreadsheet in code.
MMSpreadsheetView *spreadSheetView = [[MMSpreadsheetView alloc] initWithNumberOfHeaderRows:1 numberOfHeaderColumns:1 frame:self.view.bounds];

// Register your cell classes.
[spreadSheetView registerCellClass:[MMGridCell class] forCellWithReuseIdentifier:@"GridCell"];
[spreadSheetView registerCellClass:[MMTopRowCell class] forCellWithReuseIdentifier:@"TopRowCell"];
[spreadSheetView registerCellClass:[MMLeftColumnCell class] forCellWithReuseIdentifier:@"LeftColumnCell"];

// Set the delegate & datasource spreadsheet view.
spreadSheetView.delegate = self;
spreadSheetView.dataSource = self;

// Add the spreadsheet view as a subview.
[self.view addSubview:spreadSheetView];
self.spreadSheetView = spreadSheetView;
```

---

##Caveats

<ul>
<li><strong>Performance</strong>: As the number of cells shown increases, scrolling performance declines. A large grid (1000x1000) takes a long time to initialize, but if the cell sizes are large enough (150x150) or greater, scrolling performance is not affected. However, a small grid (50x50) of (20x20) cells basically doesn't scroll.</li>
<li><strong>NSIndexPath convenience category</strong>: The library includes a convenience category for NSIndexPath to reduce confusion. The additions of indexPath.mmSpreadsheetRow and indexPath.mmSpreadsheetColumn represent their respective elements.</li>
<li><strong>CollectionView pass-through methods</strong>: The following methods provide support for copy/paste actions on cells. All three should be implemented if any are.
<ol>
<li>spreadsheetView:shouldShowMenuForItemAtIndexPath:</li>
<li>spreadsheetView:canPerformAction:forItemAtIndexPath:withSender:</li>
<li>spreadsheetView:performAction:forItemAtIndexPath:withSender:<br /><br /></li>
</ol></li>
<li><strong>Unintended gesture handling</strong>: MMSpreadsheetView hooks into the collection view pan gesture recognizers to implement "exclusive touch," which disables tap registration on other sections of the grid until the first touch ends. Also, touches are disabled when the view is in a bounce to prevent locking the view in an awkward state.</li>
</ul>

---

##Credit
Designed and Developed by these fine folks at [Mutual Mobile](http://mutualmobile.com):

###Development

* [Jeff Lacey](http://twitter.com/canispater)
* [Kevin Harwood](http://twitter.com/kevinharwood)

---

##Feedback
We'd love to hear feedback on the library. Create Github issues, or hit us up on Twitter.

---

##License ![License MIT](https://go-shields.herokuapp.com/license-MIT-blue.png)
`MMSpreadsheetView` is available under the MIT license. See the LICENSE file for more info.
