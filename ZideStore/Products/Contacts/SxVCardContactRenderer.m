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

#include "SxVCardContactRenderer.h"
#include "common.h"

#include <NGObjWeb/WOResponse.h>

@implementation SxVCardContactRenderer

+ (id)renderer {
  return [[[self alloc] init] autorelease];
}

- (NSString *)vCardStringForObject:(id)_object {
  return [self subclassResponsibility:_cmd];
}

- (NSString *)addressStringForDict:(NSDictionary *)_dict {
  NSString *city, *country, *state, *street, *zip;
  NSString *result;
  
  city = [_dict valueForKey:@"city"];
  country = [_dict valueForKey:@"country"];
  state = [_dict valueForKey:@"state"];
  street = [_dict valueForKey:@"street"];
  zip = [_dict valueForKey:@"zip"];
  
  result = [NSString stringWithFormat:@";;%@;%@;%@;%@;%@",
                     [street length] ? street : @"",
                     [city length] ? city : @"",
                     [state length] ? state : @"",
                     [zip length] ? zip : @"",
                     [country length] ? country : @""];

  return (![result isEqualToString:@";;;;;;"]) ? result : nil;
}

- (NSString *)vCardForObject:(id)_object inContainer:(id)_container {
  NSMutableString *ms;
  NSString *vCard;
  id tmp;

  if ((vCard = [self vCardStringForObject:_object]) == nil)
    return nil;
  
  ms = [NSMutableString stringWithCapacity:256];
  [ms appendString:@"BEGIN:vCard\r\n"];
  [ms appendString:@"VERSION:3.0\r\n"];
  [ms appendString:@"PROFILE:vCard\r\n"];

  
  if ((tmp = [_container baseURL]) != nil ) {
    NSString *primaryKey;

    primaryKey = [[_object valueForKey:@"pkey"] stringValue];
    
    [ms appendString:@"SOURCE:"];
    [ms appendString:[[tmp stringByAppendingPathComponent:primaryKey]
                           stringByAppendingString:@".vcf"]];
    [ms appendString:@"\r\nNAME:"];
    [ms appendString:[NSString stringWithFormat:
                               @"vCard for object with primary key '%@'",
                               primaryKey]];
    [ms appendString:@"\r\n"];
  }

  tmp = [_object valueForKey:@"email1"];
  if ([tmp length] > 0) {
    [ms appendString:@"EMAIL,TYPE=INTERNET,PREF:"];
    [ms appendString:tmp];
    [ms appendString:@"\r\n"];
  }
  
  [ms appendString:vCard];

  if ((tmp = [_object valueForKey:@"version"]) != nil) {
    [ms appendString:@"VERSION:"];
    [ms appendString:[tmp stringValue]];
    [ms appendString:@"\r\n"];
  }

  [ms appendString:@"END:vCard\r\n"];
  
  return ms;
}

- (WOResponse *)vCardResponseForObject:(id)_object inContext:(id)_ctx
  container:(id)_container
{
  WOResponse *response;
  NSString *vCard;

  response = [WOResponse responseWithRequest:[_ctx request]];
  
  if ((vCard = [self vCardForObject:_object inContainer:_container]) != nil) {
    NSData *contentData;

    contentData = [NSData dataWithBytes:[vCard cString]
                          length:[vCard cStringLength]];
    
    [response setStatus:200];
    [response setContent:contentData];
  }
  else {
    [response setStatus:500];
    // vCard rendering failed
  }
  return response;
}

@end /* SxVCardContactRenderer */
