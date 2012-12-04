//
//  MBCore.m
//  MarkBook
//
//  Created by amoblin on 12-12-1.
//  Copyright (c) 2012年 amoblin. All rights reserved.
//

#import "MBCore.h"
#import "ChildNode.h"

#define EGGS_ROOT               @"/Applications/MarkBook.app/Contents/Resources/myeggs"

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

@implementation MBCore

- (id)init {
    self.root = [NSHomeDirectory() stringByAppendingPathComponent:@".MarkBook"];
    NSString *notes_path = [self.root stringByAppendingPathComponent:@"notes/"];
    self.contents = [[NSMutableArray alloc] init];
    self.pathInfos = [[NSMutableDictionary alloc] initWithCapacity:300];
    self.fm = [NSFileManager defaultManager];
    self.treeController = [[NSTreeController alloc] init];

    self.treeController.childrenKeyPath = @"children";
    self.treeController.leafKeyPath = @"isLeaf";
    
    [self buildTree];
    
    if ( ![self.fm fileExistsAtPath:notes_path]) {
        NSLog(@"NO MarkBook HOME found, create: %@", notes_path);
        [self.fm createDirectoryAtPath:notes_path withIntermediateDirectories:YES attributes:NULL error:nil];
        [self.fm copyItemAtPath:[EGGS_ROOT stringByAppendingPathComponent:@"welcome.rst"] toPath:[notes_path stringByAppendingPathComponent:@"welcome.rst"] error:nil];
        [self.fm copyItemAtPath:[EGGS_ROOT stringByAppendingPathComponent:@"markdown.md"] toPath:[notes_path stringByAppendingPathComponent:@"markdown.md"] error:nil];
    } else {
        NSLog(@"found MarkBook HOME: %@", notes_path);
    }

    [self initializeEventStream];
    return self;
}

- (void) initializeEventStream {
    NSString *notesPath = [self.root stringByAppendingPathComponent:@"notes"];
    NSArray *pathsToWatch = [NSArray arrayWithObject:notesPath];
    FSEventStreamContext context = {0, (__bridge void *)self, NULL, NULL, NULL};
    NSTimeInterval latency = 0.1;
    self.stream = FSEventStreamCreate(NULL, &fsevents_callback, &context, (__bridge CFArrayRef) pathsToWatch, [self.lastEventId unsignedLongValue], (CFAbsoluteTime) latency, kFSEventStreamCreateFlagUseCFTypes);
    
    FSEventStreamScheduleWithRunLoop(self.stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(self.stream);
}

void fsevents_callback(ConstFSEventStreamRef streamRef, void *userData, size_t numEvents,
       void *eventPaths, const FSEventStreamEventFlags eventFlags[],
       const FSEventStreamEventId eventIds[]) {
    
    MBCore *c = (__bridge MBCore *)userData;
    size_t i;
    for (i=0; i<numEvents; i++) {
        [c addModifiedFilesAtPath:[(__bridge NSArray *)eventPaths objectAtIndex:i]];
        c.lastEventId = [NSNumber numberWithLong:eventIds[i]];
    }
}

- (void) addModifiedFilesAtPath: (NSString *)path {
    NSArray *nodes = [self.fm contentsOfDirectoryAtPath:path error:nil];
    BOOL isDir;
    
    NSLog(@"%@", path);
    
    if ( ![self.fm fileExistsAtPath:path isDirectory:&isDir]) {
        NSLog(@"ERROR: path NOT exist: %@", path);
        return;
    }
    
    if ([self.pathInfos objectForKey:path]) {
    } else {
        [self.fm createDirectoryAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:path] withIntermediateDirectories:YES attributes:NULL error:nil];
        [self.pathInfos setObject:nodes forKey:path];
        NSLog(@"add observer: %@", path);
        return;
    }
    
    NSString *prePath;
    if ([[self.treeController selectedNodes] count] > 0) {
         prePath = [[[[self.treeController selectedNodes] objectAtIndex:0] representedObject] urlString];
    }
    
    NSIndexPath *indexPath = [self indexPathOfString:path];
    if ( ! indexPath) {
        NSLog(@"new dir: %@", path);
        return;
    }
    //NSLog(@"index path: %@", indexPath);
    NSArray *newNodes = [self.fm contentsOfDirectoryAtPath:path error:nil];
    NSArray *oldNodes = [self.pathInfos objectForKey:path];
    for (NSString *node in newNodes) {
        //NSLog(@"new node: %@", node);
        if (! [[NSArray arrayWithObjects:@"rst", @"md", @"markdown", nil] containsObject:[node pathExtension]] ) {
            continue;
        }
        if ( [oldNodes containsObject:node]) {
            NSString *fullPath = [path stringByAppendingPathComponent:node];
            NSDictionary *attributes = [self.fm attributesOfItemAtPath:fullPath error:NULL];
            NSDate *modDate = [attributes objectForKey:NSFileModificationDate];
            
            if ([self.pathInfos objectForKey:path]) {
                if ([modDate compare:[self.pathInfos objectForKey:fullPath]] == NSOrderedDescending) {
                    NSLog(@"file changed: %@", node);
                    if ([[node pathExtension] isEqualToString:@"rst"]) {
                        [self rst2html:fullPath];
                    } else if ([[node pathExtension] isEqualToString:@"md"] || [[node pathExtension] isEqualToString:@"markdown"]) {
                        [self md2html:fullPath];
                    }
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:@"fileContentChangedNotification" object:self
                     userInfo:[NSDictionary dictionaryWithObject:fullPath forKey:@"urlStr"]];
                }
            }
            [self.pathInfos setObject:modDate forKey:fullPath];
        } else {
            NSString *fullPath = [path stringByAppendingPathComponent:node];
            [self addChild:fullPath withName:[node stringByDeletingPathExtension] selectParent:YES];
            NSLog(@"append child: %@", node);
        }
    }
    
    for (NSString *node in oldNodes) {
        if ( ! [[NSArray arrayWithObjects:@"rst", @"md", @"markdown", nil] containsObject:[node pathExtension]] ) {
            continue;
        }
        if ( ![newNodes containsObject:node]) {
            NSLog(@"remove: %@", node);
            NSString *fullPath = [path stringByAppendingPathComponent:node];
            //should remove in tree
            NSIndexPath *nodeIndex = [self indexPathOfString:fullPath];
            if (nodeIndex) {
                [self.treeController removeObjectAtArrangedObjectIndexPath:nodeIndex];
            }
        }
    }
    [self.pathInfos setObject:newNodes forKey:path];
    if (prePath) {
        //NSLog(@"reselect previous one");
        [self.treeController setSelectionIndexPath:[self indexPathOfString:prePath]];
    }
}

- (NSIndexPath*)indexPathOfString:(NSString *)path {
    //NSLog(@"search for path: %@", path);
    return [self indexPathOfString:path inNodes:[[self.treeController arrangedObjects] childNodes]];
}

- (NSIndexPath*)indexPathOfString:(NSString *)path inNodes:(NSArray*)nodes {
    for(NSTreeNode* node in nodes) {
        //NSLog(@"compare with %@", [[node representedObject] urlString]);
        if([[[node representedObject] urlString] isEqualToString:path]) {
            return [node indexPath];
        }
        if([[node childNodes] count]) {
            NSIndexPath* indexPath = [self indexPathOfString:path inNodes:[node childNodes]];
            if(indexPath)
                return indexPath;
        }
    }
    return nil;
}

- (void) buildTree {
	self.buildingOutlineView = YES;		// indicate to ourselves we are building the default tree at startup
    NSString *notesPath = [self.root stringByAppendingPathComponent:@"notes"];
    NSDictionary *notes = [[NSDictionary alloc] initWithObjectsAndKeys:[self.fm displayNameAtPath:notesPath], @"group", [self recurise:notesPath], @"entries", [NSString stringWithFormat:@"%@/", notesPath], KEY_URL, nil];
    NSArray *entries = [[NSArray alloc] initWithObjects:notes, nil];
    [self addEntries:(NSDictionary *)entries atIndexPath:(NSIndexPath*)@""];
	self.buildingOutlineView = NO;		// we're done building our default tree
}

- (NSArray *)recurise:(NSString *)path {
    path = [NSString stringWithFormat:@"%@/", path];
    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:100];
    
    NSArray *nodes = [self.fm contentsOfDirectoryAtPath:path error:nil];
    [self.fm createDirectoryAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:path] withIntermediateDirectories:YES attributes:NULL error:nil];
    [self.pathInfos setObject:nodes forKey:path];
    //NSLog(@"add observer: %@", path);
    
    BOOL isDir = NO;
    for (NSString *file in nodes) {
        if ([file isEqualToString:@".git"]) {
            continue;
        }
        NSString *fullPath = [path stringByAppendingPathComponent:file];
        [self.fm fileExistsAtPath:fullPath isDirectory:(&isDir)];
        if (isDir) {
            NSArray *entries = [self recurise:fullPath];
            fullPath = [NSString stringWithFormat:@"%@/", fullPath];
            [arr addObject:[[NSDictionary alloc] initWithObjectsAndKeys:file, @"name", entries, @"entries", fullPath, @"url", nil]];
        } else {
            if ([[NSArray arrayWithObjects:@"rst", @"md", @"markdown", nil] containsObject:[file pathExtension]] ) {
                NSDictionary *attributes = [self.fm attributesOfItemAtPath:fullPath error:NULL];
                NSDate *modDate = [attributes objectForKey:NSFileModificationDate];
                [self.pathInfos setObject:modDate forKey:fullPath];
            }
        }
    }
    return arr;
}

- (void)addEntries:(NSDictionary *)entries atIndexPath:(NSIndexPath *)indexPath {
	NSEnumerator *entryEnum = [entries objectEnumerator];
	
	id entry;
	while ((entry = [entryEnum nextObject])) {
		if ([entry isKindOfClass:[NSDictionary class]]) {
			NSString *urlStr = [entry objectForKey:KEY_URL];
			
			if ([entry objectForKey:KEY_SEPARATOR]) {
				// its a separator mark, we treat is as a leaf
				[self addChild:nil withName:nil selectParent:YES];
			} else if ([entry objectForKey:KEY_FOLDER]) {
				// its a file system based folder,
				// we treat is as a leaf and show its contents in the NSCollectionView
				NSString *folderName = [entry objectForKey:KEY_FOLDER];
				[self addChild:urlStr withName:folderName selectParent:YES];
			} else if ([entry objectForKey:KEY_GROUP]) {
				// it's a generic container
				NSString *folderName = [entry objectForKey:KEY_GROUP];
                [self addFolder:folderName withURL:urlStr atIndexPath:indexPath];
				
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
    //NSTreeNode *lastSelectedNode = [[self.treeController selectedNodes] objectAtIndex:0];
    //[myOutlineView collapseItem:lastSelectedNode];
}

- (void)addChild:(NSString *)url withName:(NSString *)nameStr selectParent:(BOOL)select {
	TreeAdditionObj *treeObjInfo = [[TreeAdditionObj alloc] initWithURL:url withName:nameStr selectItsParent:select];
	
	if (self.buildingOutlineView) {
		// add the child node to the tree controller, but on the main thread to avoid lock ups
		[self performSelectorOnMainThread:@selector(performAddChild:) withObject:treeObjInfo waitUntilDone:YES];
	} else {
		[self performAddChild:treeObjInfo];
	}
}

// -------------------------------------------------------------------------------
//	addFolder:folderName
// -------------------------------------------------------------------------------
- (void)addFolder:(NSString *)folderName withURL:(NSString *)url atIndexPath:(NSIndexPath *)indexPath
{
	TreeAdditionObj *treeObjInfo = [[TreeAdditionObj alloc] initWithURL:url withName:folderName selectItsParent:NO];
	if (self.buildingOutlineView) {
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
        [self.treeController insertObject:node atArrangedObjectIndexPath:myIndexPath];
        NSLog(@"my index Path:%@", myIndexPath);
        NSLog(@"insert object: %@", node.urlString);
        // in insertObject action, rst2html will be called!
        return;
    }
	// NSTreeController inserts objects using NSIndexPath, so we need to calculate this
	NSIndexPath *indexPath = nil;
	
	// if there is no selection, we will add a new group to the end of the contents array
	if ([[self.treeController selectedObjects] count] == 0) {
		// there's no selection so add the folder to the top-level and at the end
		indexPath = [NSIndexPath indexPathWithIndex:[self.contents count]];
	} else {
		// get the index of the currently selected node, then add the number its children to the path -
		// this will give us an index which will allow us to add a node to the end of the currently selected node's children array.
		//
		indexPath = [self.treeController selectionIndexPath];
		if ([[[self.treeController selectedObjects] objectAtIndex:0] isLeaf]) {
			// user is trying to add a folder on a selected child,
			// so deselect child and select its parent for addition
			[self selectParentFromSelection];
		} else {
			indexPath = [indexPath indexPathByAddingIndex:[[[[self.treeController selectedObjects] objectAtIndex:0] children] count]];
		}
	}
	
	ChildNode *node = [[ChildNode alloc] init];
    node.nodeTitle = [treeAddition nodeName];
    node.urlString = [treeAddition nodeURL];
	
	// the user is adding a child node, tell the controller directly
	[self.treeController insertObject:node atArrangedObjectIndexPath:indexPath];
    //NSLog(@"index Path:%@", indexPath);
    //NSLog(@"insert Object: %@", node.urlString);
}



// -------------------------------------------------------------------------------
//	performAddChild:treeAddition
// -------------------------------------------------------------------------------
- (void)performAddChild:(TreeAdditionObj *)treeAddition
{
	if ([[self.treeController selectedObjects] count] > 0) {
		// we have a selection
		if ([[[self.treeController selectedObjects] objectAtIndex:0] isLeaf]) {
			// trying to add a child to a selected leaf node, so select its parent for add
			[self selectParentFromSelection];
		}
	}
	
	// find the selection to insert our node
	NSIndexPath *indexPath;
	if ([[self.treeController selectedObjects] count] > 0) {
		// we have a selection, insert at the end of the selection
		indexPath = [self.treeController selectionIndexPath];
		indexPath = [indexPath indexPathByAddingIndex:[[[[self.treeController selectedObjects] objectAtIndex:0] children] count]];
	} else {
		// no selection, just add the child to the end of the tree
		indexPath = [NSIndexPath indexPathWithIndex:[self.contents count]];
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
                node.nodeTitle = [self.fm displayNameAtPath:[node urlString]];
		} else {
			// the child to insert will be an empty URL
            node.nodeTitle = @"Untitled";
            node.urlString = @"http://";
		}
	}
	
	// the user is adding a child node, tell the controller directly
	[self.treeController insertObject:node atArrangedObjectIndexPath:indexPath];
    //NSLog(@"insert Object At Index Path: %@", indexPath);

	// adding a child automatically becomes selected by NSOutlineView, so keep its parent selected
	if ([treeAddition selectItsParent])
		[self selectParentFromSelection];
}

// -------------------------------------------------------------------------------
//	selectParentFromSelection
//
//	Take the currently selected node and select its parent.
// -------------------------------------------------------------------------------
- (void)selectParentFromSelection
{
	if ([[self.treeController selectedNodes] count] > 0) {
		NSTreeNode* firstSelectedNode = [[self.treeController selectedNodes] objectAtIndex:0];
		NSTreeNode* parentNode = [firstSelectedNode parentNode];
		if (parentNode) {
			// select the parent
			NSIndexPath* parentIndex = [parentNode indexPath];
			[self.treeController setSelectionIndexPath:parentIndex];
		} else {
			// no parent exists (we are at the top of tree), so make no selection in our outline
			NSArray* selectionIndexPaths = [self.treeController selectionIndexPaths];
			[self.treeController removeSelectionIndexPaths:selectionIndexPaths];
		}
	}
}


- (void) rst2html:(NSString *)path{
    BOOL isDir;
    [self.fm fileExistsAtPath:path isDirectory:&isDir];
    if (isDir) {
        return;
    }

    NSString *dest = [NSString stringWithFormat:@"%@.html", [[self.root stringByAppendingPathComponent:@"build"] stringByAppendingPathComponent:path]];
    NSString *parent_path = [dest stringByDeletingLastPathComponent];
    if ( ! [self.fm fileExistsAtPath:parent_path isDirectory:nil]) {
        [self.fm createDirectoryAtPath:parent_path withIntermediateDirectories:YES attributes:NULL error:nil];
    }
    
    NSTask *task = [[NSTask alloc] init];
    NSString *rst2html_command = [EGGS_ROOT stringByAppendingPathComponent:@"bin/rst2html.py"];
    NSArray *args = [NSArray arrayWithObjects:rst2html_command, @"--stylesheet-path=/Applications/MarkBook.app/Contents/Resources/myeggs/default.css", path, dest, nil];
    [task setEnvironment:[NSDictionary dictionaryWithObjectsAndKeys:@"zh_CN.UTF-8", @"LC_CTYPE", nil]];
    [task setLaunchPath:[EGGS_ROOT stringByAppendingPathComponent:@"bin/mypython"]];
    [task setArguments:args];
    [task launch];
    
    [task waitUntilExit];
    int status = [task terminationStatus];
    if (status == 0) {
    } else {
        NSLog(@"Task failed.");
    }
}

- (void) md2html:(NSString *)path {
    BOOL isDir;
    [self.fm fileExistsAtPath:path isDirectory:&isDir];
    if (isDir) {
        return;
    }

    NSString *dest = [NSString stringWithFormat:@"%@.html", [[self.root stringByAppendingPathComponent:@"build"] stringByAppendingPathComponent:path]];
    NSString *parent_path = [dest stringByDeletingLastPathComponent];
    if ( ! [self.fm fileExistsAtPath:parent_path isDirectory:nil]) {
        [self.fm createDirectoryAtPath:parent_path withIntermediateDirectories:YES attributes:NULL error:nil];
    }
    
    NSTask *task = [[NSTask alloc] init];


    NSArray *args = [NSArray arrayWithObjects:path, nil];

    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];

    NSFileHandle *file;
    file = [pipe fileHandleForReading];

    [task setEnvironment:[NSDictionary dictionaryWithObjectsAndKeys:@"zh_CN.UTF-8", @"LC_CTYPE", nil]];
    [task setLaunchPath:[EGGS_ROOT stringByAppendingPathComponent:@"bin/markdown"]];
    [task setArguments:args];
    [task launch];
    
    [task waitUntilExit];
    int status = [task terminationStatus];
    if (status == 0) {
    } else {
        NSLog(@"Task failed.");
    }

    NSString *string = [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    string = [NSString stringWithFormat:@"<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\"> <head> <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"/>  </head><body> %@ </body></html>", string];
    //NSLog(@"%@", dest);
    [string writeToFile:dest atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (NSArray *) listDirectory:(NSString *)path {
    NSArray *nodes = [self.fm contentsOfDirectoryAtPath:path error:nil];
    NSMutableArray *arrays = [[NSMutableArray alloc] initWithCapacity:100];
    for(NSString *node in nodes) {
        NoteSnap* note = [[NoteSnap alloc] initWithDir:path fileName:node];
        [arrays addObject:note];
    }
    return arrays;
}

@end

@implementation NoteSnap

- (id) initWithDir:(NSString *)path fileName:(NSString *)name {
    self.urlStr = [path stringByAppendingPathComponent:name];
    self.title = [name stringByDeletingPathExtension];
    self.abstract = @"Abstract...";
	return self;
}

@end
