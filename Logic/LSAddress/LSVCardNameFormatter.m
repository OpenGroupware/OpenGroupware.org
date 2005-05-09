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

#include "LSVCardNameFormatter.h"
#include "NSString+VCard.h"
#include "common.h"

@implementation LSVCardFormattedNameFormatter

+ (id)formatter {
  return [[[self alloc] init] autorelease];
}

- (NSString *)fnForPerson:(id)_person {
  NSString *tmp, *tmp2, *fn;

  tmp  = [_person valueForKey:@"name"];
  tmp2 = [_person valueForKey:@"firstname"];
  if (([tmp isNotNull] && ([tmp length] > 0)) &&
      ([tmp2 isNotNull] && ([tmp2 length] > 0))) {
    fn = [[tmp2 stringByAppendingString:@" "] stringByAppendingString:tmp];
  }
  else if ([tmp isNotNull] && [tmp length])
    fn = tmp;  // ok, lastname
  else if ([tmp2 isNotNull] && [tmp2 length])
    fn = tmp2; // take firstname
  else { // no firstname, no lastname, take id
    fn = [@"Person: " stringByAppendingString:
             [[_person valueForKey:@"companyId"] stringValue]];
  }
  
  return fn;
}

- (NSString *)stringForObjectValue:(id)_person {
  return [[self fnForPerson:_person] stringByEscapingUnsafeVCardCharacters];
}

@end /* LSVCardFormattedNameFormatter */

@implementation LSVCardNameFormatter

- (void)_appendTextValue:(NSString *)_str toVCard:(NSMutableString *)_vCard {
  [_vCard appendString:[_str stringByEscapingUnsafeVCardCharacters]];
}

- (NSString *)stringForObjectValue:(id)_person {
  // N:lastname;givenname;additional names;honorific prefixes;
  //   honorifix suffixes
  NSMutableString *ms;
  NSString *tmp, *tmp2, *fn;
  
  ms = [NSMutableString stringWithCapacity:64];
  
  tmp  = [_person valueForKey:@"name"];
  tmp2 = [_person valueForKey:@"firstname"];
  fn   = [self fnForPerson:_person];

  // lastname
  [self _appendTextValue:[tmp isNotNull] ? tmp : fn toVCard:ms];
  [ms appendString:@";"];
  // firstname
  tmp = tmp2;
  [self _appendTextValue:[tmp isNotNull] ? tmp : @"" toVCard:ms];
  [ms appendString:@";"];
  // middlename
  tmp = [_person valueForKey:@"middlename"];
  [self _appendTextValue:[tmp isNotNull] ? tmp : @"" toVCard:ms];
  [ms appendString:@";"];
  // degree
  tmp = [_person valueForKey:@"degree"];
  [self _appendTextValue:[tmp isNotNull] ? tmp : @"" toVCard:ms];
  [ms appendString:@";"];
  // other title
  tmp = [_person valueForKey:@"other_title1"];
  [self _appendTextValue:[tmp isNotNull] ? tmp : @"" toVCard:ms];
  if ([(tmp = [_person valueForKey:@"other_title2"]) isNotNull]) {
    [ms appendString:@","];
    [self _appendTextValue:tmp toVCard:ms];
  }
  
  return ms;
}

@end /* LSVCardNameFormatter */
