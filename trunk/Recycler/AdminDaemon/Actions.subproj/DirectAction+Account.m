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
#include "common.h"
#include "NSObject+EKVC.h"
#include "EOControl+XmlRpcDirectAction.h"
#include <OGoAccounts/SkyAccountDocument.h>
#include <OGoContacts/SkyCompanyDocument.h>
#include <OGoAccounts/SkyAccountTeamsDataSource.h>
#include <EOControl/EOGenericRecord.h>
#include <EOControl/EOKeyGlobalID.h>
#include <GDLAccess/GDLAccess.h>
#include <NGMail/NGMail.h>

@interface NSUserDefaults(Private)
- (NSDictionary *)loadPersistentDomainNamed:(NSString *)_n;
@end /* NSUserDefaults(Private) */

@implementation DirectAction(Account)

/* private methods */

- (NSDictionary *)_domainNamed:(NSString *)_n {
  NSUserDefaults *ud;

  ud = [NSUserDefaults standardUserDefaults];

  if (([ud persistentDomainForName:_n])) {
    [ud removePersistentDomainForName:_n];
    [ud setPersistentDomain:[(id)ud loadPersistentDomainNamed:_n]
        forName:_n];
  }
  return [ud persistentDomainForName:_n];
}

- (id)_getAccountForId:(NSString *)_uid withAttributes:(id)_attributes
  inContext:(id)_ctx
{
  return [[_ctx documentManager] documentForURL:_uid];
}

- (id)_getEOForURL:(NSString *)_url inContext:(id)_ctx {
  EOGlobalID *gid;
  id result;

  if ((gid = [[_ctx documentManager] globalIDForURL:_url]) == nil)
    return nil;
    
  result =  [_ctx runCommand:@"person::get-by-globalid",
                    @"gid", gid, nil];
  if ([result isKindOfClass:[NSArray class]])
    return [result objectAtIndex:0];  
  
  return nil;
}

- (id)_getAccountForURL:(NSString *)_url inContext:(id)_ctx {
  EOGlobalID *gid;
  NSString   *key;
  id result;
  
  key = [_url lastPathComponent];
  
  /*
    The account gid can't be queried from the document manager,
    as it would always return IDs from the 'Person' entity.
    
    HH asks: So what? There is not "Account" entity!
  */
  gid = [EOKeyGlobalID globalIDWithEntityName:@"Account"
                       keys:&key keyCount:1 zone:nil];

  if (gid == nil)
    return nil;
    
  result =  [_ctx runCommand:@"account::get-by-globalid",
                    @"gid", gid, nil];
  if ([result isKindOfClass:[NSArray class]])
    return [result objectAtIndex:0];
  
  return nil;
}

- (NSDictionary *)_dictionaryForAccountEOGenericRecord:(id)_record {
  static NSArray *accountKeys = nil;
  id result;
  
  if (accountKeys == nil) {
    accountKeys = [[NSArray alloc] initWithObjects:
                                   @"login", @"isAccount", @"isExtraAccount",
                                   @"isPerson", @"isIntraAccount",
                                   @"ownerId", @"templateUserId",
                                   @"isTemplateUser",
                                   nil];
  }
  
  result = [self _dictionaryForEOGenericRecord:_record withKeys:accountKeys];

  [self substituteIdsWithURLsInDictionary:result
        forKeys:[NSArray arrayWithObjects:@"templateUserId", @"ownerId", nil]];
  return result;
}

- (void)_takeValuesDict:(NSDictionary *)_from
  toAccount:(SkyAccountDocument **)_to
{
  [*_to takeValuesFromObject:_from keys:@"login",@"name",@"firstname",
        @"middlename", @"nickname",@"password", nil];
}

- (id)account_getLoginAccountAction {
  EOGenericRecord *loginAccount;
  EODataSource       *accountDS;
  SkyAccountDocument *account;
  EOGlobalID         *gid;

  loginAccount = [[self commandContext] valueForKey:LSAccountKey];
  if (loginAccount == nil) {
    [self logWithFormat:@"Couldn't find current login account"];
    return [NSNumber numberWithBool:NO];
  }
    
  accountDS = [self accountDataSource];
  gid = [loginAccount valueForKey:@"globalID"];
  account = [[SkyAccountDocument alloc] initWithAccount:loginAccount
                                        globalID:gid
                                        dataSource:accountDS];
  if (account)
      return [account autorelease];
  
  [self logWithFormat:@"Couldn't create account document"];
  return [NSNumber numberWithBool:NO];
}

- (id)account_getLoginAccountIdAction {
  EOGlobalID *gid;

  gid = [[[self commandContext] valueForKey:LSAccountKey]
                valueForKey:@"globalID"];

  if (gid != nil)
    return [[[self commandContext] documentManager] urlForGlobalID:gid];

  [self logWithFormat:@"Couldn't find global id of current login account"];
  return [NSNumber numberWithBool:NO];
}

- (NSArray *)account_fetchIdsAction:(id)_arg {
  EOFetchSpecification *fspec;
  NSMutableDictionary  *hints;
  EODataSource         *accountDS;
  NSArray              *fetchResult;
  NSMutableArray       *ids;
  int i;
  
  accountDS = [self accountDataSource];
  fspec     = [[EOFetchSpecification alloc] initWithBaseValue:_arg];
  hints     = [NSMutableDictionary dictionaryWithDictionary:[fspec hints]];
  [hints setObject:[NSNumber numberWithBool:YES] forKey:@"fetchGlobalIDs"];
  [fspec setHints:hints];
  [fspec setEntityName:@"Account"];
  
  [accountDS setFetchSpecification:fspec];

  [fspec release]; fspec = nil;

  fetchResult = [accountDS fetchObjects];
  ids = [NSMutableArray arrayWithCapacity:[fetchResult count]];

  for(i = 0; i < [fetchResult count]; i++) {
    [ids addObject:[[fetchResult objectAtIndex:i] globalID]];
  }
  
  return [[[self commandContext] documentManager]
                 urlsForGlobalIDs:ids];
}

- (NSDictionary *)account_fetchIdsAndVersionsAction:(id)_arg {
  EOFetchSpecification *fspec;
  NSMutableDictionary  *hints;
  EODataSource         *accountDS;
  NSArray              *fetchResult;
  NSMutableDictionary  *result;
  NSEnumerator         *documentEnum;
  SkyAccountDocument   *account;
  id                   documentManager;
  
  accountDS = [self accountDataSource];
  fspec     = [[EOFetchSpecification alloc] initWithBaseValue:_arg];

  hints     = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithBool:YES],
                                   @"fetchGlobalIDs",nil];
  [fspec setHints:hints];
  [fspec setEntityName:@"Account"];
  [accountDS setFetchSpecification:fspec];

  [fspec release]; fspec = nil;
  fetchResult = [accountDS fetchObjects];

  result = [NSMutableDictionary dictionaryWithCapacity:[fetchResult count]];

  documentManager = [[self commandContext] documentManager];
  
  documentEnum = [fetchResult objectEnumerator];
  while ((account = [documentEnum nextObject])) {
    id gid;
    NSNumber *version;
    
    gid = [[documentManager urlForGlobalID:[account globalID]] absoluteString];
    version = ([account objectVersion] != nil)
      ? [account objectVersion]
      : [NSNumber numberWithInt:0];
    
    [result setObject:version forKey:gid];
  }
  return result;
}

- (id)account_getByIdAction:(NSString *)_uid:(id)_attributes {
  id result;
  LSCommandContext *ctx;

  if ((ctx = [self commandContext]) == nil)
    return [self invalidCommandContextFault];
  
  result = [self _getEOForURL:_uid inContext:ctx];

  if (result == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
                 reason:@"No account with given ID found"];
  }

  return [[[SkyAccountDocument alloc] initWithAccount:result
                                      globalID:
                                        [result valueForKey:@"globalID"]
                                      dataSource:[self accountDataSource]]
                                      autorelease];
}

- (id)_getAccountByAttribute:(NSString *)_attr forKey:(NSString *)_key {
  EODataSource         *accountDS;
  NSString             *attr;
  EOQualifier          *qual      = nil;
  EOFetchSpecification *fspec     = nil;
  NSArray               *result;
  
  accountDS = [self accountDataSource];
  attr      = [_attr stringValue];
  
  if ([attr length] == 0)
    return nil;
  
  qual = [[EOKeyValueQualifier alloc] initWithKey:_key
                                      operatorSelector:EOQualifierOperatorEqual
                                      value:attr];
  
  fspec = [EOFetchSpecification fetchSpecificationWithEntityName:@"Person"
                                qualifier:qual
                                sortOrderings:nil];

  [accountDS setFetchSpecification:fspec];
  [qual release]; qual = nil;
  
  result = [accountDS fetchObjects];
  
  if ([result count] == 0)
    return nil;
  
  NSAssert1([result count] == 1,
            @"invalid result count (%i records for login)", [result count]);

  return [result objectAtIndex:0];
}

- (id)_getAccountByLogin:(NSString *)_login {
  return [self _getAccountByAttribute:_login forKey:@"login"];
}

- (id)_getAccountByNumber:(NSString *)_number {
  return [self _getAccountByAttribute:_number forKey:@"number"];
}

- (id)account_getByNumberAction:(NSString *)_number {
  id account;

  if ((account = [self _getAccountByNumber:_number]))
    return account;

  return [NSNumber numberWithBool:NO];
}

- (id)account_getByLoginAction:(NSString *)_login {
  id account;

  if ((account = [self _getAccountByLogin:_login]))
    return account;

  return [NSNumber numberWithBool:NO];
}

- (id)account_passwordForLoginAction:(NSString *)_login {
  SkyAccountDocument *account = nil;

  if ([self isCurrentUserRoot]) {
    if ((account = [self _getAccountByLogin:_login]))
      return [account password];
    return [NSNumber numberWithBool:NO];
  }
  else {
    [self logWithFormat:@"non-root user tried to call passwordForLogin"];
    return [NSNumber numberWithBool:NO];
  }
}

- (id)account_getTeamsForLoginAction:(NSString *)_login {
  id ctx;
  id acc;

  if ((ctx = [self commandContext]) == nil)
    return [NSNumber numberWithBool:NO];

  acc = [ctx runCommand:@"account::get-by-login",
               @"login", _login,
               nil];

  if (acc == nil)
    return nil;
  
  return [ctx runCommand:@"account::teams", @"account", acc, nil];
}

- (NSArray *)account_fetchAction:(id)_arg {
  EOFetchSpecification *fspec;
  EODataSource         *accountDS;

  accountDS = [self accountDataSource];
  fspec     = [[[EOFetchSpecification alloc] initWithBaseValue:_arg]
                                      autorelease];

  [fspec setEntityName:@"account"];
  [accountDS setFetchSpecification:fspec];

  return [accountDS fetchObjects];
}

- (NSArray *)account_getAllTemplateUserLoginsAction {
  id result;

  result = [self account_fetchAction:@"isTemplateUser = 1"];
  return [result valueForKey:@"login"];
}

/* 
   returns an account array with id, version and email addresses which are in
   'administrated domains'
*/

- (NSArray *)_domainsInContext:(NSMutableDictionary *)_dict {
  NSDictionary        *domain;
  NSArray             *adDomains;

  if ((adDomains = [_dict objectForKey:@"administratedDomains"]))
    return adDomains;

  domain = [self _domainNamed:@"MTA"];
  adDomains = [[domain objectForKey:@"administrated domains"]
                       componentsSeparatedByString:@"; "];

  if (adDomains == nil) {
    [self debugWithFormat:@"no value for 'administrated domains' default"];
    return nil;
  }
  
  adDomains = [adDomains map:@selector(stringByTrimmingSpaces)];
  [_dict setObject:adDomains forKey:@"administratedDomains"];
  return adDomains;
}

- (id)_checkEmail:(NSString *)_email context:(NSMutableDictionary *)_dict  {
  NSArray             *adDomains;
  NGMailAddressParser *parser;
  NGMailAddress       *email;
  NSString            *host;
  NSArray             *dArray;

  if (![_email length])
    return nil;

  adDomains = [self _domainsInContext:_dict];
  
  if (![adDomains count])
    return nil;

  parser = [NGMailAddressParser mailAddressParserWithString:_email];
  email  = [parser parse];

  dArray = [[email address] componentsSeparatedByString:@"@"];

  if ([dArray count] < 2)
    host = @"localhost";
  else
    host = [dArray lastObject];

  if ([adDomains containsObject:host])
    return [email address];

  return nil;
}

- (NSDictionary *)_MTAInfo:(id)_person ctx:(NSMutableDictionary *)_ctx {
  NSMutableDictionary *dict;
  NSMutableArray      *array;
  NSEnumerator        *enumerator;
  id                  tmp, documentManager;

  NSArray *domains;
  id      ud, ctx;

  ctx             = [self commandContext];
  ud              = [ctx runCommand:@"userdefaults::get", @"user",
                         _person, nil];

  if ([ud boolForKey:@"admin_exportAddresses"] == NO)
    return nil;
  
  documentManager = [ctx documentManager];
  dict            = [[NSMutableDictionary alloc] initWithCapacity:8];
  array           = [[NSMutableArray alloc] initWithCapacity:8];
  tmp             = [[documentManager urlForGlobalID:[_person globalID]]
                                      absoluteString];

  [dict setObject:tmp                     forKey:@"globalId"];

  if ([(tmp = [_person login]) length] > 0)
    [dict setObject:tmp forKey:@"login"];

  if ([(tmp = [_person name]) length] > 0)
    [dict setObject:tmp forKey:@"name"];

  if ([(tmp = [_person firstname]) length] > 0)
    [dict setObject:tmp forKey:@"firstname"];

  if ([(tmp = [_person nickname]) length] > 0)
    [dict setObject:tmp forKey:@"nickname"];
  
  [dict setObject:[_person objectVersion] forKey:@"version"];

  enumerator = [[[[ud objectForKey:@"admin_vaddresses"]
                      componentsSeparatedByString:@"\n"]
                      map:@selector(stringByTrimmingSpaces)] objectEnumerator];
  array      = [NSMutableArray arrayWithCapacity:10];

  while ((tmp = [enumerator nextObject])) {
    if ((tmp = [self _checkEmail:tmp context:_ctx]))
      [array addObject:tmp];
  }
  [dict setObject:[[array copy] autorelease] forKey:@"vaddresses"];
  [array removeAllObjects];

  enumerator = [[ud arrayForKey:@"admin_LocalDomainAliases" ]
                    objectEnumerator];
  domains    = [self _domainsInContext:_ctx];
  while ((tmp = [enumerator nextObject])) {
    if ([domains containsObject:tmp])
      [array addObject:tmp];
  }
  [dict setObject:[[array copy] autorelease] forKey:@"aliasDomains"];
  [array removeAllObjects];
  
  {
    id account, team;
    
    account = [[SkyAccountDocument alloc] initWithGlobalID:[_person globalID]
                                          context:[self commandContext]];
    enumerator = [[[account teamsDataSource] fetchObjects] objectEnumerator];

    while ((team = [enumerator nextObject]))
      [array addObject:[team number]];

    [account release]; account = nil;
  }
  [dict setObject:array forKey:@"teams"];
    
  [array release]; array = nil;

  return dict;
}

- (NSDictionary *)_ImapInfo:(id)_person ctx:(NSMutableDictionary *)_ctx {
  NSMutableDictionary *dict;
  id                  tmp, documentManager, ud, ctx, quota;

  ctx             = [self commandContext];
  ud              = [ctx runCommand:@"userdefaults::get", @"user",
                         _person, nil];

  if ([ud boolForKey:@"admin_exportAddresses"] == NO)
    return nil;
  
  documentManager = [ctx documentManager];
  dict            = [[NSMutableDictionary alloc] initWithCapacity:8];
  tmp             = [[documentManager urlForGlobalID:[_person globalID]]
                                      absoluteString];

  [dict setObject:tmp forKey:@"globalId"];

  if ([(tmp = [_person login]) length] > 0)
    [dict setObject:tmp forKey:@"login"];

  [dict setObject:[_person objectVersion] forKey:@"version"];

  quota = [ud stringForKey:@"admin_mailquota"];

  if ([quota length] > 0)
    [dict setObject:quota forKey:@"quota"];

  return dict;
}

- (id)account_fetchMTAInfoAction:(NSArray *)_keys {
  NSMutableArray      *marray;
  NSEnumerator        *enumerator;
  NSMutableDictionary *ctx;
  NSDictionary        *domain;
  id                  documentManager, obj;
  
  domain = [self _domainNamed:@"MTA"];
  
  if (![[domain objectForKey:@"export data"] boolValue]) {
    [self logWithFormat:@"Note: 'export data' is disabled."];
    return nil;
  }
  
  documentManager = [[self commandContext] documentManager];
  enumerator      = [_keys objectEnumerator];
  marray          = [NSMutableArray arrayWithCapacity:[_keys count]];
  ctx             = [NSMutableDictionary dictionaryWithCapacity:8];

  while ((obj = [enumerator nextObject])) {
    id tmp;
    
    if ((tmp = [documentManager documentForURL:obj]) == nil) {
      [self logWithFormat:@"got no object for url: '%@'", obj];
      continue;
    }

    if ((tmp = [self _MTAInfo:tmp ctx:ctx]) == nil) {
      [self logWithFormat:@"got no MTA info for url: '%@'", obj];
      continue;
    }

    [self logWithFormat:@"adding info: %@", tmp];
    
    [marray addObject:tmp];
  }
  return marray;
}

- (id)account_fetchAllMTAInfoAction {
  NSArray              *persons;
  EOFetchSpecification *fspec;
  EODataSource         *personDS;
  NSEnumerator         *enumerator;
  id                   a;
  NSMutableArray       *result;
  NSMutableDictionary  *ctx;
  NSDictionary         *domain;

  domain = [self _domainNamed:@"MTA"];

  if ([[domain objectForKey:@"export data"] boolValue] == NO) {
    [self logWithFormat:
            @"'export data' is disabled in the 'MTA' domain, not returning "
            @"data."];
    return nil;
  }

  personDS = [self personDataSource];
  fspec    = [[[EOFetchSpecification alloc]
                                     initWithBaseValue:@"isAccount = YES"]
                                     autorelease];
  ctx      = [NSMutableDictionary dictionaryWithCapacity:16];
  
  [fspec setEntityName:@"person"];
  [personDS setFetchSpecification:fspec];

  persons         = [personDS fetchObjects];
  enumerator      = [persons objectEnumerator];
  result          = [NSMutableArray arrayWithCapacity:[persons count]];
  
  while ((a = [enumerator nextObject])) {
    id tmp;
    
    if ((tmp = [self _MTAInfo:a ctx:ctx]))
      [result addObject:tmp];
  }
  return result;
}

- (id)account_fetchAllImapInfoAction {
  NSArray              *persons;
  EOFetchSpecification *fspec;
  EODataSource         *personDS;
  NSEnumerator         *enumerator;
  id                   a;
  NSMutableArray       *result;
  NSMutableDictionary  *ctx;
  NSDictionary         *domain;
  
  domain = [self _domainNamed:@"Imap"];
  
  if ([[domain objectForKey:@"export data"] boolValue] == NO) {
    [self logWithFormat:
            @"'export data' is disabled in the 'Imap' domain, not returning "
            @"data."];
    return nil;
  }
  
  personDS = [self personDataSource];
  fspec    = [[[EOFetchSpecification alloc]
                                     initWithBaseValue:@"isAccount = YES"]
                                     autorelease];
  ctx      = [[NSMutableDictionary alloc] init];
  
  [fspec setEntityName:@"person"];
  [personDS setFetchSpecification:fspec];

  persons         = [personDS fetchObjects];
  enumerator      = [persons objectEnumerator];
  result          = [NSMutableArray arrayWithCapacity:[persons count]];
  
  while ((a = [enumerator nextObject])) {
    id tmp;

    if ((tmp = [self _ImapInfo:a ctx:ctx]))
      [result addObject:tmp];
  }
  return result;
}

@end /* DirectAction(Account) */

@implementation DirectAction(Person) /* needed for LDAP */

- (id)getDocumentById:(id)_arg
  dataSource:(EODataSource *)_dataSource
  entityName:(NSString *)_entityName
  attributes:(NSArray *)_attributes
{
  // TODO: split up method
  id                   gids          = nil;
  EOQualifier          *qual         = nil;
  EOFetchSpecification *fSpec        = nil;
  BOOL                 doReturnArray = NO;
  NSArray              *returnElements;
  id                   object;
  NSEnumerator         *enumerator;
  EOGlobalID           *gid;
  NSMutableDictionary  *hints;

  if (_arg == nil) return nil;

  doReturnArray = [_arg isKindOfClass:[NSArray class]];

  gids = (doReturnArray)
    ? _arg
    : [NSArray arrayWithObject:_arg];
  
  if ([gids containsObject:@""]) {
    gids = [[gids mutableCopy] autorelease];
    [gids removeObject:@""];
  }

  gids = [[[self commandContext] documentManager] globalIDsForURLs:gids];
  if ([gids count] == 0) {
    [self logWithFormat:@"Invalid URLs given, couldn't resolve globalIDs"];
    return nil;
  }

  gid = [gids objectAtIndex:0];
  if (![[gid entityName] isEqualToString:_entityName]) {
    [self logWithFormat:
            @"ERROR: gid entity '%@' doesn't match given entity '%@'",
            [gid entityName], _entityName];
    return nil;
  }
    
  if (![gid isKindOfClass:[EOGlobalID class]]) {
    [self logWithFormat:@"Invalid URLs given, couldn't resolve globalIDs"];
    return nil;
  }
    
  qual  = [[EOKeyValueQualifier alloc]
                                    initWithKey:@"globalID"
                                    operatorSelector:
                                    EOQualifierOperatorContains
                                    value:gids];
  fSpec = [EOFetchSpecification fetchSpecificationWithEntityName:
                                    _entityName
                                    qualifier:qual
                                    sortOrderings:nil];
  [qual release]; qual = nil;
      
  if ([_attributes isKindOfClass:[NSArray class]]) {
        NSMutableDictionary *hints;

        hints = [NSMutableDictionary dictionaryWithDictionary:[fSpec hints]];
        [hints setObject:_attributes forKey:@"attributes"];
        [fSpec setHints:hints];
  }
      
  hints = [[NSMutableDictionary alloc] initWithDictionary:[fSpec hints]];
  if ([hints objectForKey:@"addDocumentsAsObserver"] == nil) {
          [hints setObject:[NSNumber numberWithBool:NO]
                 forKey:@"addDocumentsAsObserver"];
          [fSpec setHints:hints];
  }
  [hints release];

  [_dataSource setFetchSpecification:fSpec];

  returnElements = [_dataSource fetchObjects];
  enumerator = [returnElements objectEnumerator];
      
  while ((object = [enumerator nextObject])) {
    NSDictionary *logEntry;
    NSDate       *creationDate;
    
    logEntry = [[self commandContext] runCommand:
                                          @"object::get-current-log",
                                          @"object", [object globalID], nil];

    if (![object respondsToSelector:@selector(setExtendedAttribute:forKey:)])
      continue;
    if ((creationDate = [logEntry valueForKey:@"creationDate"]) == nil)
      continue;
    
    [(SkyCompanyDocument *)object setExtendedAttribute:creationDate
                                  forKey:@"lastChanged"];
  }
  
  return (doReturnArray)
    ? returnElements
    : [returnElements lastObject];
}

- (id)person_getByIdAction:(id)_arg :(id)_attributes {
  id result;

  result =  [self getDocumentById:_arg
                  dataSource:[self personDataSource]
                  entityName:@"Person"
                  attributes:_attributes];

  return (result != nil) ? result : [NSNumber numberWithBool:NO];
}

@end /* DirectAction(Person) */
                                        
