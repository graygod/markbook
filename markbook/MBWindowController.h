//
//  MBWindowController.h
//  markbook
//
//  Created by amoblin on 12-8-23.
//  Copyright (c) 2012年 amoblin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface MBWindowController : NSWindowController
@property (weak) IBOutlet WebView *webView;
@property (weak) IBOutlet NSOutlineView *sourceList;

@end
