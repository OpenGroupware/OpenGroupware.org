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

#include <OGoFoundation/SkyEditorComponent.h>

@interface SkyAddressEditorComponent : SkyEditorComponent
@end

#include <OGoFoundation/SkyEditorPage.h>
#include <OGoFoundation/LSWNotifications.h>
#include <OGoContacts/SkyAddressDocument.h>
#include <EOControl/EOKeyGlobalID.h>
#include "common.h"

@implementation SkyAddressEditorComponent

/* accessors */

- (id)address {
  return [self document];
}

- (NSString *)typeLabel {
  NSString *typeL;
  
  typeL = [[[self address] type] stringValue];
  [self debugWithFormat:@"self.address.type is '%@'", typeL];
  
  typeL = [@"addresstype_" stringByAppendingString:typeL];
  return [[self labels] valueForKey:typeL];
}

@end /* SkyAddressEditorComponent */
