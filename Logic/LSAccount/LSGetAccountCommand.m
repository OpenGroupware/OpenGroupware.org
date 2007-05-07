/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2007      Helge Hess

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

#include <GDLAccess/EOSQLQualifier.h>
#include <LSGetAccountCommand.h>
#include "common.h"

@implementation LSGetAccountCommand

/* command methods */

- (void)_prepareForExecutionInContext:(id)_context {
  EOSQLQualifier *myQualifier;
  EOSQLQualifier *isArchivedQualifier;
  
  myQualifier = [[EOSQLQualifier alloc] initWithEntity:[self entity]
                                        qualifierFormat:@"isAccount=1"];
  isArchivedQualifier = 
    [[EOSQLQualifier alloc] initWithEntity:[self entity]
                            qualifierFormat:@"dbStatus <> 'archived'"];
  
  [super _prepareForExecutionInContext:_context];
  [self conjoinWithQualifier:myQualifier];
  [self conjoinWithQualifier:isArchivedQualifier];
  [myQualifier         release];
  [isArchivedQualifier release];
}

- (void)_executeInContext:(id)_context {
  id obj;
  
  [super _executeInContext:_context];
  
  if ([(obj = [self object]) isNotNull]) {
    /* found a matching account */
  
    /* set teams for result accounts(s) in key 'teams' */
  
    LSRunCommandV(_context, @"account", @"teams",
		  @"accounts",   [self object],
		  @"returnType", intObj(LSDBReturnType_ManyObjects), nil);
  
    /* set extended attributes for result account(s) */
  
    LSRunCommandV(_context, @"person", @"get-extattrs",
		  @"objects", [self object],
		  @"relationKey", @"companyValue", nil);
  
    /* get telephones */
    LSRunCommandV(_context, @"person", @"get-telephones",
		  @"objects", [self object],
		  @"relationKey", @"telephones", nil);
  }
}

/* record initializer */

- (NSString *)entityName {
  return @"Person";
}

@end /* LSGetAccountCommand */
