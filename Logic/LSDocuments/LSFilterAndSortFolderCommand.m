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

#include "LSFilterAndSortFolderCommand.h"
#include "common.h"

@implementation LSFilterAndSortFolderCommand

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain]) != nil) {
    ordering = LSAscendingOrder;
  }
  return self;
}

- (void)dealloc {
  [self->sortAttribute release];
  [self->documentList release];

  [super dealloc];
}

/* command methods */

- (void)_executeInContext:(id)_context {
  // TODO: looks like a DUP to the other filterandsort command
  NSMutableArray *filteredList;
  NSEnumerator   *docEnumerator;
  id             document;
  id             sCmd;

  filteredList  = [[NSMutableArray alloc] initWithCapacity:32];
  docEnumerator = [self->documentList objectEnumerator];
  sCmd           = LSLookupCommand(@"system", @"sort");
  
  while ((document = [docEnumerator nextObject]) != nil) {
    if ([[document valueForKey:@"isFolder"] intValue])  // TODO: bool-value?!
      [filteredList addObject:document];
  }
  
  if ([self->sortAttribute isNotNull]) {
    NSArray *sortedList = nil;
    
    [sCmd takeValue:filteredList forKey:@"sortList"];
    [filteredList release]; filteredList = nil;
    
    [sCmd takeValue:self->sortAttribute forKey:@"sortAttribute"];
    [sCmd takeValue:[NSNumber numberWithInt:self->ordering] forKey:@"ordering"];
    sortedList = [sCmd runInContext:_context];
    [self setReturnValue:sortedList];
  }
  else {
    [self setReturnValue:filteredList];
    [filteredList release]; filteredList = nil;
  }
}

/* accessors */

- (void)setDocumentList:(NSArray *)_documentList {
  ASSIGN(self->documentList, _documentList);
}
- (NSArray *)documentList {
  return self->documentList;
}

- (void)setSortAttribute:(id)_sortAttribute {
  ASSIGN(self->sortAttribute, _sortAttribute);
}
- (id)sortAttribute {
  return self->sortAttribute;
}

- (void)setOrdering:(LSOrdering)_ordering {
  self->ordering = _ordering;
}
- (LSOrdering)ordering {
  return self->ordering;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"documentList"]) {
    [self setDocumentList:_value];
    return;
  }
  if ([_key isEqualToString:@"sortAttribute"]) {
    [self setSortAttribute:_value];
    return;
  }
  if ([_key isEqualToString:@"ordering"]) {
    [self setOrdering:[_value intValue]];
    return;
  }
  
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"documentList"])
    return [self documentList];
  if ([_key isEqualToString:@"sortAttribute"])
    return [self sortAttribute];
  if ([_key isEqualToString:@"ordering"])
    return [NSNumber numberWithInt:[self ordering]];
  return [super valueForKey:_key];
}

@end /* LSFilterAndSortFolderCommand */
