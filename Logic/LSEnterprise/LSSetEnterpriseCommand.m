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

#include "LSSetCompanyCommand.h"

@class NSArray;

@interface LSSetEnterpriseCommand : LSSetCompanyCommand
{
@protected
  NSArray *persons;
}

@end

#import "common.h"

@implementation LSSetEnterpriseCommand

- (void)dealloc {
  RELEASE(self->persons);
  [super dealloc];
}

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];

  if (self->persons != nil) { 
    id <LSCommand> cmd = LSLookupCommand(@"enterprise", @"set-persons");

    [cmd takeValue:[self returnValue] forKey:@"group"];
    [cmd takeValue:self->persons forKey:@"members"];
    [cmd runInContext:_context];
  }
}

// record initializer

- (NSString *)entityName {
  return @"Enterprise";
}

// accessors

- (void)setPersons:(NSArray *)_persons {
  ASSIGN(persons, _persons);
}

- (NSArray *)persons {
  return self->persons;
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"persons"]) {
    [self setPersons:_value];
    return;
  }
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"persons"])
    return [self persons];
  else
    return [super valueForKey:_key];
}

@end
