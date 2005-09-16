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
  NSString *itemRole; /* CHAIR, REQ-PARTICIPANT, ... */
  NSString *selectedItemRole;
}
@end

#include <OGoFoundation/OGoSession.h>
#include <LSFoundation/LSCommandContext.h>
#include "common.h"

@implementation OGoAttendeeSelection

- (void)dealloc {
  [self->selectedItemRole release];
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

- (void)setSelectedItemRole:(NSString *)_value {
  ASSIGNCOPY(self->selectedItemRole, _value);
}
- (NSString *)selectedItemRole {
  return self->selectedItemRole;
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
  [self->itemRole         release]; self->itemRole         = nil;
  [self->selectedItemRole release]; self->selectedItemRole = nil;
  [super sleep];
}

@end /* OGoAttendeeSelection */
