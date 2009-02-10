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

#include <OGoPalmUI/SkyPalmEntryEditor.h>

@interface SkyPalmAddressEditor : SkyPalmEntryEditor
{
}

- (id)address;

@end

#import <Foundation/Foundation.h>

@implementation SkyPalmAddressEditor

// accessors
- (id)address {
  return [self snapshot];
}

- (NSString *)phoneLabelIdLabel {
  static NSDictionary *labelMapping = nil;
  if (labelMapping == nil) {
    labelMapping =
      [[NSDictionary alloc] initWithObjectsAndKeys:
                            @"attribute_work",   [NSNumber numberWithInt:0],
                            @"attribute_home",   [NSNumber numberWithInt:1],
                            @"attribute_fax",    [NSNumber numberWithInt:2],
                            @"attribute_other",  [NSNumber numberWithInt:3],
                            @"attribute_email",  [NSNumber numberWithInt:4],
                            @"attribute_main",   [NSNumber numberWithInt:5],
                            @"attribute_pager",  [NSNumber numberWithInt:6],
                            @"attribute_mobile", [NSNumber numberWithInt:7],
                            nil];
  }
  return [labelMapping valueForKey:self->item];
}

// actions
- (BOOL)checkData {
  [self checkStringForKey:@"address"];
  [self checkStringForKey:@"city"];
  [self checkStringForKey:@"company"];
  [self checkStringForKey:@"country"];
  [self checkStringForKey:@"firstname"];
  [self checkStringForKey:@"lastname"];
  [self checkStringForKey:@"note"];
  [self checkStringForKey:@"phone0"];
  [self checkStringForKey:@"phone1"];
  [self checkStringForKey:@"phone2"];
  [self checkStringForKey:@"phone3"];
  [self checkStringForKey:@"phone4"];
  [self checkStringForKey:@"state"];
  [self checkStringForKey:@"title"];
  [self checkStringForKey:@"zipcode"];
  [self checkStringForKey:@"custom1"];
  [self checkStringForKey:@"custom2"];
  [self checkStringForKey:@"custom3"];
  [self checkStringForKey:@"custom4"];

  {
    NSString *lastname, *firstname, *company;
    lastname  = [[self snapshot] valueForKey:@"lastname"];
    firstname = [[self snapshot] valueForKey:@"firstname"];
    company   = [[self snapshot] valueForKey:@"company"];

    if (((lastname == nil)  || ([lastname length] == 0)) &&
        ((firstname == nil) || ([firstname length] == 0)) &&
        ((company == nil)   || ([company length] == 0)))
      {
        [self setErrorString:
              @"fill at least on of this fields:"
              @"lastname, firstname or company"];
        return NO;
      }
  }

  return YES;
}

- (id)save {
  if (![self checkData])
    return nil;
  return [super save];
}

// overwriting
- (NSString *)palmDb {
  return @"AddressDB";
}
@end /* SkyPalmAddressEditor */
