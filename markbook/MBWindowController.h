//
//  MBWindowController.h
//  markbook
//
//  Created by amoblin on 12-8-23.
//  Copyright (c) 2012年 amoblin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "MBCore.h"

@interface SnapBox : NSBox
@property (strong) IBOutlet id delegate;
@property (readwrite) BOOL selected;
@end

@interface MBWindowController : NSWindowController
@property (weak) IBOutlet NSView *middleView;
@property (strong) IBOutlet NSScrollView *tableScrollView;
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSScrollView *collectionScrollView;
@property (weak) IBOutlet NSTextField *note_title_field;
@property (weak) IBOutlet NSMatrix *note_type_matrix;
@property (strong) IBOutlet NSView *addNoteView;

@property (weak) IBOutlet WebView *webView;
@property (weak) IBOutlet NSOutlineView *myOutlineView;
@property (strong) IBOutlet NSTreeController *treeController;
@property (weak) IBOutlet NSCollectionView *myCollectionView;
@property (strong) IBOutlet NSArrayController *noteArray;
@property (strong, nonatomic) NSMutableArray *notes;

@property (strong) NSImage *folderImage;
@property (strong) NSArray *dragNodesArray;
@property (weak) IBOutlet NSButton *addButton;
@property (weak) IBOutlet NSButton *delButton;
@property (strong) IBOutlet NSWindow *alertWindow;
@property (strong) IBOutlet NSWindow *mainWindow;

@property (strong, nonatomic) NSFileManager *fm;
@property (strong, nonatomic) MBCore *core;

- (IBAction)addFileAction:(id)sender;
- (IBAction)delFileAction:(id)sender;
- (IBAction)closeNoteSheet:(id)sender;
- (void) importNotes:(NSString *)dir;

@end
