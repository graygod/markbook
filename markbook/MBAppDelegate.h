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
@property (weak) IBOutlet NSWindow *preferencesWindow;
- (IBAction)showPreferencesWindow:(id)sender;
- (IBAction)setEditorAction:(id)sender;

- (IBAction)saveAction:(id)sender;

@end
