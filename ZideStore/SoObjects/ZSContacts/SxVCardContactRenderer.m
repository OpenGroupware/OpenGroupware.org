/*
  Copyright (C) 2002-2004 SKYRIX Software AG

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

#include "SxVCardContactRenderer.h"
#include "common.h"

#include <NGObjWeb/WOResponse.h>

@implementation SxVCardContactRenderer

+ (id)renderer {
  return [[[self alloc] init] autorelease];
}

/* operations */

- (NSString *)vCardStringForObject:(id)_object {
  return [self subclassResponsibility:_cmd];
}

- (NSString *)addressStringForDict:(NSDictionary *)_dict {
  // TODO: where is this format specified? (please provide link)
  NSMutableString *ms;
  NSString *city, *country, *state, *street, *zip;
  
  ms      = [NSMutableString stringWithCapacity:256];
  city    = [_dict valueForKey:@"city"];
  country = [_dict valueForKey:@"country"];
  state   = [_dict valueForKey:@"state"];
  street  = [_dict valueForKey:@"street"];
  zip     = [_dict valueForKey:@"zip"];
  
  [ms appendString:@";;"];
  if ([street  length] > 0) [ms appendString:street]; [ms appendString:@";"];
  if ([city    length] > 0) [ms appendString:city];   [ms appendString:@";"];
  if ([state   length] > 0) [ms appendString:state];  [ms appendString:@";"];
  if ([zip     length] > 0) [ms appendString:zip];    [ms appendString:@";"];
  if ([country length] > 0) [ms appendString:country];
  
  if ([ms isEqualToString:@";;;;;;"])
    return nil;
  
  return ms;
}

- (NSString *)vCardForObject:(id)_object inContainer:(id)_container {
  NSMutableString *ms;
  NSString *vCard;
  id tmp;

  if ((vCard = [self vCardStringForObject:_object]) == nil)
    return nil;
  
  ms = [NSMutableString stringWithCapacity:256];
  [ms appendString:@"BEGIN:vCard\r\nVERSION:3.0\r\nPROFILE:vCard\r\n"];
  
  if ((tmp = [_container baseURL]) != nil) {
    NSString *primaryKey;
    NSString *s;
    
    primaryKey = [[_object valueForKey:@"pkey"] stringValue];
    
    s = [tmp stringByAppendingPathComponent:primaryKey];
    s = [s stringByAppendingString:@".vcf"];
    [ms appendString:@"SOURCE:"];
    [ms appendString:s];
    [ms appendString:@"\r\nNAME:"];
    [ms appendFormat:@"vCard for object with primary key '%@'", primaryKey];
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
  NSString   *vCard;
  
  response = [WOResponse responseWithRequest:[_ctx request]];
  
  if ((vCard = [self vCardForObject:_object inContainer:_container]) != nil) {
    NSData *contentData;
    
    contentData = [vCard dataUsingEncoding:NSUTF8StringEncoding];
    if (contentData == nil) {
      [self logWithFormat:@"ERROR: could not create data from vCard string!"];
      return nil;
    }
    
    [response setStatus:200 /* OK */];
    [response setContent:contentData];
    [response setHeader:@"text/x-vcard; charset=utf-8" forKey:@"content-type"];
  }
  else {
    /* vCard rendering failed */
    [response setStatus:500 /* server error */];
  }
  return response;
}

@end /* SxVCardContactRenderer */
