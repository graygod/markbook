//
//  MBCore.h
//  MarkBook
//
//  Created by amoblin on 12-12-1.
//  Copyright (c) 2012年 amoblin. All rights reserved.
//

#import <Foundation/Foundation.h>

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
- (void) rst2html:(NSString *)path;
- (void) md2html:(NSString *)path;
- (void)addChild:(NSString *)url withName:(NSString *)nameStr selectParent:(BOOL)select;

- (NSArray *)recurise:(NSString *)dir;
- (NSArray *) listDirectory:(NSString *)path;
@end

@interface NoteSnap: NSObject

@property (strong) NSString *title;
@property (strong) NSString *abstract;

- (id) initWithUrl:(NSString *)path;
@end
