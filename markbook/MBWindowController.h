//
//  MBWindowController.h
//  markbook
//
//  Created by amoblin on 12-8-23.
//  Copyright (c) 2012年 amoblin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "MBAppDelegate.h"

@class SeparatorCell;

@interface MBWindowController : NSWindowController

@property (weak) IBOutlet WebView *webView;
@property (weak) IBOutlet NSOutlineView *myOutlineView;
@property (strong) IBOutlet NSTreeController *treeController;
@property (weak) IBOutlet NSView *placeHolderView;

@property (nonatomic) BOOL buildingOutlineView;
@property (strong, nonatomic) NSMutableArray *contents;
@property (strong) NSImage *folderImage;
@property (strong) NSImage *urlImage;
@property (strong) SeparatorCell *separatorCell;
@property (strong) NSArray *dragNodesArray;
@property (strong) NSView *currentView;
@property (nonatomic) BOOL retargetWebView;
@property (strong) IBOutlet MBAppDelegate *delegate;
@property (weak) IBOutlet NSButton *addButton;
@property (weak) IBOutlet NSButton *delButton;
@property (strong) IBOutlet NSWindow *alertWindow;
@property (strong) IBOutlet NSWindow *mainWindow;

@property (strong, nonatomic) NSNumber *lastEventId;
@property (nonatomic) FSEventStreamRef stream;
@property (strong, nonatomic) NSFileManager *fm;
@property (strong, nonatomic) NSMutableDictionary* pathInfos;
@property (strong, nonatomic) NSString* root;

- (IBAction)addFileAction:(id)sender;
- (IBAction)delFileAction:(id)sender;
- (void) addModifiedFilesAtPath: (NSString *)path;
- (NSArray *)recurise:(NSString *)dir;
- (NSIndexPath*)indexPathOfString:(NSString *)path;
- (void) rst2html:(NSString *)path;
- (void)addChild:(NSString *)url withName:(NSString *)nameStr selectParent:(BOOL)select;

@end