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
// $Id: SxUpdatePerson.m 1 2004-08-20 11:17:52Z znek $

#include "SxUpdatePerson.h"
#include "common.h"
#include "NSMutableDictionary+SetSafeObject.h"

@implementation SxUpdatePerson

/*
  expect the following attrs:


  {
    "addr_location" = {
        city = ort;
        country = land;
        state = region;
        street = strasse;
        zip = plz;
    };
    "addr_mailing" = {
        city = "";
        country = "";
        state = "";
        street = "";
        zip = "";
    };
    "addr_private" = {
        city = "";
        country = "";
        state = "";
        street = "";
        zip = "";
    };
    "comment-compressed" = "";
    anniversary = "2003-03-12 23:00:00 -0000";
    assistantName = Assistent;
    associatedCategories = "'Favoriten','Persönlich','Schlüsselpersonen'";
    associatedCompany = Firma22;
    associatedContacts = "Ein Privater Kontaktq";
    bday = "2003-03-19 23:00:00 -0000";
    bossName = Vorgesetzteqqqqqqqqq;
    department = Abteilung;
    email1 = "email@email.de";
    email2 = "eeema122222@d2222.de";
    fburl = "http://free-busy.de";
    fileas = "Nachname, Vorname Weitere Vornamen";
    givenName = Vorname;
    imAddress = "im-addresseeeeee";
    middleName = "Weitere Vornamen";
    name = Nachname;
    nameAffix = Namenszusatz;
    nameTitle = w1wwAnr1ed1e;
    netMeetingSettings = "'callto://server/alias'";
    nickname = sPITZNME;
    office = Buero;
    partnerName = Partner;
    phoneNumbers = {
        "01_tel" = "+49 0078 qqqqqqqqqqqq";
        "03_tel_funk" = "+49 010";
        "05_tel_private" = "+49 008";
        "10_fax" = "+49 009";
    };
    profession = Beruf;
    showEmail2As = "w1wwAnr1ed1e Vorname (eeema122222@d2222.de)";
    showEmailAs = "w1wwAnr1ed1e Vorname  (email@email.de)";
    title = Positionassaaaa11111aa;
    url = "http://www.webseite.de";
}

*/


- (Class)fetchObjectClass {
  return NSClassFromString(@"SxFetchPerson");
}

- (NSString *)setCommand {
  return @"person::set";
}

- (NSString *)newCommand {
  return @"person::new";
}

- (NSMutableDictionary *)setObjectValues:(NSDictionary *)_vars {
  NSMutableDictionary *result;

  result = [super setObjectValues:_vars];
  
  [result setSafeObject:[_vars objectForKey:@"email1"]
          forKey:@"email1"];
  [result setSafeObject:[_vars objectForKey:@"givenName"]
          forKey:@"firstname"];
  [result setSafeObject:[_vars objectForKey:@"middleName"]
          forKey:@"middlename"];
  [result setSafeObject:[_vars objectForKey:@"nickname"]
          forKey:@"description"];
  [result setSafeObject:[_vars objectForKey:@"name"]
          forKey:@"name"];

  [result setSafeObject:[_vars objectForKey:@"nameTitle"]
          forKey:@"nameTitle"];
  [result setSafeObject:[_vars objectForKey:@"nameAffix"]
          forKey:@"nameAffix"];

  //  [result setSafeObject:[_vars objectForKey:@"emailAlias"]
  //          forKey:@"emailAlias"];

  [result setSafeObject:[_vars objectForKey:@"salutation"]
          forKey:@"salutation"];  
  [result setSafeObject:[_vars objectForKey:@"sensitivity"]
          forKey:@"sensitivity"];

  return result;
}

- (NSMutableDictionary *)checkForObjectModifications:(id)_eo
  in:(NSMutableDictionary *)_dict
{
  NSMutableDictionary *upd;
  id                  tmp;
  
  upd = [super checkForObjectModifications:_eo in:_dict];

  tmp = [_dict valueForKey:@"email1"];
  if (tmp) {
    if (![[_eo valueForKey:@"email1"] isEqual:tmp]) {
      [upd setSafeObject:tmp forKey:@"email1"];
    }
  }
  return upd;
}


- (id)update {
  [self updateAddress:@"location"
        values:[self->attrs objectForKey:@"business_addr"]];
  
  [self updateAddress:@"private"
        values:[self->attrs objectForKey:@"private_addr"]];

  [self updateAddress:@"mailing"
        values:[self->attrs objectForKey:@"other_addr"]];

  return [super update];
}

@end /* SxUpdatePerson */
