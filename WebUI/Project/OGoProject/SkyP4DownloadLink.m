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

#include <NGObjWeb/WODynamicElement.h>

@interface SkyP4DownloadLink : WODynamicElement
{
  WOAssociation *projectName;
  WOAssociation *projectId;
  WOAssociation *documentPath;
  WOAssociation *versionTag;
  WOAssociation *string;
  WOElement     *template;
}

@end

#include "common.h"
#include "SkyP4DocumentRequestHandler.h"
#include <NGExtensions/NSString+misc.h>
#include <NGObjWeb/WEClientCapabilities.h>

@interface WOContext(SkyP4DocumentRequestHandlerDeprecated)
- (NSString *)p4documentURLForProjectNamed:(NSString *)_pname
  path:(NSString *)_path
  versionTag:(NSString *)_versionTag
  disposition:(NSString *)_disposition;
@end

@implementation SkyP4DownloadLink

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_assocs
  template:(WOElement *)_templ
{
  if ((self = [super initWithName:_name associations:_assocs template:_templ])) {
    self->projectName  = [[_assocs objectForKey:@"projectName"] copy];
    self->projectId    = [[_assocs objectForKey:@"projectId"] copy];
    self->documentPath = [[_assocs objectForKey:@"documentPath"] copy];
    self->string       = [[_assocs objectForKey:@"string"] copy];
    self->versionTag   = [[_assocs objectForKey:@"versionTag"] copy];

    [(NSMutableDictionary *)_assocs removeObjectForKey:@"projectName"];
    [(NSMutableDictionary *)_assocs removeObjectForKey:@"documentPath"];
    [(NSMutableDictionary *)_assocs removeObjectForKey:@"string"];
    [(NSMutableDictionary *)_assocs removeObjectForKey:@"versionTag"];
    
    self->template = RETAIN(_templ);
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->string);
  RELEASE(self->versionTag);
  RELEASE(self->projectName);
  RELEASE(self->projectId);
  RELEASE(self->documentPath);
  RELEASE(self->template);
  [super dealloc];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  WOComponent *comp;
  NSString    *href;
  NSString    *path;
  
  comp = [_ctx component];

  path = [self->documentPath stringValueInComponent:comp];

  if (self->projectId) {
    href = [_ctx p4documentURLForProjectWithGlobalID:
                   [self->projectId valueInComponent:comp]
                 path:path
                 versionTag:[self->versionTag stringValueInComponent:comp]
                 disposition:@"attachment"];
  }
  else if (self->projectName) {
    NSLog(@"DEPRECATED: %s:%i", __PRETTY_FUNCTION__, __LINE__);
    href = [_ctx p4documentURLForProjectNamed:
                   [self->projectName stringValueInComponent:comp]
                 path:path
                 versionTag:[self->versionTag stringValueInComponent:comp]
                 disposition:@"attachment"];
  }
  [_response appendContentString:@"<a href='"];
  [_response appendContentString:href];
  [_response appendContentString:@"' target='"];
  [_response appendContentHTMLAttributeValue:
               [[path lastPathComponent] stringByEscapingURL]];
  [_response appendContentString:@"'>"];
  
  if (self->string) {
    [_response appendContentHTMLString:
                 [self->string stringValueInComponent:comp]];
  }
  [self->template appendToResponse:_response inContext:_ctx];
  
  [_response appendContentString:@"</a>"];
}

@end /* SkyP4DownloadLink */
