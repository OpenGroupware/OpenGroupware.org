/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#include "SxContactManager.h"
#include "common.h"

#include "SxListContactSQLQuery.h"
#include "SxEvoContactSQLQuery.h"
#include "SxContactEmailSQLQuery.h"
#include "SxFetchPerson.h"
#include "SxFetchEnterprise.h"
#include "SxFetchGroup.h"
#include "NSString+DBName.h"

#include <time.h>

@interface NSObject(EOObject)
- (EOGlobalID *)globalID;
@end /* NSObject(EOObject) */

@implementation SxContactManager

/* queries */

- (SxListContactSQLQuery *)createListQuery {
  SxListContactSQLQuery *query;
  
  if (![[self modelName] isPostgreSQL]) {
    [self logWithFormat:@"list queries only tested for PostgreSQL ..."];
    [self logWithFormat:@"model: %@", [self modelName]];
  }
  
  query = [SxListContactSQLQuery alloc];
  query = [query initWithContext:[self commandContext]];
  return [query autorelease];
}

- (NSEnumerator *)listPublicPersons {
  SxListContactSQLQuery *query = [self createListQuery];
  [query makePublicQuery];
  return [query runAndRollback];
}

- (NSEnumerator *)listPrivatePersons {
  SxListContactSQLQuery *query = [self createListQuery];
  return [query runAndRollback];
}

- (NSEnumerator *)listAccounts {
  SxListContactSQLQuery *query = [self createListQuery];
  [query makeAccountQuery];
  return [query runAndRollback];
}

/* TODO: to be improved ... */
- (NSEnumerator *)listAccountsForGroup:(id)_group {
  NSEnumerator   *enumerator;
  NSMutableArray *result;
  NSArray        *array;
  id             team, ctx, obj;
  
  if (![_group isNotNull]) /* list all accounts */
    return [self listAccounts];
  
  ctx  = [self commandContext];
  team = [ctx runCommand:@"team::get-by-login", @"login", _group, nil];

  array = [ctx runCommand:@"team::members", @"object", team, nil];
  result     = [NSMutableArray arrayWithCapacity:[array count]];
  enumerator = [array objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    NSDictionary *dict;

    dict = [[NSDictionary alloc] initWithObjectsAndKeys:
                           [obj valueForKey:@"objectVersion"],
                           @"version",
                           [obj valueForKey:@"companyId"],
                           @"pkey", nil];
    [result addObject:dict];
    [dict release];
  }
  return [result objectEnumerator];
}

- (NSEnumerator *)listAccountsWithEmail:(NSString *)_eml {
  SxContactEmailSQLQuery *query;
  
  query = [[SxContactEmailSQLQuery alloc]
                                   initWithContext:[self commandContext]];
  query = [query autorelease];
  [query setEmail:_eml];
  [query makeAccountQuery];
  return [query runAndRollback];
}

- (NSEnumerator *)listAccountsWithEmails:(NSArray *)_emls {
  SxContactEmailSQLQuery *query;
  query = [[SxContactEmailSQLQuery alloc]
                                   initWithContext:[self commandContext]];
  query = [query autorelease];
  [query setEmails:_emls];
  [query makeAccountQuery];
  return [query runAndRollback];
}

- (NSEnumerator *)listGroupsWithEmails:(NSArray *)_emls {
  SxContactEmailSQLQuery *query;
  query = [[SxContactEmailSQLQuery alloc]
                                   initWithContext:[self commandContext]];
  query = [query autorelease];
  [query setEmails:_emls];
  [query makeGroupQuery];
  return [query runAndRollback];
}

- (NSEnumerator *)listPublicPersonsWithEmails:(NSArray *)_emls {
  SxContactEmailSQLQuery *query;
  query = [[SxContactEmailSQLQuery alloc]
                                   initWithContext:[self commandContext]];
  query = [query autorelease];
  [query setEmails:_emls];
  [query makePublicQuery];
  return [query runAndRollback];
}

- (NSEnumerator *)listPrivatePersonsWithEmails:(NSArray *)_emls {
  SxContactEmailSQLQuery *query;
  query = [[SxContactEmailSQLQuery alloc]
                                   initWithContext:[self commandContext]];
  query = [query autorelease];
  [query setEmails:_emls];
  return [query runAndRollback];
}

- (NSEnumerator *)listPublicEnterprises {
  SxListContactSQLQuery *query = [self createListQuery];
  [query makePublicQuery];
  [query makeEnterpriseQuery];
  return [query runAndRollback];
}

- (NSEnumerator *)listPrivateEnterprises {
  SxListContactSQLQuery *query = [self createListQuery];
  [query makeEnterpriseQuery];
  return [query runAndRollback];
}

- (NSEnumerator *)listGroups {
  SxListContactSQLQuery *query = [self createListQuery];
  [query makeGroupQuery];
  return [query runAndRollback];
}

- (NSEnumerator *)listContactSet:(SxContactSetIdentifier *)_sid {
  if ([_sid isAccountSet])
    return [self listAccounts];
  
  if ([_sid isEnterpriseSet]) {
    return [_sid isPublicSet]
      ? [self listPublicEnterprises]
      : [self listPrivateEnterprises];
  }
  
  return [_sid isPublicSet]
    ? [self listPublicPersons]
    : [self listPrivatePersons];
}

/* evo searches */

- (NSDictionary *)versionsForIds:(NSArray *)_ids
  entityName:(NSString *)_entityName
{
  static NSArray *Attrs = nil;

  NSString            *command;
  NSEnumerator        *enumerator;
  NSMutableArray      *gids;
  NSNumber            *oid;
  NSArray             *fetch;
  NSMutableDictionary *res;
  NSDictionary        *dict;

  if (!Attrs) {
    Attrs = [[NSArray alloc] initWithObjects:@"companyId",
                             @"objectVersion", nil];
  }
  command = [NSString stringWithFormat:@"%@::get-by-globalID",
                      [_entityName lowercaseString]];
  gids = [NSMutableArray arrayWithCapacity:[_ids count]];

  enumerator = [_ids objectEnumerator];

  while ((oid = [enumerator nextObject])) {
    EOKeyGlobalID *kgid;

    kgid = [EOKeyGlobalID globalIDWithEntityName:_entityName
                          keys:&oid keyCount:1 zone:NULL];
    [gids addObject:kgid];
  }
  fetch = [[self commandContext] runCommand:command,
                                 @"gids", gids,
                                 @"attributes", Attrs, nil];

  enumerator = [fetch objectEnumerator];
  res        = [NSMutableDictionary dictionaryWithCapacity:[fetch count]];
  while ((dict = [enumerator nextObject])) {
    [res setObject:[dict objectForKey:@"objectVersion"]
         forKey:[dict objectForKey:@"companyId"]];
  }
  return res;
}

/* ZideLook section */

- (NSArray *)fullObjectInfosForPrimaryKeys:(NSArray *)_pkeys
  withSetIdentifier:(SxContactSetIdentifier *)_ident
{
  NSString             *entityName;
  NSDictionary         *versions;
  NSMutableArray       *result, *toBeFetched;
  NSEnumerator         *enumerator;
  NSDictionary         *obj;
  
  entityName  = [_ident isEnterpriseSet] ? @"Enterprise" : @"Person";
  versions    = [self versionsForIds:_pkeys entityName:entityName];
  toBeFetched = [NSMutableArray arrayWithCapacity:[_pkeys count]];
  result      = [NSMutableArray arrayWithCapacity:[_pkeys count]];
  enumerator  = [versions keyEnumerator];

  //TODO: Can this be done more efficiently?
  while ((obj = [enumerator nextObject])) {
      [toBeFetched addObject:obj];
  }

  if ([toBeFetched count]) {
    NSArray *fetchRes;
    
    fetchRes = [_ident isEnterpriseSet]
      ? [self fullEnterpriseInfosForPrimaryKeys:toBeFetched]
      : [self fullPersonInfosForPrimaryKeys:toBeFetched];
    
    [result addObjectsFromArray:fetchRes];
  }
  return result;
}


- (NSDictionary *)fullPersonInfoForPrimaryKey:(NSNumber *)_id {
  SxFetchPerson *p;
  NSDictionary  *result;

  p = [[SxFetchPerson alloc] initWithContext:[self commandContext]];
  result = [p dictWithPrimaryKey:_id];
  [p release]; p = nil;
  return result;
}

- (NSDictionary *)fullEnterpriseInfoForPrimaryKey:(NSNumber *)_id {
  SxFetchPerson *p;
  NSDictionary  *result;

  p = [[SxFetchEnterprise alloc] initWithContext:[self commandContext]];
  result = [p dictWithPrimaryKey:_id];
  [p release]; p = nil;
  return result;
}

- (NSDictionary *)fullGroupInfoForPrimaryKey:(NSNumber *)_id {
  SxFetchGroup *p;
  NSDictionary  *result;

  p = [[SxFetchGroup alloc] initWithContext:[self commandContext]];
  result = [p dictWithPrimaryKey:_id];
  [p release]; p = nil;
  return result;
}

- (NSArray *)fullPersonInfosForPrimaryKeys:(NSArray *)_pkeys {
  // TODO: use a SKYRiX bulk-query !
  NSMutableArray *ma;
  unsigned i, count;

  if (_pkeys == nil) return nil;
  if ((count = [_pkeys count]) == 0) return [NSArray array];
  ma = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSNumber     *pkey;
    NSDictionary *zlRecord;
    
    pkey     = [_pkeys objectAtIndex:i];
    zlRecord = [self fullPersonInfoForPrimaryKey:pkey];
    
    if (zlRecord == nil) zlRecord = (id)[NSNull null];
    [ma addObject:zlRecord];
  }
  return ma;
}


- (NSArray *)fullEnterpriseInfosForPrimaryKeys:(NSArray *)_pkeys {
  
  // TODO: use a SKYRiX bulk-query !
  NSMutableArray *ma;
  unsigned i, count;
  
  if (_pkeys == nil) return nil;
  if ((count = [_pkeys count]) == 0) return [NSArray array];
  ma = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSNumber     *pkey;
    NSDictionary *zlRecord;
    
    pkey     = [_pkeys objectAtIndex:i];
    zlRecord = [self fullEnterpriseInfoForPrimaryKey:pkey];
    
    if (zlRecord == nil) zlRecord = (id)[NSNull null];
    [ma addObject:zlRecord];
  }
  return ma;
}

/* set operations (need to be cached) */

- (int)refreshInterval {
  static int ref = -1;
  if (ref == -1) {
    ref = [[[NSUserDefaults standardUserDefaults] 
             objectForKey:@"ZLFolderRefresh"] intValue];
  }
  return ref > 0 ? ref : 300; /* every five minutes */
}

- (int)generationOfContactSet:(SxContactSetIdentifier *)_set {
  /* 
     This is used by ZideLook to track folder changes.
     TODO: implement folder-change detection ... (snapshot of last
     id/version set contained in the folder)
  */
  return (time(NULL) - 1047000000) / [self refreshInterval];
}

static NSComparisonResult pkeyCompare(id date1, id date2, void *self) {
  return [(NSNumber *)[(NSDictionary *)date1 objectForKey:@"pkey"] 
		      compare:(NSNumber *)
		      [(NSDictionary *)date2 objectForKey:@"pkey"]];
}

- (NSString *)idsAndVersionsCSVForContactSet:(SxContactSetIdentifier *)_set {
  /* Returns a string in the format: (id:version\n)* */
  NSMutableString *ms;
  NSEnumerator *e;
  NSArray  *infos, *tmp;
  unsigned i, count;
  
  if ((e = [self listContactSet:_set]) == nil)
    return nil;
  
  tmp = [[NSArray alloc] initWithObjectsFromEnumerator:e];
  if ((count = [tmp count]) == 0) {
    [tmp release];
    return @"";
  }
  
  /* sort keys to ensure set identity */
  infos = [tmp sortedArrayUsingFunction:pkeyCompare context:self];
  [tmp release]; tmp = nil;
  
  [self logWithFormat:@"[ids and versions] processing %i contacts", count];
  ms = [NSMutableString stringWithCapacity:(count * 8)];
  
  for (i = 0; i < count; i++) {
    NSDictionary *info;
    id version;
    
    info = [infos objectAtIndex:i];
    version = [info objectForKey:@"version"];
    if (![version isNotNull]) {
      [self logWithFormat:@"WARNING: missing version in info: %@", info];
      version = @"1";
    }
    
    [ms appendString:[[info objectForKey:@"pkey"] stringValue]];
    [ms appendString:@":"];
    [ms appendString:[version stringValue]];
    if (i != (count - 1)) /* TODO: check, not for the last ? */
      [ms appendString:@"\n"];
  }
  return ms;
}

- (int)countOfContactSet:(SxContactSetIdentifier *)_set {
  NSEnumerator *e;
  unsigned count;
  
  if ((e = [self listContactSet:_set]) == nil)
    return -1;

  count = 0;
  while ([e nextObject])
    count++;
  return count;
}

@end /* SxContactManager */


@implementation SxContactManager(vCard)

- (NSEnumerator *)idsAndVersionsAndVCardsForGlobalIDs:(NSArray *)_gids {
  static NSArray *attrs = nil;
  NSArray *result;

  if (attrs == nil)
    attrs = [[NSArray alloc] initWithObjects:
                             @"companyId", @"globalID",
                             @"objectVersion", @"vCardData", nil];
  
  result = [[self commandContext] runCommand:@"company::get-vcard",
                                  @"gids",       _gids,
                                  @"attributes", attrs,
                                  nil];
  return [result objectEnumerator];
}

- (NSEnumerator *)idsAndVersionsAndVCardsForContactSet:
  (SxContactSetIdentifier *)_set
{
  NSEnumerator   *e;
  NSMutableArray *gids;
  NSArray        *list;
  NSString       *entityName;
  int cnt, i;
  
  if ((e = [self listContactSet:_set]) == nil) return nil;

  entityName = [_set isEnterpriseSet] ? @"Enterprise" : @"Person";
  list = [[NSArray alloc] initWithObjectsFromEnumerator:e];
  if ((cnt = [list count]) == 0) {
    [list release];
    return [[NSArray array] objectEnumerator];
  }

  gids = [[NSMutableArray alloc] initWithCapacity:cnt];
  for (i = 0; i < cnt; i++) {
    id tmp;
    
    tmp = [list objectAtIndex:i];
    tmp = [(NSDictionary *)tmp objectForKey:@"pkey"];
    if (tmp == nil) {
      NSLog(@"WARNING[%s] got entry without pkey. cannot build gid",
            __PRETTY_FUNCTION__);
      continue;
    }
    tmp = [EOKeyGlobalID globalIDWithEntityName:entityName
                         keys:&tmp keyCount:1 zone:NULL];
    if (tmp) [gids addObject:tmp];
  }

  e = [self idsAndVersionsAndVCardsForGlobalIDs:gids];
  [list release];
  [gids release];
  return e;
}

@end /* SxContactManager(vCard) */
