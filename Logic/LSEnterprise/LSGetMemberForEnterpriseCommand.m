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

#include "LSGetMemberForCompanyCommand.h"

@interface LSGetMemberForEnterpriseCommand : LSGetMemberForCompanyCommand
{
  NSArray *attributes;
}
@end

@interface LSGetMemberForCompanyCommand(PrivateMethodes)
- (BOOL)fetchGlobalIDs;
@end

#include "common.h"

@implementation LSGetMemberForEnterpriseCommand

- (void)dealloc {
  [self->attributes release];
  [super dealloc];
}
 
// record initializer

- (NSString *)entityName {
  return @"Enterprise";
}

- (NSString *)memberEntityName {
  return @"Person";
}

- (void)_executeInContext:(id)_context {
  
  [super _executeInContext:_context];

  if ([self fetchGlobalIDs]) return;

  //get extended attributes

  if (self->attributes == nil ||
      [self->attributes containsObject:@"extendedAttributes"]) {
    LSRunCommandV(_context, @"person", @"get-extattrs",
                  @"objects", [self object],
                  @"relationKey", @"companyValue", nil);
  }

  if (self->attributes == nil ||
      [self->attributes containsObject:@"telephones"]) {
    //get telephones
    LSRunCommandV(_context, @"person", @"get-telephones",
                  @"objects", [self object],
                  @"relationKey", @"telephones", nil);
  }
}

- (void)setAttributes:(NSArray *)_attributes {
  ASSIGN(self->attributes, _attributes);
}
- (NSArray *)attributes {
  return self->attributes;
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"enterprise"] || 
      [_key isEqualToString:@"object"]) {
    [self setGroup:_value];
    return;
  }
  else if ([_key isEqualToString:@"enterprises"]) {
    [self setGroups:_value];
    return;
  }
  else if ([_key isEqualToString:@"attributes"]) {
    [self setAttributes:_value];
    return;
  }

  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"enterprise"] || [_key isEqualToString:@"object"])
    return [self group];
  if ([_key isEqualToString:@"enterprises"])
    return [self groups];
  if ([_key isEqualToString:@"attributes"])
    return [self attributes];

  return [super valueForKey:_key];
}

@end /* LSGetMemberForEnterpriseCommand */
