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

#include "DirectAction.h"
#include <EOControl/EOControl.h>
#include <OGoContacts/SkyPersonDocument.h>
#include <OGoContacts/SkyEnterpriseDocument.h>
#include <OGoContacts/SkyAddressDocument.h>
#include "EOControl+XmlRpcDirectAction.h"
#include "NSObject+EKVC.h"
#include "Session.h"
#include "common.h"
#include <EOControl/EOKeyGlobalID.h>

@interface DirectAction(PersonPrivate)
- (SkyEnterpriseDocument *)_getEnterpriseByArgument:(id)_arg;
- (SkyPersonDocument *)_getPersonByArgument:(id)_arg;
@end

@implementation DirectAction(Person)

- (void)_takeValuesDict:(NSDictionary *)_from
  toPerson:(SkyPersonDocument **)_to
{
  NSEnumerator *objEnum = nil;
  id           tmp      = nil;
  id           obj      = nil;                             
  
  [*_to takeValuesFromObject:_from
        keys:@"firstname",
             @"middlename",
             @"name",
             @"nickname",
             @"number",
             @"salutation",
             @"degree",
             @"url",
             @"gender",
             @"birthday",
             @"comment",
             @"isReadonly",
             @"keywords",
             @"isAccount",
             @"isPrivate",
             @"login",
          nil];

  tmp = [_from objectForKey:@"extendedAttrs"];
  
  if ([tmp respondsToSelector:@selector(keyEnumerator)]) {
    objEnum = [tmp keyEnumerator];
    while ((obj = [objEnum nextObject])) {
      id value;

      value = [tmp objectForKey:obj];
      if (value == nil) continue;
      [*_to setExtendedAttribute:value forKey:obj];
    }
  }

  tmp = [_from objectForKey:@"phones"];
  if ([tmp respondsToSelector:@selector(objectEnumerator)]) {
    objEnum = [tmp objectEnumerator];
    while ((obj = [objEnum nextObject])) {
      NSString *type;

      type = [obj valueForKey:@"type"];

      if (![type isNotNull]) continue;
    
      [*_to setPhoneNumber:[obj valueForKey:@"number"] forType:type];
      [*_to setPhoneInfo:  [obj valueForKey:@"info"]   forType:type];
    }
  }
}

- (NSArray *)_fetchPersonsWithDict:(NSDictionary *)_arg {
  EODataSource         *personDS;
  NSMutableDictionary  *dict     = nil;
  EOFetchSpecification *fspec    = nil;
  EOQualifier          *qual     = nil;
  
  // TODO: this doesn't seem to make a lot of sense?
  dict = [NSMutableDictionary dictionaryWithCapacity:8];
  [dict takeValuesFromObject:_arg keys:@"number", nil];
  [dict removeAllNulls];
  
  qual = [EOQualifier qualifierToMatchAllValues:dict
                      selector:EOQualifierOperatorLike];
  
  fspec = [EOFetchSpecification fetchSpecificationWithEntityName:@"Person"
                                qualifier:qual
                                sortOrderings:nil];
  
  personDS = [self personDataSource];
  [personDS setFetchSpecification:fspec];
  return [personDS fetchObjects];
}

- (SkyPersonDocument *)_getPersonByNumber:(NSString *)_number {
  EODataSource         *personDS;
  EOFetchSpecification *fspec    = nil;
  EOQualifier          *qual     = nil;
  
  personDS = [self personDataSource];
  _number = [_number stringValue];
  if ([_number length] == 0) return nil;
  
  qual = [[EOKeyValueQualifier alloc] initWithKey:@"number"
                                      operatorSelector:EOQualifierOperatorEqual
                                      value:_number];
  
  fspec = [EOFetchSpecification fetchSpecificationWithEntityName:@"Person"
                                qualifier:qual
                                sortOrderings:nil];
  RELEASE(qual);
  
  [personDS setFetchSpecification:fspec];
  return [[personDS fetchObjects] lastObject];
}

- (NSArray *)person_getAction:(id)_arg {
  id person;
  
  if ([_arg isKindOfClass:[NSDictionary class]])
    // TODO: this doesn't seem to make a lot of sense?
    return [self _fetchPersonsWithDict:_arg];

  person = [self _getPersonByArgument:_arg];
  return [person isNotNull] ? [NSArray arrayWithObject:person] : nil;
}

- (id)person_getByNumberAction:(NSString *)_number {
  return [self _getPersonByNumber:_number];
}

- (id)person_getByIdAction:(id)_arg :(id)_attributes {
  id result;

  result =  [self getDocumentById:_arg
                  dataSource:[self personDataSource]
                  entityName:@"Person"
                  attributes:_attributes];

  return (result != nil) ? result : [NSNumber numberWithBool:NO];
}

- (NSArray *)person_fetchIdsAction:(id)_arg {
  EOFetchSpecification *fspec;
  NSMutableDictionary  *hints;
  EODataSource         *personDS;
  
  personDS = [self personDataSource];
  fspec    = [[EOFetchSpecification alloc] initWithBaseValue:_arg];
  hints    = [NSMutableDictionary dictionaryWithDictionary:[fspec hints]];
  [hints setObject:[NSNumber numberWithBool:YES] forKey:@"fetchGlobalIDs"];
  [fspec setHints:hints];
  [fspec setEntityName:@"Person"];
  
  [personDS setFetchSpecification:fspec];

  RELEASE(fspec);

  return [[[self commandContext] documentManager]
                 urlsForGlobalIDs:[personDS fetchObjects]];
}

- (id)person_deleteByNumberAction:(NSString *)_number {
  SkyPersonDocument *person = nil;

  if ([_number isKindOfClass:[NSString class]])
    person = [self _getPersonByNumber:_number];
  
  if (person)
    [[self personDataSource] deleteObject:person];

  return person;
}

- (NSArray *)person_fetchAction:(id)_arg {
  EOFetchSpecification *fspec;
  EODataSource         *personDS;
  
  personDS = [self personDataSource];
  fspec = [[EOFetchSpecification alloc] initWithBaseValue:_arg];
  [fspec setEntityName:@"Person"];
  
  [personDS setFetchSpecification:fspec];
  [fspec release];
  
  return [personDS fetchObjects];
}

- (id)person_insertAction:(id)_arg {
  EODataSource      *personDS = [self personDataSource];
  SkyPersonDocument *person   = nil;
  
  person = [personDS createObject];
  NSAssert(person, @"couldn't create person");
  
  [self _takeValuesDict:_arg toPerson:&person];

  [personDS insertObject:person];
  [self saveAddresses:[_arg valueForKey:@"addresses"] company:person];

  return [[(EOKeyGlobalID *)[person globalID] keyValuesArray] objectAtIndex:0];
}

- (id)person_updateAction:(id)_arg {
  SkyPersonDocument *person = nil;

  if ((person = [self _getPersonByArgument:_arg]) == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                 reason:@"got no person for argument"];
  }
  
  [self _takeValuesDict:_arg toPerson:&person];
  [[self personDataSource] updateObject:person];
  [self saveAddresses:[_arg valueForKey:@"addresses"] company:person];
  return person;
}

- (id)person_deleteAction:(id)_arg {
  SkyPersonDocument *person = nil;

  person = [self _getPersonByArgument:_arg];
  if (person) [[self personDataSource] deleteObject:person];
  
  return nil;
}

- (NSArray *)person_getEnterprisesAction:(id)_arg {
  SkyPersonDocument *person       = nil;
  NSArray           *enterprises  = nil;
  EODataSource      *enterpriseDS = nil;

  person       = [self _getPersonByArgument:_arg];
  enterpriseDS = [person enterpriseDataSource];
  enterprises  = [enterpriseDS fetchObjects];
  
  return (enterprises == nil) ? [NSArray array] : enterprises;
}

- (id)person_fetchEnterprisesAction:(id)_person:(id)_fSpec {
  SkyPersonDocument    *person;
  EODataSource         *enterpriseDS;
  EOFetchSpecification *fSpec = nil;
  NSArray              *enterprises  = nil;

  /* preconditions */
  
  if ((person = [self _getPersonByArgument:_person]) == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                 reason:@"got no person for argument"];
  }
  if (![person isKindOfClass:[SkyPersonDocument class]]) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
                 reason:@"returned object for arg is not a SkyPersonDocument"];
  }
  if ((enterpriseDS = [person enterpriseDataSource]) == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
                 reason:@"found person object has no enterprise datasource"];
  }
  
  /* fetch */
  
  fSpec = [[EOFetchSpecification alloc] initWithBaseValue:_fSpec];
  [enterpriseDS setFetchSpecification:fSpec];
  [fSpec release];
  
  enterprises = [enterpriseDS fetchObjects];
  
  return (enterprises == nil) ? [NSArray array] : enterprises;
}

- (id)person_getProjectsAction:(id)_arg {
  SkyPersonDocument *person;
  EODataSource      *projectDS;
  NSArray           *projects;
  
  if ((person = [self _getPersonByArgument:_arg]) == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                 reason:@"got no person for argument"];
  }
  if (![person isKindOfClass:[SkyPersonDocument class]]) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
                 reason:@"returned object for arg is not a SkyPersonDocument"];
  }
  
  if ((projectDS = [person projectDataSource]) == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
                 reason:@"returned person object has no project datasource"];
  }
  
  projects  = [projectDS fetchObjects];
  return (projects == nil) ? [NSArray array] : projects;
}

- (id)person_deleteEnterpriseAction:(id)_arg:(id)_enterprise {
  SkyEnterpriseDocument *enterprise;
  SkyPersonDocument     *person;
  EODataSource          *personDS;
  NSException           *error;
  
  /* check preconditions */
  
  if ((person = [self _getPersonByArgument:_arg]) == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                 reason:@"got no person for first argument"];
  }
  if (![person isKindOfClass:[SkyPersonDocument class]]) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
                 reason:@"returned object for arg is not a SkyPersonDocument"];
  }
  if ((enterprise = [self _getEnterpriseByArgument:_enterprise]) == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                 reason:@"got no company for second argument"];
  }
  if (![enterprise isKindOfClass:[SkyEnterpriseDocument class]]) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
                 reason:@"found object is not a SkyEnterpriseDocument"];
  }
  
  if ((personDS = [enterprise personDataSource]) == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
                 reason:@"found enterprise object has no person datasource"];
  }
  
  /* do the actual deletion */
  
  *(&error) = nil;
  NS_DURING
    [personDS deleteObject:person];
  NS_HANDLER
    error = [localException retain];
  NS_ENDHANDLER;
  
  return (error != nil) ? (id)error : [NSNumber numberWithBool:YES];
}

- (id)person_insertEnterpriseAction:(id)_arg:(id)_enterprise {
  SkyEnterpriseDocument *enterprise;
  SkyPersonDocument     *person;
  EODataSource          *personDS;
  NSException           *error;
  
  person     = [self _getPersonByArgument:_arg];
  enterprise = [self _getEnterpriseByArgument:_enterprise];
  personDS   = [enterprise personDataSource];
  
  if (personDS == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
                 reason:@"found enterprise object has no person datasource"];
  }
  
  NS_DURING
    [personDS insertObject:person];
  NS_HANDLER
    error = [localException retain];
  NS_ENDHANDLER;
  
  return (error != nil) ? (id)error : [NSNumber numberWithBool:YES];
}

/* helper methods */

- (SkyPersonDocument *)_getPersonByArgument:(id)_arg {
  id tmp = nil;

  if ((tmp = [self getDocumentByArgument:_arg]))
    return tmp;
  
  if ([_arg respondsToSelector:@selector(stringValue)])
    return [self _getPersonByNumber:[_arg stringValue]];
  
  if ([_arg isKindOfClass:[NSDictionary class]]) {
    if ((tmp = [_arg objectForKey:@"id"]) != nil)
      return [self person_getByIdAction:tmp :nil];

    return [self _getPersonByNumber:[_arg objectForKey:@"number"]];
  }
  
  if ([_arg isKindOfClass:[SkyPersonDocument class]])
    return _arg;

  return nil;
}

/* full search */

- (NSArray *)person_fullsearchIdsAction:(id)_txt:(NSNumber *)_limit {
  // TODO: this is "somewhat" slow as it fetches the whole EO objects
  LSCommandContext *cmdctx;
  NSArray  *eos;
  NSNumber *limit;
  
  cmdctx = [self commandContext];
  if ([_txt isKindOfClass:[NSArray class]]) {
    eos = [cmdctx runCommand:@"person::full-search",
                    @"searchStrings",   _txt,
                    @"maxSearchCount", _limit,
                  nil];
  }
  else {
    eos = [cmdctx runCommand:@"person::full-search",
                    @"searchString",   [_txt stringValue],
                    @"maxSearchCount", _limit,
                  nil];
  }
  if ([eos isKindOfClass:[NSException class]])
    return eos;
  
  limit = [cmdctx valueForKey:@"_cache_fullSearchLimited"];
  if ([limit isNotNull]) {
    // TODO: what to do with search limit key '_cache_fullSearchLimited'?
    [self logWithFormat:@"WARNING: restricted search, limited to %@.", limit];
  }
  
  return [eos valueForKey:@"companyId"];
}
- (NSArray *)person_fullsearchIdsAction:(NSString *)_txt {
  return [self person_fullsearchIdsAction:_txt:nil];
}

@end /* DirectAction(Person) */
