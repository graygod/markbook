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
@end

@interface MBWindowController : NSWindowController

@property (weak) IBOutlet WebView *webView;
@property (weak) IBOutlet NSOutlineView *myOutlineView;
@property (strong) IBOutlet NSTreeController *treeController;
@property (weak) IBOutlet NSView *placeHolderView;
@property (weak) IBOutlet NSCollectionView *myCollectionView;
@property (strong) IBOutlet NSArrayController *noteArray;

@property (strong) NSImage *folderImage;
@property (strong) NSImage *urlImage;
@property (strong) NSArray *dragNodesArray;
@property (strong) NSView *currentView;
@property (nonatomic) BOOL retargetWebView;
@property (weak) IBOutlet NSButton *addButton;
@property (weak) IBOutlet NSButton *delButton;
@property (strong) IBOutlet NSWindow *alertWindow;
@property (strong) IBOutlet NSWindow *mainWindow;

@property (strong, nonatomic) NSFileManager *fm;
@property (strong, nonatomic) MBCore *core;

- (IBAction)addFileAction:(id)sender;
- (IBAction)delFileAction:(id)sender;

@end
