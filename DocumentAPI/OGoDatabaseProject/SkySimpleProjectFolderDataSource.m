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

#include "SkySimpleProjectFolderDataSource.h"
#include "SkyProjectFolderDataSource.h"
#include "SkyProjectFileManager.h"
#include "common.h"

@interface SkyProjectFolderDataSource(Internals)
- (SkyProjectFileManager *)_fileManager;
- (EOGlobalID *)_folderGID;
@end

@interface SkyProjectFileManager(Internals)
- (NSArray *)searchChildsForFolder:(NSString *)_path
  deep:(BOOL)_deep
  qualifier:(EOQualifier *)_qualifier;
@end

@implementation SkySimpleProjectFolderDataSource

- (id)initWithFolderDataSource:(SkyProjectFolderDataSource *)_ds {
  if ((self = [super init])) {
    self->source = [_ds retain];
  }
  return self;
}

- (void)dealloc {
  [self->source             release];
  [self->fetchSpecification release];
  [super dealloc];
}

/* accessors */

- (void)setFetchSpecification:(EOFetchSpecification *)_fs {
  if ([_fs isEqual:self->fetchSpecification])
    return;
  
  ASSIGNCOPY(self->fetchSpecification, _fs);
  [self postDataSourceChangedNotification];
}
- (EOFetchSpecification *)fetchSpecification {
  return self->fetchSpecification;
}

/* fetching */

- (NSArray *)fetchObjects {
  NSAutoreleasePool     *pool;
  NSArray               *result;
  NSString              *folder;
  BOOL                  fetchDeep;
  SkyProjectFileManager *fileManager;
  unsigned fetchLimit;
  
  pool = [[NSAutoreleasePool alloc] init];
  
  fetchLimit = [self->fetchSpecification fetchLimit];
  
  fileManager = [self->source _fileManager];
  // unused: qual        = [self->fetchSpecification qualifier];
  folder      = [fileManager pathForGlobalID:[source _folderGID]];
  
  fetchDeep   = [[[self->fetchSpecification hints] objectForKey:@"fetchDeep"]
                                            boolValue];
  
  result      = [fileManager searchChildsForFolder:folder
                             deep:fetchDeep
                             qualifier:[self->fetchSpecification qualifier]];

  /* apply fetch limit */
  if ((fetchLimit != 0) && ([result count] > fetchLimit)) {
    NSLog(@"%@: fetch limit reached (limit=%d, count=%d)",
          self, fetchLimit, [result count]);
    
    result = [result subarrayWithRange:NSMakeRange(0, fetchLimit)];
  }
  
  /* apply sort orderings */
  {
    NSArray *so;
    
    if ((so = [self->fetchSpecification sortOrderings]) != nil)
      result = [result sortedArrayUsingKeyOrderArray:so];
  }
  
  result = [result shallowCopy];
  [pool release];
  return [result autorelease];
}

@end /* SkySimpleProjectFolderDataSource */
