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

@class NSMutableSet;

@interface SkyP4ZipPanel: LSWContentPage {
  NSString     *zipFilePath;
  NSArray      *pathsToZip;
  id           fileManager;
  int          compressionLevel;
  id           dataSource;
  NSString     *clickedFolderPath;
  id           currentFile;
  NSMutableSet *excludedPathes;
  BOOL         saveAttributes;
  NSString     *format;
}
@end

#include "common.h"
#include "NGFileManagerZipTool.h"
#include "NGFileManagerTarTool.h"

@implementation SkyP4ZipPanel

- (id)init {
  if ((self = [super init])) {
    self->compressionLevel = 5;
    self->excludedPathes   = [[NSMutableSet alloc] init];
    self->saveAttributes   = NO; // ms: should be YES in the future
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->zipFilePath);
  RELEASE(self->pathsToZip);
  RELEASE(self->fileManager);
  RELEASE(self->dataSource);
  RELEASE(self->currentFile);
  RELEASE(self->excludedPathes);
  RELEASE(self->format);

  [super dealloc];
}

- (void)setFileManager:(id)_fm {
  ASSIGN(self->fileManager, _fm);
}
- (id)fileManager {
  return self->fileManager;
}

- (id)fileSystemAttributes {
  return [[self fileManager] fileSystemAttributesAtPath:@"/"];
}

- (void)setZipFilePath:(NSString *)_path {
  ASSIGNCOPY(self->zipFilePath, _path);
}
- (NSString *)zipFilePath {
  return self->zipFilePath;
}

- (void)setPathsToZip:(NSArray *)_paths {
  ASSIGN(self->pathsToZip, _paths);
}
- (NSArray *)pathsToZip {
  return self->pathsToZip;
}

- (void)setCurrentFile:(id)_file {
  ASSIGN(self->currentFile, _file);
}
- (id)currentFile {
  return self->currentFile;
}

- (NSString *)fileName {
  NSString *fname;
  NSString *mType;
  
  fname = [self->currentFile valueForKey:@"NSFileName"];
  mType = [self->currentFile valueForKey:@"NSFileMimeType"];
  
  if ([mType isEqualToString:@"x-skyrix/filemanager-link"]) {
    NSArray  *comps = [fname componentsSeparatedByString:@"."];
    
    return ([comps count]) ? [comps objectAtIndex:0] : fname;
  }
  return fname;
}

- (id)dataSource {
  NSMutableArray *a;
  unsigned i, count;

  if (self->dataSource)
    return self->dataSource;

  if ((count = [[self pathsToZip] count]) == 0)
    return nil;

  a = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    id info;
    
    info = [[self fileManager]
                  fileAttributesAtPath:[[self pathsToZip] objectAtIndex:i]
                  traverseLink:NO];
    if (info)
      [a addObject:info];
  }

  self->dataSource = [[EOArrayDataSource alloc] init];
  [self->dataSource setArray:a];
  return self->dataSource;
}

- (void)setFormat:(NSString *)_format {
  ASSIGN(self->format, _format);
}
- (NSString *)format {
  return self->format;
}

- (void)setCompressionLevel:(int)_level {
  self->compressionLevel = _level;
}
- (int)compressionLevel {
  return self->compressionLevel;
}

- (void)setSaveAttributes:(BOOL)_save {
  self->saveAttributes = _save;
}
- (BOOL)saveAttributes {
  return self->saveAttributes;
}

- (void)setClickedFolderPath:(NSString *)_path {
  ASSIGN(self->clickedFolderPath, _path);
}
- (NSString *)clickedFolderPath {
  return self->clickedFolderPath;
}

- (void)setExcluded:(BOOL)_exc {
  if (_exc)
    [self->excludedPathes addObject:[[self currentFile]
                                           valueForKey:NSFilePath]];
  else
    [self->excludedPathes removeObject:[[self currentFile]
                                              valueForKey:NSFilePath]];
}
- (BOOL)excluded {
  return [self->excludedPathes containsObject:
              [[self currentFile] valueForKey:NSFilePath]];
}

- (id)changeDirectory {
  [self setZipFilePath:[[self clickedFolderPath]
                              stringByAppendingPathComponent:
                              [[self zipFilePath] lastPathComponent]]];
  [[self fileManager] changeCurrentDirectoryPath:[self clickedFolderPath]];

  return nil;
}

- (id)zip {
  NSMutableArray *pathsToZip2   = nil;
  NSString       *fmt           = nil;
  NSString       *archiveFile   = nil;
  NSString       *pathExtension = nil;

  pathsToZip2 = [NSMutableArray arrayWithArray:[self pathsToZip]];
  [pathsToZip2 removeObjectsInArray:[self->excludedPathes allObjects]];

  archiveFile   = [self zipFilePath];
  pathExtension = [archiveFile pathExtension];

  fmt = [self format];
  if ([fmt isEqualToString:@"zip"]) {
    NGFileManagerZipTool *zipTool = nil;

    if ([pathExtension length] == 0) {
      archiveFile = [archiveFile stringByAppendingPathExtension:@"zip"];
    }
    zipTool = [[NGFileManagerZipTool alloc] init];
    [zipTool setSourceFileManager:[self fileManager]];
    [zipTool setTargetFileManager:[self fileManager]];
    [zipTool setSaveAttributes:   [self saveAttributes]];
    [zipTool zipPaths:pathsToZip2 toPath:archiveFile
             compressionLevel:[self compressionLevel]];
    RELEASE(zipTool);
  }
  else if ([fmt isEqualToString:@"tar"]) {
    NGFileManagerTarTool *tarTool = nil;

    if ([pathExtension length] == 0) {
      archiveFile = [archiveFile stringByAppendingPathExtension:@"tar"];
    }
    tarTool = [[NGFileManagerTarTool alloc] init];
    [tarTool setSourceFileManager:[self fileManager]];
    [tarTool setTargetFileManager:[self fileManager]];
    [tarTool setSaveAttributes:   [self saveAttributes]];
    [tarTool tarPaths:pathsToZip2 toPath:archiveFile];
    RELEASE(tarTool);
  }

  return [[(LSWSession *)[self session] navigation] leavePage];
}

- (id)back {
  return [[(LSWSession *)[self session] navigation] leavePage];
}

@end /* SkyP4ZipPanel */
