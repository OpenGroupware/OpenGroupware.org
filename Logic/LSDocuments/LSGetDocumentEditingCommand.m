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

#include "common.h"
#include "LSGetDocumentEditingCommand.h"

@implementation LSGetDocumentEditingCommand

- (void)dealloc {
  [self->checkPermissions release];
  [super dealloc];
}

/* operation */

- (void)_checkPermissionsInContext:(id)_context {
  id obj;
    
  obj = LSRunCommandV(_context, @"documentediting", @"check-get-permission",
		      @"object", [self object], nil);
  [self setObject:obj];
}

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];
  
  if (self->checkPermissions == nil)
    self->checkPermissions = [NSNumber numberWithBool:YES];
  
  if ([self->checkPermissions boolValue])
    [self _checkPermissionsInContext:_context];
  
  LSRunCommandV(_context, @"documentediting", @"get-attachment-name",
                @"objects", [self object], nil);
}

/* record initializer */

- (NSString *)entityName {
  return @"DocumentEditing";
}

- (NSNumber *)checkPermissions {
  return self->checkPermissions;
}
- (void)setCheckPermissions:(NSNumber *)_bool {
  ASSIGN(self->checkPermissions, _bool);
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"checkPermissions"]) {
    ASSIGN(self->checkPermissions, _value);
    return;
  }
  
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"checkPermissions"])
    return self->checkPermissions;
  
  return [super valueForKey:_key];
}

@end /* LSGetDocumentEditingCommand */
