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

#include "SxVCardPersonRenderer.h"
#include "common.h"

@implementation SxVCardPersonRenderer

- (NSString *)fullNameForObject:(id)_object {
  NSString *firstname, *lastname;

  firstname = [_object valueForKey:@"givenName"];
  lastname = [_object valueForKey:@"name"];

  if (firstname != nil) {
    if (lastname != nil)
      return [NSString stringWithFormat:@"%@ %@", firstname, lastname];
    else
      return firstname;
  }
  else {
    return (lastname != nil) ? lastname : @"No Name";
  }
}

- (NSString *)namePartsForObject:(id)_object {
  NSString *title, *firstname, *middlename, *lastname, *affix;

  title      = [_object valueForKey:@"nameTitle"];
  firstname  = [_object valueForKey:@"givenName"];
  middlename = [_object valueForKey:@"middleName"];
  lastname   = [_object valueForKey:@"name"];
  affix      = [_object valueForKey:@"nameAffix"];

  return [NSString stringWithFormat:@"%@;%@;%@;%@;%@",
                   [lastname length] ? lastname : @"",
                   [firstname length] ? firstname : @"",
                   [middlename length] ? middlename : @"",
                   [title length] ? title : @"",
                   [affix length] ? affix : @""];
}

- (NSString *)categoriesForString:(NSString *)_string {
  return [_string stringByReplacingString:@"'" withString:@""];
}

- (NSString *)vCardStringForObject:(id)_object {
  NSMutableString *ms;
  id tmp;
  NSDictionary *phones;
  
  ms = [NSMutableString stringWithCapacity:256];

  [ms appendString:@"FN:"];
  [ms appendString:[self fullNameForObject:_object]];
  [ms appendString:@"\r\n"];

  [ms appendString:@"N:"];
  [ms appendString:[self namePartsForObject:_object]];
  [ms appendString:@"\r\n"];

  tmp = [_object valueForKey:@"nickname"];
  if ([tmp length] > 0) {
    [ms appendString:@"NICKNAME:"];
    [ms appendString:tmp];
    [ms appendString:@"\r\n"];
  }

  if ((tmp = [_object valueForKey:@"bday"]) != nil) {
    [ms appendString:@"BDAY:"];
    if ([tmp isKindOfClass:[NSCalendarDate class]])
      [ms appendString:[tmp descriptionWithCalendarFormat:@"%Y-%m-%d"
                            timeZone:nil locale:nil]];
    else
      [ms appendString:tmp];
    [ms appendString:@"\r\n"];
  }

  tmp = [_object valueForKey:@"email2"];
  if ([tmp length] > 0) {
    [ms appendString:@"EMAIL,TYPE=INTERNET:"];
    [ms appendString:tmp];
    [ms appendString:@"\r\n"];
  }

  tmp = [_object valueForKey:@"url"];
  if ([tmp length] > 0) {
    [ms appendString:@"URL:"];
    [ms appendString:tmp];
    [ms appendString:@"\r\n"];
  }

  tmp = [_object valueForKey:@"associatedCompany"];
  if ([tmp length] > 0) {
    [ms appendString:@"ORG:"];
    [ms appendString:tmp];
    [ms appendString:@"\r\n"];
  }

  tmp = [_object valueForKey:@"title"];
  if ([tmp length] > 0) {
    [ms appendString:@"TITLE:"];
    [ms appendString:tmp];
    [ms appendString:@"\r\n"];
  }

  tmp = [_object valueForKey:@"profession"];
  if ([tmp length] > 0) {
    [ms appendString:@"ROLE:"];
    [ms appendString:tmp];
    [ms appendString:@"\r\n"];
  }

  tmp = [_object valueForKey:@"associatedCategories"];
  if ([tmp length] > 0) {
    [ms appendString:@"CATEGORY:"];
    [ms appendString:[self categoriesForString:tmp]];
    [ms appendString:@"\r\n"];
  }
  
  if ((tmp = [_object valueForKey:@"addr_location"]) != nil) {
    NSString *add;

    if ((add = [self addressStringForDict:tmp]) != nil) {
      [ms appendString:@"ADR,TYPE=WORK,PREF:"];
      [ms appendString:add];
      [ms appendString:@"\r\n"];
    }
  }

  if ((tmp = [_object valueForKey:@"addr_mailing"]) != nil) {
    NSString *add;

    if ((add = [self addressStringForDict:tmp]) != nil) {
      [ms appendString:@"ADR,TYPE=INTL,POSTAL,PARCEL,DOM:"];
      [ms appendString:add];
      [ms appendString:@"\r\n"];
    }
  }

  if ((tmp = [_object valueForKey:@"addr_private"]) != nil) {
    NSString *add;

    if ((add = [self addressStringForDict:tmp]) != nil) {
      [ms appendString:@"ADR,TYPE=HOME:"];
      [ms appendString:add];
      [ms appendString:@"\r\n"];
    }
  }

  if ((phones = [_object valueForKey:@"phoneNumbers"]) != nil) {
    tmp = [phones valueForKey:@"01_tel"];
    if ([tmp length] > 0) {
      [ms appendString:@"TEL,TYPE=WORK,VOICE,PREF:"];
      [ms appendString:tmp];
      [ms appendString:@"\r\n"];
    }
    tmp = [phones valueForKey:@"03_tel_funk"];
    if ([tmp length] > 0) {
      [ms appendString:@"TEL,TYPE=WORK,CELL:"];
      [ms appendString:tmp];
      [ms appendString:@"\r\n"];
    }
    tmp = [phones valueForKey:@"05_tel_private"];
    if ([tmp length] > 0) {
      [ms appendString:@"TEL,TYPE=HOME,VOICE:"];
      [ms appendString:tmp];
      [ms appendString:@"\r\n"];
    }
    tmp = [phones valueForKey:@"10_fax"];
    if ([tmp length] > 0) {
      [ms appendString:@"TEL,TYPE=WORK,FAX:"];
      [ms appendString:tmp];
      [ms appendString:@"\r\n"];
    }
  }
  return ms;
}

@end /* SxVCardPersonRenderer */
