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

#import "common.h"
#import "LSFilterAndSortDocCommand.h"

@implementation LSFilterAndSortDocCommand

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    ordering = LSAscendingOrder;
  }
  return self;
}

- (void)dealloc {
  [self->sortAttribute release];
  [self->documentList release];
  [super dealloc];
}

// command methods

- (void)_executeInContext:(id)_context {
  NSMutableArray *filteredList  = [NSMutableArray new];
  NSEnumerator   *docEnumerator = [self->documentList objectEnumerator];
  id             document       = nil;
  id             sCmd           = LSLookupCommand(@"system", @"sort");
  
  while ((document = [docEnumerator nextObject])) 
    if (![[document valueForKey:@"isFolder"] intValue]) 
      [filteredList addObject:document];

  if (self->sortAttribute) {
    NSArray *sortedList = nil;
    
    [sCmd takeValue:filteredList forKey:@"sortList"];
    RELEASE(filteredList);
    [sCmd takeValue:self->sortAttribute forKey:@"sortAttribute"];
    [sCmd takeValue:[NSNumber numberWithInt:self->ordering] forKey:@"ordering"];
    sortedList = [sCmd runInContext:_context];
    [self setReturnValue:sortedList];
  }
  else {
    [self setReturnValue:filteredList];
    RELEASE(filteredList); filteredList = nil;
  }
}

// accessors

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

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"documentList"]) {
    [self setDocumentList:_value];
    return;
  }
  else  if ([_key isEqualToString:@"sortAttribute"]) {
    [self setSortAttribute:_value];
    return;
  }
  else if ([_key isEqualToString:@"ordering"]) {
    [self setOrdering:[_value intValue]];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"documentList"])
    return [self documentList];
  else if ([_key isEqualToString:@"sortAttribute"])
    return [self sortAttribute];
  else if ([_key isEqualToString:@"ordering"])
    return [NSNumber numberWithInt:[self ordering]];
  return [super valueForKey:_key];
}

@end
