//
//  MBCore.h
//  MarkBook
//
//  Created by amoblin on 12-12-1.
//  Copyright (c) 2012年 amoblin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface MBCore : NSObject

@property (strong) NSTreeController *treeController;

@property (strong, nonatomic) NSNumber *lastEventId;
@property (nonatomic) FSEventStreamRef stream;

@property (strong, nonatomic) NSString* root;
@property (strong, nonatomic) NSMutableArray *contents;
@property (strong, nonatomic) NSMutableDictionary* pathInfos;
@property (strong, nonatomic) NSFileManager *fm;
@property (nonatomic) BOOL buildingOutlineView;

- (NSIndexPath*)indexPathOfString:(NSString *)path;
- (void) addModifiedFilesAtPath: (NSString *)path;
- (void) rst:(NSString *)path tohtml:(NSString *)dest;
- (void) updateHtml:(NSString *)path;
- (void) md:(NSString *)path tohtml:(NSString *)dest;
- (void)addChild:(NSString *)url withName:(NSString *)nameStr selectParent:(BOOL)select;
- (NSString *) getDestPath:(NSString *)path;

- (NSArray *)recurise:(NSString *)dir;
- (NSArray *) listDirectory:(NSString *)path;
@end

@interface NoteSnap: NSObject

@property (strong, nonatomic) NSString* root;
@property (strong) NSString *title;
@property (strong) NSString *urlStr;
@property (strong) NSImage *abstract;

- (id) initWithFile:(NSString *)path snapshot:(NSString *)img_path;
@end
