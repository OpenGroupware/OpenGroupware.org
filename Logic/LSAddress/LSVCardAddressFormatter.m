/*
  Copyright (C) 2005 SKYRIX Software AG

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

#include "LSVCardAddressFormatter.h"
#include "NSString+VCard.h"
#include "common.h"

@implementation LSVCardAddressFormatter

static NSDictionary *addressMapping = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  addressMapping = [[ud dictionaryForKey:@"LSVCard_AddressMapping"]   copy];
}  

+ (id)formatter {
  return [[[self alloc] init] autorelease];
}

- (BOOL)generateTag {
  // generate ADR and \r\n
  return NO;
}
- (BOOL)generateType {
  // generate address type argument
  return NO;
}

- (void)_appendTextValue:(NSString *)_str toVCard:(NSMutableString *)_vCard {
  if ([_str isNotEmpty]) /* required for Cocoa (nil adds) */
    [_vCard appendString:[_str stringByEscapingUnsafeVCardCharacters]];
}

- (NSString *)stringForObjectValue:(id)address {
  NSMutableString *ms;
  NSString *pobox, *extadd, *street, *city, *zip, *country, *state;
  NSString *tmp;
  id type;
  
  pobox   = nil;
  extadd  = nil;
  street  = [address valueForKey:@"street"];
  city    = [address valueForKey:@"city"];
  zip     = [address valueForKey:@"zip"];
  country = [address valueForKey:@"country"];
  state   = [address valueForKey:@"state"];

  // TODO: add fields for the two in the DB (OGo 1.1)
  if ([(tmp = [address valueForKey:@"name2"]) isNotNull]) {
    if ([tmp hasPrefix:@"pobox:"])
      pobox = [tmp substringFromIndex:6];
    if ([tmp hasPrefix:@"extadd:"])
      pobox = [tmp substringFromIndex:7];
  }
  if ([(tmp = [address valueForKey:@"name3"]) isNotNull]) {
    if ([tmp hasPrefix:@"pobox:"])
      pobox = [tmp substringFromIndex:6];
    if ([tmp hasPrefix:@"extadd:"])
      pobox = [tmp substringFromIndex:7];
  }
  
  if (!([street isNotEmpty] || [city isNotEmpty] || [state isNotEmpty] ||
        [zip isNotEmpty] || [country isNotEmpty] ))
    return nil;
  
  // ADR: post office box;extended address;street address;city;region;
  //      postal code;country
  // @see Default: LSVCard_AddressMapping
  
  ms = [NSMutableString stringWithCapacity:64];
  
  if ([self generateTag])  /* currently disabled */
    [ms appendString:@"ADR"];
  
  if ([self generateType]) { /* currently disabled */
    type = [address valueForKey:@"type"];
    type = [addressMapping valueForKey:type];
    
    if ([type length] > 0) [ms appendFormat:@";TYPE=%@", type];
  }
  if ([self generateTag] || [self generateType]) 
    [ms appendString:@":"];
  
  [self _appendTextValue:pobox   toVCard:ms]; [ms appendString:@";"];
  [self _appendTextValue:extadd  toVCard:ms]; [ms appendString:@";"];
  [self _appendTextValue:street  toVCard:ms]; [ms appendString:@";"];
  [self _appendTextValue:city    toVCard:ms]; [ms appendString:@";"];
  [self _appendTextValue:state   toVCard:ms]; [ms appendString:@";"];
  [self _appendTextValue:zip     toVCard:ms]; [ms appendString:@";"];
  [self _appendTextValue:country toVCard:ms];
  if ([self generateTag]) [ms appendString:@"\r\n"];
  
  return ms;
}

@end /* LSVCardAddressFormatter */
