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

#include <OGoFoundation/OGoComponent.h>

@class EOGlobalID;

@interface SkyProject4VersionList : OGoComponent
{
  id         fileManager;
  id         dataSource;
  EOGlobalID *documentId;
  id         currentVersionItem;
}

@end

#include "common.h"

@implementation SkyProject4VersionList

- (void)dealloc {
  [self->currentVersionItem release];
  [self->documentId         release];
  [self->fileManager        release];
  [self->dataSource         release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self->currentVersionItem release]; self->currentVersionItem = nil;
  [super sleep];
}

/* accessors */

- (void)setDocumentId:(EOGlobalID *)_gid {
  ASSIGNCOPY(self->documentId, _gid);
}
- (id)documentId {
  return self->documentId;
}

- (void)setFileManager:(id)_fm {
  ASSIGN(self->fileManager, _fm);
}
- (id)fileManager {
  return self->fileManager;
}

- (void)setDataSource:(id)_ds {
  ASSIGN(self->dataSource, _ds);
}
- (id)dataSource {
  return self->dataSource;
}

- (NSString *)documentPath {
  return [[self fileManager] pathForGlobalID:[self documentId]];
}
- (NSDictionary *)fileSystemInfo {
  return [[self fileManager] fileSystemAttributesAtPath:[self documentPath]];
}

- (void)setCurrentVersionItem:(id)_item {
#if 0
  [self debugWithFormat:@"cv: %@", self->currentVersionItem];
#endif
  ASSIGN(self->currentVersionItem, _item);
}
- (id)currentVersionItem {
  return self->currentVersionItem;
}

/* actions */

- (id)clickedVersion {
  //id       doc      = nil;
  //NSString *version = nil;
  SkyProjectHistoryDocument *doc;
  id                        page;

  //version       = [[self currentVersionItem] valueForKey:@"SkyVersionName"];
  //doc           = [[self fileManager] documentAtPath:[self documentPath]];
  //[doc takeValue:version forKey:@"versionToView"];

  doc = [[SkyProjectHistoryDocument alloc] initWithFileAttributes:
                                           [self currentVersionItem]
                                           fileManager:[self fileManager]];
  page    = [self activateObject:doc withVerb:@"view"];

  return page;
}

@end /* SkyProject4VersionList */
