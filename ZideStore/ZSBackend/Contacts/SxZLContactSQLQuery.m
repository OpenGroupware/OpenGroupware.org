/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id: SxZLContactSQLQuery.m 1 2004-08-20 11:17:52Z znek $

#include "common.h"
#include "SxZLContactSQLQuery.h"

@implementation NSEnumerator(Transactions)
- (void)setAutoCommit:(BOOL)_commit {}
- (void)setAutoRollback:(BOOL)_commit {}
@end

@implementation SxZLContactSQLQuery

typedef enum {
    isPublic,
    isPrivate,
    isAccount,
    isPerson,
    isGroup,
    isEnterprise
  } QueryType;

- (NSDictionary *)contactForEO:(id)_eo qType:(QueryType)_qType {
  NSEnumerator *keyEnum;
  NSString     *key;
  NSMutableDictionary *dict;

  keyEnum = [_eo keyEnumerator];
  dict    = [NSMutableDictionary dictionaryWithCapacity:10];

  while ((key = [keyEnum nextObject])) {
    id o;

    o = [_eo valueForKey:key];

    if ([o isNotNull]) {
      [dict setObject:o forKey:key];
    }
  }
  [dict setObject:[_eo valueForKey:@"companyId"] forKey:@"pkey"];

  if (_qType == isPerson || _qType == isPerson || _qType == isPrivate ||
      _qType == isAccount)
  {
    [dict setObject:[_eo valueForKey:@"name"] forKey:@"sn"];
    [dict setObject:[_eo valueForKey:@"firstname"] forKey:@"givenname"];
    [dict setObject:[_eo valueForKey:@"birthday"] forKey:@"bday"];
    [dict setObject:[_eo valueForKey:@"description"] forKey:@"nickname"];
    [dict setObject:[_eo valueForKey:@"bossName"] forKey:@"manager"];
    [dict setObject:[_eo valueForKey:@"partnerName"] forKey:@"spousecn"];
    [dict setObject:[_eo valueForKey:@"assistantName"] forKey:@"secretarycn"];
    [dict setObject:[_eo valueForKey:@"office"] forKey:@"roomnumber"];
    [dict setObject:[_eo valueForKey:@"occupation"] forKey:@"profession"];
    [dict setObject:[_eo valueForKey:@"anniversary"]
          forKey:@"weddinganniversary"];
    [dict setObject:[_eo valueForKey:@"freebusyUrl"] forKey:@"fburl"];
    [dict setObject:[_eo valueForKey:@"nameTitle"] forKey:@"nametitle"];
    [dict setObject:[_eo valueForKey:@"nameAffix"] forKey:@"nameaffix"];
    [dict setObject:[_eo valueForKey:@"imAddress"] forKey:@"imaddress"];
    [dict setObject:[_eo valueForKey:@"associatedContacts"]
          forKey:@"associatedcontacts"];
    [dict setObject:[_eo valueForKey:@"associatedCategories"]
          forKey:@"associatedcategories"];
    [dict setObject:[_eo valueForKey:@"associatedCompany"]
          forKey:@"associatedcompany"];
  }
  else if (_qType == isEnterprise || _qType == isGroup) {
    [dict setObject:[_eo valueForKey:@"description"] forKey:@"cn"];
    [dict setObject:[_eo valueForKey:@"email"] forKey:@"email1"];
  }
  [dict setObject:[_eo valueForKey:@"objectVersion"]
        forKey:@"object_version"];

#if 0  
  if ([self shouldFetchAllEmails] && [self isPersonQuery]) {
    [self addColumn:@"email1.value_string" as:@"email1" to:_sql];
    [self addColumn:@"email2.value_string" as:@"email2" to:_sql];
    [self addColumn:@"email3.value_string" as:@"email3" to:_sql];
  }
  if ([self isPersonQuery])
    [self addColumn:@"extjobtitle.value_string" as:@"jobtitle" to:_sql];
  
  if ([self shouldFetchAllPhoneNumbers] && ![self isGroupQuery]) {
    if (![self isNumberReserved]) {
      [self addColumn:@"t1.number"  as:@"tel01" to:_sql];
      [self addColumn:@"t5.number"  as:@"tel05" to:_sql];
      if ([self isPersonQuery])
	[self addColumn:@"t3.number"  as:@"tel03" to:_sql];
      [self addColumn:@"t10.number" as:@"tel10" to:_sql];
      if ([self isPersonQuery])
	[self addColumn:@"t15.number" as:@"tel15" to:_sql];
    }
    else {
      [self addColumn:@"t1.fnumber"  as:@"tel01" to:_sql];
      [self addColumn:@"t5.fnumber"  as:@"tel05" to:_sql];
      if ([self isPersonQuery])
        [self addColumn:@"t3.fnumber"  as:@"tel03" to:_sql];
      [self addColumn:@"t10.fnumber" as:@"tel10" to:_sql];
      if ([self isPersonQuery])
        [self addColumn:@"t15.fnumber" as:@"tel15" to:_sql];
    }
  }
  
  if ([self isPersonQuery]) {
    if ([self shouldFetchLocationAddress])
      [self addAddrResultOfTable:@"location" prefix:@"loc"  to:_sql];
    if ([self shouldFetchMailingAddress])
      [self addAddrResultOfTable:@"mailing"  prefix:@"mail" to:_sql];
    if ([self shouldFetchPrivateAddress])
      [self addAddrResultOfTable:@"private"  prefix:@"priv" to:_sql];
  }
  else if ([self isEnterpriseQuery]) {
    [self addAddrResultOfTable:@"ship" prefix:@"ship"  to:_sql];
    [self addAddrResultOfTable:@"bill" prefix:@"bill"  to:_sql];
  }
#endif
  return dict;
}

- (NSEnumerator *)run {
  LSCommandContext *c;
  NSArray          *array;
  NSMutableArray   *result;
  NSEnumerator     *enumerator;
  id               obj;
  QueryType        queryType;
  
  c   = [self commandContext];
  if ([self isPublicContactQuery]) {
    queryType = isPublic;
    array = [c runCommand:@"person::get",
               @"isPrivate", [NSNumber numberWithBool:NO],
               @"returnType", intObj(LSDBReturnType_ManyObjects), nil];
  }
  else if ([self isPrivateContactQuery]) {
    queryType = isPrivate;
    array = [c runCommand:@"person::get",
                 @"isPrivate", [NSNumber numberWithBool:YES],
               @"returnType", intObj(LSDBReturnType_ManyObjects), nil];
  }
  else if ([self isAccountContactQuery]) {
    queryType = isAccount;
    array = [c runCommand:@"account::get",
               @"returnType", intObj(LSDBReturnType_ManyObjects), nil];
  }
  else if ([self isPersonQuery]) {
    queryType = isPerson;
    array = [c runCommand:@"person::get",
               @"returnType", intObj(LSDBReturnType_ManyObjects), nil];
  }
  else if ([self isGroupQuery]) {
    queryType = isGroup;
    array = [c runCommand:@"team::get-all",
               @"returnType", intObj(LSDBReturnType_ManyObjects), nil];
  }
  else if ([self isEnterpriseQuery]) {
    queryType = isEnterprise;
    array = [c runCommand:@"enterprise::get",
               @"returnType", intObj(LSDBReturnType_ManyObjects), nil];
  }
  else {
    NSLog(@"%s:%d unmapped query ...", __PRETTY_FUNCTION__, __LINE__);
    array = nil;
  }
  enumerator = [array objectEnumerator];
  result     = [NSMutableArray arrayWithCapacity:[array count]];
  while ((obj = [enumerator nextObject])) {
    [result addObject:[self contactForEO:obj qType:queryType]];
  }
  return [result objectEnumerator];
}


@end /* SxZLContactSQLQuery */
