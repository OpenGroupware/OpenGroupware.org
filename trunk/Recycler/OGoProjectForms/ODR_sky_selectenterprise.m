/*
  Copyright (C) 2000-2005 SKYRIX Software AG

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

#include "ODR_sky_selectpopup.h"

/*
  Usage:
    
    <var:select-enterprise url="selectedenterpriseurl"/>
                        
  Attribute:

    url
    noselectionstring
    name
    namequery  e.g. namequery="*mdlink*"
    labelattr [default: login]
*/

@interface ODR_sky_select_enterprise : ODR_sky_selectpopup
@end

#include "common.h"

@implementation ODR_sky_select_enterprise

static int sortEnterprises(id a1, id a2, void *userData) {
  return [[a1 valueForKey:userData] compare:[a2 valueForKey:userData]];
}

- (id)_objectsForNode:(id)_node inContext:(WOContext *)_ctx {
  static NSArray *attrs = nil;
  id      cmdctx;
  NSArray *gids, *objs;
  NSString *name = [self stringFor:@"namequery" node:_node ctx:_ctx];

  if (name == nil)
    name = @"%";
  else if ([name hasPrefix:@"*"] && [name length] > 1) {
    name = [name substringWithRange:NSMakeRange(1, [name length]-1)];
  }
  else if ([name hasSuffix:@"*"] && [name length] > 1) {
    name = [name substringWithRange:NSMakeRange(0,  [name length]-1)];
  }

  if (attrs == nil) {
    attrs = [[NSArray alloc] initWithObjects:@"globalID", @"description", nil];
  }
  
  cmdctx = [(LSWSession *)[_ctx session] commandContext];
    
  gids = [cmdctx runCommand:@"enterprise::extended-search",
                   @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
                   @"operator",       @"OR",
                   @"description",    name,
                   @"maxSearchCount", [NSNumber numberWithInt:500],
                   nil];
  objs = [cmdctx runCommand:@"enterprise::get-by-globalid",
                   @"gids",       gids,
                   @"attributes", attrs,
                   nil];
  
  objs = [objs sortedArrayUsingFunction:sortEnterprises
               context:@"description"];
  
  return objs;
}

- (NSString *)_urlForObject:(id)_object {
  EOKeyGlobalID *gid;

  if (_object == nil)
    return nil;
  
  if ((gid = (id)[_object valueForKey:@"globalID"]))
    return [[gid keyValues][0] stringValue];

  return nil;
}

- (NSString *)_labelForObject:(id)_object forNode:(id)_node
  inContext:(WOContext *)_ctx
{
  NSString *labelattr;
  
  if ((labelattr = [self stringFor:@"labelattr" node:_node ctx:_ctx]) == nil)
    labelattr = @"description";
  
  return [_object valueForKey:labelattr];
}

@end /* ODR_sky_selectenterprise */
