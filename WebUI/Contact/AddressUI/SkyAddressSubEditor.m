/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include <OGoFoundation/SkyEditorComponent.h>

@interface SkyAddressSubEditor : SkyEditorComponent
@end

#include "common.h"
#include <OGoContacts/SkyAddressDocument.h>

@implementation SkyAddressSubEditor

/* accessors */

- (SkyAddressDocument *)address {
  return (SkyAddressDocument *)[self document];
}

- (NSString *)typeLabel {
  NSString *typeL;
  
  typeL = [[[self address] type] stringValue];
  typeL = [@"addresstype_" stringByAppendingString:typeL];
  
  return [[self labels] valueForKey:typeL];
}

- (BOOL)save {
  return [[self document] save];
}

@end /* SkyAddressEditorComponent */
