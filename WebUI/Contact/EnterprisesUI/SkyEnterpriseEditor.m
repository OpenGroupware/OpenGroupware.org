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

#include <OGoFoundation/SkyEditorPage.h>

@class NSString;

@interface SkyEnterpriseEditor : SkyEditorPage
{
  BOOL     isInAssignMode;
  BOOL     limitAccessToCreator; // only if isNew
  NSString *addressType;
}
@end

#include "common.h"
#include <OGoFoundation/LSWNotifications.h>
#include <OGoContacts/SkyEnterpriseDocument.h>
#include <OGoContacts/SkyEnterpriseDataSource.h>

@interface SkyEnterpriseEditor(PrivateMethodes)
- (NSString *)_violatedUniqueKeyName;
@end

@implementation SkyEnterpriseEditor

- (void)dealloc {
  [self->addressType release];
  [super dealloc];
}

/* activation */

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(id)_cfg
{
  BOOL r;

  r = [super prepareForActivationCommand:_command
             type:_type configuration:_cfg];
  if (!r) return NO;
  
  if (![[self object] isKindOfClass:[SkyDocument class]]) {
    id obj = [[self object] globalID];
    obj = [self runCommand:@"object::get-by-globalid", @"gid", obj, nil];
    obj = [obj lastObject];
    [self setObject:obj];
  }
  return r;
}

/* accessors */

- (void)setAddressType:(NSString *)_atype {
  ASSIGN(self->addressType, _atype);
}
- (NSString *)addressType {
  return self->addressType;
}

- (id)enterprise {
  return [self object];
}

- (void)setLimitAccessToCreator:(BOOL)_flag {
  self->limitAccessToCreator = _flag;
}
- (BOOL)limitAccessToCreator {
  return self->limitAccessToCreator;
}

- (BOOL)checkConstraintsForSave {
  NSMutableString *error = nil;
  NSString        *lname = nil;
  id              labels = nil;

  labels = [self labels];
  error  = [NSMutableString stringWithCapacity:128];
  lname  = [[self enterprise] valueForKey:@"name"];

  if (lname == nil || ![lname isNotNull] || [lname length] == 0)
    [error appendString:[labels valueForKey:@"error_no_name"]];

  if ([error length] > 0) {
    [self setErrorString:error];
    return NO;
  }
  
  [self setErrorString:nil];
  return [super checkConstraintsForSave];
}

- (SkyDocument *)addressDocument {
  return [[self enterprise] addressForType:[self valueForKey:@"addressType"]];
}

- (void)setIsInAssignMode:(BOOL)_isInAssignMode {
  self->isInAssignMode = _isInAssignMode;
}
- (BOOL)isInAssignMode {
  return self->isInAssignMode;
}

- (BOOL)isOwnerLoggedInOrNew {
  id   myAccount  = [[self session] activeAccount];
  id   accountId  = [myAccount valueForKey:@"companyId"];

  return ([accountId isEqual:[[self object] valueForKey:@"ownerId"]] ||
          [self isInNewMode]);
}

- (BOOL)isDeleteEnabled {
  return [self isInAssignMode] == NO &&
         [self isInNewMode] == NO;
}

- (BOOL)isAccessRightEnabled {
  // TODO: deprecated
  return YES;
}

- (id)save {
  NSString *key   = nil;
  id       result = nil;

  result = [super save];
  if ([self isAccessRightEnabled]) {
    if (result && ([self isInNewMode]) && self->limitAccessToCreator) {
      SkyAccessManager *manager =
        [[[self session] commandContext] accessManager];
      id accessGID = [[[self session] activeAccount] globalID];
      id objectGID = [[self enterprise] globalID];
      if (![manager setOperation:@"rw" onObjectID:objectGID
                    forAccessGlobalID:accessGID])
        {
          NSLog(@"%s: cannot save limited access for creator %@ to "
                @"enterprise %@",
                __PRETTY_FUNCTION__, accessGID, objectGID);
        }
      else
        [[NSNotificationCenter defaultCenter]
                               postNotificationName:
                               @"SkyAccessHasChangedNotification"
                               object:objectGID userInfo:nil];
    }
  }

  if (result)
    return result;
  else if ((key = [self _violatedUniqueKeyName])) {
    NSMutableString *str = [[NSMutableString alloc] initWithCapacity:128];

    [str appendString:[[self labels] valueForKey:@"couldNotSaveEnterprise"]];
    [str appendString:@". "];
    [str appendString:[[self labels] valueForKey:@"fieldMustBeUnique"]];
    [str appendString:@": "];
    [str appendString:[[self labels] valueForKey:key]];
    
    [self setErrorString:str];
    
    return nil;
  }
  return nil;
}

@end /* SkyEnterpriseEditor */


@implementation SkyEnterpriseEditor(PrivateMethodes)

- (BOOL)_isKeyViolated:(NSString *)_key {
  static id searchRec = nil;  
  NSArray   *list     = nil;
  unsigned  maxCount  = ([self isInNewMode]) ? 0 : 1;

  if (searchRec == nil) {
    searchRec = [self runCommand:@"search::newrecord",
                                  @"entity", @"Enterprise", nil];
    [searchRec setComparator:@"EQUAL"];
    RETAIN(searchRec);
  }
  
  [searchRec takeValue:[[self object] valueForKey:_key] forKey:_key];
  list = [self runCommand:@"enterprise::extended-search",
               @"operator",       @"OR",
               @"searchRecords",  [NSArray arrayWithObject:searchRec],
               @"fetchIds",       [NSNumber numberWithBool:YES],
               @"maxSearchCount", [NSNumber numberWithInt:2],
               nil];
  
  return ([list count] > maxCount) ? YES : NO;
}

- (NSString *)_violatedUniqueKeyName {
  if ([self _isKeyViolated:@"number"])
    return @"number";
  
  return nil;
}

- (id)doNothing {
  return nil;
}

@end /* SkyEnterpriseEditor(PrivateMethodes) */
