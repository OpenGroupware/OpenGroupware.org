/*
  Copyright (C) 2000-2003 SKYRIX Software AG

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

#include "EOQualifier+Additions.h"
#include "common.h"

@implementation NSArray(QualifierArray)

- (int)indexOfKeyValueQualifierForKey:(NSString *)_key {
  // flat lookup of a key-value qualifier
  unsigned i, count;
  
  if ((count = [self count]) == 0)
    return NSNotFound;
  
  for (i = 0; i < count; i++) {
    EOKeyValueQualifier *q;
    
    q = [self objectAtIndex:i];
    if (![q isKindOfClass:[EOKeyValueQualifier class]])
      continue;
    
    if ([[q key] isEqualToString:_key])
      return i;
  }
  return NSNotFound;
}

- (int)indexOfQualifierOfClass:(Class)_clazz {
  // flat lookup of a key-value qualifier
  unsigned i, count;
  
  if ((count = [self count]) == 0)
    return NSNotFound;
  
  for (i = 0; i < count; i++) {
    EOQualifier *q;
    
    q = [self objectAtIndex:i];
    
    if ([q isKindOfClass:_clazz])
      return i;
  }
  return NSNotFound;
}

- (int)indexOfAndOrQualifier {
  // flat lookup of a key-value qualifier
  unsigned i, count;
  
  if ((count = [self count]) == 0)
    return NSNotFound;
  
  for (i = 0; i < count; i++) {
    EOQualifier *q;
    
    q = [self objectAtIndex:i];
    
    if ([q isKindOfClass:[EOOrQualifier class]])
      return i;
    if ([q isKindOfClass:[EOAndQualifier class]])
      return i;
  }
  return NSNotFound;
}

- (NSDictionary *)generalizeKeyValueLikeQualifiers:(NSArray **)_remaining {
  NSMutableDictionary *md = nil;
  NSMutableArray *rest = nil;
  unsigned i, count;
  
  if (_remaining) *_remaining = nil;
  if ((count = [self count]) == 0)
    return nil;

  for (i = 0; i < count; i++) {
    EOQualifier *q;
    
    q = [self objectAtIndex:i];
    
    if (![q isKindOfClass:[EOKeyValueQualifier class]]) {
      BOOL isLike;
      
#if GNU_RUNTIME
      isLike = sel_eq([(EOKeyValueQualifier *)q selector], 
		      EOQualifierOperatorLike);
#else
      isLike = [(EOKeyValueQualifier *)q selector] == EOQualifierOperatorLike
	? YES : NO;
#endif
      
      if (isLike) {
	NSMutableArray *keys = nil;
	
	if (md == nil) 
	  md = [NSMutableDictionary dictionaryWithCapacity:count];
	else
	  keys = [md objectForKey:[(EOKeyValueQualifier *)q value]];
	if (keys == nil) {
	  keys = [[NSMutableArray alloc] initWithCapacity:4];
	  [md setObject:keys forKey:[(EOKeyValueQualifier *)q value]];
	  [keys release];
	}
	[keys addObject:[(EOKeyValueQualifier *)q key]];
	continue;
      }
    }
    
    if (rest == nil) rest = [NSMutableArray arrayWithCapacity:count];
  }
  *_remaining = rest;
  return md;
}

@end /* NSArray(QualifierArray) */

@implementation NSMutableArray(QualifierArray)

- (BOOL)removeQualifier:(EOQualifier *)_qualifier {
  // remove a qualifier, returns YES if it did exists, otherwise NO
  unsigned idx;
  
  if (_qualifier == nil) 
    return NO;
  
  if ((idx = [self indexOfObject:_qualifier]) == NSNotFound)
    return NO;
  
  [self removeObjectAtIndex:idx];
  
  return YES;
}

- (id)removeKeyValueQualifierForKey:(NSString *)_key operation:(SEL)_sel {
  /* removes a KVC qualifier, gives back the value if found */
  EOKeyValueQualifier *kvq;
  unsigned idx;
  id value;
  
  if ((idx = [self indexOfKeyValueQualifierForKey:_key]) == NSNotFound)
    return nil;
  
  kvq = [self objectAtIndex:idx];
  // TODO: check operation
  
  value = [[[kvq value] retain] autorelease];
  [self removeObjectAtIndex:idx];
  return value;
}

@end /* NSMutableArray(QualifierArray) */
