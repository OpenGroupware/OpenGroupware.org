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

#include "SkyMailingListDataSource.h"
#include "common.h"

@implementation SkyMailingListDataSource

- (id)initWithContext:(id)_ctx {
  if ((self = [super init])) {
    self->context = [_ctx retain];
  }
  return self;
}

- (void)dealloc {
  [self->context release];
  [self->path    release];
  [self->fetchSpecification release];
  [super dealloc];
}

/* path */

- (NSString *)_buildPath {
  NSNumber *accountId;
  NSString *p;
  
  accountId = [[self->context valueForKey:LSAccountKey]
		              valueForKey:@"companyId"];
  p = [accountId stringValue];
  p = [p stringByAppendingPathExtension:@"mailingListManager"];
  
  p = [[[NSUserDefaults standardUserDefaults]
                        stringForKey:@"LSAttachmentPath"]
                        stringByAppendingPathComponent:p];
  return p;
}

/* accessors */

- (void)setFetchSpecification:(EOFetchSpecification *)_fs {
  ASSIGN(self->fetchSpecification, _fs);
}
- (EOFetchSpecification *)fetchSpecification {
  return self->fetchSpecification;
}

- (NSString *)path {
  if (self->path != nil)
    return self->path;
  
  self->path = [[self _buildPath] copy];
  return self->path;
}

/* operations */

- (NSArray *)fetchObjects {
  NSFileManager *fm;

  fm = [NSFileManager defaultManager];
  
  if ([fm fileExistsAtPath:[self path]])
    return [NSArray arrayWithContentsOfFile:self->path];
  
  return [NSArray array];
}

- (void)save:(NSArray *)_array {
  NSAssert([_array writeToFile:[self path] atomically:YES],
	   @"writing mailing list failed");
}

- (void)insertObject:(id)_object {
  NSArray      *a;
  NSEnumerator *enumerator;
  NSDictionary *obj;
  NSString     *name;

  a          = [self fetchObjects];
  enumerator = [a objectEnumerator];
  name       = [(NSDictionary *)_object objectForKey:@"name"];

  if ([name length] == 0) {
    NSLog(@"%s: could not insert spam entry %@, missing name",
          __PRETTY_FUNCTION__, _object);
  }
  while ((obj = [enumerator nextObject])) {
    if ([[obj objectForKey:@"name"] isEqual:name])
      break;
  }
  if (obj) {
    NSLog(@"%s: could not insert entry, name already exist %@",
          __PRETTY_FUNCTION__, obj);
    return;
  }
  a = [a mutableCopy];
  [(NSMutableArray *)a addObject:_object];

  [self save:a];

  [a release]; a = nil;
}

- (void)deleteObject:(id)_object {
  NSMutableArray *array;
  NSString       *name;
  int            cnt,i;

  array = [[self fetchObjects] mutableCopy];
  cnt   = [array count];
  name  = [(NSDictionary *)_object objectForKey:@"name"];

  if (![name length]) {
    NSLog(@"%s: could not delete spam entry %@, missing name",
          __PRETTY_FUNCTION__, _object);
    return;
  }

  for (i = 0; i < cnt; i++) {
    NSDictionary *obj;

    obj = [array objectAtIndex:i];

    if (![[obj objectForKey:@"name"] isEqual:name])
      continue;

    [array removeObjectAtIndex:i];
    i--; cnt--;
  }
  [self save:array];
  [array release]; array = nil;
}

- (id)createObject:(id)_object {
  return [NSMutableDictionary dictionaryWithCapacity:8];
}

- (void)updateObject:(id)_object {
  NSArray      *array;
  NSString     *name;
  NSEnumerator *enumerator;
  NSDictionary *obj;
  int          i;
  
  name = [(NSDictionary *)_object objectForKey:@"name"];
  if ([name length] == 0) {
    [self logWithFormat:
            @"ERROR(%s): could not update spam entry %@, missing name.",
            __PRETTY_FUNCTION__, _object];
    return;
  }
  
  array      = [self fetchObjects];
  enumerator = [array objectEnumerator];
  i          =  0;
  while ((obj = [enumerator nextObject])) {
    if ([[obj objectForKey:@"name"] isEqual:name]) {
      break;
    }
    i++;
  }
  if (obj == nil) {
    NSLog(@"%s: could not update entry %@", __PRETTY_FUNCTION__, _object);
    return;
  }
  array = [array mutableCopy];
  [(NSMutableArray *)array removeObjectAtIndex:i];
  [(NSMutableArray *)array insertObject:_object atIndex:i];
  
  [self save:array];
  [array release]; array = nil;
}

@end /* SkyMailingListDataSource */
