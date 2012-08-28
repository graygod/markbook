//
//  MBWindowController.h
//  markbook
//
//  Created by amoblin on 12-8-23.
//  Copyright (c) 2012年 amoblin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

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

@property (strong, nonatomic) NSNumber *lastEventId;
@property (nonatomic) FSEventStreamRef stream;
@property (strong, nonatomic) NSFileManager *fm;
@property (strong, nonatomic) NSMutableDictionary* pathModificationDates;
@property (strong, nonatomic) NSString* root;

- (IBAction)refreshAction:(id)sender;

- (void) addModifiedImagesAtPath: (NSString *)path;
    - (NSArray *)recurise:(NSString *)dir;
@end
