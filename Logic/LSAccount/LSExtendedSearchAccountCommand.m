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

#include <LSSearch/LSExtendedSearchCommand.h>

@interface LSExtendedSearchCommand(PRIVATE)
- (NSNumber *)fetchIds;
@end

@interface LSExtendedSearchAccountCommand : LSExtendedSearchCommand
@end

#import "common.h"

@implementation LSExtendedSearchAccountCommand

+ (int)version {
  return [super version] /* v2 */;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

/* command methods */

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];

  if ([[self fetchIds] boolValue])
    return;
  
  LSRunCommandV(_context, @"account", @"teams",
		@"accounts", [self object],
		@"returnType", intObj(LSDBReturnType_ManyObjects), nil);

  //get extended attributes 
  LSRunCommandV(_context, @"person", @"get-extattrs",
		@"objects", [self object],
		@"relationKey", @"companyValue", nil);

  //get telephones
  LSRunCommandV(_context, @"person", @"get-telephones",
		@"objects", [self object],
		@"relationKey", @"telephones", nil);
}

- (EOSQLQualifier *)extendedSearchQualifier:(void *)_context {
  EOSQLQualifier *qualifier           = nil;
  EOSQLQualifier *isAccountQualifier  = nil;
  EOSQLQualifier *isArchivedQualifier = nil;

  qualifier = [super extendedSearchQualifier:_context];

  isAccountQualifier  = [[EOSQLQualifier alloc] initWithEntity:[self entity]
                          qualifierFormat:@"isAccount=1"];
  isArchivedQualifier = [[EOSQLQualifier alloc] initWithEntity:[self entity]
                          qualifierFormat:@"dbStatus <> 'archived'"];
  
  [qualifier conjoinWithQualifier:isAccountQualifier];
  [qualifier conjoinWithQualifier:isArchivedQualifier];
  [isAccountQualifier  release]; isAccountQualifier  = nil;
  [isArchivedQualifier release]; isArchivedQualifier = nil;  
  return qualifier;
}

- (NSString *)entityName {
  return @"Person";
}

@end /* LSExtendedSearchAccountCommand */
