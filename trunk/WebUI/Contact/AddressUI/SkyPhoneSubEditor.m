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

#import "common.h"
#import <OGoFoundation/SkyEditorComponent.h>
#import <OGoContacts/SkyCompanyDocument.h>

@interface SkyPhoneSubEditor : SkyEditorComponent {
  NSArray  *showOnly;
  NSString *phoneType;
}
@end /* SkyPhoneEditor */

@implementation SkyPhoneSubEditor

- (void)dealloc {
  [self->phoneType release];
  [self->showOnly release];
  [super dealloc];
}

- (void)setShowOnly:(NSArray *)_attrs {
  ASSIGN(self->showOnly, _attrs);
}
- (NSArray *)showOnly {
  return showOnly;
}

- (SkyCompanyDocument *)company {
  return (SkyCompanyDocument *)[self document];
}

- (NSArray *)phoneTypes {
  NSArray *types;

  types = [[[self company] phoneTypes]
                  sortedArrayUsingSelector:@selector(compare:)];

  if (self->showOnly != nil) {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    int count = [types count];
    int i;

    for (i = 0; i < count; i++) {
      NSString *type = [types objectAtIndex:i];

      if ([self->showOnly containsObject:type]) {
        [result addObject:type];
      }
    }
    return [result autorelease];
  }
  return types;
}

- (void)setPhoneType:(NSString *)_type {
  ASSIGN(self->phoneType, _type);
}
- (NSString *)phoneType {
  return self->phoneType;
}

- (void)setPhoneValue:(NSString *)_value {
  [[self company] setPhoneNumber:_value forType:[self phoneType]];
}
- (NSString *)phoneValue {
  return [[self company] phoneNumberForType:[self phoneType]];
}

- (void)setPhoneInfoValue:(NSString *)_value {
  [[self company] setPhoneInfo:_value forType:[self phoneType]];
}
- (NSString *)phoneInfoValue {
  return [[self company] phoneInfoForType:[self phoneType]];
}

@end /* SkyPhoneEditor */
