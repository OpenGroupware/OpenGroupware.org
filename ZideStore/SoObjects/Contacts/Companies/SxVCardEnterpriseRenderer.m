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
// $Id: SxVCardEnterpriseRenderer.m 1 2004-08-20 11:17:52Z znek $

#include "SxVCardEnterpriseRenderer.h"
#include "common.h"

@implementation SxVCardEnterpriseRenderer

- (NSString *)vCardStringForObject:(id)_object {
  NSMutableString *ms;
  id tmp;
  NSDictionary *phones;
  
  ms = [NSMutableString stringWithCapacity:256];

  [ms appendString:@"FN:"];
  [ms appendString:[_object valueForKey:@"description"]];
  [ms appendString:@"\r\n"];

  [ms appendString:@"N:"];
  [ms appendString:[_object valueForKey:@"description"]];
  [ms appendString:@";;;;\r\n"];

  if ((tmp = [_object valueForKey:@"addr_bill"]) != nil) {
    NSString *add;

    if ((add = [self addressStringForDict:tmp]) != nil) {
      [ms appendString:@"ADR,TYPE=WORK,PREF:"];
      [ms appendString:add];
      [ms appendString:@"\r\n"];
    }
  }

  if ((tmp = [_object valueForKey:@"addr_ship"]) != nil) {
    NSString *add;

    if ((add = [self addressStringForDict:tmp]) != nil) {
      [ms appendString:@"ADR,TYPE=WORK,INTL,POSTAL,PARCEL,DOM:"];
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
    tmp = [phones valueForKey:@"10_fax"];
    if ([tmp length] > 0) {
      [ms appendString:@"TEL,TYPE=WORK,FAX:"];
      [ms appendString:tmp];
      [ms appendString:@"\r\n"];
    }
  }
  return ms;
}

@end /* SxVCardEnterpriseRenderer */
