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

@interface SkyP4ZipInfo: LSWContentPage {
  id           fileManager;
  NSString     *zipFileName;
  NSDictionary *info;
  NSString     *infoKey;
  NSDictionary *infoItem;
}
@end

#include "common.h"
#include "NGFileManagerZipTool.h"
#include "NGFileManagerTarTool.h"

@implementation SkyP4ZipInfo
/*
- (id)init {
  if ((self = [super init])) {
  }
  return self;
}
*/
- (void)dealloc {
  RELEASE(self->fileManager);
  RELEASE(self->zipFileName);
  RELEASE(self->info);
  RELEASE(self->infoKey);
  RELEASE(self->infoItem);

  [super dealloc];
}

- (void)setFileManager:(id)_fm {
  ASSIGN(self->fileManager, _fm);
}
- (id)fileManager {
  return self->fileManager;
}

- (void)setZipFileName:(NSString *)_file {
  ASSIGN(self->zipFileName, _file);
}
- (NSString *)zipFileName {
  return self->zipFileName;
}

- (NSDictionary *)info {
  if (self->info == nil) {
    NGFileManagerZipInfo *zipInfo = nil;

    zipInfo = [[NGFileManagerZipInfo alloc] init];
    [zipInfo setFileManager:[self fileManager]];
    self->info = [[zipInfo infoOnZipFileAtPath:[self zipFileName]] retain];
    RELEASE(zipInfo);
  }

  return self->info;
}

- (NSArray *)infoKeys {
  return [[self info] allKeys];
}

- (void)setInfoKey:(NSString *)_key {
  ASSIGN(self->infoKey, _key);
}
- (NSString *)infoKey {
  return self->infoKey;
}

- (NSDictionary *)infoItem {
  return [[self info] objectForKey:[self infoKey]];
}

@end
