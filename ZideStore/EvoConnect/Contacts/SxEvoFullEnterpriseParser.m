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

#include "SxEvoFullEnterpriseParser.h"
#include "common.h"

@implementation SxEvoFullEnterpriseParser

static inline id attrV(id _obj)  {
  static NSNull *NSNullValue = nil;
  
  if (NSNullValue == nil)
    NSNullValue = [[NSNull null] retain];

  if ([_obj isNotNull])
    return _obj;

  return NSNullValue;
}

- (void)setName:(NSDictionary *)_entry object:(NSMutableDictionary *)object_ {
  NSString *descr;
  
  descr = [_entry objectForKey:@"davDisplayName"];
  if ([descr length] != 0)
    [object_ setObject:descr forKey:@"description"];
  else
    [object_ setObject:[_entry valueForKey:@"cn"] forKey:@"description"];
}

- (NSDictionary *)phones:(NSDictionary *)_entry {
  NSMutableDictionary *dict;

  dict = [NSMutableDictionary dictionaryWithCapacity:2];

  [dict setObject:attrV([_entry objectForKey:@"telephoneNumber"])
        forKey:@"01_tel"];

  [dict setObject:attrV([_entry objectForKey:@"homefax"])
        forKey:@"10_fax"];

  return dict;
}

- (void)setEmail:(NSDictionary *)_entry
  object:(NSMutableDictionary *)object_
{
  [object_ setObject:attrV([_entry objectForKey:@"email1"])
           forKey:@"email"];

  [object_ setObject:attrV([_entry objectForKey:@"businesshomepage"])
           forKey:@"url"];
}

- (void)setOtherKeys:(NSDictionary *)_entry
  object:(NSMutableDictionary *)object_
{
}

- (id)parseEntry:(id)_entry {
  NSMutableDictionary *result;

  result = [super parseEntry:_entry];

  [result setObject:[self addressFor:@"business" record:_entry]
          forKey:@"addr_bill"];

  [result setObject:[self addressFor:@"other" record:_entry]
          forKey:@"addr_ship"];

  [result setObject:[self phones:_entry] forKey:@"phoneNumbers"];

  [self setEmail:_entry      object:result];
  [self setName:_entry       object:result];
  [self setOtherKeys:_entry  object:result];

  return result;
}

@end /* SxEvoFullEnterpriseParser */
