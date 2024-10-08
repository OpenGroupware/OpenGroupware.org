/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

#include <OGoFoundation/LSWContentPage.h>

/* 
   SkyCompanyAccessEditor

   TODO: why is that in OGoProject, looks like a generic component for
         editing ACLs?

   Posts: 
     SkyAccessHasChangedNotification - if the operation was changed
	 
   Activated by:
     SkyProject4DocumentViewer with document-gid as the globalID and rw
     SkyP4FolderView           with gid-for-path as the globalID and dirw
*/

@class NSArray, NSMutableDictionary;
@class EOGlobalID;

@interface SkyCompanyAccessEditor : LSWContentPage
{
  EOGlobalID          *globalID;
  NSMutableDictionary *accessIds;
  NSArray             *accessChecks;
}

@end

#include <LSFoundation/SkyAccessManager.h>
#include "common.h"

@implementation SkyCompanyAccessEditor

- (void)dealloc {
  [self->accessChecks release];
  [self->globalID     release];
  [self->accessIds    release];
  [super dealloc];
}

/* accessors */

- (void)setGlobalID:(EOGlobalID *)_gid {
  LSCommandContext *cmdctx;
  NSDictionary *ids;
  
  ASSIGN(self->globalID, _gid);
  [self->accessIds release]; self->accessIds = nil;
  
  cmdctx =[(OGoSession *)[self session] commandContext];
  ids = [[cmdctx accessManager] allowedOperationsForObjectId:self->globalID];
  self->accessIds = [ids mutableCopy];
}
- (EOGlobalID *)globalID {
  return self->globalID;
}

- (void)setAccessIds:(id)_id {
  ASSIGN(self->accessIds, _id);
}
- (id)accessIds {
  return self->accessIds;
}

- (void)setAccessChecks:(NSArray *)_id {
  ASSIGN(self->accessChecks, _id);
}
- (NSArray *)accessChecks {
  return self->accessChecks;
}

/* notifications */

- (void)postAccessHasChanged:(id)_obj {
  [[NSNotificationCenter defaultCenter]
    postNotificationName:@"SkyAccessHasChangedNotification"
    object:_obj userInfo:nil];
}

/* actions */

- (id)save {
  SkyAccessManager *manager;
  NSDictionary     *dict;
  NSEnumerator     *enumerator;
  id               obj;
  NSMutableSet     *gidsObj;
  NSSet            *gidsNew;

  manager = [[(OGoSession *)[self session] commandContext] accessManager];

  /*
    The dict will be empty if no ACL was set on the object. Otherwise the
    keys will be the global-ids of accounts or teams and the values the
    respective permissions assigned ('', 'rw' or 'r').
  */
  dict = [manager allowedOperationsForObjectId:self->globalID];
  
  gidsObj = [NSMutableSet setWithArray:[dict allKeys]];
  gidsNew = [NSSet setWithArray:[self->accessIds allKeys]];

  /* after this one 'gidsObj' will contain users/teams which got access
     removed */
  [gidsObj minusSet:gidsNew];

  /* reset permissions */
  enumerator = [gidsObj objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil)
    [self->accessIds setObject:@"" forKey:obj];
  
  /* now update the full ACL */
  if (![manager setOperations:self->accessIds onObjectID:self->globalID]) {
    // TODO: localize
    [self setErrorString:@"Could not set access rights"];
    return nil;
  }
  [self postAccessHasChanged:self->globalID];
  
  return [[(OGoSession *)[self session] navigation] leavePage];
}

- (id)cancel {
  return [[(OGoSession *)[self session] navigation] leavePage];
}

@end /* SkyObjectPropertyEditor */
