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
    
    <var:select-account url="selectedaccounturl"/>
                        
  Attribute:

    url
    noselectionstring
    name
    labelattr [default: login]
*/

@interface ODR_sky_select_account : ODR_sky_selectpopup
@end

#include "common.h"

@implementation ODR_sky_select_account

static int sortAccounts(id a1, id a2, void *userData) {
  return [(NSString *)[a1 valueForKey:@"login"] compare:[a2 valueForKey:@"login"]];
}

- (id)_objectsForNode:(id)_node inContext:(WOContext *)_ctx {
  static NSArray *attrs = nil;
  id       cmdctx;
  NSArray  *gids, *objs;
  NSString *cacheKey;
  
  if (attrs == nil) {
    attrs = [[NSArray alloc] initWithObjects:@"globalID", @"login",
                               @"name", @"firstname", nil];
  }
  
  cmdctx = [(LSWSession *)[_ctx session] commandContext];
  
  /* check cache */
  
  cacheKey = @"_cache_ODR_sky_select_account";
  
  if ((objs = [cmdctx valueForKey:cacheKey]))
    /* cache hit ! */
    return objs;
  
  /* perform query */
  
  gids = [cmdctx runCommand:@"account::extended-search",
                 @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
                 @"operator", @"OR",
                 @"login", @"%",
                 @"maxSearchCount", [NSNumber numberWithInt:500],
                 nil];
  objs = [cmdctx runCommand:@"person::get-by-globalid",
                 @"gids", gids,
                 @"attributes", attrs,
                 nil];
    
  objs = [objs sortedArrayUsingFunction:sortAccounts
               context:self];
  
  if (objs == nil) objs = [NSArray array];
  
  /* store in cache */
  
  [cmdctx takeValue:objs forKey:cacheKey];
  
  /* return result */
  
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
    labelattr = @"login";
  
  return [_object valueForKey:labelattr];
}

@end /* ODR_sky_selectaccount */
