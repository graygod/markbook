//
//  MBAppDelegate.m
//  markbook
//
//  Created by amoblin on 12-8-23.
//  Copyright (c) 2012年 amoblin. All rights reserved.
//

#import "MBAppDelegate.h"
#import "MBWindowController.h"
#import "PFMoveApplication.h"

@implementation MBAppDelegate
@synthesize selectAppPopUpButton = _selectAppPopUpButton;

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize myWindowController;
@synthesize preferencesWindow = _preferencesWindow;
@synthesize apps;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    //PFMoveToApplicationsFolderIfNecessary();
    // Insert code here to initialize your application
    myWindowController = [[MBWindowController alloc] initWithWindowNibName:@"MBWindowController"];
    [myWindowController showWindow:self];
}

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "sina.markbook" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"sina.markbook"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"markbook" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        /*
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
         */
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"markbook.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) 
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)showPreferencesWindow:(id)sender {
    [_preferencesWindow display];
    [self initAppList];
    [_preferencesWindow makeKeyAndOrderFront:self];
}

- (IBAction)setEditorAction:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[sender titleOfSelectedItem] forKey:@"editor"];
}

- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (IBAction)importNotesAction:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    //[panel setDirectoryURL:[NSURL URLWithString:NSHomeDirectory()]];
    [panel setCanChooseDirectories:YES];
    //[panel setAllowedFileTypes:[NSDictionaryResultType]; // Set what kind of file to select.
    // More panel configure code.
    [panel beginSheetModalForWindow:self.myWindowController.mainWindow completionHandler: (^(NSInteger result){
        if(result == NSOKButton) {
            NSArray *fileURLs = [panel URLs];
            NSLog(@"%@", [[fileURLs objectAtIndex:0] path]);
            [self.myWindowController importNotes:[[fileURLs objectAtIndex:0] path]];
        }
    })];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    [myWindowController showWindow:self];
    return NO;
}

- (void) initAppList {
    apps = [self AllApplications:[NSArray arrayWithObjects:@"/Applications", nil]];
    [_selectAppPopUpButton removeAllItems];
    [_selectAppPopUpButton addItemsWithTitles:apps];
    NSString *app = [[NSUserDefaults standardUserDefaults] objectForKey:@"editor"];
    if (app) {
        [_selectAppPopUpButton selectItemWithTitle:app];
    }
}

- (void) ApplicationsInDirectory:(NSString*)searchPath withApplications:(NSMutableArray*)applications{
    BOOL isDir;
    NSFileManager* manager = [NSFileManager defaultManager];
    NSArray* files = [manager contentsOfDirectoryAtPath:searchPath error:nil];
    NSEnumerator* fileEnum = [files objectEnumerator];
    NSString* file;
    while (file = [fileEnum nextObject]) {
        [manager changeCurrentDirectoryPath:searchPath];
        if ([manager fileExistsAtPath:file isDirectory:&isDir] && isDir) {
            NSString* fullpath = [searchPath stringByAppendingPathComponent:file];
            if ([[file pathExtension] isEqualToString:@"app"]) {
                [applications addObject:[file stringByDeletingPathExtension]];
            }
            else [self ApplicationsInDirectory:fullpath withApplications:applications];
        }
    }
}

- (NSArray*) AllApplications:(NSArray*) searchPaths{
    
    NSMutableArray* applications = [[NSMutableArray alloc] initWithCapacity:100];
    NSEnumerator* searchPathEnum = [searchPaths objectEnumerator];
    NSString* path;
    while (path = [searchPathEnum nextObject]) [self ApplicationsInDirectory:path withApplications:applications];
    return ([applications count]) ? applications : nil;
}

@end
