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

#include <OGoFoundation/LSWContentPage.h>

@class NSArray;

@interface SkyEnterpriseProjectList : LSWContentPage
{
@protected
  id   enterprise;
  BOOL isEditEnabled;
}
@end

#include <OGoFoundation/LSWNotifications.h>
#include <OGoFoundation/OGoFoundation.h>
#include <LSFoundation/LSFoundation.h>
#include <NGObjWeb/NGObjWeb.h>
#import <EOControl/EOGlobalID.h>
#import <Foundation/Foundation.h>
#include <OGoContacts/SkyEnterpriseDocument.h>

@implementation SkyEnterpriseProjectList

- (void)dealloc {
  [self unregisterAsObserver];
  [self->enterprise release];
  [super dealloc];
}

/* accessors */

- (void)setEnterprise:(id)_enterprise {
  ASSIGN(self->enterprise, _enterprise);
}
- (id)enterprise {
  return self->enterprise;
}

- (void)setIsEditEnabled:(BOOL)_flag {
  self->isEditEnabled = _flag;
}
- (BOOL)isEditEnabled {
  return self->isEditEnabled;
}

/* actions */

- (id)assignProject {
  id obj;
  
  if (self->enterprise == nil)
    return nil;
  
  obj = [self->enterprise globalID];

  obj = [self runCommand:@"object::get-by-globalid", @"gid", obj, nil];
  obj = [obj lastObject];
  return [self activateObject:obj withVerb:@"assignEnterpriseProjects"];
}

- (BOOL)hasNew {
  id am;
  
  am = [[[self session] valueForKey:@"commandContext"] accessManager];
  return [am operation:@"w" 
	     allowedOnObjectID:[self->enterprise valueForKey:@"globalID"]];
  
}

@end /* SkyEnterpriseProjectList */
