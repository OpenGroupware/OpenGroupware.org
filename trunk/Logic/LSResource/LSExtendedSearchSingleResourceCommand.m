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

#include <LSSearch/LSExtendedSearchCommand.h>

@interface LSExtendedSearchSingleResourceCommand : LSExtendedSearchCommand
{
}

@end

#include "common.h"

@implementation LSExtendedSearchSingleResourceCommand

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

  LSRunCommandV(_context, @"resource", @"get",
                @"returnType", intObj(LSDBReturnType_ManyObjects), nil);
}

- (EOSQLQualifier *)extendedSearchQualifier:(void *)_context {
  EOSQLQualifier *qualifier;
  EOSQLQualifier *isResourceQualifier;

  qualifier = [super extendedSearchQualifier:_context];
  
  isResourceQualifier = [[EOSQLQualifier alloc] initWithEntity:[self entity]
                                                qualifierFormat:@"type=1"];
  [qualifier conjoinWithQualifier:isResourceQualifier];
  [isResourceQualifier release]; isResourceQualifier = nil;
  return qualifier;
}

- (NSString *)entityName {
  return @"Resource";
}

@end /* LSExtendedSearchSingleResourceCommand */
