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

#include "LSNewCompanyCommand.h"

@interface LSNewPersonCommand : LSNewCompanyCommand
{
  id enterprise;
}

@end

#import "common.h"

@implementation LSNewPersonCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->enterprise);
  [super dealloc];
}
#endif

// access check
- (NSArray *)accountAttributes {
  static NSArray *accountAttr = nil;
  if (accountAttr == nil) {
    accountAttr =
      [NSArray arrayWithObjects:
               //@"isAccount",
               @"isIntraAccount",
               @"isExtraAccount",
               @"isTemplateUser",
               @"isLocked",
               @"login",
               @"password",
               nil];
    RETAIN(accountAttr);
  }
  return accountAttr;
}

// prepare
- (void)_prepareForExecutionInContext:(id)_context {
  NSEnumerator *e;
  id one;
  id newValue;

  e = [[self accountAttributes] objectEnumerator];
  while ((one = [e nextObject])) {
    newValue = [self valueForKey:one];
    if ([newValue isNotNull]) {
      NSLog(@"WARNING[%s]: %@ tried to create person with account value '%@'",
            __PRETTY_FUNCTION__, [[_context valueForKey:LSAccountKey]
                                            valueForKey:@"login"], one);
      [self takeValue:[NSNull null] forKey:one];
    }
  }

  [super _prepareForExecutionInContext:_context];
  [[self object] takeValue:[NSNumber numberWithBool:YES] forKey:@"isPerson"];
  [[self object] takeValue:[NSNumber numberWithBool:NO]  forKey:@"isAccount"];
}

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];

  if (self->enterprise != nil) {
    LSRunCommandV(_context, @"person", @"set-enterprise",
                  @"member", [self object],
                  @"groups", [NSArray arrayWithObject:self->enterprise], nil);
  }
}

// accessors

- (void)setEnterprise:(id)_enterprise {
  ASSIGN(self->enterprise, _enterprise);
}
- (id)enterprise {
  return self->enterprise;
}

// initialize records

- (NSString *)entityName {
  return @"Person";
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"enterprise"]) {
    [self setEnterprise:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"enterprise"])
    return [self enterprise];
  return [super valueForKey:_key];
}

@end
