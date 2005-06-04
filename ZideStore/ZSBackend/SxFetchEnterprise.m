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

#include "SxFetchEnterprise.h"
#include "common.h"

/*
  returns a dictionary with person attributes

  dictionary with this attrs:

  {
    "addr_bill" = {
        city = ort;
        country = region;
        state = bundesland;
        street = strasse;
        zip = plz;
    };
    "addr_ship" = {
        city = "";
        country = "";
        state = "";
        street = "";
        zip = "";
    };
    "comment-compressed" = "";
    associatedCategories = "'Favoriten','Festtagsgrüße'";
    associatedContacts = "Ein Privater Kontakt !!!!!!!!";
    description = Q204700;
    email1 = "email@111.de";
    objectVersion = 16;
    phoneNumbers = {
        "01_tel" = Geschaeftlich;
        "10_fax" = "fax mobil";
    };
    pkey = 204700;
    showEmailAs = "";
    title = "";
    url = "http://www.1111.sw";
    version = 16;
}
*/

@implementation SxFetchEnterprise

static inline NSString *attrV(id _v) {
  return [_v isNotNull] ? _v : @"";
}

- (NSString *)entityName {
  return @"Enterprise";
}
- (NSString *)getName {
  return @"enterprise::get";
}

- (NSString *)enterpriseName {
  NSDictionary *enterprise;
  
  enterprise = [[self->ctx runCommand:@"person::enterprises",
                     @"object", [self eo], nil] lastObject];
  return attrV([enterprise objectForKey:@"description"]);
}
  
- (NSDictionary *)nameAttributes {
  NSMutableDictionary *dict;
  id                  e;

  e    = [self eo];

  dict = [NSMutableDictionary dictionaryWithCapacity:2];

  [dict setObject:attrV([e valueForKey:@"description"]) forKey:@"description"];
  [dict setObject:attrV([e valueForKey:@"firstname"])   forKey:@"nickname"];
  [dict setObject:attrV([e valueForKey:@"fileas"])      forKey:@"fileas"];

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
  
  [res setObject:[self addressForType:@"bill"] forKey:@"business_addr"];
  [res setObject:[self addressForType:@"ship"] forKey:@"other_addr"];
  [res setObject:[self addressForType:@"private"] forKey:@"private_addr"];

  [res addEntriesFromDictionary:[self nameAttributes]];
  [res addEntriesFromDictionary:[self contactKeys]];
  [res addEntriesFromDictionary:[self otherKeys]];

  [self clearVars];
  
  return res;
}
  
@end  /* SxFetchEnterprise */
