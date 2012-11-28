//
//  MBAppDelegate.h
//  markbook
//
//  Created by amoblin on 12-8-23.
//  Copyright (c) 2012年 amoblin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MBWindowController;

@interface MBAppDelegate : NSObject <NSApplicationDelegate>

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong) MBWindowController *myWindowController;
@property (strong) IBOutlet NSWindow *preferencesWindow;
- (IBAction)showPreferencesWindow:(id)sender;
- (IBAction)setEditorAction:(id)sender;
@property (weak) IBOutlet NSPopUpButton *selectAppPopUpButton;
@property (strong, nonatomic) NSArray *apps;

- (IBAction)saveAction:(id)sender;

@end
