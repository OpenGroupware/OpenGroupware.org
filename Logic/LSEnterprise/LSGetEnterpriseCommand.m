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

#import <LSFoundation/LSDBObjectGetCommand.h>

@interface LSGetEnterpriseCommand : LSDBObjectGetCommand
@end

#include "common.h"
#import <EOControl/EOKeyGlobalID.h>

@implementation LSGetEnterpriseCommand

// command methods

- (void)_executeInContext:(id)_context {
  id o;
  
  [super _executeInContext:_context];

  o = [self object];
  o = LSRunCommandV(_context,
                    @"enterprise", @"check-permission",
                    @"object", o, nil);
  [self setObject:o];

  /* get extended attributes */
  LSRunCommandV(_context,
                @"enterprise", @"get-extattrs",
                @"objects", [self object],
                @"relationKey", @"companyValue", nil);
}

/* record initializer */

- (NSString *)entityName {
  return @"Enterprise";
}

/* KVC */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"gid"]) {
    _key   = @"companyId";
    _value = [_value keyValues][0];
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  id v;
  
  if ([_key isEqualToString:@"gid"]) {
    v = [super valueForKey:@"companyId"];
    v = [EOKeyGlobalID globalIDWithEntityName:[self entityName]
                       keys:&v keyCount:1
                       zone:NULL];
  }
  else
    v = [super valueForKey:_key];
  
  return v;
}

@end
