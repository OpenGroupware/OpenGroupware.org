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

#include "SxEvoFullPersonParser.h"
#include "common.h"

@implementation SxEvoFullPersonParser

static inline id attrV(id _obj) 
{
  static NSNull *NSNullValue = nil;
  
  if (NSNullValue == nil)
    NSNullValue = [[NSNull null] retain];

  if ([_obj isNotNull])
    return _obj;

  return NSNullValue;
}

- (void)setName:(NSDictionary *)_entry object:(NSMutableDictionary *)object_ {
  NSString *tmp;

  // name title doesn't seem to be transmitted on its own,
  // so we need to extract it ourselves

  if ((tmp = [_entry valueForKey:@"cn"]) != nil) {
    NSString *possibleTitle;
    NSString *n;
    BOOL isTitle = YES;
    
    possibleTitle = [[tmp componentsSeparatedByString:@" "]
                          objectAtIndex:0];

    if ((n = [_entry valueForKey:@"givenName"]) != nil) {
      if ([n hasPrefix:possibleTitle])
        isTitle = NO;
    }
    else if ((n = [_entry valueForKey:@"middlename"]) != nil) {
      if ([n hasPrefix:possibleTitle])
        isTitle = NO;
    }
    else {
      if ((n = [_entry valueForKey:@"sn"]) != nil) {
        if ([n hasPrefix:possibleTitle])
          isTitle = NO;
      }
    }

    if (isTitle)
      [object_ setObject:attrV(possibleTitle) forKey:@"nameTitle"];
    else
      [object_ setObject:[NSNull null] forKey:@"nameTitle"];
  }
  
  [object_ setObject:attrV([_entry objectForKey:@"givenName"])
           forKey:@"givenName"];

  [object_ setObject:attrV([_entry objectForKey:@"middleName"])
           forKey:@"middleName"];

  [object_ setObject:attrV([_entry valueForKey:@"nickname"])
           forKey:@"nickname"];
  
  [object_ setObject:attrV([_entry valueForKey:@"sn"])
           forKey:@"name"];

  [object_ setObject:attrV([_entry valueForKey:@"department"])
           forKey:@"department"];

  [object_ setObject:attrV([_entry valueForKey:@"roomnumber"])
           forKey:@"office"];

  [object_ setObject:attrV([_entry valueForKey:@"spousecn"])
           forKey:@"partnerName"];

  [object_ setObject:attrV([_entry valueForKey:@"manager"])
           forKey:@"bossName"];

  [object_ setObject:attrV([_entry valueForKey:@"profession"])
           forKey:@"profession"];

  [object_ setObject:attrV([_entry valueForKey:@"secretarycn"])
           forKey:@"assistantName"];

  [object_ setObject:attrV([_entry valueForKey:@"fburl"])
           forKey:@"fburl"];

  [object_ setObject:attrV([_entry valueForKey:@"fileas"])
           forKey:@"fileas"];

  [object_ setObject:attrV([_entry valueForKey:@"namesuffix"])
           forKey:@"nameAffix"];

  [object_ setObject:attrV([_entry valueForKey:@"o"])
           forKey:@"associatedCompany"];

  // these attributes are not transmitted by Evolution
  [object_ setObject:[NSNull null] forKey:@"imAddress"];
  [object_ setObject:[NSNull null] forKey:@"associatedContacts"];
  [object_ setObject:[NSNull null] forKey:@"associatedCategories"];
}

- (NSDictionary *)phones:(NSDictionary *)_entry {
  NSMutableDictionary *dict;

  dict = [NSMutableDictionary dictionaryWithCapacity:4];

  [dict setObject:attrV([_entry objectForKey:@"telephoneNumber"])
        forKey:@"01_tel"];

  [dict setObject:attrV([_entry objectForKey:@"facsimiletelephonenumber"])
        forKey:@"10_fax"];

  [dict setObject:attrV([_entry objectForKey:@"homePhone"])
        forKey:@"05_tel_private"];
  
  [dict setObject:attrV([_entry objectForKey:@"mobile"])
        forKey:@"03_tel_funk"];

  return dict;
}

- (void)setEmail:(NSDictionary *)_entry
  object:(NSMutableDictionary *)object_
{
  [object_ setObject:attrV([_entry objectForKey:@"email1"])
           forKey:@"email1"];

  [object_ setObject:attrV([_entry objectForKey:@"email2"])
           forKey:@"email2"];

  [object_ setObject:attrV([_entry objectForKey:@"businesshomepage"])
           forKey:@"url"];
}

- (NSCalendarDate *)_adjustedDateForDavString:(NSString *)_str {
  NSCalendarDate *cdate;

  if (_str == nil)
    return nil;
  
  cdate = [NSCalendarDate dateWithExDavString:[_str stringValue]];
  return [cdate dateByAddingYears:0 months:0 days:0 hours:12 minutes:0
                 seconds:0];
}

- (void)setOtherKeys:(NSDictionary *)_entry
  object:(NSMutableDictionary *)object_
{
  [object_ setObject:attrV([_entry objectForKey:@"title"])
           forKey:@"title"];

  [object_ setObject:attrV([_entry objectForKey:@"comment"])
           forKey:@"comment"];
  
  [object_ setObject:attrV([self _adjustedDateForDavString:
                                 [_entry objectForKey:@"bday"]])
           forKey:@"bday"];
    
  [object_ setObject:attrV([self _adjustedDateForDavString:
                                 [_entry objectForKey:@"weddinganniversary"]])
           forKey:@"anniversary"];
}

- (id)parseEntry:(id)_entry {
  NSMutableDictionary *result;

  result = [super parseEntry:_entry];
  
  [result setObject:[self addressFor:@"" record:_entry]
          forKey:@"addr_location"];

  [result setObject:[self addressFor:@"home" record:_entry]
          forKey:@"addr_private"];

  [result setObject:[self addressFor:@"other" record:_entry]
          forKey:@"addr_mailing"];
  
  [result setObject:[self phones:_entry] forKey:@"phoneNumbers"];

  [self setEmail:_entry      object:result];
  [self setName:_entry       object:result];
  [self setOtherKeys:_entry  object:result];
  
  return result;
}

@end /* SxEvoFullPersonParser */
