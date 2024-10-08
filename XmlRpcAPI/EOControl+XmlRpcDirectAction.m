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

#include "EOControl+XmlRpcDirectAction.h"
#include <EOControl/EOControl.h>
#include "common.h"
#include <Foundation/NSEnumerator.h>

@implementation EOFetchSpecification(XmlRpcDirectAction)

- (id)initWithDictionaryBaseValue:(NSDictionary *)_baseValue {
  if ((self = [self init])) {
    id tmp;

    if ((tmp = [_baseValue objectForKey:@"qualifier"]) != nil) {
      tmp = ([tmp isKindOfClass:[NSDictionary class]])
        ? [EOQualifier qualifierToMatchAllValues:tmp]
	: [EOQualifier qualifierWithQualifierFormat:tmp];
      
      [self setQualifier:tmp];
    }
    if ((tmp = [_baseValue objectForKey:@"sortOrderings"]) != nil) {
        NSArray        *sos = nil;
        EOSortOrdering *so;

        if ([tmp isKindOfClass:[NSArray class]]) {
          NSMutableArray *result  = nil;
          NSEnumerator   *objEnum = [tmp objectEnumerator];
          id             obj;

          result = [NSMutableArray arrayWithCapacity:8];
          while ((obj = [objEnum nextObject])) {
            so = [[EOSortOrdering alloc] initWithBaseValue:obj];
            [so autorelease];
            if (so)
              [result addObject:so];
          }
          sos = [NSArray arrayWithArray:result];
        }
        else {
          so = [[[EOSortOrdering alloc] initWithBaseValue:tmp] autorelease];
          
          if (so)
            sos = [NSArray arrayWithObject:so];
        }
        [self setSortOrderings:sos];
    }
    if ((tmp = [_baseValue objectForKey:@"fetchLimit"])) {
        if ([tmp respondsToSelector:@selector(intValue)])
          [self setFetchLimit:[tmp intValue]];
    }
    if ((tmp = [_baseValue objectForKey:@"hints"])) {
        if ([tmp isKindOfClass:[NSDictionary class]])
          [self setHints:tmp];
    }

    if ([self->hints objectForKey:@"addDocumentsAsObserver"] == nil) {
        NSMutableDictionary *hnts;

        hnts = [[NSMutableDictionary alloc] initWithDictionary:self->hints];
        [hnts setObject:[NSNumber numberWithBool:NO]
              forKey:@"addDocumentsAsObserver"];
        [self setHints:hnts];
        [hnts release];
    }
  }
  return self;
}

- (id)initWithStringBaseValue:(NSString *)_baseValue {
  EOQualifier *qual = nil;
    
  qual = [EOQualifier qualifierWithQualifierFormat:_baseValue];
  self = [self initWithEntityName:nil
	       qualifier:qual
	       sortOrderings:nil
	       usesDistinct:NO isDeep:NO hints:nil];
  return self;
}

- (id)initWithBaseValue:(id)_baseValue {
  if ([_baseValue isKindOfClass:[self class]])
    return [_baseValue copy];
  
  if ([_baseValue isKindOfClass:[NSDictionary class]])
    return [self initWithDictionaryBaseValue:_baseValue];

  if ([_baseValue isKindOfClass:[NSString class]])
    return [self initWithStringBaseValue:_baseValue];
  
  [self release];
  return nil;
}

@end /* EOFetchSpecification(XmlRpcDirectAction) */

@implementation EOSortOrdering(XmlRpcDirectAction)

- (id)initWithBaseValue:(id)_baseValue {
  NSString *k  = nil;
  SEL      sel = EOCompareAscending;

  if ([_baseValue isKindOfClass:[self class]])
    return [_baseValue copy];
  
  if ([_baseValue isKindOfClass:[NSDictionary class]]) {
    NSString *tmp;
      
    k = [(NSDictionary *)_baseValue objectForKey:@"key"];
    tmp = [[(NSDictionary *)_baseValue objectForKey:@"selector"] stringValue];
    if (tmp != nil) {
      if ([tmp isEqualToString:@"compareAscending"])
        sel = EOCompareAscending;
      else if ([tmp isEqualToString:@"compareDescending"])
        sel = EOCompareDescending;
      else if ([tmp isEqualToString:@"compareCaseInsensitiveAscending"])
        sel = EOCompareDescending;
      else if ([tmp isEqualToString:@"compareCaseInsensitiveDescending"])
        sel = EOCompareDescending;
    }
  }
  else if ([_baseValue isKindOfClass:[NSString class]]) {
    k = _baseValue;
  }
  return [self initWithKey:k selector:sel];
}

@end /* EOSortOrdering(XmlRpcDirectAction) */


@implementation EOQualifier(XmlRpcDirectAction)

+ (EOQualifier *)qualifierToMatchAllValues:(NSDictionary *)_values
  selector:(SEL)_sel
{
  /* AND qualifier */
  NSEnumerator *keys;
  NSString     *key;
  NSArray      *array;
  unsigned i;
  id qualifiers[[_values count] + 1];
  
  keys = [_values keyEnumerator];
  for (i = 0; (key = [keys nextObject]); i++) {
    id value;
    
    value = [_values objectForKey:key];
    qualifiers[i] =
      [[EOKeyValueQualifier alloc]
                            initWithKey:key
                            operatorSelector:_sel
                            value:value];
    qualifiers[i] = [qualifiers[i] autorelease];
  }
  array = [NSArray arrayWithObjects:qualifiers count:i];
  return [[[EOAndQualifier alloc] initWithQualifierArray:array] autorelease];
}

@end /* EOQualifier(XmlRpcDirectAction) */
