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

#include <OGoPalmUI/SkyPalmEntryList.h>

/*
  a table view for viewing palm addresses

  > subKey       - userDefaultSubKey                      (may be nil)
  > action       - action for single job                  (may be nil)

  < address      - current address in iteration

 */

@interface SkyPalmAddressList : SkyPalmEntryList
{}
@end

#import <Foundation/Foundation.h>
#include <OGoPalm/SkyPalmAddressDocument.h>
#include <OGoFoundation/OGoFoundation.h>

@implementation SkyPalmAddressList

// overwriting
- (NSString *)palmDb {
  return @"AddressDB";
}
- (NSString *)itemKey {
  return @"address";
}
- (NSString *)updateNotificationName {
  return @"LSWUpdatedPalmAddress";
}
- (NSString *)deleteNotificationName {
  return @"LSWDeletedPalmAddress";
}
- (NSString *)newNotificationName {
  return @"LSWNewPalmAddress";
}
- (NSString *)newDirectActionName {
  return @"newPalmAddress";
}
- (NSString *)viewDirectActionName {
  return @"viewPalmAddress";
}
- (NSString *)primaryKey {
  return @"palm_address_id";
}

- (NSArray *)possibleClickKeys {
  static NSArray *clickKeys = nil;

  if (clickKeys == nil) {
    clickKeys = [[NSArray alloc] initWithObjects:
                                 @"attribute_description",
                                 @"attribute_lastname",
                                 @"attribute_firstname",
                                 @"attribute_company", nil];
  }
  return clickKeys;
}

// values

- (NSString *)addressIcon {
  return ([[(SkyPalmAddressDocument *)[self record] skyrixType]
                                    isEqualToString:@"person"])
    ? @"link_person.gif"
    : @"link_enterprise.gif";
}

// selection actions

- (id)selectionCreatePersons {
  // not yet possible
  [self clearSelections];
  return nil;
}
- (id)selectionCreateEnterprises {
  // not yet possible
  [self clearSelections];
  return nil;
}

@end
