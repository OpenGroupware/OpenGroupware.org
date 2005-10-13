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

#include "LSVCardLabelFormatter.h"
#include "NSString+VCard.h"
#include "common.h"

@implementation LSVCardLabelFormatter

+ (id)formatter {
  return [[[self alloc] init] autorelease];
}

- (NSString *)stringForObjectValue:(id)address {
  NSString *name1, *name2, *name3, *street, *city, *zip, *country, *state;
  NSString *label;
  
  name1   = [address valueForKey:@"name1"];
  name2   = [address valueForKey:@"name2"];
  name3   = [address valueForKey:@"name3"];
  street  = [address valueForKey:@"street"];
  city    = [address valueForKey:@"city"];
  zip     = [address valueForKey:@"zip"];
  country = [address valueForKey:@"country"];
  state   = [address valueForKey:@"state"];
  
  if (!([street isNotEmpty] || [city isNotEmpty] || [zip isNotEmpty] || 
        [country isNotEmpty] || [name1 isNotEmpty] || [name2 isNotEmpty] ||
        [name3 isNotEmpty]))
    return nil;
  
  label = @"";
  if ([name1 isNotEmpty])
    label = [label stringByAppendingFormat:@"%@\\n", name1];
  if ([name2 isNotEmpty])
    label = [label stringByAppendingFormat:@"%@\\n", name2];
  if ([name3 isNotEmpty])
    label = [label stringByAppendingFormat:@"%@\\n", name3];
  
  if ([street isNotEmpty])
    label = [label stringByAppendingFormat:@"%@\\n", street];
  if ([zip isNotEmpty])
    label = [label stringByAppendingFormat:@"%@ ", zip];
  if ([city isNotEmpty])
    label = [label stringByAppendingFormat:@"%@\\n", city];
  if ([country isNotEmpty])
    label = [label stringByAppendingString:[country stringValue]];
  return label;
}

@end /* LSVCardLabelFormatter */
