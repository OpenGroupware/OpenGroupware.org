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

/*

  bindings

  actionType  componentAction / directAction / noAction
  key         currentKey
  clickKey    key where action should be placed

  value       value to display

  action      componentAction
  href        directAction URL


 */

#include <OGoFoundation/OGoComponent.h>

#define ACTION_NO_ACTION        0
#define ACTION_COMPONENT_ACTION 1
#define ACTION_DIRECT_ACTION    2

@interface SkyPalmEntryListContent : OGoComponent
@end /* SkyPalmEntryListContent */

#include "common.h"

@implementation SkyPalmEntryListContent

// accessors

- (BOOL)synchronizesVariablesWithBindings {
  return NO;
}

- (NSString *)key {
  return [self valueForBinding:@"key"];
}
- (NSString *)clickKey {
  return [self valueForBinding:@"clickKey"];
}
- (BOOL)click {
  return ([[self key] isEqualToString:[self clickKey]])
    ? YES : NO;
}

- (NSString *)actionType {
  return [self valueForBinding:@"actionType"];
}
- (BOOL)hasAction {
  return [[self actionType] isEqualToString:@"componentAction"]
    ? YES : NO;
}

- (BOOL)hasDirectAction {
  return [[self actionType] isEqualToString:@"directAction"]
    ? YES : NO;
}

- (BOOL)hasNoAction {
  NSString *type = [self actionType];
  return ((type == nil) || ([type length] == 0) ||
          ([type isEqualToString:@"noAction"]))
    ? YES : NO;
}

- (id)entryAction {
  return [self valueForBinding:@"action"];
}

- (id)entryActionURL {
  return [self valueForBinding:@"href"];
}

- (id)value {
  return [self valueForBinding:@"value"];
}

@end /* SkyPalmEntryListContent */
