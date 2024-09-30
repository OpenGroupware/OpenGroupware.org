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
  This command fetches person-objects based on a list of EOGlobalIDs.

  Additionally it runs or if no 'attributes' argument is set or if the
  proper specifier is set (extendedAttributes, telephones, comment):
    
    person::get-extattrs
    person::get-telephones
    person::get-comment
*/

@interface LSGetPersonsForGlobalIDs : LSGetObjectForGlobalIDs
{
  BOOL fetchArchivedPersons;
}
@end

#include <LSFoundation/LSCommandKeys.h>
#include "common.h"

@implementation LSGetPersonsForGlobalIDs

/* accessors */

- (NSString *)entityName {
  return @"Person";
}

/* extended fetches */

- (BOOL)_shouldFetchAttribute:(NSString *)_attr {
  NSArray *attrs;

  if ((attrs = self->attributes) == nil)
    return YES;
  
  return [attrs containsObject:_attr];
}

- (void)fetchAdditionalInfosForObjects:(NSArray *)_objs context:(id)_context {
  if ([_objs count] == 0) 
    return;
  
  if ([self _shouldFetchAttribute:@"extendedAttributes"]) {
    LSRunCommandV(_context, @"person", @"get-extattrs",
                  @"objects",     _objs,
                  @"entityName",  @"Person",
                  @"relationKey", @"companyValue", nil);
  }
  
  if ([self _shouldFetchAttribute:@"telephones"]) {
    LSRunCommandV(_context, @"person", @"get-telephones",
                  @"objects",    _objs,
                  @"relationKey", @"telephones", nil);
  }
  
  if ([self _shouldFetchAttribute:@"comment"]) {
    LSRunCommandV(_context, @"person", @"get-comment",
                  @"objects",     _objs,
                  @"relationKey", @"comment", nil);
  }
}

- (EOSQLQualifier *)validateQualifier:(EOSQLQualifier *)_qual {
  EOSQLQualifier *isArchivedQualifier = nil;
  
  if (self->fetchArchivedPersons)
    return _qual;
  
  /* filter out archived entries */
  
  isArchivedQualifier = [[EOSQLQualifier alloc] 
                          initWithEntity:[self entity]
                          qualifierFormat:@"dbStatus <> 'archived'"];
  [_qual conjoinWithQualifier:isArchivedQualifier];
  [isArchivedQualifier release];
  return _qual;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"fetchArchivedPersons"])
    self->fetchArchivedPersons = [_value boolValue];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"fetchArchivedPersons"])
    return [NSNumber numberWithBool:self->fetchArchivedPersons];
  
  return [super valueForKey:_key];
}

@end /* LSGetPersonsForGlobalIDs */
