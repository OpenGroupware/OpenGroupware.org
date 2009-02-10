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

#include <NGObjWeb/NGObjWeb.h>
#include <OGoFoundation/OGoFoundation.h>
#include <NGMime/NGMimeType.h>
#include <OGoPalm/SkyPalmEntryDataSource.h>

@implementation WODirectAction(PalmViews)

- (id)_newPageForType:(NSString *)_mimetype {
  NGMimeType *type = [NGMimeType mimeType:_mimetype];
  id         sn    = [self session];
  return [sn instantiateComponentForCommand:@"new" type:type];
}

- (id<WOActionResults>)_newPalmAction:(NSString *)_mimetype {
  id page;

  page = [self _newPageForType:_mimetype];
  if ([page isContentPage])
    [[[self session] navigation] enterPage:page];
  
  return page;
}

- (id<WOActionResults>)newPalmAddressAction {
  return [self _newPalmAction:@"eo/palmaddress"];
}
- (id<WOActionResults>)newPalmDateAction {
  id page;
  page = [self _newPalmAction:@"eo/palmdate"];
  return page;
}
- (id<WOActionResults>)newPalmMemoAction {
  return [self _newPalmAction:@"eo/palmmemo"];
}
- (id<WOActionResults>)newPalmJobAction {
  return [self _newPalmAction:@"eo/palmjob"];
}

#if 0
- (id<WOActionResults>)_viewPalmAction:(NSString *)_pageName
  forPalmDB:(NSString *)_palmDb {
  id                     page = nil;
  id                     ctx  = nil;
  NSString               *oid = nil;
  SkyPalmEntryDataSource *ds  = nil;
  id                     obj  = nil;

  if ((oid  = [[self request] formValueForKey:@"oid"]) == nil) {
    [self logWithFormat:@"missing object id in view-action"];
    return nil;
  }
  if ([oid intValue] == 0) {
    [self logWithFormat:@"invalid object id:%@", oid];
    return nil;
  }
  if ((page = [self pageWithName:_pageName]) == nil) {
    [self logWithFormat:@"could not load page: %@",_pageName];
    return nil;
  }

  ctx = [(id)[self session] commandContext];
  ds  = [SkyPalmEntryDataSource dataSourceWithContext:ctx
                                forPalmDb:_palmDb];
  if ((obj = [ds fetchObjectForId:[oid intValue]]) == nil) {
    [self logWithFormat:@"could not load object for id:%@", oid];
    return nil;
  }
  [page setObject:obj];
  if ([page isContentPage])
    [[[self session] navigation] enterPage:page];
  return page;
}
- (id<WOActionResults>)viewPalmAddressAction {
  return [self _viewPalmAction:@"SkyPalmAddressViewer"
               forPalmDB:@"AddressDB"];
}
- (id<WOActionResults>)viewPalmDateAction {
  return [self _viewPalmAction:@"SkyPalmDateViewer"
               forPalmDB:@"DatebookDB"];
}
- (id<WOActionResults>)viewPalmMemoAction {
  return [self _viewPalmAction:@"SkyPalmMemoViewer"
               forPalmDB:@"MemoDB"];
}
- (id<WOActionResults>)viewPalmJobAction {
  return [self _viewPalmAction:@"SkyPalmJobViewer"
               forPalmDB:@"ToDoDB"];
}
#endif

@end
