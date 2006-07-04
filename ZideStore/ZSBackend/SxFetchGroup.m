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

#include "SxFetchGroup.h"
#include "common.h"

@implementation SxFetchGroup

static inline NSString *attrV(id _v) {
  return [_v isNotNull] ? _v : (id)@"";
}

- (NSString *)entityName {
  return @"Team";
}

- (NSString *)getName {
  return @"team::get";
}

- (NSString *)enterpriseName {
  // TODO: this method is a DUP in various classes
  NSDictionary *record;

  record = [[self->ctx runCommand:@"person::enterprises",
                 @"object", [self eo], nil] lastObject];
  return attrV([record objectForKey:@"description"]);
}

- (NSDictionary *)nameAttributes {
  NSMutableDictionary *dict;
  id                  e;

  e    = [self eo];

  dict = [NSMutableDictionary dictionaryWithCapacity:1];

  [dict setObject:attrV([e valueForKey:@"description"]) forKey:@"description"];
  
  return dict;
}

- (NSDictionary *)otherKeys {
  NSMutableDictionary *dict;

  dict = [NSMutableDictionary dictionaryWithCapacity:2];
  [dict addEntriesFromDictionary:[super otherKeys]];
  [dict setObject:attrV([[self eo] valueForKey:@"email"]) forKey:@"email1"];
  return dict;
}

- (NSDictionary *)dictWithPrimaryKey:(NSNumber *)_number {
  NSMutableDictionary *res;

  [self clearVars];
  [self loadEOForID:_number];
  
  if (![self eo]) {
    NSLog(@"missing eo-object for %@", _number);
    return nil;
  }
  
  res = [NSMutableDictionary dictionaryWithCapacity:32];
  [res addEntriesFromDictionary:[self nameAttributes]];
  [res addEntriesFromDictionary:[self otherKeys]];

  [self clearVars];
  
  return res;
}
  
@end  /* SxFetchGroup */
