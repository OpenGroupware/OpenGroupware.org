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

#include <OGoPalmUI/SkyPalmEntryViewer.h>
#include <OGoPalm/SkyPalmAddressDocument.h>

@interface SkyPalmAddressViewer: SkyPalmEntryViewer
{
}
@end

#import <Foundation/Foundation.h>
#include <OGoFoundation/OGoFoundation.h>

@implementation SkyPalmAddressViewer

// overwriting
- (NSString *)updateNotificationName {
  return @"LSWUpdatedPalmAddress";
}
- (NSString *)deleteNotificationName {
  return @"LSWDeletedPalmAddress";
}
- (NSString *)palmDb {
  return @"AddressDB";
}
- (NSString *)entityName {
  return @"palm_address";
}

// accessors
- (id)address {
  return [self object];
}

// skyrix assignment

- (NSString *)addressIcon {
  return ([[(SkyPalmAddressDocument *)[self address] skyrixType]
                                    isEqualToString:@"person"])
    ? @"link_person.gif"
    : @"link_enterprise.gif";
}

// action

- (id)viewSkyrixRecord {
  id gid = nil;

  gid = [[[self record] skyrixRecord] valueForKey:@"globalID"];

  if (gid) {
    [[self session] transferObject:gid owner:self];
    [self executePasteboardCommand:@"view"];
  }

  return nil;
}
  

@end /* SkyPalmAddressViewer */
