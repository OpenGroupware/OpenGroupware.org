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

#include <OGoFoundation/OGoContentPage.h>

@class NSData, NSString, NSArray, NSMutableArray;

@interface SkyP4UnzipPanel : OGoContentPage
{
  NSData         *zipData;
  NSString       *fileName;
  NSMutableArray *excludeList;
  id             fileManager;
  BOOL           recursive;
  NSArray        *infoList;
  NSDictionary   *infoItem;
  BOOL           restoreAttributes;
  BOOL           overwrite;
  BOOL           remove;
  NSString       *version;
}
- (void)setExclude:(BOOL)_excl;
- (BOOL)exclude;
@end

#include "common.h"
#include "NGFileManagerZipTool.h"
#include "NGFileManagerTarTool.h"

@implementation SkyP4UnzipPanel

- (id)init {
  if ((self = [super init])) {
    self->excludeList = [[NSMutableArray alloc] init];
    self->restoreAttributes = NO; // ms: should be YES in the future
    self->overwrite         = YES;
    self->remove            = NO;
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->zipData);
  RELEASE(self->fileName);
  RELEASE(self->excludeList);
  RELEASE(self->fileManager);
  RELEASE(self->infoList);
  RELEASE(self->version);

  [super dealloc];
}

// accessors

- (void)setZipData:(NSData *)_data {
  ASSIGN(self->zipData, _data);
}
- (NSData *)zipData {
  return self->zipData;
}

- (void)setFileName:(NSString *)_fileName {
  ASSIGN(self->fileName, _fileName);
}
- (NSString *)fileName {
  return self->fileName;
}

- (void)setVersion:(NSString *)_version {
  ASSIGN(self->version, _version);
}
- (NSString *)version {
  return self->version;
}

/*
  - (void)setExcludeList:(NSArray *)_list {
  self->excludeList = [[NSMutableArray alloc] initWithArray:_list];
}
- (NSArray *)excludeList {
  return self->excludeList;
}
*/

- (void)setFileManager:(id)_fm {
  ASSIGN(self->fileManager, _fm);
}
- (id)fileManager {
  return self->fileManager;
}

- (id)fileSystemAttributes {
  return [[self fileManager] fileSystemAttributesAtPath:@"/"];
}

- (NSArray *)infoList {
  if (self->infoList == nil) {
    NSString *pe = nil;

    pe = [[self fileName] pathExtension];
    if ([pe isEqual:@"zip"] || [pe isEqual:@"ZIP"]) {
      NGFileManagerZipInfo *zipInfo = nil;

      zipInfo = [[NGFileManagerZipInfo alloc] init];
      [zipInfo setFileManager:[self fileManager]];

      if ([self zipData] != nil)
        self->infoList = [zipInfo infoListOnZippedData:[self zipData]];
      else
        self->infoList = [zipInfo infoListOnZipFileAtPath:[self fileName]];

      RETAIN(self->infoList);
      RELEASE(zipInfo);
    }
    else if ([pe isEqual:@"tar"] || [pe isEqual:@"TAR"]) {
      NGFileManagerTarInfo *tarInfo = nil;

      tarInfo = [[NGFileManagerTarInfo alloc] init];
      [tarInfo setFileManager:[self fileManager]];

      if ([self zipData] != nil)
        self->infoList = [tarInfo infoListOnTaredData:[self zipData]];
      else
        self->infoList = [tarInfo infoListOnTarFileAtPath:[self fileName]];

      RETAIN(self->infoList);
      RELEASE(tarInfo);
    }
  }

  return self->infoList;
}

- (void)setInfoItem:(NSDictionary *)_item {
  ASSIGN(self->infoItem, _item);
}
- (NSDictionary *)infoItem {
  return self->infoItem;
}

- (NSString *)dateAndTime {
  return [NSString stringWithFormat:@"%@ %@",
                   [[self infoItem] valueForKey:@"date"],
                   [[self infoItem] valueForKey:@"time"]];
}

- (void)setExclude:(BOOL)_excl {
  if (_excl) {
    if (![self exclude])
      [self->excludeList addObject:[[self infoItem]
                                          objectForKey:@"pathName"]];
  }
  else {
    [self->excludeList removeObject:[[self infoItem]
                                           objectForKey:@"pathName"]];
  }
}
- (BOOL)exclude {
  return [self->excludeList containsObject:
              [[self infoItem] objectForKey:@"pathName"]];
}

- (void)setRestoreAttributes:(BOOL)_restore {
  self->restoreAttributes = _restore;
}
- (BOOL)restoreAttributes {
  return self->restoreAttributes;
}

- (void)setOverwrite:(BOOL)_overwrite {
  self->overwrite = _overwrite;
}
- (BOOL)overwrite {
  return self->overwrite;
}

- (void)setRemove:(BOOL)_remove {
  self->remove = _remove;
}
- (BOOL)remove {
  return self->remove;
}

// actions

- (id)unzip {
  EOOrQualifier  *qualifier = nil;
  NSMutableArray *qualiList = nil;
  NSEnumerator   *enumer    = nil;
  NSString       *exclPath  = nil;
  NSString       *pe        = nil;
  NSString       *path      = nil;
  id             fm         = nil;

  fm        = [self fileManager];
  path      = [self fileName];
  pe        = [path pathExtension];
  qualiList = [[NSMutableArray alloc] init];
  enumer    = [self->excludeList objectEnumerator];
  while ((exclPath = [enumer nextObject])) {
    EOQualifier *quali = nil;

    if ([exclPath hasSuffix:@"/"])
      exclPath = [exclPath substringToIndex:([exclPath length] - 1)];

    quali = [EOQualifier qualifierWithQualifierFormat:@"description like %@",
                         [@"*" stringByAppendingString:exclPath]];
    [qualiList addObject:quali];
  }
  qualifier = [[EOOrQualifier alloc] initWithQualifierArray:qualiList];

  if ([pe isEqualToString:@"zip"] || [pe isEqualToString:@"ZIP"]) {
    NGFileManagerUnzipTool *unzipTool = nil;

    unzipTool   = [[NGFileManagerUnzipTool alloc] init];
    [unzipTool setSourceFileManager:fm];
    [unzipTool setTargetFileManager:fm];
    [unzipTool setExcludeQualifier: qualifier];
    [unzipTool setRestoreAttributes:[self restoreAttributes]];
    [unzipTool setOverwrite:        [self overwrite]];
    if ([self zipData] != nil)
      [unzipTool unzipData:[self zipData] toPath:[fm currentDirectoryPath]];
    else
      [unzipTool unzipPath:path toPath:[fm currentDirectoryPath]];
  }
  else if ([pe isEqualToString:@"tar"] || [pe isEqualToString:@"TAR"]) {
    NGFileManagerUntarTool *untarTool = nil;

    NSLog(@">>>>>>>>>>>>>>>>>>>>");
    untarTool   = [[NGFileManagerUntarTool alloc] init];
    [untarTool setSourceFileManager:fm];
    [untarTool setTargetFileManager:fm];
    [untarTool setExcludeQualifier: qualifier];
    [untarTool setRestoreAttributes:[self restoreAttributes]];
    [untarTool setOverwrite:        [self overwrite]];
    NSLog(@">>>>>>>>>>>>>>>>>>>>");
    if ([self zipData] != nil) {
      [untarTool untarData:[self zipData] toPath:[fm currentDirectoryPath]];
      NSLog(@">>>>>>>>>>>>>>>>>>>> data");
    }
    else {
      [untarTool untarPath:path toPath:[fm currentDirectoryPath]];
      NSLog(@">>>>>>>>>>>>>>>>>>>> path");
    }
  }

  if ([self remove]) {
    NSString *trashPath = nil;

    trashPath = [fm trashFolderForPath:path];
    
    if ([path hasPrefix:trashPath]) {
      if ([fm removeFileAtPath:path handler:nil]) {
        [[(OGoSession *)[self session] navigation] leavePage];
      }
    }
    else {
      NSString *tmp;
      unsigned i;
      
      trashPath = [trashPath stringByAppendingPathComponent:
                             [path lastPathComponent]];
      tmp = trashPath;
      i = 0;
      while ([fm fileExistsAtPath:tmp]) {
        i++;
        tmp = [trashPath stringByAppendingFormat:@"%d", i];
      }
      trashPath = tmp;
      
      if ([fm movePath:path toPath:trashPath handler:nil]) {
        [[(OGoSession *)[self session] navigation] leavePage];
      }
    }
  }

  return [[(OGoSession *)[self session] navigation] leavePage];
}

@end /* SkyP4UnzipPanel */
