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

#include "SxFetchPerson.h"
#include <EOControl/EOControl.h>
#include "common.h"

/*
  returns a dictionary with person attributes


  this attributes will be returned

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
    "comment-compressed" = ""
    anniversary = "2003-03-13 00:00:00 +0100";
    assistantName = Assistent;
    associatedCategories = "'Favoriten','Feiertag'";
    associatedCompany = Firma22;
    associatedContacts = "Ein Privater Kontaktq";
    bday = "2003-03-20 00:00:00 +0100";
    bossName = Vorgesetzteqqqqqqqqq;
    department = Abteilung;
    email1 = "email@email.de";
    email2 = "eeema122222@d2222.de";
    enterpriseName = "";
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
    objectVersion = 59;
    office = Buero;
    partnerName = Partner;
    phoneNumbers = {
        "01_tel" = "+49 0078 qqqqqqqqqqqq";
        "03_tel_funk" = "+49 010";
        "05_tel_private" = "+49 008";
        "10_fax" = "+49 009";
    };
    pkey = 209830;
    profession = Beruf;
    showEmail2As = "Vorname Weitere";
    showEmailAs = "Vorname Weitere";
    title = Positionssaaaa11111aa;
    url = "http://www.webseite.de";
    version = 59;
}
  
*/

@implementation SxFetchPerson

static BOOL debugOn = NO;

static inline NSString *attrV(id _v) {
  return [_v isNotNull] ? _v : (id)@"";
}

- (NSString *)entityName {
  return @"Person";
}

- (NSString *)getName {
  return @"person::get";
}

- (NSString *)enterpriseName {
  NSDictionary *record;
  
  record = [[self->ctx runCommand:@"person::enterprises",
                      @"object", [self eo], nil] lastObject];
  return attrV([record objectForKey:@"description"]);
}
  
- (NSDictionary *)nameAttributes {
  NSMutableDictionary *dict;
  id                  e;

  dict = [NSMutableDictionary dictionaryWithCapacity:16];
  e    = [self eo];
  
#if 0
  [dict setObject:attrV([e valueForKey:@"salutation"])
        forKey:@"salutation"];
#endif
  
  [dict setObject:attrV([e valueForKey:@"firstname"])   forKey:@"givenName"];
  [dict setObject:attrV([e valueForKey:@"middlename"])
        forKey:@"middleName"];
  [dict setObject:attrV([e valueForKey:@"description"]) forKey:@"nickname"];
  [dict setObject:attrV([e valueForKey:@"name"])        forKey:@"name"];

  [dict setObject:attrV([e valueForKey:@"fileas"])      forKey:@"fileas"];
  [dict setObject:attrV([e valueForKey:@"nameTitle"])   forKey:@"nameTitle"];
  [dict setObject:attrV([e valueForKey:@"nameAffix"])   forKey:@"nameAffix"];
  
  //  [dict setObject:attrV([e valueForKey:@"emailAlias"])
  //        forKey:@"emailAlias"];
  //  [dict setObject:attrV([e valueForKey:@"sensitivity"])
  //        forKey:@"sensitivity"];
  
  return dict;
}

- (NSDictionary *)otherKeys {
  NSMutableDictionary *dict;
  id tmp;

  dict = [NSMutableDictionary dictionaryWithCapacity:2];

  [dict addEntriesFromDictionary:[super otherKeys]];

  tmp = [[self eo] valueForKey:@"associatedCompany"];
  if (![tmp isNotNull])
    tmp = [self enterpriseName];
  if (![tmp isNotNull])
    tmp = @"";
  [dict setObject:tmp forKey:@"associatedCompany"];
  
  [dict setObject:attrV([[self eo] valueForKey:@"email1"]) forKey:@"email1"];
  return dict;
}

- (NSDictionary *)dictWithPrimaryKey:(NSNumber *)_number {
  NSMutableDictionary *res;
  id tmp;
  
  [self clearVars];
  [self loadEOForID:_number];
  
  if (![self eo]) {
    [self logWithFormat:@"missing eo-object for %@", _number];
    return nil;
  }

  res = [NSMutableDictionary dictionaryWithCapacity:32];
  
  if ((tmp = [self addressForType:@"location"]))
    [res setObject:tmp forKey:@"business_addr"];
  if ((tmp = [self addressForType:@"private"]))
    [res setObject:tmp forKey:@"private_addr"];
  if ((tmp = [self addressForType:@"mailing"]))
    [res setObject:tmp forKey:@"other_addr"];
  
  if ((tmp = [self enterpriseName]))
    [res setObject:tmp forKey:@"enterpriseName"];
  
  if ((tmp = [self nameAttributes])) [res addEntriesFromDictionary:tmp];
  if ((tmp = [self contactKeys]))    [res addEntriesFromDictionary:tmp];
  if ((tmp = [self otherKeys]))      [res addEntriesFromDictionary:tmp];
  
  [self clearVars];

  if (debugOn) {
    NSLog(@"%s:%d return %@", __PRETTY_FUNCTION__, __LINE__,
          res);
  }
  return res;
}
  
@end /* SxFetchPerson */
