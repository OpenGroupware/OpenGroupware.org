/*
  Copyright (C) 2000-2005 SKYRIX Software AG

  This file is part of OpenGroupware.org

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

#include "DirectAction.h"
#include <EOControl/EOControl.h>
#include <OGoContacts/SkyEnterpriseDocument.h>
#include <OGoContacts/SkyPersonDocument.h>
#include "EOControl+XmlRpcDirectAction.h"
#include "NSObject+EKVC.h"
#include "Session.h"
#include "common.h"
#include <EOControl/EOKeyGlobalID.h>

@interface DirectAction(EnterprisePrivate)
- (SkyEnterpriseDocument *)_getEnterpriseByArgument:(id)_arg;
- (SkyPersonDocument *)_getPersonByArgument:(id)_arg;
@end

@implementation DirectAction(Enterprise)

- (void)_takeValuesDict:(NSDictionary *)_from
  toEnterprise:(SkyEnterpriseDocument **)_to
{
  NSEnumerator *objEnum = nil;
  id           tmp      = nil;
  id           obj      = nil;
  
  [*_to takeValuesFromObject:_from
        keys:@"name",
             @"number",
             @"priority",
             @"salutation",
             @"url",
             @"bank",
             @"bankCode",
             @"account",
             @"keywords",
             @"login",
             @"email",
             @"comment",
             @"category",
             nil];

  tmp = [_from objectForKey:@"extendedAttrs"];
  if ([tmp respondsToSelector:@selector(keyEnumerator)]) {
    objEnum = [tmp keyEnumerator];
    while ((obj = [objEnum nextObject]) != nil) {
      id value;

      value = [(NSDictionary *)tmp objectForKey:obj];
      if (value == nil) continue;
      [*_to setExtendedAttribute:value forKey:obj];
    }
  }

  tmp = [_from objectForKey:@"phones"];
  if ([tmp respondsToSelector:@selector(objectEnumerator)]) {
    objEnum = [tmp objectEnumerator];
    while ((obj = [objEnum nextObject]) != nil) {
      NSString *type;

      type = [obj valueForKey:@"type"];

      if (![type isNotNull]) continue;
    
      [*_to setPhoneNumber:[obj valueForKey:@"number"] forType:type];
      [*_to setPhoneInfo:  [obj valueForKey:@"info"]   forType:type];
    }
  }  
}

- (NSArray *)_fetchEnterprisesWithDict:(NSDictionary *)_arg {
  EODataSource         *enterpriseDS = [self enterpriseDataSource];
  NSMutableDictionary  *dict     = nil;
  EOFetchSpecification *fspec    = nil;
  EOQualifier          *qual     = nil;

  dict = [NSMutableDictionary dictionaryWithCapacity:8];
  [dict takeValuesFromObject:_arg keys:@"number",nil];
  [dict removeAllNulls];

  qual = [EOQualifier qualifierToMatchAllValues:dict
                      selector:EOQualifierOperatorLike];
  
  fspec = [EOFetchSpecification fetchSpecificationWithEntityName:@"Enterprise"
                                qualifier:qual
                                sortOrderings:nil];
  
  [enterpriseDS setFetchSpecification:fspec];
  return [enterpriseDS fetchObjects];
}

- (SkyEnterpriseDocument *)_getEnterpriseByNumber:(NSString *)_number {
  EODataSource         *enterpriseDS = [self enterpriseDataSource];
  EOFetchSpecification *fspec    = nil;
  EOQualifier          *qual     = nil;
  
  if ([[_number stringValue] length] == 0) return nil;
  
  qual = [[EOKeyValueQualifier alloc] initWithKey:@"number"
                                      operatorSelector:EOQualifierOperatorEqual
                                      value:_number];
  
  fspec = [EOFetchSpecification fetchSpecificationWithEntityName:@"Enterprise"
                                qualifier:qual
                                sortOrderings:nil];
  [qual release]; qual = nil;

  [enterpriseDS setFetchSpecification:fspec];
  return [[enterpriseDS fetchObjects] lastObject];
}

- (NSArray *)enterprise_getAction:(id)_arg {
  if ([_arg respondsToSelector:@selector(stringValue)])
    return [NSArray arrayWithObject:
                    [self _getEnterpriseByArgument:_arg]];
  else
    return [self _fetchEnterprisesWithDict:_arg];
}

- (NSArray *)enterprise_fetchIdsAction:(id)_arg {
  EOFetchSpecification *fspec;
  NSMutableDictionary  *hints;
  EODataSource         *enterpriseDS;
  
  enterpriseDS = [self enterpriseDataSource];
  fspec    = [[EOFetchSpecification alloc] initWithBaseValue:_arg];
  hints    = [NSMutableDictionary dictionaryWithDictionary:[fspec hints]];
  [hints setObject:[NSNumber numberWithBool:YES] forKey:@"fetchGlobalIDs"];
  [fspec setHints:hints];
  [fspec setEntityName:@"Enterprise"];
  
  [enterpriseDS setFetchSpecification:fspec];
  RELEASE(fspec);
  
  return [[[self commandContext] documentManager]
                 urlsForGlobalIDs:[enterpriseDS fetchObjects]];
}

- (id)enterprise_getByNumberAction:(NSString *)_number {
  return [self _getEnterpriseByNumber:_number];
}

- (id)enterprise_getByIdAction:(id)_arg :(id)_attributes {
  id result;

  result = [self getDocumentById:_arg
                 dataSource:[self enterpriseDataSource]
                 entityName:@"Enterprise"
                 attributes:_attributes];

  return (result != nil) ? result : [NSNumber numberWithBool:NO];
}

- (id)enterprise_deleteByNumberAction:(NSString *)_number {
  SkyEnterpriseDocument *enterprise = nil;

  if ([_number isKindOfClass:[NSString class]])
    enterprise = [self _getEnterpriseByNumber:_number];
  
  if (enterprise != nil)
    [[self enterpriseDataSource] deleteObject:enterprise];

  return enterprise;
}


- (NSArray *)enterprise_fetchAction:(id)_arg {
  EOFetchSpecification *fspec;
  EODataSource         *enterpriseDS = [self enterpriseDataSource];

  fspec = [[[EOFetchSpecification alloc] initWithBaseValue:_arg] autorelease];
  [fspec setEntityName:@"Enterprise"];

  [enterpriseDS setFetchSpecification:fspec];

  return [enterpriseDS fetchObjects];
}

- (id)enterprise_insertAction:(id)_arg {
  EODataSource      *enterpriseDS = [self enterpriseDataSource];
  SkyEnterpriseDocument *enterprise   = nil;
  
  enterprise = [enterpriseDS createObject];
  NSAssert(enterprise, @"couldn't create enterprise");
  
  [self _takeValuesDict:_arg toEnterprise:&enterprise];

  [enterpriseDS insertObject:enterprise];
  [self saveAddresses:[_arg valueForKey:@"addresses"] company:enterprise];

  return [[(EOKeyGlobalID *)[enterprise globalID] keyValuesArray]
                          objectAtIndex:0];
}

- (id)enterprise_updateAction:(id)_arg {
  SkyEnterpriseDocument *enterprise = nil;

  enterprise = [self _getEnterpriseByArgument:_arg];
  if (enterprise != nil) {
    [self _takeValuesDict:_arg toEnterprise:&enterprise];
    [[self enterpriseDataSource] updateObject:enterprise];
    [self saveAddresses:[_arg valueForKey:@"addresses"] company:enterprise];
    return enterprise;
  }
  [self logWithFormat:@"ERROR: did not find enterprise for argument '%@'",
        _arg];
  return [NSNumber numberWithBool:NO];
}

- (id)enterprise_getPersonsAction:(id)_arg {
  SkyEnterpriseDocument *enterprise = nil;
  EODataSource          *personDS   = nil;
  NSArray *result;

  if ((enterprise = [self _getEnterpriseByArgument:_arg]) == nil) {
    [self logWithFormat:@"ERROR: no valid enterprise for argument '%@' found",
	    _arg];
    return [NSNumber numberWithBool:NO];
  }
  if (![enterprise isKindOfClass:[SkyEnterpriseDocument class]]) {
    [self logWithFormat:
          @"did not find enterprise for argument '%@' - found '%@' instead",
          _arg, NSStringFromClass([enterprise class])];
    return [NSNumber numberWithBool:NO];
  }

  if ((personDS = [enterprise personDataSource]) == nil)
    return [NSArray array];
  
  if ((result = [personDS fetchObjects]) != nil)
    return result;
  
  return [NSNumber numberWithBool:NO];
}

- (id)enterprise_deleteAction:(id)_arg {
  // TODO: rewrite to use faults for error codes?
  SkyEnterpriseDocument *enterprise;
  NSArray *persons = nil;
  BOOL    hasFailed = NO;
  
  if ((enterprise = [self _getEnterpriseByArgument:_arg]) == nil) {
    [self logWithFormat:@"did not find enterprise for argument '%@'", _arg];
    return [NSNumber numberWithBool:NO];
  }
  
  if ((persons = [self enterprise_getPersonsAction:_arg]) == nil) {
    [self logWithFormat:@"did not find persons for enterprise '%@'", _arg];
    return [NSNumber numberWithBool:NO];
  }
  
  if ([persons count] > 0) {
    [self logWithFormat:
              @"ERROR: there are still persons associated with "
              @"enterprise '%@', can not delete it", _arg];
    return [NSNumber numberWithBool:NO];
  }

  NS_DURING
    [[self enterpriseDataSource] deleteObject:enterprise];
  NS_HANDLER
    hasFailed = YES;
  NS_ENDHANDLER;

  return [NSNumber numberWithBool:!hasFailed];
}

- (NSArray *)enterprise_fetchPersonsAction:(id)_enterprise :(id)_fSpec {
  SkyEnterpriseDocument *enterprise;
  EODataSource          *personDS;
  EOFetchSpecification  *fSpec;

  enterprise = [self _getEnterpriseByArgument:_enterprise];
  fSpec      = [[EOFetchSpecification alloc] initWithBaseValue:_fSpec];
  personDS   = [enterprise personDataSource];

  [personDS setFetchSpecification:fSpec];
  [fSpec release];
  
  return (personDS != nil) ? [personDS fetchObjects] : [NSArray array];
}

- (NSArray *)enterprise_getProjectsAction:(id)_arg {
  SkyEnterpriseDocument *enterprise;
  EODataSource          *projectDS;

  enterprise = [self _getEnterpriseByArgument:_arg];
  projectDS  = [enterprise projectDataSource];
  
  return (projectDS != nil) ? [projectDS fetchObjects] : [NSArray array];
}

- (id)enterprise_deletePersonAction:(id)_arg:(id)_person {
  SkyEnterpriseDocument *enterprise = nil;
  SkyPersonDocument     *person     = nil;
  BOOL                  hasFailed   = NO;
  
  if ((enterprise = [self _getEnterpriseByArgument:_arg]) != nil) {
    if ([enterprise isKindOfClass:[SkyEnterpriseDocument class]]) {
      if ((person = [self _getPersonByArgument:_person]) != nil) {
        if ([person isKindOfClass:[SkyPersonDocument class]]) {
          EODataSource *personDS = nil;

          if ((personDS = [enterprise personDataSource]) != nil) {
            NS_DURING
              [personDS deleteObject:person];
            NS_HANDLER
              hasFailed = YES;
            NS_ENDHANDLER;

            return [NSNumber numberWithBool:!hasFailed];
          }
          [self logWithFormat:@"ERROR: did not find person datasource"];
          return [NSNumber numberWithBool:NO];
        }
      }
      [self logWithFormat:@"ERROR: did not find person for argument '%@'",
            _person];
      return [NSNumber numberWithBool:NO];
    }
  }
  [self logWithFormat:@"ERROR: did not find enterprise for argument '%@'",
        _arg];
  return [NSNumber numberWithBool:NO];
}

- (void)enterprise_insertPersonAction:(id)_arg :(id)_person {
  SkyEnterpriseDocument *enterprise = nil;
  SkyPersonDocument     *person     = nil;
  EODataSource          *personDS   = nil;

  enterprise = [self _getEnterpriseByArgument:_arg];
  person     = [self _getPersonByArgument:_person];
  personDS   = [enterprise personDataSource];
  
  if (personDS) [personDS insertObject:person];
}

- (SkyEnterpriseDocument *)_getEnterpriseByArgument:(id)_arg {
  id tmp = nil;

  if ((tmp = [self getDocumentByArgument:_arg]) != nil)
    return tmp;
  if ([_arg respondsToSelector:@selector(stringValue)])
    return [self _getEnterpriseByNumber:[_arg stringValue]]; 
  
  if ([_arg isKindOfClass:[NSDictionary class]]) {
    if ((tmp = [(NSDictionary *)_arg objectForKey:@"id"]) != nil)
      return [self enterprise_getByIdAction:tmp:nil];
    
    if ((tmp = [(NSDictionary *)_arg objectForKey:@"number"]) != nil)
      return [self _getEnterpriseByNumber:tmp];
    
    return nil;
  }
  
  if ([_arg isKindOfClass:[SkyEnterpriseDocument class]])
    return _arg;

  return nil;
}

@end /* DirectAction(Enterprise) */
