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

#import "SkyDocumentHistoryDataSource.h"
#import "common.h"
#include <OGoDatabaseProject/SkyProjectFileManager.h>

@interface SkyProjectFileManager(Locking_Internals)
- (NSArray *)allVersionAttributesAtPath:(NSString *)_path;
@end /* SkyProjectFileManager(Locking_Internals) */

@implementation SkyDocumentHistoryDataSource

- (id)init {
  NSLog(@"ERROR[%s]: wrong initializer, use 'initWithContext:..'",
        __PRETTY_FUNCTION__);
  RELEASE(self);
  return nil;
}

- (id)initWithContext:(id)_context documentGlobalID:(EOGlobalID *)_dgid
  projectGlobalID:(EOGlobalID *)_pgid
{
  SkyProjectFileManager *fm = nil;

  fm = [[SkyProjectFileManager alloc] initWithContext:_context
                                      projectGlobalID:_pgid];
  AUTORELEASE(fm);
  return [self initWithFileManager:fm documentGlobalID:_dgid];
}

- (id)initWithFileManager:(SkyProjectFileManager *)_fm
  documentGlobalID:(EOGlobalID *)_dgid
{
  if ((self = [super init])) {
    self->docGID      = [_dgid copy];
    self->fileManager = RETAIN(_fm);
    self->fSpec       = nil;
    self->isValid     = YES;
    {
      NSString *path;

      path = [self->fileManager pathForGlobalID:self->docGID];

      [self->fileManager registerObject:self
           selector:@selector(postDataSourceChangedNotification)
           forVersionChangeOnPath:path];
    }
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  RELEASE(self->fSpec);
  RELEASE(self->docGID);
  RELEASE(self->fileManager);
  [super dealloc];
}
#endif

- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec {
  if (![self->fSpec isEqual:_fSpec]) {
    ASSIGNCOPY(self->fSpec, _fSpec);
    [self postDataSourceChangedNotification];
  }
}
- (EOFetchSpecification *)fetchSpecification {
  return AUTORELEASE([self->fSpec copy]);
}

- (NSArray *)fetchObjects {
  NSArray     *versions, *sort;
  EOQualifier *qualifier;

  versions = [self->fileManager allVersionAttributesAtPath:
                  [self->fileManager pathForGlobalID:self->docGID]];
  
  if ((qualifier = [self->fSpec qualifier]) != nil)
    versions = [versions filteredArrayUsingQualifier:qualifier];
  
  if ((sort = [self->fSpec sortOrderings]))
    versions = [versions sortedArrayUsingKeyOrderArray:sort];

  return versions;
}

@end /* SkyDocumentHistoryDataSource */
