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

// TODO: is this actually used somewhere - looks broken!

#include <LSFoundation/LSGetObjectForGlobalIDs.h>

/*
  This command fetches account-objects based on a list of EOGlobalIDs.
*/

@interface LSGetAccountsForGlobalIDsCommand : LSGetObjectForGlobalIDs
{
@protected  
  BOOL     fetchArchivedAccounts;
}
@end

#include <LSFoundation/LSCommandKeys.h>
#import <EOControl/EOControl.h>
#import <GDLAccess/GDLAccess.h>
#include "common.h"

@implementation LSGetAccountsForGlobalIDsCommand

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    self->fetchArchivedAccounts = NO;
  }
  return self;
}

- (NSString *)entityName {
  // TODO: this looks weird? There is no entity "Account"?!
  return @"Account";
}

/* execution */

- (EOSQLQualifier *)validateQualifier:(EOSQLQualifier *)_qual {
  EOSQLQualifier *isArchivedQualifier;
  
  if (self->fetchArchivedAccounts) 
    return _qual;
  
  isArchivedQualifier = [[EOSQLQualifier alloc]
                                         initWithEntity:[self entity]
                                         qualifierFormat:
                                           @"dbStatus <> 'archived'"];

  [_qual conjoinWithQualifier:isArchivedQualifier];
  [isArchivedQualifier release]; isArchivedQualifier = nil;
  return _qual;
}

- (void)fetchAdditionalInfosForObjects:(NSArray *)_obj context:(id)_context {
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"fetchArchivedAccounts"])
    self->fetchArchivedAccounts = [_value boolValue];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"fetchArchivedAccounts"])
    return [NSNumber numberWithBool:self->fetchArchivedAccounts];

  return [super valueForKey:_key];
}

@end /* LSGetAccountsForGlobalIDsCommand */
