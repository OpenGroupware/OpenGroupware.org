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

#include <LSAddress/LSGetCompanyForMemberCommand.h>

@interface LSGetEnterpriseForPersonCommand : LSGetCompanyForMemberCommand
{
  NSArray *attributes;
  /* you can define groups of attributes to fetch, e.g.
       "telephones" and
       "extendedAttributes"
  */
}
@end

@interface LSGetEnterpriseForPersonCommand(PrivateMethodes)
- (BOOL)fetchGlobalIDs;
@end

#include "common.h"

@implementation LSGetEnterpriseForPersonCommand

- (void)dealloc {
  [self->attributes release];
  [super dealloc];
}

// record initializer

- (NSString *)entityName {
  return @"Person";
}

- (NSString *)groupEntityName {
  return @"Enterprise";
}

- (NSString *)relationKey {
  return @"enterprises";
}

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];

  if ([self fetchGlobalIDs]) return;
  
  if (self->attributes == nil ||
      [self->attributes containsObject:@"extendedAttributes"]) {
    //get extended attributes
    LSRunCommandV(_context, @"enterprise", @"get-extattrs",
                  @"objects", [self object],
                  @"relationKey", @"companyValue", nil);
  }

  if (self->attributes == nil ||
      [self->attributes containsObject:@"telephones"]) {
    //get telephones
    LSRunCommandV(_context, @"enterprise", @"get-telephones",
                  @"objects", [self object],
                  @"relationKey", @"telephones", nil);
  }
}

/* accessors */

- (void)setAttributes:(NSArray *)_attrs {
  ASSIGN(self->attributes, _attrs);
}
- (NSArray *)attributes {
  return self->attributes;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"person"] || [_key isEqualToString:@"object"])
    [self setMember:_value];
  else if ([_key isEqualToString:@"persons"])
    [self setMembers:_value];
  else if ([_key isEqualToString:@"attributes"])
    [self setAttributes:_value];  
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"person"] || [_key isEqualToString:@"object"])
    return [self member];
  if ([_key isEqualToString:@"persons"])
    return [self members];
  if ([_key isEqualToString:@"attributes"])
    return [self attributes];

  return [super valueForKey:_key];
}

@end /* LSGetEnterpriseForPersonCommand */
