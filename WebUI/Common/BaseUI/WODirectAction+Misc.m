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

#include <NGObjWeb/WODirectAction.h>
#include "common.h"

@interface NSObject(TaskDA_PRIVATE)
- (void)setExecutant:(id)_executant;
@end

@implementation WODirectAction(Misc)

/* some new actions */
/* TODO: they should be moved to another place */

- (id<WOActionResults>)newNewsArticleAction {
  NGMimeType  *mt = [NGMimeType mimeType:@"eo" subType:@"newsarticle"];
  WOComponent *ct = nil;

  ct = [[self session] instantiateComponentForCommand:@"new" type:mt];
  [[[self session] navigation] enterPage:(id)ct];
  return nil;
}

- (id<WOActionResults>)newPersonAction {
  NGMimeType  *mt;
  WOComponent *ct;

  mt = [NGMimeType mimeType:@"objc" subType:@"SkyPersonDocument"];
  ct = [[self session] instantiateComponentForCommand:@"new" type:mt];

  [[[self session] navigation] enterPage:(id)ct];
  return ct;
}

- (id<WOActionResults>)newCompanyAction {
  NGMimeType  *mt;
  WOComponent *ct;

  mt = [NGMimeType mimeType:@"objc" subType:@"SkyEnterpriseDocument"];
  ct = [[self session] instantiateComponentForCommand:@"new" type:mt];

  [[[self session] navigation] enterPage:(id)ct];
  return ct;
}

- (id<WOActionResults>)newTaskAction {
  // copied from LSWJobs.m
  NGMimeType  *mt = [NGMimeType mimeType:@"eo/job"];
  WOComponent *ct = nil;

  [[self session] removeTransferObject];
  ct = [[self session] instantiateComponentForCommand:@"new" type:mt];
  [ct setExecutant:[[self session] activeAccount]];
  if (ct) [[[self session] navigation] enterPage:(id)ct];
  return ct;
}

@end /* WODirectAction(Misc) */
