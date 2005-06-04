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

#include <LSAddress/LSSetCompanyCommand.h>

@class NSArray;

@interface LSSetEnterpriseCommand : LSSetCompanyCommand
{
@protected
  NSArray *persons;
}

@end

#include "common.h"

@implementation LSSetEnterpriseCommand

- (void)dealloc {
  [self->persons release];
  [super dealloc];
}

/* execute command */

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];

  if (self->persons != nil) { 
    id <LSCommand> cmd = LSLookupCommand(@"enterprise", @"set-persons");

    [cmd takeValue:[self returnValue] forKey:@"group"];
    [cmd takeValue:self->persons forKey:@"members"];
    [cmd runInContext:_context];
  }
}

/* record initializer */

- (NSString *)entityName {
  return @"Enterprise";
}

/* accessors */

- (void)setPersons:(NSArray *)_persons {
  ASSIGN(persons, _persons);
}
- (NSArray *)persons {
  return self->persons;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"persons"]) {
    [self setPersons:_value];
    return;
  }

  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"persons"])
    return [self persons];

  return [super valueForKey:_key];
}

@end /* LSSetEnterpriseCommand */
