/*
  Copyright (C) 2005 SKYRIX Software AG

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

#include <OGoFoundation/OGoComponent.h>

@interface OGoCycleSelection : OGoComponent
{
  NSString *cycleType;
  NSString *cycleEndDate;
  
  id item; // transient
}

@end

#include "common.h"

@interface WOComponent(LSWAppointmentEditor) // HACK HACK
- (NSString *)calendarOnClickEventForFormElement:(NSString *)_name;
@end

@implementation OGoCycleSelection

- (void)dealloc {
  [self->cycleEndDate release];
  [self->cycleType    release];
  [self->item         release];
  [super dealloc];
}

/* defaults */

- (NSUserDefaults *)userDefaults {
  static NSUserDefaults *ud = nil;
  if (ud == nil) ud = [[NSUserDefaults standardUserDefaults] retain];
  return ud;
}

/* accessors */

- (void)setItem:(id)_value {
  ASSIGNCOPY(self->item, _value);
}
- (id)item {
  return self->item;
}

- (void)setCycleType:(NSString *)_s {
  ASSIGNCOPY(self->cycleType, _s);
}
- (NSString *)cycleType {
  return self->cycleType;
}

- (void)setCycleEndDate:(NSString *)_cDate {
  ASSIGNCOPY(self->cycleEndDate, _cDate);
}
- (NSString *)cycleEndDate {
  return self->cycleEndDate;
}

/* JavaScript support */

- (NSString *)cycleEndDateOnClickEvent {
  // TODO: HACK HACK
  return [[self parent] calendarOnClickEventForFormElement:@"cycleEndDate"];
}

/* notifications */

- (void)sleep {
  [self->item release]; self->item = nil;
  [super sleep];
}

@end /* OGoCycleSelection */
