/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include "common.h"
#include <EOControl/EOKeyGlobalID.h>

@implementation NSObject(OGoSessionLabel)

- (NSString *)labelForObjectInSession:(id)_sn {
  EOGlobalID *gid;
  BOOL       canEntity;
  NSString   *label;
  
  gid       = [self valueForKey:@"globalID"];
  canEntity = [self respondsToSelector:@selector(entity)] ? YES : NO;
  
  if ([self respondsToSelector:@selector(headers)]) {
    return ([self valueForKey:@"subject"] != nil)
      ? [self valueForKey:@"subject"]
      : @"";
  }
  
  if (canEntity || gid != nil) {
    /* a generic record */
    NSString *name;

    label = nil;
    name  = canEntity ? [[self entity] name] : [gid entityName];
    
    if ([[self valueForKey:@"isAccount"] boolValue]) {
      label = [self valueForKey:@"login"];
      if (![label isNotNull])
        label = [self valueForKey:@"name"];
    }
    else if ([[self valueForKey:@"isTeam"] boolValue]) {
      label = [self valueForKey:@"description"];
    }
    else {
      label = [self valueForKey:@"title"];
      if ([label isNotNull]) goto done;
      label = [self valueForKey:@"name"];
      if ([label isNotNull]) goto done;
      label = [self valueForKey:@"subject"];
      if ([label isNotNull]) goto done;
      label = [self valueForKey:@"name1"];
      if ([label isNotNull]) goto done;
      label = [self valueForKey:@"invoiceNr"];
      if ([label isNotNull]) goto done;
      label = [self valueForKey:@"articleNr"];
      if ([label isNotNull]) goto done;
      label = [self valueForKey:@"unit"];
      if ([label isNotNull]) goto done;
      label = [self valueForKey:@"categoryName"];
      if ([label isNotNull]) goto done;
      label = [self valueForKey:@"accountNr"];
      if ([label isNotNull]) goto done;
      label = [self valueForKey:@"description"];
      if ([label isNotNull]) goto done;
    done:
      ;
    }
    label = [label stringValue];

    if (![label isNotNull]) {
      id pkey;

      pkey = nil;
      
      if (canEntity) {
        pkey = [[self entity] primaryKeyAttributeNames];
        if ([pkey count] > 0) pkey = [pkey objectAtIndex:0];

        if (pkey) pkey = [self valueForKey:pkey];

      }
      else
        pkey = [(EOKeyGlobalID *)gid keyValues][0];
      
      label = [NSString stringWithFormat:@"%@<%@>", name,
                        pkey ? pkey : @"null"];
    }
    return label;
  }
  
  /* generic label */
  label = [self description];
  if ([label length] > 30)
    label = [[label substringToIndex:27] stringByAppendingString:@"..."];
    
  return [[label copy] autorelease];
}

@end /* NSObject(OGoSessionLabel) */

@implementation NSDictionary(OGoSessionLabel)

- (NSString *)labelForObjectInSession:(id)_sn {
  if ([self valueForKey:@"articleNr"] != nil)
    return [self valueForKey:@"articleNr"];
  
  if ([self valueForKey:@"name"] != nil)
    return [self valueForKey:@"name"];
  
  return @"";
}

@end /* NSDictionary(OGoSessionLabel) */
