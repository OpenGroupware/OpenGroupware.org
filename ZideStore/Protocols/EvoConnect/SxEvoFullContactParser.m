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
// $Id: SxEvoFullContactParser.m 1 2004-08-20 11:17:52Z znek $

#include "SxEvoFullContactParser.h"
#include "common.h"

@implementation SxEvoFullContactParser

static inline id attrV(id _obj) 
{
  static NSNull *NSNullValue = nil;
  
  if (NSNullValue == nil)
    NSNullValue = [[NSNull null] retain];

  if ([_obj isNotNull])
    return _obj;

  return NSNullValue;
}

+ (id)parserWithContext:(id)_ctx {
  return [[[self alloc] initWithContext:_ctx] autorelease];
}
- (id)initWithContext:(id)_ctx {
  if ((self = [super init])) {
    ASSIGN(self->context, _ctx);
  }
  return self;
}

- (void)dealloc {
  [self->context release];
  [super dealloc];
}

/* rendering */

- (NSString *)_queryStringForKind:(NSString *)_kind attr:(NSString *)_attr {
  NSString *result;
  
  if ([_kind length] == 0)

    // maybe we should re-map that in the mapping list
    if ([_attr isEqualToString:@"PostalCode"])
      result = @"zip";
    else
      result =  [_attr lowercaseString];
  else {
    result = [_kind stringByAppendingString:_attr];

    if (![_kind isEqualToString:@"home"])
      result = [result lowercaseString];
  }
  return result;
}
  
- (NSDictionary *)addressFor:(NSString *)_kind
                      record:(NSDictionary *)_record {
  NSMutableDictionary *dict;
  id                  tmp;

  dict = [NSMutableDictionary dictionaryWithCapacity:5];
  
  tmp = attrV([_record objectForKey:
                       [self _queryStringForKind:_kind attr:@"City"]]);
  [dict setObject:tmp forKey:@"city"];
  
  tmp = attrV([_record objectForKey:
                       [self _queryStringForKind:_kind attr:@"Country"]]);
  [dict setObject:tmp forKey:@"country"];

  tmp = attrV([_record objectForKey:
                       [self _queryStringForKind:_kind attr:@"State"]]);
  [dict setObject:tmp forKey:@"state"];

  tmp = attrV([_record objectForKey:
                       [self _queryStringForKind:_kind attr:@"Street"]]);
  [dict setObject:tmp forKey:@"street"];
  
  tmp = attrV([_record objectForKey:
                       [self _queryStringForKind:_kind attr:@"PostalCode"]]);
  [dict setObject:tmp forKey:@"zip"];

  tmp = attrV([_record objectForKey:
                     [self _queryStringForKind:_kind attr:@"PostOfficeBox"]]);
  [dict setObject:tmp forKey:@"name3"];

  return dict;
}

- (NSMutableDictionary *)parseEntry:(id)_entry {
  NSMutableDictionary *result;

  // this looks stupid, but I want to be compatible with the ZL stuff
  result = [NSMutableDictionary dictionaryWithCapacity:64];
  return result;
}


@end /* SxEvoFullContactParser */
