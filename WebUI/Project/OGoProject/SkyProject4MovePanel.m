/*
  Copyright (C) 2000-2005 SKYRIX Software AG

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

#include <OGoFoundation/LSWContentPage.h>

/*
  SkyProject4MovePanel
  
  Used to move files inside projects.
  
  Note: this is also called by OGoDocumentImport for the save-and-move
        operation. In this mode it passes in dictionaries describing new
	documents in the 'newDocuments' parameter.
*/

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
#if 1
  return NO;
#else
  // TODO: explain why this is commented out or what it does
  return ![[self tabKey] isEqualToString:@"delete"];
#endif
}

/* title */

- (NSString *)windowTitle {
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
    : (NSString *)@"copy / move files from project ";

  projectName = [(NSDictionary *)[self fileSystemAttributes] 
                                 objectForKey:@"NSFileSystemName"];
  return [NSString stringWithFormat:@"%@ %@", action, projectName];
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
  if (self->selectedProject == nil) {
    return [(NSDictionary *)[self fileSystemAttributes] 
                            objectForKey:NSFileSystemNumber];
  }
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
  return [comps isNotEmpty] ? (NSString *)[comps objectAtIndex:0] : fname;
}

- (void)setNewDocuments:(NSArray *)_newDocuments {
  ASSIGN(self->newDocuments, _newDocuments);
  [self setTabKey:@"new"];
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

/* failed files */

- (void)fileManager:(id)_fm moveFailedForFile:(NSString *)_file code:(int)_c {
  if (!self->failedFiles)
    self->failedFiles = [[NSMutableArray alloc] initWithCapacity:64];
  [self->failedFiles addObject:_file];
}

- (void)resetFailedFiles {
  [self->failedFiles release]; self->failedFiles = nil;
}

- (BOOL)hasFailedFiles {
  return [self->failedFiles count] > 0 ? YES : NO;
}

- (void)setFailedFilesErrorString {
  id l;

  l = [self labels];
  if ([self->failedFiles count] == [self->pathsToMove count]) {
    [self setErrorString:[l valueForKey:@"no files could be moved."]];
  }
  else {
    [self setPathsToMove:self->failedFiles];
    [self setErrorString:[l valueForKey:@"some files could be moved."]];
  }
}

/* actions */

- (id)selectProject {
  [self debugWithFormat:@"selected project: %@", [self selectedProject]];
  return nil;
}

- (id)moveToFolder {
  NSString *destination;
  id       fm, l;
  BOOL     isDir;
  
  [self resetFailedFiles];
  
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
  
  if ([self->pathsToMove count] == 0)
    return nil;
    
  if (![fm movePaths:self->pathsToMove toPath:destination handler:self])
    return [self printError];
  
  if (![self hasFailedFiles]) {
    /* no errors, everything moved .. */
    [fm changeCurrentDirectoryPath:destination];
    return [[(OGoSession *)[self session] navigation] leavePage];
  }
  
  [self setFailedFilesErrorString];
  [self resetFailedFiles];
  return nil; /* stay on page */
}

- (id)copyToFolder {
  NSMutableArray *leftFiles;
  NSString *destination;
  unsigned i, count;
  id       fm, l;
  
  [self resetFailedFiles];
  
  destination = [self clickedFolderPath];
  fm          = [self fileManager];
  l           = [self labels];
  
  [self debugWithFormat:@"copy to folder: %@.", destination];
  
  if (![fm changeCurrentDirectoryPath:destination]) {
    [self setErrorString:[l valueForKey:@"couldn't change directory .."]];
    return nil; /* stay on page */
  }

  /* start copy loop */

  leftFiles = [[self->pathsToMove mutableCopy] autorelease];
    
  count = [self->pathsToMove count];
  for (i = 0; i < count; i++) {
    NSString *path;
    NSString *fdest;
      
    path = [self->pathsToMove objectAtIndex:i];
    fdest = [path lastPathComponent];
    fdest = [destination stringByAppendingPathComponent:fdest];
      
    if ([fm copyPath:path toPath:fdest handler:nil])
      [leftFiles removeObject:path];
  }
  
  if ([leftFiles count] == 0)
    /* no errors, everything copied .. */
    return [[(OGoSession *)[self session] navigation] leavePage];
  
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
  return nil;
}

- (id)createDocuments {
  OGoNavigation *nav;
  NSFileManager *fm;
  NSString      *dest;
  int           i, cnt;
  BOOL          isDir;
  id            l;

#warning TODO: create new documents
  [self logWithFormat:@"CREATE: %@", self->newDocuments];
  
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
  
  for (i = 0, cnt = [self->newDocuments count]; i < cnt; i++) {
    NSDictionary *aDoc;
    NSString     *fname;
    NSString     *subject;
    NSDictionary *attrs;
    
    aDoc    = [self->newDocuments objectAtIndex:i];
    fname   = [aDoc valueForKey:@"NSFileName"];
    subject = [aDoc valueForKey:@"NSFileSubject"];

#warning TODO: create new documents
    [self logWithFormat:@"  doc: %@", aDoc];

    if ([subject length] > 0) {
      attrs  = [NSDictionary dictionaryWithObjectsAndKeys:
                             subject, @"NSFileSubject", nil];
    }
    else
      attrs = nil;

    fname = [dest stringByAppendingPathComponent:fname];
    
    [self logWithFormat:@"save fm='%@' %d bytes at %@ .. attrs='%@'",
          fm,
          [[aDoc valueForKey:@"content"] length], fname, attrs];
    
    if (![fm createFileAtPath:fname contents:[aDoc valueForKey:@"content"]
             attributes:attrs]) {
      return [self printErrorWithSource:fname destination:nil];
    }
  }
  
  nav = [[self session] navigation];
  [nav leavePage];
  [nav leavePage];
  return [nav activePage];
}

@end /* SkyProject4MovePanel */
