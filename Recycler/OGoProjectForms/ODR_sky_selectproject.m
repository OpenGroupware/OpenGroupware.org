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
    
    <var:select-project url="selectedprojecturl"
                       [person=projects-of-person|
                        enterprise=projects-of-enterprise|
                        datasource=ds]/>
                        
  Attribute:

    url
    person | enterprise | datasource
    noselectionstring
    name
    labelattr
*/

@interface ODR_sky_select_project : ODR_sky_selectpopup
@end

#include <OGoBase/LSCommandContext+Doc.h>
#include "common.h"

@interface NSObject(GID)
- (EOGlobalID *)globalID;
- (id)initWithContext:(id)_ctx companyId:(EOGlobalID *)_gid;
- (id)initWithContext:(id)_ctx;
@end

@implementation ODR_sky_select_project

- (EODataSource *)_projectDataSourceForNode:(id)_node inContext:(id)_ctx {
  EODataSource *ds = nil;
  id cmdctx;
  id tmp;
  
  cmdctx = [(LSWSession *)[_ctx session] commandContext];
  
  if ((tmp = [self valueFor:@"datasource" node:_node ctx:_ctx])) {
    ds = tmp;
  }
  else if ((tmp = [self valueFor:@"person" node:_node ctx:_ctx])) {
    EOGlobalID *gid = nil;
    Class clazz;

    clazz = NGClassFromString(@"SkyPersonProjectDataSource");
    
    if ([tmp isKindOfClass:[EOGlobalID class]])
      gid = tmp;
    else if ([tmp isKindOfClass:[NSString class]])
      gid = [[cmdctx documentManager] globalIDForURL:tmp];
    else if ([tmp respondsToSelector:@selector(globalID)])
      gid = [tmp globalID];
    else
      gid = [[cmdctx documentManager] globalIDForURL:[tmp stringValue]];
    
    if (gid)
      ds = [[[clazz alloc] initWithContext:cmdctx companyId:gid] autorelease];
  }
  else if ((tmp = [self valueFor:@"enterprise" node:_node ctx:_ctx])) {
    EOGlobalID *gid = nil;
    Class clazz;
    
    clazz = NGClassFromString(@"SkyEnterpriseProjectDataSource");
    
    if ([tmp isKindOfClass:[EOGlobalID class]])
      gid = tmp;
    else if ([tmp isKindOfClass:[NSString class]])
      gid = [[cmdctx documentManager] globalIDForURL:tmp];
    else if ([tmp respondsToSelector:@selector(globalID)])
      gid = [tmp globalID];
    else
      gid = [[cmdctx documentManager] globalIDForURL:[tmp stringValue]];
    
    if (gid)
      ds = [[[clazz alloc] initWithContext:cmdctx companyId:gid] autorelease];
  }
  else {
    tmp = NGClassFromString(@"SkyProjectDataSource");
    ds = [[[tmp alloc] initWithContext:cmdctx] autorelease];
  }
  
  return ds;
}

static int sortProjects(id a1, id a2, void *userData) {
  return [(NSString *)[a1 valueForKey:userData] compare:[a2 valueForKey:userData]];
}

- (NSString *)_labelAttrForObject:(id)_object forNode:(id)_node
  inContext:(WOContext *)_ctx
{
  NSString *labelattr;
  
  if ((labelattr = [self stringFor:@"labelattr" node:_node ctx:_ctx]) == nil)
    labelattr = @"name";
  
  return labelattr;
}

- (id)_objectsForNode:(id)_node inContext:(WOContext *)_ctx {
  EODataSource *ds;
  NSArray      *projects;
  NSString *labelattr;

  if ((ds = [self _projectDataSourceForNode:_node inContext:_ctx]) == nil)
    return nil;
  
  if ((projects = [ds fetchObjects]) == nil)
    return nil;
  
  if ([projects count] == 0)
    return projects;

  labelattr = [self _labelAttrForObject:nil forNode:_node inContext:_ctx];

  if (labelattr) {
    projects = [projects sortedArrayUsingFunction:sortProjects
                         context:labelattr];
  }
  
  return projects;
}

- (NSString *)_urlForObject:(id)_object {
  EOKeyGlobalID *gid;
  
  if (_object == nil)
    return nil;
  
  if ((gid = (EOKeyGlobalID *)[_object globalID]))
    return [[gid keyValues][0] stringValue];
  
  return nil;
}

- (NSString *)_labelForObject:(id)_object forNode:(id)_node
  inContext:(WOContext *)_ctx
{
  NSString *labelattr;

  labelattr = [self _labelAttrForObject:_object forNode:_node inContext:_ctx];
  
  return [_object valueForKey:labelattr];
}

@end /* ODR_sky_selectproject */
