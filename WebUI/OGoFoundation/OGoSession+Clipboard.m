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

#include "OGoSession.h"
#include "common.h"
#include <OGoFoundation/NSObject+LSWPasteboard.h>
#include <OGoFoundation/LSWClipboardOwner.h>

@implementation OGoSession(Clipboard)

- (OWPasteboard *)clipboard {
  return [self pasteboardWithName:LSWClipboardName];
}

- (NSArray *)clipboardTypesForObject:(id)_object {
  return [NSArray arrayWithObject:[_object lswPasteboardType]];
}

- (void)placeInClipboard:(id)_object types:(NSArray *)_types {
  OWPasteboard *pb = [self clipboard];

  NSAssert(pb, @"no clipboard available ..");

  [pb declareTypes:_types
      owner:[LSWClipboardOwner clipboardOwnerForSession:self object:_object]];

  [self logWithFormat:@"declared clipboard types: %@", _types];
  
  NSAssert([pb setObject:_object forType:[_object lswPasteboardType]],
           @"could not set pasteboard data");
}

- (void)placeInClipboard:(id)_object {
  [self placeInClipboard:_object
	types:[self clipboardTypesForObject:_object]];
}

- (id)objectInClipboardWithType:(NGMimeType *)_type {
  return [[self clipboard] objectForType:_type];
}

- (id)objectInClipboard {
  OWPasteboard *cb    = [self clipboard];
  NSArray      *types = [cb types];
  id           type;
  id           object;

  if ([types count] == 0) {
    [self logWithFormat:
            @"WARNING: could not get object from clipboard (no types declared)"];
    return nil;
  }
  type = [cb availableTypeFromArray:types];
  if (type == nil) {
    [self logWithFormat:@"WARNING: could not get object from clipboard .."];
    return nil;
  }
  
  object = [self objectInClipboardWithType:type];
  if (object)
    return object;
  else {
    [self logWithFormat:
            @"WARNING: could not get object from clipboard for type %@.",
            type];
    return nil;
  }
}

- (NSString *)labelForObjectInClipboard {
  return [self labelForObject:[self objectInClipboard]];
}

- (BOOL)clipboardContainsObject {
  OWPasteboard *cb = [self clipboard];
  return ([[cb types] count]) > 0 ? YES : NO;
}

@end /* OGoSession(Clipboard) */
