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

@interface LSSetAddressCommand : LSDBObjectSetCommand
{
@private
  BOOL shouldLog;
}

@end

#import "common.h"

@implementation LSSetAddressCommand

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    self->shouldLog = YES;
    [self takeValue:@"Address changed" forKey:@"logText"];
    [self takeValue:@"05_changed"      forKey:@"logAction"];
  }
  return self;
}

- (void)_executeInContext:(id)_context {
  id      companyId  = [[self object] valueForKey:@"companyId"];
  NSArray *companies = nil;

  [super _executeInContext:_context];
  
  companies = LSRunCommandV(_context, @"company",  @"get",
                            @"primaryKey",  @"companyId",
                            @"companyId",   companyId, nil);

  [self assert:([companies count] < 2)
        format:@"Only one object allowed for one companyId, "
               @"found %i companies: %@", [companies count], companies];
  [self assert:([companies count] != 0)
        format:@"Need one object for companyId %@, found none", companyId];
  
  if (self->shouldLog) {
    LSRunCommandV(_context, @"object", @"add-log",
                    @"logText",  [self valueForKey:@"logText"],
                    @"action",   [self valueForKey:@"logAction"],
                    @"objectId", companyId, nil);
  }
  LSRunCommandV(_context, @"object", @"increase-version",
                @"object", [companies lastObject], nil);
}


// initialize records

- (NSString *)entityName {
  return @"Address";
}


- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"shouldLog"])
    self->shouldLog = [_value boolValue];
  else 
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"shouldLog"])
    return [NSNumber numberWithBool:self->shouldLog];
  else
    return [super valueForKey:_key];
}

@end
