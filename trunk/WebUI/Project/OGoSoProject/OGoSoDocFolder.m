/*
  Copyright (C) 2005 Helge Hess

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

#include "OGoSoDocFolder.h"
#include "common.h"

@implementation OGoSoDocFolder

- (id)initWithName:(NSString *)_key inContainer:(id)_folder {
  if ((self = [super init]) != nil) {
    self->name = [_key copy];
    self->container = [_folder retain];
  }
  return self;
}

- (void)dealloc {
  [self->projectPath release];
  [self->fileManager release];
  [self->container   release];
  [self->name        release];
  [super dealloc];
}

/* containment */

- (void)detachFromContainer {
  [self->container release]; self->container = nil;
  [self->name      release]; self->name      = nil;
}

- (NSString *)nameInContainer {
  return self->name;
}
- (id)container {
  return self->container;
}

/* notifications */

- (void)sleep {
  [self detachFromContainer];
  [self->fileManager release]; self->fileManager = nil;
}

/* folder operations */

- (BOOL)isProjectRootFolder {
  id tmp;

  if ((tmp = [self container]) == nil)
    return YES;
  if (![tmp isKindOfClass:[self class]])
    return YES;
  return NO;
}

- (EOGlobalID *)projectGlobalIDInContext:(id)_ctx {
  id tmp;
  
  if ((tmp = [self container]) == nil)
    return nil;
  if (tmp == self) /* loop?! */
    return nil;
  
  return [tmp projectGlobalIDInContext:_ctx];
}

- (id)fileManagerInContext:(id)_ctx {
  id tmp;
  
  if ((tmp = [self container]) == nil)
    return nil;
  if (tmp == self) /* loop?! */
    return nil;
  
  return [tmp fileManagerInContext:_ctx];
}
- (id)fileManager {
  return [self fileManagerInContext:nil];
}

- (EODataSource *)folderDataSourceInContext:(id)_ctx {
  NSString *p;
  
  p = [self storagePath];
  return [[self fileManagerInContext:_ctx] dataSourceAtPath:p];
}

- (id)projectFolder {
  if ([self isProjectRootFolder])
    return [self container];
  
  return [[self container] projectFolder];
}

- (NSString *)storagePath {
  NSMutableString *ma;
  id folder;
  
  if (self->projectPath)
    return self->projectPath;

  if ([self isProjectRootFolder]) {
    self->projectPath = @"/";
    return self->projectPath;
  }
  
  ma = [[NSMutableString alloc] initWithCapacity:256];
  
  for (folder = self; folder != nil && ![folder isProjectRootFolder];
       folder = [folder container]) {
    [ma insertString:@"/" atIndex:0];
    [ma insertString:[folder nameInContainer] atIndex:0];
  }

  [ma insertString:@"/" atIndex:0];
  
  self->projectPath = [ma copy];
  [ma release];
  
  return self->projectPath;
}

/* name lookup */

- (id)lookupName:(NSString *)_name inContext:(id)_ctx acquire:(BOOL)_ac {
  id p;
  
  /* check method names */
  
  if ((p = [super lookupName:_name inContext:_ctx acquire:NO]) != nil)
    return p;
  
  // TODO: check pathes
  
  // TODO: stop acquistion?
  return nil;
}

@end /* OGoSoDocFolder */
