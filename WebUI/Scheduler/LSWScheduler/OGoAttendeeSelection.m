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

#include "OGoUserSelectionComponent.h"

/*
  OGoAttendeeSelection
  
  This component serves similiar roles like SkyParticipantsSelection, but
  has a different visual appearance and includes popups to select the role
  of a given attendee.
*/

@interface OGoAttendeeSelection : OGoUserSelectionComponent
{
  NSString *itemRole; /* gen-variable! CHAIR, REQ-PARTICIPANT, ... */
  NSMutableDictionary *roleMap;
}
@end

#include <OGoFoundation/OGoSession.h>
#include <LSFoundation/LSCommandContext.h>
#include "common.h"

@implementation OGoAttendeeSelection

- (id)init {
  if ((self = [super init]) != nil) {
    self->roleMap = [[NSMutableDictionary alloc] initWithCapacity:16];
  }
  return self;
}

- (void)dealloc {
  [self->roleMap  release];
  [self->itemRole release];
  [super dealloc];
}

/* accessors */

- (void)setItemRole:(NSString *)_value {
  ASSIGNCOPY(self->itemRole, _value);
}
- (NSString *)itemRole {
  return self->itemRole;
}

- (id)itemRoleMapKey {
  return [self->item valueForKey:@"companyId"];
}

- (void)setSelectedItemRole:(NSString *)_value {
  [self->roleMap setObject:_value forKey:[self itemRoleMapKey]];
}
- (NSString *)selectedItemRole {
  return [self->roleMap objectForKey:[self itemRoleMapKey]];
}

/* derived accessors */

- (NSString *)itemRoleLabel {
  NSString *s;
  
  if ((s = [self itemRole]) == nil)
    return nil;
  
  s = [s hasPrefix:@"-"]
    ? [@"popupaction_" stringByAppendingString:s]
    : [@"popuprole_"   stringByAppendingString:s];
  
  return [[self labels] valueForKey:s];
}

/* notifications */

- (void)sleep {
  [self->itemRole release]; self->itemRole = nil;
  [super sleep];
}

/* page processing hooks */

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  /* we reset the role map, it will be filled from the popups */
  [self->roleMap removeAllObjects];
  
  /* Note: the following can trigger a search in the parent class */
  [super takeValuesFromRequest:_req inContext:_ctx];
}

/* participants management */

- (void)applyAddDelActionsInRoleMap {
  unsigned i, count;

  /* walk over result list and add all items which have a status set */
  
  for (i = 0, count = [self->resultList count]; i < count; i++) {
    NSString *role;
    id part;
    
    part = [self->resultList objectAtIndex:i];
    role = [self->roleMap objectForKey:[part valueForKey:@"companyId"]];
    if (![role isNotEmpty] || [role hasPrefix:@"-"]) {
      [self->roleMap removeObjectForKey:[part valueForKey:@"companyId"]];
      continue;
    }
    
    /* add to participants */
    [self->participants addObject:part];
  }
  [self->resultList removeAllObjects];

  /* walk over participants list and remove all items w/o status */
  
  for (i = 0, count = [self->participants count]; i < count; i++) {
    NSString *role;
    id part;
    
    part = [self->participants objectAtIndex:i];
    role = [self->roleMap objectForKey:[part valueForKey:@"companyId"]];
    if ([role isNotEmpty] && ![role hasPrefix:@"-"])
      continue;

    /* abuse self->resultList as a temporary delete-list */
    [self->resultList addObject:part];
  }
  for (i = 0, count = [self->resultList count]; i < count; i++) {
    id part;
    
    part = [self->resultList objectAtIndex:i];
    [self->participants removeObject:part];
  }
  [self->resultList removeAllObjects];
}

/* actions */

- (id)search {
  /* process result-list before it gets replaced */
  [self applyAddDelActionsInRoleMap];
  
  return [super search];
}

@end /* OGoAttendeeSelection */
