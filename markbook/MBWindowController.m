//
//  MBWindowController.m
//  markbook
//
//  Created by amoblin on 12-8-23.
//  Copyright (c) 2012年 amoblin. All rights reserved.
//

#import "MBWindowController.h"
#import "ChildNode.h"
#import "ImageAndTextCell.h"
#import "SeparatorCell.h"


#define EGGS_ROOT               @"/Applications/MarkBook.app/Contents/Resources/myeggs"

#define COLUMNID_NAME			@"NameColumn"	// the single column name in our outline view
#define INITIAL_INFODICT		@"Outline"		// name of the dictionary file to populate our outline view

#define ICONVIEW_NIB_NAME		@"IconView"		// nib name for the icon view
#define FILEVIEW_NIB_NAME		@"FileView"		// nib name for the file view
#define CHILDEDIT_NAME			@"ChildEdit"	// nib name for the child edit window controller

#define UNTITLED_NAME			@"Untitled.rst"		// default name for added folders and leafs

#define HTTP_PREFIX				@"/"

// default folder titles
#define DEVICES_NAME			@"DEVICES"
#define PLACES_NAME				@"PLACES"


#define kNodesPBoardType		@"myNodesPBoardType"	// drag and drop pasteboard type

#define KEY_NAME				@"name"
#define KEY_URL					@"url"
#define KEY_SEPARATOR			@"separator"
#define KEY_GROUP				@"group"
#define KEY_FOLDER				@"folder"
#define KEY_ENTRIES				@"entries"


// -------------------------------------------------------------------------------
//	TreeAdditionObj
//
//	This object is used for passing data between the main and secondary thread
//	which populates the outline view.
// -------------------------------------------------------------------------------
@interface TreeAdditionObj : NSObject
{
	NSIndexPath *indexPath;
	NSString	*nodeURL;
	NSString	*nodeName;
	BOOL		selectItsParent;
}

@property (readonly) NSIndexPath *indexPath;
@property (readonly) NSString *nodeURL;
@property (readonly) NSString *nodeName;
@property (readonly) BOOL selectItsParent;

@end


#pragma mark -

@implementation TreeAdditionObj

@synthesize indexPath, nodeURL, nodeName, selectItsParent;

// -------------------------------------------------------------------------------
//  initWithURL:url:name:select
// -------------------------------------------------------------------------------
- (id)initWithURL:(NSString *)url withName:(NSString *)name selectItsParent:(BOOL)select
{
	self = [super init];
	
	nodeName = name;
	nodeURL = url;
	selectItsParent = select;
	
	return self;
}
@end


@interface MBWindowController ()

@end

@implementation MBWindowController
@synthesize webView;
@synthesize myOutlineView;
@synthesize buildingOutlineView;
@synthesize treeController;
@synthesize placeHolderView;
@synthesize contents;
@synthesize folderImage, urlImage;
@synthesize separatorCell;
@synthesize dragNodesArray;
@synthesize currentView;
@synthesize retargetWebView;
@synthesize delegate;
@synthesize addButton;
@synthesize stream;
@synthesize lastEventId;
@synthesize fm;
@synthesize pathInfos;
@synthesize root;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        root = [NSHomeDirectory() stringByAppendingPathComponent:@"MarkBook/"];

        if ( ! [[NSUserDefaults standardUserDefaults] objectForKey:@"editor"]) {
            [[NSUserDefaults standardUserDefaults] setObject:@"TextEdit" forKey:@"editor"];
        }
        contents = [[NSMutableArray alloc] init];
        
		// cache the reused icon images
		folderImage = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
		[folderImage setSize:NSMakeSize(16,16)];
		
		urlImage = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericURLIcon)];
		[urlImage setSize:NSMakeSize(16,16)];
        
        fm = [NSFileManager defaultManager];
        pathInfos = [[NSMutableDictionary alloc] initWithCapacity:300];
        
        NSString *notes_path = [NSHomeDirectory() stringByAppendingPathComponent:@"MarkBook/notes"];
        if ( ! [fm fileExistsAtPath:notes_path]) {
            [fm createDirectoryAtPath:notes_path withIntermediateDirectories:YES attributes:NULL error:nil];
            //NSLog(@"%@", [EGGS_ROOT stringByAppendingPathComponent:@"welcome.rst"]);
            //NSLog(@"%@", [notes_path stringByAppendingPathComponent:@"welcome.rst"]);
            [fm copyItemAtPath:[EGGS_ROOT stringByAppendingPathComponent:@"welcome.rst"] toPath:[notes_path stringByAppendingPathComponent:@"welcome.rst"] error:nil];
        }
        
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


- (void) awakeFromNib {
    
	NSTableColumn *tableColumn = [myOutlineView tableColumnWithIdentifier:COLUMNID_NAME];
	ImageAndTextCell *imageAndTextCell = [[ImageAndTextCell alloc] init];
	[imageAndTextCell setEditable:YES];
	[tableColumn setDataCell:imageAndTextCell];
    
    [addButton setImage:[NSImage imageNamed:NSImageNameAddTemplate]];
    
	separatorCell = [[SeparatorCell alloc] init];
    [separatorCell setEditable:NO];
    
	[NSThread detachNewThreadSelector:	@selector(populateOutlineContents:)
										toTarget:self		// we are the target
										withObject:nil];
    
	[myOutlineView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
    [myOutlineView setDoubleAction:@selector(openNote:)];
    [self initializeEventStream];
}

- (void) initializeEventStream {
    NSString *notesPath = [root stringByAppendingPathComponent:@"notes"];
    NSArray *pathsToWatch = [NSArray arrayWithObject:notesPath];
    FSEventStreamContext context = {0, (__bridge void *)self, NULL, NULL, NULL};
    NSTimeInterval latency = 0.1;
    stream = FSEventStreamCreate(NULL, &fsevents_callback, &context, (__bridge CFArrayRef) pathsToWatch, [lastEventId unsignedLongValue], (CFAbsoluteTime) latency, kFSEventStreamCreateFlagUseCFTypes);
    
    FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(stream);
}

void fsevents_callback(ConstFSEventStreamRef streamRef,
                       void *userData,
                       size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[]) {
    
    MBWindowController *wc = (__bridge MBWindowController *)userData;
    size_t i;
    for (i=0; i<numEvents; i++) {
        //NSLog(@"%@", streamRef);
        //NSLog(@"%u", eventFlags[i]);
        [wc addModifiedImagesAtPath:[(__bridge NSArray *)eventPaths objectAtIndex:i]];
        wc.lastEventId = [NSNumber numberWithLong:eventIds[i]];
    }
}

- (IBAction)addFileAction:(id)sender {
    NSString *parentDir;
    if ([[treeController selectedNodes] count] > 0) {
        NSTreeNode *selectedNode = [[treeController selectedNodes] objectAtIndex:0];
        if ([selectedNode isLeaf]) {
            parentDir = [[[selectedNode parentNode] representedObject] urlString];
        } else {
            parentDir = [[selectedNode representedObject] urlString];
        }
    } else {
        parentDir = [root stringByAppendingPathComponent:@"notes"];
    }
    //NSLog(@"%@", [parentDir stringByAppendingPathComponent:UNTITLED_NAME]);
    //NSLog(@"%@", [self indexPathOfString:parentDir]);
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    NSString *content = [NSString stringWithFormat:@"=====\nTitle\n=====\n\n:Author: your_name\n:title: english_title\n:date: %@\n", [dateFormatter stringFromDate:[NSDate date]]];
    NSData *fileContents = [content dataUsingEncoding:NSUTF8StringEncoding];
    [fm createFileAtPath:[parentDir stringByAppendingPathComponent:UNTITLED_NAME] contents:fileContents attributes:nil];
    
    //[self addChild:[parentDir stringByAppendingPathComponent:UNTITLED_NAME] withName:UNTITLED_NAME selectParent:YES];
    //[self addFolder:UNTITLED_NAME withURL: atIndexPath:(NSIndexPath*)@""];
}

- (void) addModifiedImagesAtPath: (NSString *)path {
    NSDate *modDate = [[NSDate alloc] init];
    NSArray *nodes = [fm contentsOfDirectoryAtPath:path error:nil];
    NSString *fullPath = nil;
    BOOL isDir;
    //NSLog(@"******* %@",path);
    
    if ([fm fileExistsAtPath:path isDirectory:&isDir]) {
    } else {
        //NSLog(@"%@", path);
        return;
    }
    
    NSDictionary *attributes = [fm attributesOfItemAtPath:path error:NULL];
    modDate = [attributes objectForKey:NSFileModificationDate];
    
    if ([pathInfos objectForKey:path]) {
        if ([modDate compare:[[pathInfos objectForKey:path] objectAtIndex:0]] == NSOrderedDescending) {
            NSString *prePath;
            if ([[treeController selectedNodes] count] > 0) {
                 prePath = [[[[treeController selectedNodes] objectAtIndex:0] representedObject] urlString];
            }
            
            NSIndexPath *indexPath = [self indexPathOfString:path];
            if (indexPath) {
                //[treeController removeObjectAtArrangedObjectIndexPath:indexPath];

                //NSDictionary *notes = [[NSDictionary alloc] initWithObjectsAndKeys:[fm displayNameAtPath:path], @"group", [self recurise:path], @"entries", path, KEY_URL, nil];
                 //NSArray *entries = [[NSArray alloc] initWithObjects:notes, nil];
                
                //if (buildingOutlineView) {
                //    [self addEntries:(NSDictionary *)entries atIndexPath:indexPath];
                //} else {
                 //   [myOutlineView setHidden:YES];
                 //   [self addEntries:(NSDictionary *)entries atIndexPath:indexPath];
                 //   if (prePath) {
                 //       [treeController setSelectionIndexPath:[self indexPathOfString:prePath]];
                 //   }
                 //   [myOutlineView setHidden:NO];
                //}
                NSArray *newNodes = [fm contentsOfDirectoryAtPath:path error:nil];
                NSArray *oldNodes = [[pathInfos objectForKey:path] objectAtIndex:1];
                for (NSString *node in newNodes) {
                    if ( ![oldNodes containsObject:node]) {
                        NSString *fullPath = [path stringByAppendingPathComponent:node];
                        NSLog(@"%@", node);
                        //should add in tree
                        [self addChild:fullPath withName:[node stringByDeletingPathExtension] selectParent:YES];
                    }
                }
                
                for (NSString *node in oldNodes) {
                    if ( ![newNodes containsObject:node]) {
                        NSString *fullPath = [path stringByAppendingPathComponent:node];
                        //should remove in tree
                        NSLog(@"%@", node);
                        NSIndexPath *nodeIndex = [self indexPathOfString:fullPath];
                        if (nodeIndex) {
                            [treeController removeObjectAtArrangedObjectIndexPath:nodeIndex];
                        }
                    }
                }
                [pathInfos setObject:[NSArray arrayWithObjects:modDate, newNodes, nil] forKey:path];
            }
        }
    } else {
        //NSLog(@"%@", [NSTemporaryDirectory() stringByAppendingPathComponent:path]);
        [fm createDirectoryAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:path] withIntermediateDirectories:YES attributes:NULL error:nil];
        [pathInfos setObject:[NSArray arrayWithObjects:modDate, nodes, nil] forKey:path];
    }

    for(NSString *node in nodes) {
        fullPath = [path stringByAppendingPathComponent:node];
        [fm fileExistsAtPath:fullPath isDirectory:(&isDir)];
        
        NSDictionary *fileAttributes = [fm attributesOfItemAtPath:fullPath error:NULL];
        modDate = [fileAttributes objectForKey:NSFileModificationDate];
        
        /* rst file */
        if ([[node pathExtension] isEqualToString:@"rst"]) {
            if ([pathInfos objectForKey:fullPath]) {
                if ([modDate compare:[pathInfos objectForKey:fullPath]] == NSOrderedDescending) {
                    [pathInfos setObject:modDate forKey:fullPath];
                    [self rst2html:fullPath withSync:YES];
                    [webView reload:self];
                }
            } else {
                //[self rst2html:fullPath withSync:NO];
                [pathInfos setObject:modDate forKey:fullPath];
            }
        }
    }
}

- (void) rst2html:(NSString *)path withSync:(BOOL)isSync {
    BOOL isDir;
    [fm fileExistsAtPath:path isDirectory:&isDir];
    if (isDir) {
        return;
    }

    NSString *dest = [NSString stringWithFormat:@"%@.html", [NSTemporaryDirectory() stringByAppendingPathComponent:path]];
    NSString *parent_path = [dest stringByDeletingLastPathComponent];
    if ( ! [fm fileExistsAtPath:parent_path isDirectory:nil]) {
        [fm createDirectoryAtPath:parent_path withIntermediateDirectories:YES attributes:NULL error:nil];
    }
    
    NSTask *task = [[NSTask alloc] init];
    NSString *rst2html_command = [EGGS_ROOT stringByAppendingPathComponent:@"bin/rst2html.py"];
    NSArray *args = [NSArray arrayWithObjects:rst2html_command, path, dest, nil];
    [task setEnvironment:[NSDictionary dictionaryWithObjectsAndKeys:@"zh_CN.UTF-8", @"LC_CTYPE", nil]];
    [task setLaunchPath:[EGGS_ROOT stringByAppendingPathComponent:@"bin/mypython"]];
    [task setArguments:args];
    [task launch];
    if (isSync) {
        [task waitUntilExit];
        int status = [task terminationStatus];
        if (status == 0)
            NSLog(@"Task succeeded.");
        else
            NSLog(@"Task failed.");
    }
}

- (NSIndexPath*)indexPathOfString:(NSString *)path
{
    return [self indexPathOfString:path inNodes:[[treeController arrangedObjects] childNodes]];
}

- (NSIndexPath*)indexPathOfString:(NSString *)path inNodes:(NSArray*)nodes
{
    for(NSTreeNode* node in nodes)
    {
        //NSLog(@"%@", [[node representedObject] urlString]);
        if([[[node representedObject] urlString] isEqualToString:path]) {
            return [node indexPath];
        }
        if([[node childNodes] count])
        {
            NSIndexPath* indexPath = [self indexPathOfString:path inNodes:[node childNodes]];
            if(indexPath)
                return indexPath;
        }
    }
    return nil;
}

- (void) openNote:(id) sender {
	NSArray	*selection = [treeController selectedNodes];	
	if ([selection count] > 0) {
        BaseNode *node = [[selection objectAtIndex:0] representedObject];
        NSString *app = [[NSUserDefaults standardUserDefaults] objectForKey:@"editor"];
        [[NSWorkspace sharedWorkspace] openFile:[node urlString] withApplication:app];
    }
}

// -------------------------------------------------------------------------------
//	setContents:newContents
// -------------------------------------------------------------------------------
- (void)setContents:(NSArray *)newContents
{
	if (contents != newContents)
	{
		contents = [[NSMutableArray alloc] initWithArray:newContents];
	}
}

// -------------------------------------------------------------------------------
//	contents:
// -------------------------------------------------------------------------------
- (NSMutableArray *)contents
{
	return contents;
}


#pragma mark - Actions

// -------------------------------------------------------------------------------
//	selectParentFromSelection
//
//	Take the currently selected node and select its parent.
// -------------------------------------------------------------------------------
- (void)selectParentFromSelection
{
	if ([[treeController selectedNodes] count] > 0) {
		NSTreeNode* firstSelectedNode = [[treeController selectedNodes] objectAtIndex:0];
		NSTreeNode* parentNode = [firstSelectedNode parentNode];
		if (parentNode) {
			// select the parent
			NSIndexPath* parentIndex = [parentNode indexPath];
			[treeController setSelectionIndexPath:parentIndex];
		} else {
			// no parent exists (we are at the top of tree), so make no selection in our outline
			NSArray* selectionIndexPaths = [treeController selectionIndexPaths];
			[treeController removeSelectionIndexPaths:selectionIndexPaths];
		}
	}
}

// -------------------------------------------------------------------------------
//	addFolder:folderName
// -------------------------------------------------------------------------------
- (void)addFolder:(NSString *)folderName withURL:(NSString *)url atIndexPath:(NSIndexPath *)indexPath
{
	TreeAdditionObj *treeObjInfo = [[TreeAdditionObj alloc] initWithURL:url withName:folderName selectItsParent:NO];
	
	if (buildingOutlineView) {
		// add the folder to the tree controller, but on the main thread to avoid lock ups
        [self performSelectorOnMainThread:@selector(performAddFolder:) withObject:[NSArray arrayWithObjects:treeObjInfo, @"", nil] waitUntilDone:YES];
	} else {
        [self performAddFolder:[NSArray arrayWithObjects:treeObjInfo, indexPath, nil]];
	}
}

// -------------------------------------------------------------------------------
//	performAddFolder:treeAddition
// -------------------------------------------------------------------------------
- (void)performAddFolder:(NSArray *)array {
    TreeAdditionObj *treeAddition = [array objectAtIndex:0];
    NSIndexPath *myIndexPath = [array objectAtIndex:1];
    if ( ! [myIndexPath isEqual:@""]) {
        ChildNode *node = [[ChildNode alloc] init];
        node.nodeTitle = [treeAddition nodeName];
        node.urlString = [treeAddition nodeURL];
        
        // the user is adding a child node, tell the controller directly
        [treeController insertObject:node atArrangedObjectIndexPath:myIndexPath];
        // in insertObject action, rst2html will be called!
        return;
    }
	// NSTreeController inserts objects using NSIndexPath, so we need to calculate this
	NSIndexPath *indexPath = nil;
	
	// if there is no selection, we will add a new group to the end of the contents array
	if ([[treeController selectedObjects] count] == 0) {
		// there's no selection so add the folder to the top-level and at the end
		indexPath = [NSIndexPath indexPathWithIndex:[contents count]];
	} else {
		// get the index of the currently selected node, then add the number its children to the path -
		// this will give us an index which will allow us to add a node to the end of the currently selected node's children array.
		//
		indexPath = [treeController selectionIndexPath];
		if ([[[treeController selectedObjects] objectAtIndex:0] isLeaf]) {
			// user is trying to add a folder on a selected child,
			// so deselect child and select its parent for addition
			[self selectParentFromSelection];
		} else {
			indexPath = [indexPath indexPathByAddingIndex:[[[[treeController selectedObjects] objectAtIndex:0] children] count]];
		}
	}
	
	ChildNode *node = [[ChildNode alloc] init];
    node.nodeTitle = [treeAddition nodeName];
    node.urlString = [treeAddition nodeURL];
	
	// the user is adding a child node, tell the controller directly
	[treeController insertObject:node atArrangedObjectIndexPath:indexPath];
}



// -------------------------------------------------------------------------------
//	performAddChild:treeAddition
// -------------------------------------------------------------------------------
- (void)performAddChild:(TreeAdditionObj *)treeAddition
{
	if ([[treeController selectedObjects] count] > 0)
	{
		// we have a selection
		if ([[[treeController selectedObjects] objectAtIndex:0] isLeaf])
		{
			// trying to add a child to a selected leaf node, so select its parent for add
			[self selectParentFromSelection];
		}
	}
	
	// find the selection to insert our node
	NSIndexPath *indexPath;
	if ([[treeController selectedObjects] count] > 0)
	{
		// we have a selection, insert at the end of the selection
		indexPath = [treeController selectionIndexPath];
		indexPath = [indexPath indexPathByAddingIndex:[[[[treeController selectedObjects] objectAtIndex:0] children] count]];
	}
	else
	{
		// no selection, just add the child to the end of the tree
		indexPath = [NSIndexPath indexPathWithIndex:[contents count]];
	}
	
	// create a leaf node
	ChildNode *node = [[ChildNode alloc] initLeaf];
	node.urlString = [treeAddition nodeURL];
    
	if ([treeAddition nodeURL]) {
		if ([[treeAddition nodeURL] length] > 0) {
			// the child to insert has a valid URL, use its display name as the node title
			if ([treeAddition nodeName])
                node.nodeTitle = [treeAddition nodeName];
			else
                node.nodeTitle = [fm displayNameAtPath:[node urlString]];
		} else {
			// the child to insert will be an empty URL
            node.nodeTitle = @"Untitled";
            node.urlString = @"http://";
		}
	}
	
	// the user is adding a child node, tell the controller directly
	[treeController insertObject:node atArrangedObjectIndexPath:indexPath];

	// adding a child automatically becomes selected by NSOutlineView, so keep its parent selected
	if ([treeAddition selectItsParent])
		[self selectParentFromSelection];
}

- (void)addEntries:(NSDictionary *)entries atIndexPath:(NSIndexPath *)indexPath {
	NSEnumerator *entryEnum = [entries objectEnumerator];
	
	id entry;
	while ((entry = [entryEnum nextObject]))
	{
		if ([entry isKindOfClass:[NSDictionary class]])
		{
			NSString *urlStr = [entry objectForKey:KEY_URL];
			
			if ([entry objectForKey:KEY_SEPARATOR])
			{
				// its a separator mark, we treat is as a leaf
				[self addChild:nil withName:nil selectParent:YES];
			}
			else if ([entry objectForKey:KEY_FOLDER])
			{
				// its a file system based folder,
				// we treat is as a leaf and show its contents in the NSCollectionView
				NSString *folderName = [entry objectForKey:KEY_FOLDER];
				[self addChild:urlStr withName:folderName selectParent:YES];
			} else if ([entry objectForKey:KEY_GROUP]) {
				// it's a generic container
				NSString *folderName = [entry objectForKey:KEY_GROUP];
                [self addFolder:folderName withURL:urlStr atIndexPath:indexPath];
				
				// add its children
				NSDictionary *newChildren = [entry objectForKey:KEY_ENTRIES];
                [self addEntries:newChildren atIndexPath:(NSIndexPath*)@""];
				
				[self selectParentFromSelection];
			} else {
				// its a leaf item with a URL
				NSString *nameStr = [entry objectForKey:KEY_NAME];
				[self addChild:urlStr withName:nameStr selectParent:YES];
			}
		}
	}
	
	// inserting children automatically expands its parent, we want to close it
    if (buildingOutlineView) {
        if ([[treeController selectedNodes] count] > 0)
        {
            NSTreeNode *lastSelectedNode = [[treeController selectedNodes] objectAtIndex:0];
            if ([[fm displayNameAtPath:[[lastSelectedNode representedObject] urlString]] isEqualToString:@"notes"]) {
                return;
            }
            [myOutlineView collapseItem:lastSelectedNode];
        }
    }
}

- (NSArray *)recurise:(NSString *)dir{
    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:100];
    
    //NSLog(@"%@", dir);
    BOOL isDir = NO;
    for (NSString *file in [fm contentsOfDirectoryAtPath:dir error:nil]) {
        NSString *filePath = [dir stringByAppendingPathComponent:file];
        [fm fileExistsAtPath:filePath isDirectory:(&isDir)];
        if (isDir) {
            if ([file isEqualToString:@".git"]) {
                continue;
            }
            NSArray *entries = [self recurise:filePath];
            filePath = [NSString stringWithFormat:@"%@/", filePath];
            [arr addObject:[[NSDictionary alloc] initWithObjectsAndKeys:file, @"group", entries, @"entries", filePath, @"url", nil]];
        } else if ([[file pathExtension] isEqualToString:@"rst"]) {
            [arr addObject:[[NSDictionary alloc] initWithObjectsAndKeys:[file stringByDeletingPathExtension], @"name", filePath, @"url", nil]];
        }
        isDir = NO;
    }
    return arr;
}

// -------------------------------------------------------------------------------
//	addChild:url:withName:selectParent
// -------------------------------------------------------------------------------
- (void)addChild:(NSString *)url withName:(NSString *)nameStr selectParent:(BOOL)select
{
	TreeAdditionObj *treeObjInfo = [[TreeAdditionObj alloc] initWithURL:url
                                                               withName:nameStr
                                                        selectItsParent:select];
	
	if (buildingOutlineView)
	{
		// add the child node to the tree controller, but on the main thread to avoid lock ups
		[self performSelectorOnMainThread:@selector(performAddChild:)
                               withObject:treeObjInfo
                            waitUntilDone:YES];
	}
	else
	{
		[self performAddChild:treeObjInfo];
	}
	
}

// -------------------------------------------------------------------------------
//	changeItemView
// ------------------------------------------------------------------------------
- (void)changeItemView
{
	NSArray	*selection = [treeController selectedNodes];	
	if ([selection count] > 0)
    {
        BaseNode *node = [[selection objectAtIndex:0] representedObject];
        NSString *urlStr = [node urlString];
        if (urlStr)
        {
            //NSURL *targetURL = [NSURL fileURLWithPath:urlStr];
            
            if ([urlStr hasPrefix:HTTP_PREFIX])
            {
                // 1) the url is a web-based url
                //
                if (currentView != webView)
                {
                    // change to web view
                    [self removeSubview];
                    currentView = nil;
                    [placeHolderView addSubview:webView];
                    currentView = webView;
                }
                
                // this will tell our WebUIDelegate not to retarget first responder since some web pages force
                // forus to their text fields - we want to keep our outline view in focus.
                retargetWebView = YES;	

                //NSString *filedir = @"notes/mac";
                //NSString *filename = @"cocoa.rst";

                //[urlStr stringByDeletingLastPathComponent]
                
                NSString *dest_path = [NSString stringWithFormat:@"%@.html", [NSTemporaryDirectory() stringByAppendingPathComponent:urlStr]];
                
                if ( ! [fm fileExistsAtPath:dest_path isDirectory:nil]) {
                    //NSLog(@"url file is not existed. generating");
                    [self rst2html:urlStr withSync:YES];
                }
                //NSLog(@"%@", [[NSString stringWithFormat:@"file://%@.html", [NSTemporaryDirectory() stringByAppendingPathComponent:urlStr]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
                [webView setMainFrameURL:[[NSString stringWithFormat:@"file://%@.html", [NSTemporaryDirectory() stringByAppendingPathComponent:urlStr]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            }
            /*
             else
            {
                // 2) the url is file-system based (folder or file)
                //
                if (currentView != [fileViewController view] || currentView != [iconViewController view])
                {
                    // detect if the url is a directory
                    NSNumber *isDirectory = nil;
                    
                    NSURL *url = [NSURL fileURLWithPath:[node urlString]];
                    [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
                    if ([isDirectory boolValue])
                    {
                        // avoid a flicker effect by not removing the icon view if it is already embedded
                        if (!(currentView == [iconViewController view]))
                        {
                            // remove the old subview
                            [self removeSubview];
                            currentView = nil;
                        }
                        
                        // change to icon view to display folder contents
                        [placeHolderView addSubview:[iconViewController view]];
                        currentView = [iconViewController view];
                        
                        // its a directory - show its contents using NSCollectionView
                        iconViewController.url = targetURL;
                        
                        // add a spinning progress gear in case populating the icon view takes too long
                        [progIndicator setHidden:NO];
                        [progIndicator startAnimation:self];
                        
                        // note: we will be notifed back to stop our progress indicator
                        // as soon as iconViewController is done fetching its content.
                    }
                    else
                    {
                // 3) its a file, just show the item info
                        //
                        // remove the old subview
                        [self removeSubview];
                        currentView = nil;
                        
                        // change to file view
                        [placeHolderView addSubview:[fileViewController view]];
                        currentView = [fileViewController view];
                        
                        // update the file's info
                        fileViewController.url = targetURL;
                    }
                }
            }
             */
            
            NSRect newBounds;
            newBounds.origin.x = 0;
            newBounds.origin.y = 0;
            newBounds.size.width = [[currentView superview] frame].size.width;
            newBounds.size.height = [[currentView superview] frame].size.height;
            [currentView setFrame:[[currentView superview] frame]];
            
            // make sure our added subview is placed and resizes correctly
            [currentView setFrameOrigin:NSMakePoint(0,0)];
            [currentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        }
        else
        {
            // there's no url associated with this node
            // so a container was selected - no view to display
            [self removeSubview];
            currentView = nil;
        }
    }
}

- (void)populateOutlineContents:(id)inObject
{
	buildingOutlineView = YES;		// indicate to ourselves we are building the default tree at startup
	[myOutlineView setHidden:YES];	// hide the outline view - don't show it as we are building the contents
	
    NSString *notesPath = [NSString stringWithFormat:@"%@/", [root stringByAppendingPathComponent:@"notes"]];
    NSDictionary *notes = [[NSDictionary alloc] initWithObjectsAndKeys:[fm displayNameAtPath:notesPath], @"group", [self recurise:notesPath], @"entries", notesPath, KEY_URL, nil];
    NSArray *entries = [[NSArray alloc] initWithObjects:notes, nil];
    [self addEntries:(NSDictionary *)entries atIndexPath:(NSIndexPath*)@""];
	
	buildingOutlineView = NO;		// we're done building our default tree
	// remove the current selection
	NSArray *selection = [treeController selectionIndexPaths];
	[treeController removeSelectionIndexPaths:selection];
	
	[myOutlineView setHidden:NO];	// we are done populating the outline view content, show it again
	
}


#pragma mark - Node checks

// -------------------------------------------------------------------------------
//	isSeparator:node
// -------------------------------------------------------------------------------
- (BOOL)isSeparator:(BaseNode *)node
{
    return ([node nodeIcon] == nil && [[node nodeTitle] length] == 0);
}

// -------------------------------------------------------------------------------
//	isSpecialGroup:groupNode
// -------------------------------------------------------------------------------
- (BOOL)isSpecialGroup:(BaseNode *)groupNode
{ 
	return ([groupNode nodeIcon] == nil &&
			([[groupNode nodeTitle] isEqualToString:DEVICES_NAME] || [[groupNode nodeTitle] isEqualToString:PLACES_NAME]));
}


#pragma mark - NSOutlineView delegate

// -------------------------------------------------------------------------------
//	shouldSelectItem:item
// -------------------------------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item;
{
	// don't allow special group nodes (Devices and Places) to be selected
	BaseNode *node = [item representedObject];
	return (![self isSpecialGroup:node] && ![self isSeparator:node]);
}

// -------------------------------------------------------------------------------
//	dataCellForTableColumn:tableColumn:item
// -------------------------------------------------------------------------------
- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	NSCell *returnCell = [tableColumn dataCell];
	
	if ([[tableColumn identifier] isEqualToString:COLUMNID_NAME])
	{
		// we are being asked for the cell for the single and only column
		BaseNode *node = [item representedObject];
		if ([self isSeparator:node])
            returnCell = separatorCell;
	}
	
	return returnCell;
}


// -------------------------------------------------------------------------------
//	removeSubview
// -------------------------------------------------------------------------------
- (void)removeSubview
{
	// empty selection
	NSArray *subViews = [placeHolderView subviews];
	if ([subViews count] > 0)
	{
		[[subViews objectAtIndex:0] removeFromSuperview];
	}
	
	[placeHolderView displayIfNeeded];	// we want the removed views to disappear right away
}


// -------------------------------------------------------------------------------
//	textShouldEndEditing:fieldEditor
// -------------------------------------------------------------------------------
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	if ([[fieldEditor string] length] == 0)
	{
		// don't allow empty node names
		return NO;
	}
	else
	{
		return YES;
	}
}

// -------------------------------------------------------------------------------
//	shouldEditTableColumn:tableColumn:item
//
//	Decide to allow the edit of the given outline view "item".
// -------------------------------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	BOOL result = YES;
	item = [item representedObject];
	if ([self isSpecialGroup:item]) {
		result = NO; // don't allow special group nodes to be renamed
	} else {
		if ([[item urlString] isAbsolutePath])
			result = NO;	// allow rename a note
	}
	return result;
}

// -------------------------------------------------------------------------------
//	outlineView:willDisplayCell:forTableColumn:item
// -------------------------------------------------------------------------------
- (void)outlineView:(NSOutlineView *)olv willDisplayCell:(NSCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([[tableColumn identifier] isEqualToString:COLUMNID_NAME])
	{
		// we are displaying the single and only column
		if ([cell isKindOfClass:[ImageAndTextCell class]])
		{
			item = [item representedObject];
			if (item)
			{
				if ([item isLeaf])
				{
					// does it have a URL string?
					NSString *urlStr = [item urlString];
					if (urlStr)
					{
						if ([item isLeaf])
						{
							NSImage *iconImage;
							if ([[item urlString] hasPrefix:HTTP_PREFIX])
								iconImage = urlImage;
							else
								iconImage = [[NSWorkspace sharedWorkspace] iconForFile:urlStr];
							[item setNodeIcon:iconImage];
						}
						else
						{
							NSImage* iconImage = [[NSWorkspace sharedWorkspace] iconForFile:urlStr];
							[item setNodeIcon:iconImage];
						}
					}
					else
					{
						// it's a separator, don't bother with the icon
					}
				}
				else
				{
					// check if it's a special folder (DEVICES or PLACES), we don't want it to have an icon
					if ([self isSpecialGroup:item])
					{
						[item setNodeIcon:nil];
					}
					else
					{
						// it's a folder, use the folderImage as its icon
						[item setNodeIcon:folderImage];
					}
				}
			}
			
			// set the cell's image
			[(ImageAndTextCell*)cell setImage:[item nodeIcon]];
		}
	}
}

// -------------------------------------------------------------------------------
//	outlineViewSelectionDidChange:notification
// -------------------------------------------------------------------------------
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	if (buildingOutlineView)	// we are currently building the outline view, don't change any view selections
		return;

	// ask the tree controller for the current selection
	NSArray *selection = [treeController selectedObjects];
	if ([selection count] > 1)
	{
		// multiple selection - clear the right side view
		[self removeSubview];
		currentView = nil;
	}
	else
	{
		if ([selection count] == 1)
		{
			// single selection
			[self changeItemView];
		}
		else
		{
			// there is no current selection - no view to display
			[self removeSubview];
			currentView = nil;
		}
	}
}

// ----------------------------------------------------------------------------------------
// outlineView:isGroupItem:item
// ----------------------------------------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	return ([self isSpecialGroup:[item representedObject]] ? YES : NO);
}


#pragma mark - NSOutlineView drag and drop

// ----------------------------------------------------------------------------------------
// draggingSourceOperationMaskForLocal <NSDraggingSource override>
// ----------------------------------------------------------------------------------------
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return NSDragOperationMove;
}

// ----------------------------------------------------------------------------------------
// outlineView:writeItems:toPasteboard
// ----------------------------------------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
	[pboard declareTypes:[NSArray arrayWithObjects:kNodesPBoardType, nil] owner:self];
	
	// keep track of this nodes for drag feedback in "validateDrop"
	self.dragNodesArray = items;
	
	return YES;
}

// -------------------------------------------------------------------------------
//	outlineView:validateDrop:proposedItem:proposedChildrenIndex:
//
//	This method is used by NSOutlineView to determine a valid drop target.
// -------------------------------------------------------------------------------
- (NSDragOperation)outlineView:(NSOutlineView *)ov
						validateDrop:(id <NSDraggingInfo>)info
						proposedItem:(id)item
						proposedChildIndex:(NSInteger)index
{
	NSDragOperation result = NSDragOperationNone;
	
	if (!item)
	{
		// no item to drop on
		result = NSDragOperationGeneric;
	}
	else
	{
		if ([self isSpecialGroup:[item representedObject]])
		{
			// don't allow dragging into special grouped sections (i.e. Devices and Places)
			result = NSDragOperationNone;
		}
		else
		{	
			if (index == -1)
			{
				// don't allow dropping on a child
				result = NSDragOperationNone;
			}
			else
			{
				// drop location is a container
				result = NSDragOperationMove;
			}
		}
	}
	
	return result;
}

// -------------------------------------------------------------------------------
//	handleWebURLDrops:pboard:withIndexPath:
//
//	The user is dragging URLs from Safari.
// -------------------------------------------------------------------------------
- (void)handleWebURLDrops:(NSPasteboard *)pboard withIndexPath:(NSIndexPath *)indexPath
{
	NSArray *pbArray = [pboard propertyListForType:@"WebURLsWithTitlesPboardType"];
	NSArray *urlArray = [pbArray objectAtIndex:0];
	NSArray *nameArray = [pbArray objectAtIndex:1];
	
	NSInteger i;
	for (i = ([urlArray count] - 1); i >=0; i--)
	{
		ChildNode *node = [[ChildNode alloc] init];
		
        node.isLeaf = YES;

        node.nodeTitle = [nameArray objectAtIndex:i];
        
        node.urlString = [urlArray objectAtIndex:i];
		[treeController insertObject:node atArrangedObjectIndexPath:indexPath];
	}
}

// -------------------------------------------------------------------------------
//	handleInternalDrops:pboard:withIndexPath:
//
//	The user is doing an intra-app drag within the outline view.
// -------------------------------------------------------------------------------
- (void)handleInternalDrops:(NSPasteboard *)pboard withIndexPath:(NSIndexPath *)indexPath
{
	// user is doing an intra app drag within the outline view:
	//
	NSArray* newNodes = self.dragNodesArray;

	// move the items to their new place (we do this backwards, otherwise they will end up in reverse order)
	NSInteger idx;
	for (idx = ([newNodes count] - 1); idx >= 0; idx--)
	{
		[treeController moveNode:[newNodes objectAtIndex:idx] toIndexPath:indexPath];
	}
	
	// keep the moved nodes selected
	NSMutableArray *indexPathList = [NSMutableArray array];
    for (NSUInteger i = 0; i < [newNodes count]; i++)
	{
		[indexPathList addObject:[[newNodes objectAtIndex:i] indexPath]];
	}
	[treeController setSelectionIndexPaths: indexPathList];
}

// -------------------------------------------------------------------------------
//	handleFileBasedDrops:pboard:withIndexPath:
//
//	The user is dragging file-system based objects (probably from Finder)
// -------------------------------------------------------------------------------
- (void)handleFileBasedDrops:(NSPasteboard *)pboard withIndexPath:(NSIndexPath *)indexPath
{
	NSArray *fileNames = [pboard propertyListForType:NSFilenamesPboardType];
	if ([fileNames count] > 0)
	{
		NSInteger i;
		NSInteger count = [fileNames count];
		
		for (i = (count - 1); i >=0; i--)
		{
			ChildNode *node = [[ChildNode alloc] init];

			NSURL *url = [NSURL fileURLWithPath:[fileNames objectAtIndex:i]];
            NSString *name = [fm displayNameAtPath:[url path]];
            node.isLeaf = YES;

            node.nodeTitle = name;
            node.urlString = [url path];
			[treeController insertObject:node atArrangedObjectIndexPath:indexPath];
		}
	}
}

// -------------------------------------------------------------------------------
//	handleURLBasedDrops:pboard:withIndexPath:
//
//	Handle dropping a raw URL.
// -------------------------------------------------------------------------------
- (void)handleURLBasedDrops:(NSPasteboard *)pboard withIndexPath:(NSIndexPath *)indexPath
{
	NSURL *url = [NSURL URLFromPasteboard:pboard];
	if (url)
	{
		ChildNode *node = [[ChildNode alloc] init];

		if ([url isFileURL])
		{
			// url is file-based, use it's display name
			NSString *name = [fm displayNameAtPath:[url path]];
            node.nodeTitle = name;
            node.urlString = [url path];
		}
		else
		{
			// url is non-file based (probably from Safari)
			//
			// the url might not end with a valid component name, use the best possible title from the URL
			if ([[[url path] pathComponents] count] == 1)
			{
				if ([[url absoluteString] hasPrefix:HTTP_PREFIX])
				{
					// use the url portion without the prefix
					NSRange prefixRange = [[url absoluteString] rangeOfString:HTTP_PREFIX];
					NSRange newRange = NSMakeRange(prefixRange.length, [[url absoluteString] length]- prefixRange.length - 1);
                    node.nodeTitle = [[url absoluteString] substringWithRange:newRange];
				}
				else
				{
					// prefix unknown, just use the url as its title
                    node.nodeTitle = [url absoluteString];
				}
			}
			else
			{
				// use the last portion of the URL as its title
                node.nodeTitle = [[url path] lastPathComponent];
			}
				
            node.urlString = [url absoluteString];
		}
        node.isLeaf = YES;
		
		[treeController insertObject:node atArrangedObjectIndexPath:indexPath];
	}
}

// -------------------------------------------------------------------------------
//	outlineView:acceptDrop:item:childIndex
//
//	This method is called when the mouse is released over an outline view that previously decided to allow a drop
//	via the validateDrop method. The data source should incorporate the data from the dragging pasteboard at this time.
//	'index' is the location to insert the data as a child of 'item', and are the values previously set in the validateDrop: method.
//
// -------------------------------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView*)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)targetItem childIndex:(NSInteger)index
{
	// note that "targetItem" is a NSTreeNode proxy
	//
	BOOL result = NO;
	
	// find the index path to insert our dropped object(s)
	NSIndexPath *indexPath;
	if (targetItem)
	{
		// drop down inside the tree node:
		// feth the index path to insert our dropped node
		indexPath = [[targetItem indexPath] indexPathByAddingIndex:index];
	}
	else
	{
		// drop at the top root level
		if (index == -1)	// drop area might be ambibuous (not at a particular location)
			indexPath = [NSIndexPath indexPathWithIndex:[contents count]]; // drop at the end of the top level
		else
			indexPath = [NSIndexPath indexPathWithIndex:index]; // drop at a particular place at the top level
	}

	NSPasteboard *pboard = [info draggingPasteboard];	// get the pasteboard
	
	// check the dragging type -
	if ([pboard availableTypeFromArray:[NSArray arrayWithObject:kNodesPBoardType]])
	{
		// user is doing an intra-app drag within the outline view
		[self handleInternalDrops:pboard withIndexPath:indexPath];
		result = YES;
	}
	else if ([pboard availableTypeFromArray:[NSArray arrayWithObject:@"WebURLsWithTitlesPboardType"]])
	{
		// the user is dragging URLs from Safari
		[self handleWebURLDrops:pboard withIndexPath:indexPath];		
		result = YES;
	}
	else if ([pboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]])
	{
		// the user is dragging file-system based objects (probably from Finder)
		[self handleFileBasedDrops:pboard withIndexPath:indexPath];
		result = YES;
	}
	else if ([pboard availableTypeFromArray:[NSArray arrayWithObject:NSURLPboardType]])
	{
		// handle dropping a raw URL
		[self handleURLBasedDrops:pboard withIndexPath:indexPath];
		result = YES;
	}
	
	return result;
}

@end
