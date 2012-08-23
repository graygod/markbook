//
//  MBWindowController.m
//  markbook
//
//  Created by amoblin on 12-8-23.
//  Copyright (c) 2012年 amoblin. All rights reserved.
//

#import "MBWindowController.h"

@interface MBWindowController ()

@end

@implementation MBWindowController
@synthesize webView;
@synthesize sourceList;

- (id) init {
    self = [super initWithWindowNibName:@"MBWindowController"];
    return self;
}

- (void) awakeFromNib {
    
    NSString *root = [NSHomeDirectory() stringByAppendingPathComponent:@"markbook"];
    NSString *notesPath = [root stringByAppendingPathComponent:@"notes"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *filelist = [[NSArray alloc] init];
    filelist = [fileManager contentsOfDirectoryAtPath:notesPath error:nil];
    for (NSString *file in filelist) {
        NSLog(@"%@", file);
    }
    
    NSString *filedir = @"notes/mac";
    NSString *filename = @"cocoa.rst";
    NSString *source = [NSString stringWithFormat:@"%@/%@/%@", root, filedir, filename];
    NSString *dest = [NSTemporaryDirectory() stringByAppendingFormat:@"%@.htm", filename];
    NSString *url = [NSString stringWithFormat:@"file://%@", dest];
    NSArray *args = [NSArray arrayWithObjects:source, dest, nil];
    
    [[NSTask launchedTaskWithLaunchPath:@"/usr/local/bin/rst2html.py" arguments:args] waitUntilExit];
    
    [[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}

- (id)initWithWindow:(NSWindow *)window
{
    //self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma mark - NSOutlineView delegate  

//- (BOOL)outlineView:

@end
