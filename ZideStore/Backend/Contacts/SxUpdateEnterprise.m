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

#include "SxUpdateEnterprise.h"
#include "common.h"
#include "NSMutableDictionary+SetSafeObject.h"

@implementation SxUpdateEnterprise

/*

 expect the following attrs:


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
    associatedCategories = "'Favoriten','Festtagsgrüße','Geschenke','Hauptkunde','Schlüsselpersonen'";
    associatedContacts = aaaaa;
    description = Q204700aaa;
    email = "email@111.deaaa";
    phoneNumbers = {
        "01_tel" = Geschaeftlich;
        "10_fax" = "fax mobil";
    };
    showEmailAs = "aaQ204700aaa (email@111.deaaa)";
    url = "http://www.1111.swa";
}

*/

- (Class)fetchObjectClass {
  return NSClassFromString(@"SxFetchEnterprise");
}

- (NSString *)setCommand {
  return @"enterprise::set";
}
- (NSString *)newCommand {
  return @"enterprise::new";
}

- (NSMutableDictionary *)checkForObjectModifications:(id)_eo
  in:(NSMutableDictionary *)_dict
{
  NSMutableDictionary *upd;
  id                  tmp;
  
  upd = [super checkForObjectModifications:_eo in:_dict];

  if ((tmp = [_dict valueForKey:@"email1"])) {
    if (![[_eo valueForKey:@"email"] isEqual:tmp]) {
      [upd setSafeObject:tmp forKey:@"email1"];
    }
  }

  return upd;
}

- (NSMutableDictionary *)setObjectValues:(NSDictionary *)_vars {
  NSMutableDictionary *result;

  result = [super setObjectValues:_vars];
  
  [result setSafeObject:[_vars objectForKey:@"description"]
          forKey:@"description"];
  [result setSafeObject:[_vars objectForKey:@"email1"]
          forKey:@"email"];
  [result setSafeObject:[_vars objectForKey:@"nickname"]
          forKey:@"firstname"];
  return result;
}

- (id)update {
  NSDictionary *phones;

  [self updateAddress:@"ship"
        values:[self->attrs objectForKey:@"other_addr"]];
  [self updateAddress:@"bill"
        values:[self->attrs objectForKey:@"business_addr"]];
  [self updateAddress:@"private"
        values:[self->attrs objectForKey:@"private_addr"]];

  phones = [self->attrs objectForKey:@"phoneNumbers"];

  return [super update];
}

@end  /* SxUpdateEnterprise */
