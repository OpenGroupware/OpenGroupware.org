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

#include "SkyEnterpriseDocument.h"

/*
  Inherits from SkyCompanyDocument+JS

  supported JS properties:

  supported JS functions:
  
    DataSource getProjectDataSource([bool cache=default:YES])
    DataSource getPersonDataSource([bool cache=default:YES])
  
  private JS functions:

    Array getAddressTypes()
*/

#include "common.h"
#include "SkyAddressDocument.h"
#include "SkyEnterpriseProjectDataSource.h"
#include "SkyEnterprisePersonDataSource.h"
#include <NGExtensions/EOCacheDataSource.h>

@implementation SkyEnterpriseDocument(JSSupport)

/* methods */

- (id)_jsfunc_getProjectDataSource:(NSArray *)_args {
  BOOL     doCache;
  unsigned count;
  SkyEnterpriseProjectDataSource *ds;
  id ctx;
  
  if ((ctx = [self context]) == nil) {
    NSLog(@"ERROR(%s): document %@ has no context !", __PRETTY_FUNCTION__, self);
    return nil;
  }
  
  doCache = YES;
  if ((count = [_args count]) > 0)
    doCache = [[_args objectAtIndex:0] boolValue];
  
  ds = [SkyEnterpriseProjectDataSource alloc];
  ds = [ds initWithContext:ctx enterpriseId:[self globalID]];
  
  if (ds == nil) {
    NSLog(@"%s: couldn't create person project datasource for personId: %@",
          __PRETTY_FUNCTION__, [self globalID]);
    return nil;
  }
  
  if (doCache) {
    /* wrap in cache datasource */
    id cds;
    
    cds = [[EOCacheDataSource alloc] initWithDataSource:ds];
    RELEASE(ds);
    ds = cds;
  }

#if DEBUG
  NSAssert1([ds isKindOfClass:[EODataSource class]] || ds == nil,
            @"result is not an EODataSource: %@ ..", ds);
#endif
  
  return AUTORELEASE(ds);
}

- (id)_jsfunc_getPersonDataSource:(NSArray *)_args {
  BOOL     doCache;
  unsigned count;
  SkyEnterprisePersonDataSource *ds;
  id ctx;
  
  if ((ctx = [self context]) == nil) {
    NSLog(@"ERROR(%s): document %@ has no context !", __PRETTY_FUNCTION__, self);
    return nil;
  }
  
  doCache = YES;
  if ((count = [_args count]) > 0)
    doCache = [[_args objectAtIndex:0] boolValue];
  
  ds = [SkyEnterprisePersonDataSource alloc];
  ds = [ds initWithContext:ctx companyId:[self globalID]];
  
  if (ds == nil) {
    NSLog(@"%s: couldn't create person enterprise datasource for personId: %@",
          __PRETTY_FUNCTION__, [self globalID]);
    return nil;
  }
  
  if (doCache) {
    /* wrap in cache datasource */
    id cds;
    
    cds = [[EOCacheDataSource alloc] initWithDataSource:ds];
    RELEASE(ds);
    ds = cds;
  }

#if DEBUG
  NSAssert1([ds isKindOfClass:[EODataSource class]] || ds == nil,
            @"result is not an EODataSource: %@ ..", ds);
#endif
  
  return AUTORELEASE(ds);
}

- (id)_jsfunc_getAddressTypes:(NSArray *)_args {
  /* private function !!! */
  return [self addressTypes];
}

- (NSString *)_defaultAddressType {
  return @"location";
#if 0
  return [[NSUserDefaults standardUserDefaults]
                          stringForKey:
                            @"SkyEnterpriseDocument_JS_defaultAddressType"];
#endif
  //return [[self addressTypes] objectAtIndex:0];
}

@end /* SkyEnterpriseDocument(JSSupport) */
