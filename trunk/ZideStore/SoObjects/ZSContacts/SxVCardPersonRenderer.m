/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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
  NSMutableString *ms;
  NSString *title, *firstname, *middlename, *lastname, *affix;

  title      = [_object valueForKey:@"nameTitle"];
  firstname  = [_object valueForKey:@"givenName"];
  middlename = [_object valueForKey:@"middleName"];
  lastname   = [_object valueForKey:@"name"];
  affix      = [_object valueForKey:@"nameAffix"];
  
  ms = [NSMutableString stringWithCapacity:256];
  
  if ([title length]      > 0) [ms appendString:title]; 
  [ms appendString:@";"];
  if ([firstname length]  > 0) [ms appendString:firstname]; 
  [ms appendString:@";"];
  if ([middlename length] > 0) [ms appendString:middlename]; 
  [ms appendString:@";"];
  if ([lastname length]   > 0) [ms appendString:lastname]; 
  [ms appendString:@";"];
  if ([affix length]      > 0) [ms appendString:affix]; 
  return ms;
}

- (NSString *)categoriesForString:(NSString *)_string {
  return [_string stringByReplacingString:@"'" withString:@""];
}

- (void)appendProperty:(NSString *)_name filledValue:(id)_value 
  to:(NSMutableString *)_ms
{
  if (![_value isNotNull])
    return;
  
  _value = [_value stringValue];
  if ([_value length] == 0)
    return;
  
  [_ms appendString:_name];
  [_ms appendString:@":"];
  [_ms appendString:_value];
  [_ms appendString:@"\r\n"];
}

- (void)appendAddressesOfObject:(id)_object to:(NSMutableString *)_ms {
  id tmp;
  
  if ((tmp = [_object valueForKey:@"addr_location"]) != nil) {
    NSString *add;
    
    if ((add = [self addressStringForDict:tmp]) != nil) {
      [_ms appendString:@"ADR,TYPE=WORK,PREF:"];
      [_ms appendString:add];
      [_ms appendString:@"\r\n"];
    }
  }
  
  if ((tmp = [_object valueForKey:@"addr_mailing"]) != nil) {
    NSString *add;

    if ((add = [self addressStringForDict:tmp]) != nil) {
      [_ms appendString:@"ADR,TYPE=INTL,POSTAL,PARCEL,DOM:"];
      [_ms appendString:add];
      [_ms appendString:@"\r\n"];
    }
  }

  if ((tmp = [_object valueForKey:@"addr_private"]) != nil) {
    NSString *add;

    if ((add = [self addressStringForDict:tmp]) != nil) {
      [_ms appendString:@"ADR,TYPE=HOME:"];
      [_ms appendString:add];
      [_ms appendString:@"\r\n"];
    }
  }
}

- (void)appendPhonesOfObject:(id)_object to:(NSMutableString *)_ms {
  NSDictionary *phones;
  id tmp;
  
  if ((phones = [_object valueForKey:@"phoneNumbers"]) == nil)
    return;
  
  tmp = [phones valueForKey:@"01_tel"];
  if ([tmp length] > 0) {
      [_ms appendString:@"TEL,TYPE=WORK,VOICE,PREF:"];
      [_ms appendString:tmp];
      [_ms appendString:@"\r\n"];
  }
  tmp = [phones valueForKey:@"03_tel_funk"];
  if ([tmp length] > 0) {
      [_ms appendString:@"TEL,TYPE=WORK,CELL:"];
      [_ms appendString:tmp];
      [_ms appendString:@"\r\n"];
  }
  tmp = [phones valueForKey:@"05_tel_private"];
  if ([tmp length] > 0) {
      [_ms appendString:@"TEL,TYPE=HOME,VOICE:"];
      [_ms appendString:tmp];
      [_ms appendString:@"\r\n"];
  }
  tmp = [phones valueForKey:@"10_fax"];
  if ([tmp length] > 0) {
      [_ms appendString:@"TEL,TYPE=WORK,FAX:"];
      [_ms appendString:tmp];
      [_ms appendString:@"\r\n"];
  }
}

- (NSString *)vCardStringForObject:(id)_object {
  NSMutableString *ms;
  id tmp;
  
  ms = [NSMutableString stringWithCapacity:256];
  
  [ms appendString:@"FN:"];
  [ms appendString:[self fullNameForObject:_object]];
  [ms appendString:@"\r\n"];

  [ms appendString:@"N:"];
  [ms appendString:[self namePartsForObject:_object]];
  [ms appendString:@"\r\n"];

  [self appendProperty:@"NICKNAME" 
	filledValue:[_object valueForKey:@"nickname"]
	to:tmp];
  
  if ((tmp = [_object valueForKey:@"bday"]) != nil) {
    [ms appendString:@"BDAY:"];
    if ([tmp isKindOfClass:[NSCalendarDate class]]) {
      NSString *s;
      unsigned char buf[64];
      
      sprintf(buf, "%04i-%02i-%02i", 
	      [tmp yearOfCommonEra], [tmp monthOfYear], [tmp dayOfMonth]);
      
      s = [[NSString alloc] initWithCString:buf];
      [ms appendString:s];
      [s release];
    }
    else
      [ms appendString:[tmp stringValue]];
    [ms appendString:@"\r\n"];
  }
  
  tmp = [_object valueForKey:@"email2"];
  if ([tmp length] > 0) {
    [ms appendString:@"EMAIL,TYPE=INTERNET:"];
    [ms appendString:tmp];
    [ms appendString:@"\r\n"];
  }
  
  [self appendProperty:@"URL" 
	filledValue:[_object valueForKey:@"url"] 
	to:ms];
  [self appendProperty:@"ORG" 
	filledValue:[_object valueForKey:@"associatedCompany"] 
	to:ms];
  [self appendProperty:@"TITLE" 
	filledValue:[_object valueForKey:@"title"]
	to:ms];
  [self appendProperty:@"ROLE" 
	filledValue:[_object valueForKey:@"profession"]
	to:ms];
  
  tmp = [_object valueForKey:@"associatedCategories"];
  if ([tmp length] > 0) {
    [ms appendString:@"CATEGORY:"];
    [ms appendString:[self categoriesForString:tmp]];
    [ms appendString:@"\r\n"];
  }
  
  [self appendAddressesOfObject:_object to:ms];
  [self appendPhonesOfObject:_object    to:ms];
  return ms;
}

@end /* SxVCardPersonRenderer */
