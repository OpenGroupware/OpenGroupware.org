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
// $Id$

#include "OGoConfigDataSource.h"
#include "OGoConfigDatabase.h"
#include "common.h"

@implementation OGoConfigDataSource

- (id)initWithConfigDatabase:(OGoConfigDatabase *)_db {
  if ((self = [super init])) {
    self->db = [_db retain];
  }
  return self;
}
- (id)init {
  return [self initWithConfigDatabase:nil];
}

- (void)dealloc {
  [self->db release];
  [super dealloc];
}

/* accessors */

- (OGoConfigDatabase *)configDatabase {
  return self->db;
}

- (void)setFetchSpecification:(EOFetchSpecification *)_fspec {
  if ([self->fetchSpecification isEqual:_fspec])
    return;
  
  [self->fetchSpecification autorelease];
  self->fetchSpecification = [_fspec copy];
  
  [self postDataSourceChangedNotification];
}
- (EOFetchSpecification *)fetchSpecification {
  return self->fetchSpecification;
}

/* error handling */

- (void)resetLastException {
}
- (NSException *)lastException {
  return nil;
}
- (void)setLastException:(NSException *)_exc {
  [_exc raise]; // improve ...
}

/* fetching */

- (NSArray *)_fetchAllEntries {
  NSMutableArray *result;
  NSArray  *names;
  unsigned i, count;
  
  names = [self->db fetchEntryNames];
  if ([names isKindOfClass:[NSException class]]) {
    [self setLastException:(id)names];
    return nil;
  }
  
  if ((count = [names count]) == 0)
    return names;
  
  result = [NSMutableArray arrayWithCapacity:(count + 1)];
  for (i = 0; i < count; i++) {
    id entry;

    entry = [self->db fetchEntryWithName:[names objectAtIndex:i]];
    if (entry == nil) continue;
    
    [result addObject:entry];
  }
  
  return result;
}

- (NSArray *)fetchObjects {
  EOQualifier *q;
  NSArray     *sort;
  NSArray     *result;
  
  [self resetLastException];
  
  if ((result = [self _fetchAllEntries]) == nil)
    return nil;
  if (self->fetchSpecification == nil)
    return result;
  
  q    = [self->fetchSpecification qualifier];
  sort = [self->fetchSpecification sortOrderings];

  if (q == nil) {
    if (sort)
      result = [result sortedArrayUsingKeyOrderArray:sort];
  }
  else {
    result = [result filteredArrayUsingQualifier:q];
    if (sort) result = [result sortedArrayUsingKeyOrderArray:sort];
  }
  return result;
}

@end /* OGoConfigDataSource */
