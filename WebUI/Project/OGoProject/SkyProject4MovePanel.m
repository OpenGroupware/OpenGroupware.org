/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#include <OGoFoundation/LSWContentPage.h>

@class NSString, NSArray, NSMutableArray;

@interface SkyProject4MovePanel : LSWContentPage
{
  id       fileManager;
  id       dataSource;
  NSArray  *pathsToMove;
  NSString *destinationPath;
  NSArray  *unclickablePaths;
  NSString *clickedFolderPath;
  NSString *tabKey;
  NSArray  *newDocuments;
  id       currentFile; // item of table-view

  id       selectedProject;
  
  NSMutableArray *failedFiles;
}

- (id)fileManager;
- (id)fileSystemAttributes;

@end

#include "common.h"
#include "OGoComponent+FileManagerError.h"

@implementation SkyProject4MovePanel

- (void)dealloc {
  [self->tabKey            release];
  [self->clickedFolderPath release];
  [self->unclickablePaths  release];
  [self->currentFile       release];
  [self->dataSource        release];
  [self->fileManager       release];
  [self->pathsToMove       release];
  [self->destinationPath   release];
  [self->newDocuments      release];
  [self->failedFiles       release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self->currentFile release]; self->currentFile = nil;
  [super sleep];
}


- (void)setTabKey:(NSString *)_key {
  if ([_key isEqualToString:self->tabKey])
    return;

  ASSIGNCOPY(self->tabKey, _key);
}
- (NSString *)tabKey {
  if (self->tabKey == nil)
    self->tabKey = @"copy";
  return self->tabKey;
}
- (BOOL)showMove {
  return [[self tabKey] isEqualToString:@"move"];
}
- (BOOL)showCopy {
  return [[self tabKey] isEqualToString:@"copy"];
}

- (BOOL)showNew {
  return [[self tabKey] isEqualToString:@"new"];
}

- (BOOL)isProjectSelectionEnabled {
  return NO;
  //return ![[self tabKey] isEqualToString:@"delete"];
}

/* title */

- (NSString *)windowTitle {
  NSString *title;
  NSString *projectName;
  NSString *action;

  if ([self showMove])
    action = [[self labels] valueForKey:@"MoveFilesFromProject"];

  if ([self showCopy])
    action = [[self labels] valueForKey:@"CopyFilesFromProject"];

  if ([self showNew])
    action = [[self labels] valueForKey:@"CreateFilesInProject"];

  action = (action != nil)
    ? action
    : @"copy / move files from project ";

  projectName = [[self fileSystemAttributes] objectForKey:@"NSFileSystemName"];
  
  title = [NSString stringWithFormat:@"%@ %@", action, projectName];
  
  return title;
}

/* accessors */

- (void)setFileManager:(id)_fm {
  ASSIGN(self->fileManager, _fm);
}
- (id)fileManager {
  return self->fileManager;
}

- (void)setSelectedProject:(id)_project {
  [self debugWithFormat:@"selected project %@", _project];
  ASSIGN(self->selectedProject, _project);
}
- (id)selectedProject {
  if (self->selectedProject == nil)
    return [[self fileSystemAttributes] objectForKey:NSFileSystemNumber];
  
  return self->selectedProject;
}

- (void)setDestinationPath:(NSString *)_p {
  ASSIGNCOPY(self->destinationPath, _p);
}
- (NSString *)destinationPath {
  return self->destinationPath;
}

- (void)setPathsToMove:(NSArray *)_paths {
  [self debugWithFormat:@"set paths: %@", _paths];
  ASSIGNCOPY(self->pathsToMove, _paths);
  [self->tabKey     release]; self->tabKey = @"move";
  [self->dataSource release]; self->dataSource = nil;
}
- (NSArray *)pathsToMove {
  return self->pathsToMove;
}

- (void)setPathsToCopy:(NSArray *)_paths {
  [self debugWithFormat:@"set paths: %@", _paths];
  [self->dataSource release]; self->dataSource = nil;
  ASSIGNCOPY(self->pathsToMove, _paths);
  [self->tabKey release]; self->tabKey = @"copy";
}
- (NSArray *)pathsToCopy {
  return self->pathsToMove;
}

- (NSString *)fileName {
  NSString *fname;
  NSString *mType;
  NSArray  *comps;

  fname = [self->currentFile valueForKey:@"NSFileName"];
  mType = [self->currentFile valueForKey:@"NSFileMimeType"];
  
  if (![mType isEqualToString:@"x-skyrix/filemanager-link"])
    return fname;
  
  comps = [fname componentsSeparatedByString:@"."];
  return [comps count] > 0 ? [comps objectAtIndex:0] : fname;
}

- (void)setNewDocuments:(NSArray *)_newDocuments {
  ASSIGN(self->newDocuments, _newDocuments);
  [self->tabKey release]; self->tabKey = @"new";
}
- (NSArray *)newDocuments {
  return self->newDocuments;
}

- (NSArray *)unclickablePaths {
  NSMutableArray *ma;
  unsigned i, count;
  
  if (self->unclickablePaths)
    return self->unclickablePaths;
  
  ma = [NSMutableArray arrayWithCapacity:4];
  for (i = 0, count = [[self pathsToMove] count]; i < count; i++) {
    NSString *path;

    path = [[self pathsToMove] objectAtIndex:i];
    path = [path stringByDeletingLastPathComponent];

    if ([path length] > 0)
      [ma addObject:path];
  }
  
  self->unclickablePaths = [ma copy];

  //[self debugWithFormat:@"unclick: %@", self->unclickablePaths];
  
  return self->unclickablePaths;
}

- (id)dataSource {
  NSMutableArray *a;
  unsigned i, count;
  
  if (self->dataSource)
    return self->dataSource;

  if (self->newDocuments != nil) {
    self->dataSource = [[EOArrayDataSource alloc] init];

    [self->dataSource setArray:self->newDocuments];
    return self->dataSource;
  }

  if ((count = [[self pathsToMove] count]) == 0)
    return nil;
  
  a = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    id info;

    info = [[self fileManager]
                  fileAttributesAtPath:[[self pathsToMove] objectAtIndex:i]
                  traverseLink:NO];
    if (info)
      [a addObject:info];
  }

  self->dataSource = [[EOArrayDataSource alloc] init];
  [self->dataSource setArray:a];
  return self->dataSource;
}

- (id)fileSystemAttributes {
  return [[self fileManager] fileSystemAttributesAtPath:@"/"];
}

- (void)setCurrentFile:(id)_file {
  ASSIGN(self->currentFile, _file);
}
- (id)currentFile {
  return self->currentFile;
}

- (void)setClickedFolderPath:(NSString *)_path {
  ASSIGNCOPY(self->clickedFolderPath, _path);
}
- (NSString *)clickedFolderPath {
  return self->clickedFolderPath;
}

/* actions */

- (id)selectProject {
  [self debugWithFormat:@"selected project: %@", [self selectedProject]];
  return nil;
}

- (void)fileManager:(id)_fm moveFailedForFile:(NSString *)_file code:(int)_code
{
  if (!self->failedFiles)
    self->failedFiles = [[NSMutableArray alloc] initWithCapacity:64];
  [self->failedFiles addObject:_file];
}

- (id)moveToFolder {
  NSString *destination;
  id       fm, l;
  BOOL     isDir;
  

  [self->failedFiles release]; self->failedFiles = nil;

  l           = [self labels];
  destination = [self clickedFolderPath];
  fm          = [self fileManager];

  [self debugWithFormat:@"move to folder: %@.", destination];

  if (![fm fileExistsAtPath:destination isDirectory:&isDir]) {
    [self setErrorString:[l valueForKey:@"Missing folder"]];
    return nil;
  }
  if (!isDir) {
    [self setErrorString:[l valueForKey:@"Path is no folder"]];
    return nil;
  }
  
  {
    /* start move loop */
    if (![self->pathsToMove count])
      return nil;
    
    if (![fm movePaths:self->pathsToMove toPath:destination handler:self]) {
      return [self printError];
    }
    
    if ([self->failedFiles count] == 0) {
      /* no errors, everything moved .. */
      [fm changeCurrentDirectoryPath:destination];
      return [[(LSWSession *)[self session] navigation] leavePage];
    }

    if ([self->failedFiles count] == [self->pathsToMove count]) {
      [self setErrorString:[l valueForKey:@"no files could be moved."]];
    }
    else {
      [self setPathsToMove:self->failedFiles];
      [self setErrorString:[l valueForKey:@"some files could be moved."]];
    }
    [self->failedFiles release]; self->failedFiles = nil;
  }
  return nil;
}

- (id)copyToFolder {
  NSString *destination;
  id fm, l;
  
  destination = [self clickedFolderPath];
  fm          = [self fileManager];
  l           = [self labels];
  
  [self debugWithFormat:@"copy to folder: %@.", destination];
  
  if ([fm changeCurrentDirectoryPath:destination]) {
    /* start copy loop */
    unsigned i, count;
    NSMutableArray *leftFiles;

    leftFiles = [[self->pathsToMove mutableCopy] autorelease];
    
    count = [self->pathsToMove count];
    for (i = 0; i < count; i++) {
      NSString *path;
      NSString *fdest;
      
      path = [self->pathsToMove objectAtIndex:i];
      fdest = [destination stringByAppendingPathComponent:
                             [path lastPathComponent]];

      if ([fm copyPath:path toPath:fdest handler:nil]) {
        [leftFiles removeObject:path];
      }
    }
    if ([leftFiles count] == 0)
      /* no errors, everything copied .. */
      return [[(LSWSession *)[self session] navigation] leavePage];

    if ([leftFiles count] == [self->pathsToMove count]) {
      [self printError];
      if ([[self errorString] length] == 0)
        [self setErrorString:[l valueForKey:@"no files could be copied."]];
    }
    else {
      [self setPathsToCopy:leftFiles];
      [self printError];
      if ([[self errorString] length] == 0)
        [self setErrorString:[l valueForKey:@"some files could be copied."]];
    }
  }
  else
    [self setErrorString:[l valueForKey:@"couldn't change directory .."]];
  
  return nil;
}

- (id)createDocuments {
  OGoNavigation *nav;
  NSFileManager *fm;
  NSString      *dest;
  int           i, cnt;
  BOOL          isDir;
  id            l;

  l  = [self labels];
  fm = [self fileManager];

  if (fm == nil) {
    [self setErrorString:@"No file manager set!"];
    return nil;
  }

  dest = [self clickedFolderPath];

  if (![fm fileExistsAtPath:dest isDirectory:&isDir]) {
    [self setErrorString:[l valueForKey:@"Missing folder"]];
    return nil;
  }
  if (!isDir) {
    [self setErrorString:[l valueForKey:@"Path is no folder"]];
    return nil;
  }
  
  
  cnt = [self->newDocuments count];
  for (i=0; i<cnt; i++) {
    NSDictionary *aDoc    = [self->newDocuments objectAtIndex:i];
    NSString     *fname   = [aDoc valueForKey:@"NSFileName"];
    NSString     *subject = [aDoc valueForKey:@"NSFileSubject"];
    NSDictionary *attrs   = nil;

    if ([subject length] > 0) {
      attrs  = [NSDictionary dictionaryWithObjectsAndKeys:
                             subject, @"NSFileSubject", nil];
    }

    fname = [dest stringByAppendingPathComponent:fname];

    [self logWithFormat:@"save fm='%@' %d bytes at %@ .. attrs='%@'",
          fm,
          [[aDoc valueForKey:@"content"] length], fname, attrs];
    
    if (![fm createFileAtPath:fname contents:[aDoc valueForKey:@"content"]
             attributes:attrs]) {
      return [self printErrorWithSource:fname destination:nil];
    }
  }

  nav = [self navigation];
  [nav leavePage];
  [nav leavePage];
  return [nav activePage];
}

@end /* SkyProject4MovePanel */
