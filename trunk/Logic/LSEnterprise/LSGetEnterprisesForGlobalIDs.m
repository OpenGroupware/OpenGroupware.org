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

#include <LSFoundation/LSGetObjectForGlobalIDs.h>

/*
  This command fetches enterprise-objects based on a list of EOGlobalIDs.
*/

@interface LSGetEnterprisesForGlobalIDs : LSGetObjectForGlobalIDs
@end

#include <LSFoundation/LSCommandKeys.h>
#include "common.h"

@implementation LSGetEnterprisesForGlobalIDs

- (NSString *)entityName {
  return @"Enterprise";
}

- (BOOL)_shouldFetchAttribute:(NSString *)_attr {
  NSArray *attrs;

  attrs = self->attributes;
  
  return (attrs == nil)
    ? YES
    : [attrs containsObject:_attr];
}

- (void)fetchAdditionalInfosForObjects:(NSArray *)_objs context:(id)_context {
  if ([_objs count] == 0) return;
  
  if ([self _shouldFetchAttribute:@"extendedAttributes"]) {
    LSRunCommandV(_context, @"enterprise", @"get-extattrs",
                  @"objects", _objs,
                  @"entityName",  @"Enterprise",
                  @"relationKey", @"companyValue", nil);
  }
  if ([self _shouldFetchAttribute:@"telephones"]) {
    LSRunCommandV(_context, @"enterprise", @"get-telephones",
                  @"objects", _objs,
                  @"relationKey", @"telephones", nil);
  }
  if ([self _shouldFetchAttribute:@"comment"]) {
    LSRunCommandV(_context, @"enterprise", @"get-comment",
                  @"objects", _objs,
                  @"relationKey", @"comment", nil);
  }
}

@end /* LSGetPersonsForGlobalIDs */
