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

#define COLUMNID_NAME			@"NameColumn"	// the single column name in our outline view
#define INITIAL_INFODICT		@"Outline"		// name of the dictionary file to populate our outline view

#define ICONVIEW_NIB_NAME		@"IconView"		// nib name for the icon view
#define FILEVIEW_NIB_NAME		@"FileView"		// nib name for the file view
#define CHILDEDIT_NAME			@"ChildEdit"	// nib name for the child edit window controller

#define HTTP_PREFIX				@"/"

// default folder titles
#define DEVICES_NAME			@"DEVICES"
#define PLACES_NAME				@"PLACES"


#define kNodesPBoardType		@"myNodesPBoardType"	// drag and drop pasteboard type

@implementation MBWindowController

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        self.fm = [NSFileManager defaultManager];
        self.core = [[MBCore alloc] init];

        if ( ! [[NSUserDefaults standardUserDefaults] objectForKey:@"editor"]) {
            [[NSUserDefaults standardUserDefaults] setObject:@"TextEdit" forKey:@"editor"];
        }
        
		// cache the reused icon images
		self.folderImage = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
		[self.folderImage setSize:NSMakeSize(18,18)];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


- (void) awakeFromNib {
    /*
    [NSThread detachNewThreadSelector:	@selector(populateOutlineContents:)
                                        toTarget:self		// we are the target
                                        withObject:nil];
                                        */
    [self.noteArray addObserver:self forKeyPath:@"selectionIndexes" options:NSKeyValueObservingOptionNew context:nil];
    [self populateOutlineContents:nil];
	NSTableColumn *tableColumn = [self.myOutlineView tableColumnWithIdentifier:COLUMNID_NAME];
	ImageAndTextCell *imageAndTextCell = [[ImageAndTextCell alloc] init];
	[imageAndTextCell setEditable:YES];
	[tableColumn setDataCell:imageAndTextCell];
    [self.myCollectionView setBackgroundColors:[NSArray arrayWithObjects:[NSColor colorWithPatternImage:[NSImage imageNamed:@"Reeder-Noise.png"]], nil]];

    //[self.tableView setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"bg-body.png"]]];
    
    [self.addButton setImage:[NSImage imageNamed:NSImageNameAddTemplate]];
    [self.delButton setImage:[NSImage imageNamed:NSImageNameRemoveTemplate]];
    
	[self.myOutlineView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSnapAndWebView:) name:@"fileContentChangedNotification" object:nil];
    [self.webView setPolicyDelegate:self];
}

- (void)webView:(WebView *)webView 
    decidePolicyForNavigationAction:(NSDictionary *)actionInformation
    request:(NSURLRequest *)request frame:(WebFrame *)frame 
    decisionListener:(id < WebPolicyDecisionListener >)listener
{
    NSString *host = [[request URL] host];
    if (host) {
        [[NSWorkspace sharedWorkspace] openURL:[request URL]];
    } else {
        [listener use];
    }
}

- (void)updateSnapAndWebView:(NSNotification *)aNotification {
	NSString *urlStr = [[aNotification userInfo] objectForKey:@"urlStr"];
    NSString *img_path = [[self.core getDestPath:urlStr] stringByAppendingPathExtension:@"png"];
    //[[[self.noteArray selectedObjects] objectAtIndex:0] setAbstract:[[NSImage alloc] initWithContentsOfFile:img_path]];
    NSLog(@"%@", [[self.noteArray selectedObjects] objectAtIndex:0]);
    [self.webView reload:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"selectionIndexes"]) {
        if ([[self.noteArray selectedObjects] count] > 0) {
            if ([[self.noteArray selectedObjects] count] == 1) {
                NoteSnap *note = (NoteSnap *)[[self.noteArray selectedObjects] objectAtIndex:0];
                NSLog(@"change selection: %@", note.title);
                NSString *urlStr = note.urlStr;

                if ([[NSArray arrayWithObjects:@"rst", @"md", @"markdown", nil] containsObject:[urlStr pathExtension]]) {
                    
                    // this will tell our WebUIDelegate not to retarget first responder since some web pages force
                    // forus to their text fields - we want to keep our outline view in focus.

                    NSString *dest_path = [self getHtmlPath:urlStr];
                    //NSLog(@"%@", dest_path);
                    
                    if ( ! [self.fm fileExistsAtPath:dest_path isDirectory:nil]) {
                        //NSLog(@"url file is not existed. generating");
                        //[self performSelectorOnMainThread:@selector(rst2html:) withObject:urlStr waitUntilDone:YES];
                        [self.core updateHtml:urlStr];
                    }
                    if ([[urlStr pathExtension] isEqualToString:@"rst"]) {
                        [self.webView setMainFrameURL:[[NSString stringWithFormat:@"file://%@", dest_path] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                    } else {
                        [self.webView setMainFrameURL:[[NSString stringWithFormat:@"file://%@", dest_path] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                    }
                    [self.webView layout];
                }
            }
        }
    }
}

- (IBAction)addFileAction:(id)sender {
    NSString *parentDir;
    if ([[self.treeController selectedNodes] count] > 0) {
        NSTreeNode *selectedNode = [[self.treeController selectedNodes] objectAtIndex:0];
        parentDir = [[selectedNode representedObject] urlString];
    } else {
        parentDir = [self.core.root stringByAppendingPathComponent:@"notes"];
    }
    //NSLog(@"%@", [self indexPathOfString:parentDir]);
    
    /*
    [NSApp beginSheet:self.alertWindow
       modalForWindow:self.mainWindow
        modalDelegate:self
       didEndSelector:@selector(addAlertDidEnd:returnCode:contextInfo:)
          contextInfo:(__bridge void *)parentDir];
    //[NSApp runModalForWindow:self.alertWindow];
    
    //NSAlert *alert = [NSAlert alertWithMessageText:@"hello" defaultButton:@"OK" alternateButton:@"Cancle" otherButton:nil informativeTextWithFormat:@"nihao"];
     */

    NSAlert *theAlert = [[NSAlert alloc] init];
    [theAlert addButtonWithTitle:@"创建"];
    [theAlert addButtonWithTitle:@"取消"];
    [theAlert setMessageText:@"请输入笔记名称，选择笔记类型。"];
    
    [theAlert setAccessoryView:self.addNoteView];
    
    [theAlert beginSheetModalForWindow:self.mainWindow modalDelegate:self didEndSelector:@selector(addAlertDidEnd:returnCode:contextInfo:) contextInfo:(__bridge void*)parentDir];
}

- (IBAction)delFileAction:(id)sender {
    if ([[self.noteArray selectedObjects] count] == 0) {
        return;
    }
    NSString *path = [[[self.noteArray selectedObjects] objectAtIndex:0] urlStr];
    NSAlert *theAlert = [[NSAlert alloc] init];
    [theAlert addButtonWithTitle:@"好"];
    [theAlert addButtonWithTitle:@"取消"];
    [theAlert setMessageText:[NSString stringWithFormat:@"确认删除文件 %@ ？", [path lastPathComponent]]];
    [theAlert setAlertStyle:NSWarningAlertStyle];
    [theAlert beginSheetModalForWindow:self.mainWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:(__bridge void*) path];
}

- (IBAction)closeNoteSheet:(id)sender {
    [NSApp endSheet:self.alertWindow];
}

- (void)addAlertDidEnd:(NSAlert *)alertWindow returnCode:(NSInteger)returnCode contextInfo:(void *)parent_path {
    NSString *path = (__bridge NSString*)parent_path;
    if (returnCode == NSAlertFirstButtonReturn) {
        NSLog(@"%@", path);
        NSLog(@"%ld", returnCode);
        //NSString *title = [(NSTextField *)alert.accessoryView stringValue];
        NSString *title = self.note_title_field.stringValue;
        NSString *extension = [self.core.note_types objectAtIndex:self.note_type_matrix.selectedRow];
        NSString *file = [[path stringByAppendingPathComponent:title] stringByAppendingPathExtension:extension];
        if ([self.fm fileExistsAtPath:file]) {
            NSLog(@"Error, file Exists!");
            //[NSApp stopModal];
            
            NSAlert *theAlert = [[NSAlert alloc] init];
            [theAlert addButtonWithTitle:@"好"];
            [theAlert setMessageText:[NSString stringWithFormat:@"已存在笔记： %@", [file lastPathComponent]]];
            //[theAlert beginSheetModalForWindow:self.mainWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
            [theAlert runModal];
            return;
        }
        
        NSInteger n = [title length];
        /*
        for(int i=0; i< [title length];i++){
            int a = [title characterAtIndex:i];
            if( a > 0x4e00 && a < 0x9fff)
                n++;
        }*/
        for ( int i=0; i<[title length];++i) {
            NSRange range = NSMakeRange(i, 1);
            NSString *subString = [title substringWithRange:range];
            const char *cString=[subString UTF8String];
            if (strlen(cString)==1) {
            }else if (strlen(cString)==3) {
                n++;
            }
        }
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        
        NSString *mark = [@"" stringByPaddingToLength:n withString: @"=" startingAtIndex:0];
        NSString *content = [NSString stringWithFormat:@"%@\n%@\n%@\n\n.. Author: your_name\n.. title:: english_title\n.. |date| date:: %@\n\n", mark,title, mark, [dateFormatter stringFromDate:[NSDate date]]];
        NSData *fileContents = [content dataUsingEncoding:NSUTF8StringEncoding];
        [self.fm createFileAtPath:file contents:fileContents attributes:nil];
        NSString *img_path = [[self.core getDestPath:file] stringByAppendingPathExtension:@"png"];
         NoteSnap* note = [[NoteSnap alloc] initWithFile:file snapshot:img_path];
        [self.notes addObject:note];
        [self.noteArray setSelectsInsertedObjects:YES];
        [self.noteArray setContent:self.notes];

    } else if (returnCode == NSAlertSecondButtonReturn) {
    } else {
    }
    //[sheet orderOut:self];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)path {
    if (returnCode == NSAlertFirstButtonReturn) {
        //NSLog(@"Move to trash");
        [[NSWorkspace sharedWorkspace] recycleURLs:[NSArray arrayWithObjects:[NSURL fileURLWithPath:(__bridge NSString *)path], nil] completionHandler:^(NSDictionary *newURLs, NSError *error) {
            if (error != nil) {
            }
            [self.notes removeObject:[[self.noteArray selectedObjects] objectAtIndex:0]];
            [self.noteArray setContent:self.notes];
        }];
    } else if (returnCode == NSAlertSecondButtonReturn) {
        //NSLog(@"Cancle");
    } else {
        //NSLog(@"other");
    }
}

- (void) openNote:(id) sender {
    NoteSnap *note = [(NSArray *)sender objectAtIndex:0];
    NSString *app = [[NSUserDefaults standardUserDefaults] objectForKey:@"editor"];
    NSLog(@"open note:%@", [note urlStr]);
    [[NSWorkspace sharedWorkspace] openFile:[note urlStr] withApplication:app];
}

// -------------------------------------------------------------------------------
//	setContents:newContents
// -------------------------------------------------------------------------------
- (void)setContents:(NSArray *)newContents
{
	if (self.core.contents != newContents)
	{
		self.core.contents = [[NSMutableArray alloc] initWithArray:newContents];
	}
}

// -------------------------------------------------------------------------------
//	contents:
// -------------------------------------------------------------------------------
- (NSMutableArray *)contents {
	return self.core.contents;
}

- (void)populateOutlineContents:(id)inObject {
	[self.myOutlineView setHidden:YES];	// hide the outline view - don't show it as we are building the contents
	
    [self.treeController setContent:self.core.treeController.content];
    
	// remove the current selection
	NSArray *selection = [self.treeController selectionIndexPaths];
	[self.treeController removeSelectionIndexPaths:selection];

	[self.myOutlineView setHidden:NO];
    [self.myOutlineView expandItem:[[[self.treeController arrangedObjects] childNodes] objectAtIndex:0]];
    [self.treeController setSelectionIndexPath:[[NSIndexPath indexPathWithIndex:0] indexPathByAddingIndex:0]];
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
- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	NSCell *returnCell = [tableColumn dataCell];
	
	return returnCell;
}

// -------------------------------------------------------------------------------
//	textShouldEndEditing:fieldEditor
// -------------------------------------------------------------------------------
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	if ([[fieldEditor string] length] == 0) {
		// don't allow empty node names
		return NO;
	} else {
        NSString *oldPath = [[[[self.treeController selectedNodes] objectAtIndex:0] representedObject] urlString];
        NSString *newPath = [[oldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[fieldEditor string]];
        oldPath = [oldPath stringByDeletingPathExtension];
        [self.fm moveItemAtPath:oldPath toPath:newPath error:nil];
        [[[[self.treeController selectedNodes] objectAtIndex:0] representedObject] setUrlString:newPath];
        [self.fm moveItemAtPath:[self getHtmlPath:oldPath] toPath:[self getHtmlPath:newPath] error:nil];
		return YES;
	}
}

- (NSString *)getHtmlPath:(NSString *)path {
    return [[self.core getDestPath:path] stringByAppendingPathExtension:@"html"];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	return YES;
}

// -------------------------------------------------------------------------------
//	outlineView:willDisplayCell:forTableColumn:item
// -------------------------------------------------------------------------------
- (void)outlineView:(NSOutlineView *)olv willDisplayCell:(NSCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	if ([[tableColumn identifier] isEqualToString:COLUMNID_NAME]) {
		// we are displaying the single and only column
		if ([cell isKindOfClass:[ImageAndTextCell class]]) {
			item = [item representedObject];
			if (item) {
				if ([item isLeaf]) {
					// does it have a URL string?
					NSString *urlStr = [item urlString];
					if (urlStr) {
						if ([item isLeaf]) {
                            [item setNodeIcon:self.folderImage];
						} else {
							NSImage* iconImage = [[NSWorkspace sharedWorkspace] iconForFile:urlStr];
							[item setNodeIcon:iconImage];
						}
					} else {
						// it's a separator, don't bother with the icon
					}
				} else {
					// check if it's a special folder (DEVICES or PLACES), we don't want it to have an icon
					if ([self isSpecialGroup:item]) {
						[item setNodeIcon:nil];
					} else {
						// it's a folder, use the folderImage as its icon
						[item setNodeIcon:self.folderImage];
					}
				}
			}
			
			// set the cell's image
			[(ImageAndTextCell*)cell setImage:[item nodeIcon]];
		}
	}
}

#pragma mark - changeItemView

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	if (self.core.buildingOutlineView)
		return;
    
	NSArray *selection = [self.treeController selectedObjects];
	if ([selection count] == 1) {
        NSString *urlStr = [[selection objectAtIndex:0] urlString];
        if (urlStr) {
            self.notes =[[NSMutableArray alloc] initWithArray:[self.core listDirectory:urlStr]];
        }
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
	return ([self isSpecialGroup:[item representedObject]] ? YES : NO);
}

#pragma mark - NSOutlineView drag and drop

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
	return NSDragOperationMove;
}

- (BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
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
		[self.treeController insertObject:node atArrangedObjectIndexPath:indexPath];
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
	for (idx = ([newNodes count] - 1); idx >= 0; idx--) {
		[self.treeController moveNode:[newNodes objectAtIndex:idx] toIndexPath:indexPath];
	}
	
	// keep the moved nodes selected
	NSMutableArray *indexPathList = [NSMutableArray array];
    for (NSUInteger i = 0; i < [newNodes count]; i++) {
		[indexPathList addObject:[[newNodes objectAtIndex:i] indexPath]];
	}
	[self.treeController setSelectionIndexPaths: indexPathList];
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
            NSString *name = [self.fm displayNameAtPath:[url path]];
            node.isLeaf = YES;

            node.nodeTitle = name;
            node.urlString = [url path];
			[self.treeController insertObject:node atArrangedObjectIndexPath:indexPath];
		}
	}
}

// -------------------------------------------------------------------------------
//	handleURLBasedDrops:pboard:withIndexPath:
//
//	Handle dropping a raw URL.
// -------------------------------------------------------------------------------
- (void)handleURLBasedDrops:(NSPasteboard *)pboard withIndexPath:(NSIndexPath *)indexPath {
	NSURL *url = [NSURL URLFromPasteboard:pboard];
	if (url)
	{
		ChildNode *node = [[ChildNode alloc] init];

		if ([url isFileURL])
		{
			// url is file-based, use it's display name
			NSString *name = [self.fm displayNameAtPath:[url path]];
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
		
		[self.treeController insertObject:node atArrangedObjectIndexPath:indexPath];
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
	if (targetItem) {
		// drop down inside the tree node:
		// feth the index path to insert our dropped node
		indexPath = [[targetItem indexPath] indexPathByAddingIndex:index];
	} else {
		// drop at the top root level
		if (index == -1)	// drop area might be ambibuous (not at a particular location)
			indexPath = [NSIndexPath indexPathWithIndex:[self.core.contents count]]; // drop at the end of the top level
		else
			indexPath = [NSIndexPath indexPathWithIndex:index]; // drop at a particular place at the top level
	}

	NSPasteboard *pboard = [info draggingPasteboard];	// get the pasteboard
	
	// check the dragging type -
	if ([pboard availableTypeFromArray:[NSArray arrayWithObject:kNodesPBoardType]]) {
		// user is doing an intra-app drag within the outline view
		[self handleInternalDrops:pboard withIndexPath:indexPath];
		result = YES;
	} else if ([pboard availableTypeFromArray:[NSArray arrayWithObject:@"WebURLsWithTitlesPboardType"]]) {
		// the user is dragging URLs from Safari
		[self handleWebURLDrops:pboard withIndexPath:indexPath];		
		result = YES;
	} else if ([pboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]]) {
		// the user is dragging file-system based objects (probably from Finder)
		[self handleFileBasedDrops:pboard withIndexPath:indexPath];
		result = YES;
	} else if ([pboard availableTypeFromArray:[NSArray arrayWithObject:NSURLPboardType]]) {
		// handle dropping a raw URL
		[self handleURLBasedDrops:pboard withIndexPath:indexPath];
		result = YES;
	}
	
	return result;
}

- (IBAction)doubleClick:(id)sender {
    if ([[self.noteArray selectedObjects] count] == 1) {
        NoteSnap *note = (NoteSnap *)[[self.noteArray selectedObjects] objectAtIndex:0];
        //NSLog(@"double click selection: %@", note.title);
        NSString *app = [[NSUserDefaults standardUserDefaults] objectForKey:@"editor"];
        [[NSWorkspace sharedWorkspace] openFile:note.urlStr withApplication:app];
    }
}

- (void)importNotes:(NSString *)dir {
    NSTreeNode *parentNode;
    if ([self.treeController selectedNodes].count > 0) {
        NSTreeNode *node = [[self.treeController selectedNodes] objectAtIndex:0];
        if([node isLeaf]) {
            parentNode = node.parentNode;
        } else {
            parentNode = node;
        }
    } else {
        parentNode = [[[self.treeController arrangedObjects] childNodes] objectAtIndex:0];
    }
    NSString *dest = [[[parentNode representedObject] urlString] stringByAppendingPathComponent:[dir lastPathComponent]];
    //[self.fm createSymbolicLinkAtPath:dest withDestinationPath:dir error:nil];
    [self.fm copyItemAtPath:dir toPath:dest error:nil];
    [self addChild:dest withName:[dir lastPathComponent] selectParent:YES];
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

- (void)addChild:(NSString *)url withName:(NSString *)nameStr selectParent:(BOOL)select {
	TreeAdditionObj *treeObjInfo = [[TreeAdditionObj alloc] initWithURL:url withName:nameStr selectItsParent:select];	
    [self performAddChild:treeObjInfo];
}

@end

@implementation SnapBox

- (NSView *)hitTest:(NSPoint)aPoint
{
    // don't allow any mouse clicks for subviews in this NSBox
    if(NSPointInRect(aPoint,[self convertRect:[self bounds] toView:[self superview]])) {
		return self;
	} else {
		return nil;
	}
}

-(void)mouseDown:(NSEvent *)theEvent {
	[super mouseDown:theEvent];
    
	// check for click count above one, which we assume means it's a double click
	if([theEvent clickCount] > 1) {
		if(self.delegate && [self.delegate respondsToSelector:@selector(doubleClick:)]) {
        [self.delegate performSelector:@selector(doubleClick:) withObject:self];
		}
	}
}

@end
