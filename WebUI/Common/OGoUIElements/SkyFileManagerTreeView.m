/*
  Copyright (C) 2000-2004 SKYRIX Software AG

  This file is part of OpenGroupware.org.

  OGo is free software; you can redistribute it and/or modify it under
  the terms of the GNU Lesser General Public License as published by the
  Free Software Foundation; either version 2, or (at your option) any
  later version.

  OGo is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
  License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with OGo; see the file COPYING.  If not, write to the
  Free Software Foundation, 59 Temple Place - Suite 330, Boston, MA
  02111-1307, USA.
*/
// $Id$

#include <OGoFoundation/LSWComponent.h>

@class NSString, NSMutableSet, NSArray;

/*
  An UI element to display a filemanager hierachy as a tree. If onClick is not
  overridden, a click on a filelink will change the current directory of the
  filemanager.
  
  Bindings:

    fileManager    - NGFileManager - in
    currentPath    - NSString
    fileSystemPath - NSString      - out
    
    onClick     - NSString      - in
      action to execute if the file is clicked
    zoomDefault - NSString      - in
      default to store the zoom-state in
    
    unclickablePaths - NSArray of paths
    
    onDrop      - NSString      - in
      action to execute if sth was dropped
    droppedObject  - id            - out
      the dropped object, as set by WEDragContainer
    dropTags     - NSString      - in
*/

@interface SkyFileManagerTreeView : LSWComponent
{
  NSString     *title;
  id           fileManager;
  NSString     *currentPath;
  NSMutableSet *zoom;
  NSArray      *pathStack;
  NSString     *stackPath;
  id           currentFile;
  NSString     *onClick;
  NSString     *zoomDefault; /* name of userdefault to store the zoom in */
  BOOL         zoomDidChange;
  
  NSString     *onDrop;
  NSArray      *dropTags;
  id           droppedObject;
  
  NSArray      *unclickablePaths;

  BOOL         useFileSystemCache; /* to prevent confusions if
                                      filesystem changed */
  NSMutableDictionary *fsCache;
}

@end

#include <OGoFoundation/LSWSession.h>
#include <LSFoundation/LSFoundation.h>
#include <NGObjWeb/NGObjWeb.h>
#include "common.h"

@implementation SkyFileManagerTreeView

static NSDictionary *onlySubFoldersHints = nil;

+ (void)initialize {
  if (onlySubFoldersHints == nil) {
    onlySubFoldersHints = [[NSDictionary dictionaryWithObject:
					   [NSNumber numberWithBool:YES]
					 forKey:@"onlySubFolderNames"] copy];
  }
}

- (id)init {
  if ((self = [super init])) {
    self->zoom = [[NSMutableSet alloc] initWithCapacity:64];
  }
  return self;
}

- (void)dealloc {
  [self->dropTags         release];
  [self->droppedObject    release];
  [self->onDrop           release];
  [self->unclickablePaths release];
  [self->zoomDefault      release];
  [self->onClick          release];
  [self->zoom             release];
  [self->fileManager      release];
  [self->pathStack        release];
  [self->stackPath        release];
  [self->currentFile      release];
  [self->currentPath      release];
  [self->title            release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  if (self->zoomDidChange && ([self->zoomDefault length] > 0)) {
    [[(LSWSession *)[self session] userDefaults]
                  setObject:[self->zoom allObjects]
                  forKey:self->zoomDefault];
    self->zoomDidChange = NO;
  }
  [super sleep];
}

/* request handling */

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  [super takeValuesFromRequest:_req inContext:_ctx];
  [self->fsCache release]; self->fsCache = nil;
}

- (id)invokeActionForRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  id res;
  res = [super invokeActionForRequest:_req inContext:_ctx];
  [self->fsCache release]; self->fsCache = nil;
  return nil;
}

/* response generation */

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  [self->fsCache release]; self->fsCache = nil;
  [super appendToResponse:_response inContext:_ctx];
}

/* accessors */

- (void)setFileManager:(id)_fm {
  ASSIGN(self->fileManager, _fm);
}
- (id)fileManager {
  return self->fileManager;
}

- (void)setCurrentPath:(NSString *)_path {
  ASSIGNCOPY(self->currentPath, _path);
}
- (NSString *)currentPath {
  return self->currentPath;
}

- (void)setOnClick:(NSString *)_action {
  ASSIGNCOPY(self->onClick, _action);
}
- (NSString *)onClick {
  return self->onClick;
}

- (void)setOnDrop:(NSString *)_action {
  ASSIGNCOPY(self->onDrop, _action);
}
- (NSString *)onDrop {
  return self->onDrop;
}

- (void)setDropTags:(NSArray *)_tags {
  ASSIGNCOPY(self->dropTags, _tags);
}
- (NSArray *)dropTags {
  return self->dropTags;
}

- (void)setDroppedObject:(id)_action {
  ASSIGN(self->droppedObject, _action);
}
- (id)droppedObject {
  return self->droppedObject;
}

- (void)setUnclickablePaths:(NSArray *)_paths {
  ASSIGNCOPY(self->unclickablePaths, _paths);
}
- (NSArray *)unclickablePaths {
  return self->unclickablePaths;
}

- (void)setZoomDefault:(NSString *)_def {
  if ([self->zoomDefault isEqualToString:_def])
    return;
  
  ASSIGNCOPY(self->zoomDefault, _def);
  
  if (!self->zoomDidChange && ([_def length] > 0)) {
    NSArray *defZoom;
    
    defZoom = [[(LSWSession *)[self session] userDefaults] arrayForKey:_def];
    if (defZoom) {
      [self->zoom removeAllObjects];
      [self->zoom addObjectsFromArray:defZoom];
    }
  }
}
- (NSString *)zoomDefault {
  return self->zoomDefault;
}

- (NSString *)currentPathLabel {
  if ([self->currentPath isEqualToString:@"/"]) {
    NSDictionary *attrs;
    NSString *fsname;
    
    attrs = [[self fileManager] fileSystemAttributesAtPath:@"/"];

    if ((fsname = [attrs objectForKey:@"NSFileSystemName"]))
      return fsname;

    return @"root";
  }
  
  return self->currentPath;
}

- (void)setPathStack:(NSArray *)_stack {
  //if (_stack != self->pathStack) {
  if (YES) {
    NSString *tmp;
    
    [self->stackPath release]; self->stackPath = nil;

    [self->pathStack autorelease];
    self->pathStack = [_stack retain];
    
    tmp = [NSString pathWithComponents:_stack];
    
    if (![tmp isAbsolutePath])
      tmp = [@"/" stringByAppendingString:tmp];
    
    self->stackPath = [tmp copy];
  }
}

- (void)setFileSystemPath:(NSString *)_path {
  // noop to please KVC
}

- (NSString *)fileSystemPath {
  return self->stackPath;
}

- (NSArray *)currentPathContent {
  NSMutableArray *result;
  static BOOL    LoadClass        = YES;
  static Class   FileManagerClass = NULL;

  if (LoadClass == YES) {
    FileManagerClass = NSClassFromString(@"SkyProjectFileManager");
    LoadClass = NO;
  }

  if (self->useFileSystemCache == YES) {
    if ((result = [self->fsCache objectForKey:[self fileSystemPath]])) {
      return result;
    }
  }
  
  if ([self->fileManager isKindOfClass:FileManagerClass]) {
    EODataSource         *ds;
    EOFetchSpecification *fs;
    
    ds   = [self->fileManager dataSourceAtPath:[self fileSystemPath]];
    fs   = [[EOFetchSpecification alloc] initWithEntityName:@"Doc"
                                         qualifier:nil
                                         sortOrderings:nil
                                         usesDistinct:NO isDeep:NO 
					 hints:onlySubFoldersHints];
    [ds setFetchSpecification:fs];
    result = [[[ds fetchObjects] mutableCopy] autorelease];
    [fs release]; fs = nil;
  }
  else {
    NSString       *base;
    unsigned i, count;
    NSArray *contents;

    base     = [self fileSystemPath];
    contents = [self->fileManager directoryContentsAtPath:base];
    result   = [NSMutableArray arrayWithCapacity:16];
  
    for (i = 0, count = [contents count]; i < count; i++) {
      NSString *subPath;
      BOOL     isDir;
    
      subPath = [contents objectAtIndex:i];
      subPath = [base stringByAppendingPathComponent:subPath];
    
      if ([self->fileManager fileExistsAtPath:subPath isDirectory:&isDir]) {
        if (isDir)
          [result addObject:[contents objectAtIndex:i]];
      }
    }
  }
  [result sortUsingSelector:@selector(compare:)];

  if (self->useFileSystemCache) {
    if (!self->fsCache)
      self->fsCache = [[NSMutableDictionary alloc] initWithCapacity:16];
    
    [self->fsCache setObject:result forKey:[self fileSystemPath]];
  }
  
  return result;
}
- (NSArray *)rootFolderContent {
  [self setCurrentPath:@"/"];
  [self setPathStack:[NSArray arrayWithObject:@"/"]];
  return [self currentPathContent];
}

- (BOOL)currentPathIsFile {
  BOOL isDir = NO;

  if (![self->fileManager fileExistsAtPath:[self fileSystemPath]
            isDirectory:&isDir])
    isDir = YES;

  return isDir ? NO : YES;
}
- (BOOL)currentPathIsClickable {
  if (self->unclickablePaths == nil)
    return YES;
  
  return ![self->unclickablePaths containsObject:[self fileSystemPath]];
}

- (BOOL)isCurrentPathSelected {
  NSString *path, *cwd;
  
  path = [self fileSystemPath];
  cwd  = [[self fileManager] currentDirectoryPath];
  
  return [cwd isEqualToString:path] ? YES : NO;
}
- (BOOL)isCurrentPathDirectory {
  return ![self currentPathIsFile];
}

- (void)setIsExpand:(BOOL)_flag {
  NSString *path;

  path = [self fileSystemPath];

  [self debugWithFormat:@"set expanded %s: %@ zoom %@", 
	  _flag ? "yes" : "no", path, self->zoom];
  
  if (_flag) {
    if (![self->zoom containsObject:path]) {
      [self->zoom addObject:path];
      self->zoomDidChange = YES;
    }
  }
  else {
    if ([self->zoom containsObject:path]) {
      [self->zoom removeObject:path];
      self->zoomDidChange = YES;
    }
  }
  
}
- (BOOL)isExpand {
  NSString *cp;

  cp = [self fileSystemPath];
  
  if ([cp isEqualToString:@"/"])
    return YES;
  
  return [self->zoom containsObject:cp];
}

- (NSString *)currentTreeIcon {
  return [self isExpand]
    ? ([[self currentPathContent] count] == 0
       ? @"folder_closed_13.gif"
       : @"folder_opened_13.gif")
    : @"folder_closed_13.gif";
}
- (NSString *)currentCornerTreeIcon {
  return [self isExpand]
    ? ([[self currentPathContent] count] == 0
       ? @"folder_corner_closed_13.gif"
       : @"folder_corner_opened_13.gif")
    : @"folder_corner_closed_13.gif";
}
- (NSString *)currentBGColor {
  if ([self isCurrentPathSelected])
    return [[self config] valueForKey:@"colors_mainButtonRow"];
  
  return [[self config] valueForKey:@"colors_tableViewContentCell"];
}

- (BOOL)useDrop {
  return [self->onDrop length] > 0 ? YES : NO;
}

/* actions */

- (id)clickedFolder {
  NSString *path;

  path = [self fileSystemPath];

  [self debugWithFormat:@"clicked folder: %@", path];

  if (self->onClick)
    return [self performParentAction:self->onClick];
  
  
  
  if (![[self fileManager] changeCurrentDirectoryPath:path]) {
    [self logWithFormat:@"couldn't switch to folder '%@'", path];
  }
  
  return nil;
}
- (id)gotoRoot {
  [self setCurrentPath:@"/"];
  [self setPathStack:[NSArray arrayWithObject:@"/"]];
  
  if (self->onClick)
    return [self performParentAction:self->onClick];
  
  if (![[self fileManager] changeCurrentDirectoryPath:@"/"]) {
    [self logWithFormat:@"couldn't switch to folder /"];
  }
  return nil;
}

- (id)droppedFile {
  //[self debugWithFormat:@"dropped: %@", [self droppedObject]];
  
  if (self->onDrop)
    return [self performParentAction:self->onDrop];
  
  [[[self context] page]
          takeValue:@"can't handle dropped object"
          forKey:@"errorString"];
  return nil;
}
- (id)droppedFileAtRoot {
  [self setCurrentPath:@"/"];
  [self setPathStack:[NSArray arrayWithObject:@"/"]];
  
  return [self droppedFile];
}

- (BOOL)useFileSystemCache {
  return self->useFileSystemCache;
}
- (void)setUseFileSystemCache:(BOOL)_b {
  self->useFileSystemCache = _b;
}

- (NSString *)title {
  return self->title;
}
- (void)setTitle:(NSString *)_t {
  ASSIGN(self->title, _t);
}

@end /* SkyFileManagerTreeView */
