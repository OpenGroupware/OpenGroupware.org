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

#include "LSSort.h"
#include "common.h"

static Class StringClass = Nil;

static NSComparisonResult arraySorter(id obj1, id obj2, void *sortAttribute) {
  SEL compareMethod;
  id  value1;
  id  value2;

  value1 = [obj1 valueForKey:sortAttribute];
  if (![value1 isNotNull])
    return 1;
  
  value2 = [obj2 valueForKey:sortAttribute];
  if (![value2 isNotNull])
    return -1;

  if (value1 == value2) return NSOrderedSame;
  
  if (StringClass == Nil)
    StringClass = [NSString class];
  
  if ([value1 isKindOfClass:StringClass]) {
    compareMethod = @selector(caseInsensitiveCompare:);
    value1 = [value1 sortString];
    value2 = [value2 sortString];
  }
  else {
    compareMethod = @selector(compare:);
  }
  return (long)[value1 performSelector:compareMethod withObject:value2];
}
static NSComparisonResult arrayWithRelKeySorter
  (id obj1, id obj2, void *sortAttribute) 
{
  id value1 = [obj1 valueForKey:[(id)sortAttribute valueForKey:@"key"]];
  id value2 = [obj2 valueForKey:[(id)sortAttribute valueForKey:@"key"]];
  if (value1 == value2) return NSOrderedSame;
  return
    arraySorter(value1, value2, [(id)sortAttribute valueForKey:@"relKey"]);
}
static NSComparisonResult arrayDescSorter
  (id obj1, id obj2, void *sortAttribute) 
{
  id  value1;
  id  value2;
  SEL compareMethod;

  value1 = [obj1 valueForKey:sortAttribute];
  if (![value1 isNotNull])
    return 1;
  
  value2 = [obj2 valueForKey:sortAttribute];
  if (![value2 isNotNull])
    return -1;
  
  if (value1 == value2) return NSOrderedSame;
  
  if (StringClass == Nil)
    StringClass = [NSString class];
  
  if ([value1 isKindOfClass:StringClass]) {
    compareMethod = @selector(caseInsensitiveCompare:);
    value1 = [value1 sortString];
    value2 = [value2 sortString];
  } 
  else
    compareMethod = @selector(compare:);
  
  return (long)[value2 performSelector:compareMethod withObject:value1];
}
static NSComparisonResult arrayWithRelKeyDescSorter
  (id obj1, id obj2, void *sortAttribute)
{
  id value1 = [obj1 valueForKey:[(id)sortAttribute valueForKey:@"key"]];
  id value2 = [obj2 valueForKey:[(id)sortAttribute valueForKey:@"key"]];
  if (value1 == value2) return NSOrderedSame;
  return
    arrayDescSorter(value1, value2, [(id)sortAttribute valueForKey:@"relKey"]);
}

@implementation NSString(SortMiscStrings)

- (NSString *)sortString {
  // TODO: this is not really necessary and looks pretty expensive
  //       who calls this method?
  int             i, len;
  NSMutableString *sortString;
  
  len        = [self length];
  sortString = [NSMutableString stringWithCapacity:len];
  
  for (i = 0; i < len; i++) {
    unichar c;
    
    switch ((c = [self characterAtIndex:i])) {
      case 196: [sortString appendString:@"Ae"]; break;
      case 214: [sortString appendString:@"Oe"]; break;
      case 220: [sortString appendString:@"Ue"]; break;
      case 228: [sortString appendString:@"ae"]; break;
      case 246: [sortString appendString:@"oe"]; break;
      case 252: [sortString appendString:@"ue"]; break;
      case 223: [sortString appendString:@"ss"]; break;
        
      default: {
	/* TODO: *expensive* ! */
        NSString *s;
        
	if (StringClass == Nil) StringClass = [NSString class];
        s = [[StringClass alloc] initWithCharacters:&c length:1];
        [sortString appendString:s];
        [s release];
        break;
      }
    }
  }
  return sortString;
}

@end /* NSString(SortMiscStrings) */

@implementation LSSort

+ (int)version {
  return 1;
}

+ (id)sortWithArray:(NSArray *)_sortArray andContext:_sortContext {
  return [[[self alloc] initWithArray:_sortArray
                        andContext:_sortContext] autorelease];
}

- (id)init {
  if ((self = [super init])) {
    self->ordering = LSAscendingOrder;
  }
  return self;
}

- (id)initWithArray:(NSArray *)_sortArray andContext:(id)_sortContext {
  if ((self = [self init])) {
    self->sortArray   = [_sortArray   retain];
    self->sortContext = [_sortContext retain];
  }
  return self;
}

- (void)dealloc {
  [self->sortArray   release];
  [self->sortContext release];
  [super dealloc];
}

/* accessors */

- (void)setSortArray:(NSArray *)_sortArray {
  ASSIGN(sortArray, _sortArray);
}

- (void)setSortContext:_sortContext {
  ASSIGN(sortContext, _sortContext);
}

- (void)setOrdering:(LSOrdering)_ordering {
  ordering = _ordering;
}
- (LSOrdering)ordering {
  return ordering;
}
  
- (NSArray *)_sortedArrayDesc {
  return [sortArray sortedArrayUsingFunction:arrayDescSorter
                    context:self->sortContext];
}

- (NSArray *)_sortedArrayAsc {
  return [sortArray sortedArrayUsingFunction:arraySorter
                    context:self->sortContext];
}

- (NSArray *)sortedArray {
  if (self->ordering == LSDescendingOrder) 
    return [self _sortedArrayDesc];
  if (self->ordering == LSAscendingOrder)
    return [self _sortedArrayAsc];
  return  [self _sortedArrayAsc];
}

/* sorting */

- (NSArray *)sortArray:(NSArray *)_array
  inContext:(id)_context
  ordering:(LSOrdering)_ordering 
{
  NSArray *sa;

  sa = [_array sortedArrayUsingFunction:
                 _ordering == LSDescendingOrder ? arrayDescSorter : arraySorter
               context:_context];
  return sa;
}

- (NSArray *)sortArrayWithRelKey:(NSArray *)_array
  inContext:(id)_context
  ordering:(LSOrdering)_ordering 
{
  NSArray *sa;

  sa = [_array sortedArrayUsingFunction:
		 _ordering == LSDescendingOrder
                 ? arrayWithRelKeyDescSorter
                 : arrayWithRelKeySorter
               context: _context];
  return sa;
}

@end /* LSSort */
