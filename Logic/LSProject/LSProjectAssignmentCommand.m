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

#include "LSProjectAssignmentCommand.h"
#include "common.h"

@interface LSProjectAssignmentCommand(Privates)
- (void)setHasAccess:(NSNumber *)_hasAccess;
@end

@implementation LSProjectAssignmentCommand

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    [self setHasAccess:[NSNumber numberWithBool:YES]];
  }
  return self;
}

- (void)dealloc {
  [self->companies        release];
  [self->removedCompanies release];
  [self->hasAccess        release];
  [super dealloc];
}

/* accessors */

- (void)setCompanies:(NSArray *)_companies {
  ASSIGN(self->companies, _companies);
}
- (NSArray *)companies {
  return self->companies;
}

- (void)setRemovedCompanies:(NSArray *)_removedCompanies {
  ASSIGN(self->removedCompanies, _removedCompanies);
}
- (NSArray *)removedCompanies {
  return self->removedCompanies;
}

- (void)setHasAccess:(NSNumber *)_hasAccess {
  ASSIGN(self->hasAccess, _hasAccess);
}
- (NSNumber *)hasAccess {
  return self->hasAccess;
}

/* command methods */

- (id)_getAssignmentForAccount:(id)_object inList:(NSArray *)_list {
  NSEnumerator *listEnum;
  NSNumber     *pkey;
  id           listObject;
  
  listEnum = [_list objectEnumerator];
  pkey     = [_object valueForKey:@"companyId"];
  
  while ((listObject = [listEnum nextObject])) {
    NSNumber *opkey;
    
    opkey = [listObject valueForKey:@"companyId"];
    if ([pkey isEqual:opkey]) return listObject;
  }
  return nil;
}

- (void)_removeOldCompaniesInContext:(id)_context {
  NSEnumerator *acEnum      = nil;
  NSEnumerator *asEnum      = nil;
  NSArray      *assignments = nil;
  id           ac           = nil;
  id           as           = nil; 

  acEnum = [self->removedCompanies objectEnumerator];
  
  while ((ac = [acEnum nextObject])) {
    LSRunCommandV(_context, @"person", @"get-project-assignments",
                  @"object",      ac,
                  @"relationKey", @"projectAssignments", nil);
    
    assignments = [ac valueForKey:@"projectAssignments"];
    asEnum = [assignments objectEnumerator];
    
    while ((as = [asEnum nextObject])) {
      NSNumber *asFKey;
      
      asFKey = [as valueForKey:@"projectId"];
      if (![[[self object] valueForKey:@"projectId"] isEqual:asFKey])
        continue;

      LSRunCommandV(_context,        @"projectcompanyassignment",  @"delete",
                    @"object",       as,
                    @"reallyDelete", [NSNumber numberWithBool:YES], nil);
    }
  }
}

- (void)_saveCompaniesInContext:(id)_context {
  NSArray      *oldAssignments = nil;
  NSEnumerator *acEnum         = nil;
  id           ac              = nil; 
  id           obj             = nil;

  obj = [self object];
  
  LSRunCommandV(_context, @"project", @"get-company-assignments",
                @"object",      obj,
                @"relationKey", @"companyAssignments", nil);

  oldAssignments = [obj valueForKey:@"companyAssignments"];
  acEnum         = [self->companies objectEnumerator];
  
  while ((ac = [acEnum nextObject])) {
    id as = [self _getAssignmentForAccount:ac inList:oldAssignments];

    if (as == nil) {
      LSRunCommandV(_context,       @"projectcompanyassignment",  @"new",
                    @"projectId",   [obj valueForKey:@"projectId"],
                    @"companyId",   [ac valueForKey:@"companyId"],
                    @"hasAccess",   self->hasAccess,
                    @"accessRight", [ac valueForKey:@"accessRight"], nil);
    }
    else {
      LSRunCommandV(_context,     @"projectcompanyassignment",  @"set",
                  @"object",      as,
                  @"hasAccess",   self->hasAccess,
                  @"accessRight", [ac valueForKey:@"accessRight"], nil);
    }
    [ac takeValue:[EONull null] forKey:@"accessRight"];
  }
}


- (void)_executeInContext:(id)_context {
  if (self->removedCompanies) {
    [self _removeOldCompaniesInContext:_context];
  }
  if (self->companies) {
    [self _saveCompaniesInContext:_context];
  }
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"project"]) {
    [self setObject:_value];
    return;
  } 
  if ([_key isEqualToString:@"companies"]) {
    [self setCompanies:_value];
    return;
  }
  if ([_key isEqualToString:@"removedCompanies"]) {
    [self setRemovedCompanies:_value];
    return;
  }
  if ([_key isEqualToString:@"accounts"]) {
    [self setCompanies:_value];
    return;
  }
  if ([_key isEqualToString:@"removedAccounts"]) {
    [self setRemovedCompanies:_value];
    return;
  }
  if ([_key isEqualToString:@"hasAccess"]) {
    [self setHasAccess:_value];
    return;
  }
  
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"project"])
    return [self object];
  if ([_key isEqualToString:@"companies"])
    return [self companies];
  if ([_key isEqualToString:@"removedCompanies"])
    return [self removedCompanies];
  if ([_key isEqualToString:@"accounts"])
    return [self companies];
  if ([_key isEqualToString:@"removedAccounts"])
    return [self removedCompanies];
  if ([_key isEqualToString:@"hasAccess"])
    return [self hasAccess];
  
  return [super valueForKey:_key];
}

@end /* LSProjectAssignmentCommand */
