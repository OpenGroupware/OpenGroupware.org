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

#include "LSWAddressEditor.h"
#include "common.h"

@implementation LSWAddressEditor(Wizard)

- (NSString *)wizardObjectType {
  return @"address";
}

- (id)wizardSave {
  id obj     = nil;
  id result  = nil;
  id address = [self snapshot];

  RELEASE(self->company);
  self->company = [self wizardObjectParent];
  RETAIN(self->company);

  if (self->company == nil || [self addressType] == nil) {
    [self setErrorString:@"cannot insert new address!"];
    return nil;
  }
  
  result = [self runCommand:@"address::get",
                   @"companyId", [self->company valueForKey:@"companyId"],
                   @"type",      [self addressType],
                   @"operator",  @"AND", nil];
  if ([(NSArray *)result count] == 1) {
    id           key         = nil;
    NSEnumerator *enumerator;

    enumerator = [[address allKeys] objectEnumerator];
    result = [result lastObject];
    while ((key = [enumerator nextObject])) {
      [result takeValue:[address valueForKey:key] forKey:key];
    }
    [self setSnapshot:result];      
  }
  
  obj = [self updateObject];
  
  [self _save];
  
  return obj;
}

@end /* LSWAddressEditor(Wizard) */
