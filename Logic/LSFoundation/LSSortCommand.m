/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include "LSSort.h"
#include "LSSortCommand.h"
#include "common.h"

@implementation LSSortCommand

+ (int)version {
  return 1;
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    self->ordering = LSAscendingOrder;
  }
  return self;
}

- (void)dealloc {
  [self->sortAttribute release];
  [self->sortList      release];
  [super dealloc];
}

/* command type */

- (BOOL)requiresChannel {
  return NO;
}
- (BOOL)requiresTransaction {
  return NO;
}

/* execution */

- (void)_executeInContext:(id)_context {
  LSSort  *sort;
  NSArray *sa;
  
  sort = [[LSSort alloc] init];
  [sort setSortArray:self->sortList];
  [sort setSortContext:self->sortAttribute];
  [sort setOrdering:self->ordering];

  //[self logWithFormat:@"ordering: %@", self->ordering];
  sa = [sort sortedArray];
  [self setReturnValue:sa];
  
  [sort release];
}

/* accessors */

- (void)setSortAttribute:(id)_sortAttribute {
  id tmp = self->sortAttribute;
  self->sortAttribute = [_sortAttribute retain];
  [tmp release];
}
- (id)sortAttribute {
  return self->sortAttribute;
}

- (void)setSortList:(NSArray *)_sortList {
  id tmp = self->sortList;
  self->sortList = [_sortList retain];
  [tmp release];
}
- (NSArray *)sortList {
  return self->sortList;
}

- (void)setOrdering:(LSOrdering)_ordering {
  self->ordering = _ordering;
}

- (LSOrdering)ordering {
  return self->ordering;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"sortAttribute"])
    [self setSortAttribute:_value];
  else if ([_key isEqualToString:@"sortList"])
    [self setSortList:_value];
  else if ([_key isEqualToString:@"ordering"])
    [self setOrdering:[_value intValue]];
  else
    [self foundInvalidSetKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"sortAttribute"])
    return [self sortAttribute];
  else if ([_key isEqualToString:@"sortList"])
    return [self sortList];
  else if ([_key isEqualToString:@"ordering"])
    return [NSNumber numberWithInt:[self ordering]];
  else
    return [self foundInvalidGetKey:_key];
}

@end
