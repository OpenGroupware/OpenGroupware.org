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
//$Id$

#include "SkyAccountApplication.h"
#include "SkyAccountAction.h"
#include <OGoDaemon/SDApplication.h>
#include "common.h"


@implementation SkyAccountApplication

static NSArray *AccountAttrNames    = nil;
static NSArray *AccountAttrs        = nil;
static NSArray *GroupAttrNames      = nil;
static NSArray *GroupAttrs          = nil;
static NSArray *CompanyAssAttrNames = nil;
static NSArray *CompanyAssAttrs     = nil;


/*
  Caches:
  login2AccountCache  -->  login -> {login,..}
  uid2AccountCache    -->  uid   -> {login,..}
  name2GroupCache     -->  gname -> {description,..}
  gid2GroupCache      -->  gid   -> {description,..}
  uid2GroupCache      -->  uid   -> ({description,..},..)
  gid2AccountCache    -->  gid   -> ({login,..}, ..)
*/    

+ (void)initialize {
  if (!AccountAttrNames) {
    AccountAttrNames = [[NSArray alloc] initWithObjects:
                                        @"login", @"companyId",
                                        @"name", @"firstname", nil];
    GroupAttrNames = [[NSArray alloc] initWithObjects:
                                      @"description", @"companyId",
                                      @"isLocationTeam", nil];
    CompanyAssAttrNames = [[NSArray alloc] initWithObjects:
                                           @"companyId", @"subCompanyId", nil];

  }
}

- (id)init {
  if ((self = [super init])) {
    [NGXmlRpcAction registerActionClass:[SkyAccountAction class]
                    forURI:@"/RPC2"];
    [SkyAccountAction registerMappingsInFile:@"SkyAccountActionMap"];
    
    NS_DURING {
      [self initCache];
    }
    NS_HANDLER {
#warning disable this ABORT in production code!
      printf("got objc exception %s\n",
             [[localException description] cString]);
      abort();
    }
    NS_ENDHANDLER;
  }
  return self;
}

- (void)buildAccountCacheWithModel:(EOModel *)model
  channel:(EOAdaptorChannel *)adChannel
{
  EOSQLQualifier *qual;
  EOEntity       *entity;

  entity = [model entityNamed:@"Person"];

  if (AccountAttrs == nil) {
    NSEnumerator *enumerator;
    NSString     *n;
    NSMutableArray *array;

    array      = [[NSMutableArray alloc] initWithCapacity:
                                         [AccountAttrNames count]];
    enumerator = [AccountAttrNames objectEnumerator];

    while ((n = [enumerator nextObject])) {
      [array addObject:[entity attributeNamed:n]];
    }
    AccountAttrs = [array copy];
    RELEASE(array); array = nil;
  }

  qual = [[EOSQLQualifier alloc] initWithEntity:entity
                                 qualifierFormat:@"%A <> '%@' AND %A = %@",
                                 @"dbStatus", @"archived", @"isAccount",
                                 [NSNumber numberWithInt:1], nil];
  AUTORELEASE(qual);

  if (![adChannel selectAttributes:AccountAttrs
                  describedByQualifier:qual fetchOrder:nil
                  lock:NO]) {
    NSLog(@"ERROR[%s] couldn`t fetch attrs %@ with qual %@",
          __PRETTY_FUNCTION__, AccountAttrs, qual);
    return;
  }
  {
    id obj;

    self->login2AccountCache = [[NSMutableDictionary alloc]
                                                     initWithCapacity:512];
    self->uid2AccountCache   = [[NSMutableDictionary alloc]
                                                     initWithCapacity:512];

    while ((obj = [adChannel fetchAttributes:AccountAttrs withZone:nil])) {
      NSString *uid;

      uid = [[obj objectForKey:@"companyId"] stringValue];
      [obj setObject:uid forKey:@"uid"];
      [obj removeObjectForKey:@"companyId"];
                            
      [self->login2AccountCache setObject:obj
           forKey:[obj objectForKey:@"login"]];
      [self->uid2AccountCache setObject:obj forKey:uid];;
    }
  }
}

- (void)buildAcccountsToGroupsRelations:(EOModel *)model
  channel:(EOAdaptorChannel *)adChannel
{
  EOSQLQualifier *qual;
  EOEntity       *entity;

  entity = [model entityNamed:@"CompanyAssignment"];

  if (!CompanyAssAttrs) {
    NSEnumerator *enumerator;
    NSString     *n;
    NSMutableArray *array;

    array      = [[NSMutableArray alloc] initWithCapacity:
                                         [CompanyAssAttrNames count]];
    enumerator = [CompanyAssAttrNames objectEnumerator];

    while ((n = [enumerator nextObject])) {
      [array addObject:[entity attributeNamed:n]];
    }
    CompanyAssAttrs = [array copy];
    RELEASE(array); array = nil;
  }

  qual = [[EOSQLQualifier alloc] initWithEntity:entity
                                 qualifierFormat:@"%A = %@",
                                 @"toTeam.isTeam",
                                 [NSNumber numberWithBool:YES], nil];
  AUTORELEASE(qual);

  if (![adChannel selectAttributes:CompanyAssAttrs
                  describedByQualifier:qual fetchOrder:nil
                  lock:NO]) {
    NSLog(@"ERROR[%s] couldn`t fetch attrs %@ with qual %@",
          __PRETTY_FUNCTION__, GroupAttrs, qual);
    return;
  }
  {
    id obj;

    self->gid2AccountCache = [[NSMutableDictionary alloc]
                                                     initWithCapacity:128];
    self->uid2GroupCache   = [[NSMutableDictionary alloc]
                                                     initWithCapacity:512];

    while ((obj = [adChannel fetchAttributes:AccountAttrs withZone:nil])) {
      NSMutableArray *array;
      NSString       *gid, *uid;
      id             o;

      gid = [[obj objectForKey:@"companyId"] stringValue];
      uid = [[obj objectForKey:@"subCompanyId"] stringValue];

      if (!(array = [self->gid2AccountCache objectForKey:gid])) {
        array = [NSMutableArray arrayWithCapacity:64];
        [self->gid2AccountCache setObject:array forKey:gid];
      }
      if ((o = [self->uid2AccountCache objectForKey:uid]))
        [array addObject:o];

      if (!(array = [self->uid2GroupCache objectForKey:uid])) {
        array = [NSMutableArray arrayWithCapacity:8];
        [self->uid2GroupCache setObject:array forKey:uid];
      }
      if  ((o = [self->gid2GroupCache objectForKey:gid])) {
        [array addObject:o];
      }
    }
  }
}

- (void)buildGroupsCacheWithModel:(EOModel *)model
  channel:(EOAdaptorChannel *)adChannel
{
  EOSQLQualifier *qual;
  EOEntity       *entity;

  entity = [model entityNamed:@"Team"];

  if (GroupAttrs == nil) {
    NSEnumerator *enumerator;
    NSString     *n;
    NSMutableArray *array;

    array      = [[NSMutableArray alloc] initWithCapacity:
                                         [GroupAttrNames count]];
    enumerator = [GroupAttrNames objectEnumerator];

    while ((n = [enumerator nextObject])) {
      [array addObject:[entity attributeNamed:n]];
    }
    GroupAttrs = [array copy];
    RELEASE(array); array = nil;
  }

  qual = [[EOSQLQualifier alloc] initWithEntity:entity
                                 qualifierFormat:@"%A <> '%@'",
                                 @"dbStatus", @"archived", nil];
  AUTORELEASE(qual);

  if (![adChannel selectAttributes:GroupAttrs
                  describedByQualifier:qual fetchOrder:nil
                  lock:NO]) {
    NSLog(@"ERROR[%s] couldn`t fetch attrs %@ with qual %@",
          __PRETTY_FUNCTION__, GroupAttrs, qual);
    return;
  }
  {
    id obj;

    self->name2GroupCache = [[NSMutableDictionary alloc]
                                                     initWithCapacity:128];
    self->gid2GroupCache  = [[NSMutableDictionary alloc]
                                                     initWithCapacity:128];

    while ((obj = [adChannel fetchAttributes:AccountAttrs withZone:nil])) {
      NSString *uid;

      uid = [[obj objectForKey:@"companyId"] stringValue];
      [obj setObject:uid forKey:@"gid"];
      [obj removeObjectForKey:@"companyId"];
                            
      [self->name2GroupCache setObject:obj
           forKey:[obj objectForKey:@"description"]];
      [self->gid2GroupCache setObject:obj forKey:uid];;
    }
  }
}


- (void)initCache {
  EOModel           *model;
  EOAdaptor         *adaptor;
  EODatabase        *db;
  EODatabaseContext *dbContext;
  EOAdaptorChannel  *adChannel;
  
  adaptor   = [[self lso] adaptor];
  db        = [[EODatabase alloc] initWithAdaptor:adaptor];
  dbContext = [db        createContext];
  adChannel = [[dbContext createChannel] adaptorChannel];
  model     = [adaptor model];
  AUTORELEASE(db);

  if (db == nil) {
    NSLog(@"WARNING[%s]: could not create database object !",
          __PRETTY_FUNCTION__);
    return;
  }
  if (dbContext == nil) {
    NSLog(@"WARNING[%s]: could not create database context for db %@ !",
          __PRETTY_FUNCTION__, db);
    return;
  }
  if (adChannel == nil) {
    NSLog(@"WARNING[%s]: could not create adaptor channel for ctx %@ !",
          __PRETTY_FUNCTION__, dbContext);
    return;
  }
  
  if (![adChannel openChannel]) {
    NSLog(@"WARNING[%s]: Couldn`t open channel %@", __PRETTY_FUNCTION__,
          adChannel);
    return;
  }
  if (![[adChannel adaptorContext] beginTransaction]) {
    NSLog(@"WARNING[%s]: Couldn`t begin transaction channel: %@",
          __PRETTY_FUNCTION__, adChannel);
    return;
  }
  [self buildAccountCacheWithModel:model      channel:adChannel];
  [self buildGroupsCacheWithModel:model       channel:adChannel];
  [self buildAcccountsToGroupsRelations:model channel:adChannel];

  if (![[adChannel adaptorContext] commitTransaction]) {
    NSLog(@"WARNING[%s]: Couldn`t commit transaction channel: %@",
          __PRETTY_FUNCTION__, adChannel);
    return;
  }
  [adChannel closeChannel];
  
  
}

- (void)dealloc {
  RELEASE(self->login2AccountCache);
  RELEASE(self->uid2AccountCache);
  RELEASE(self->name2GroupCache);
  RELEASE(self->gid2GroupCache);
  RELEASE(self->gid2AccountCache);
  RELEASE(self->uid2GroupCache);
  [super dealloc];
}

- (void)flushCache {
}

- (NSArray *)allGroups {
  return [self->gid2GroupCache allValues];
}

- (NSDictionary *)groupById:(NSString *)_id {
  return [self->gid2GroupCache objectForKey:_id];
}

- (NSDictionary *)groupByName:(NSString *)_name {
  return [self->name2GroupCache objectForKey:_name];
}

- (NSArray *)accountsForGroup:(NSString *)_id {
  NSArray *a;

  if (!(a = [self->gid2AccountCache objectForKey:_id]))
    a = [NSArray array];

  return a;
}

- (NSArray *)groupsForAccount:(NSString *)_id {
  NSArray *a;

  if (!(a = [self->uid2GroupCache objectForKey:_id]))
    a = [NSArray array];

  return a;
}
  
- (NSDictionary *)accountById:(NSString *)_id {
  return [self->uid2AccountCache objectForKey:_id];
}
- (NSDictionary *)accountByLogin:(NSString *)_id {
  return [self->login2AccountCache objectForKey:_id];
}

- (void)insertAccount:(NSMutableDictionary *)_account {
  [self->login2AccountCache setObject:_account
       forKey:[_account objectForKey:@"login"]];
  [self->uid2AccountCache setObject:_account
       forKey:[_account objectForKey:@"uid"]];
  [self->uid2GroupCache setObject:[NSMutableArray array]
       forKey:[_account objectForKey:@"uid"]];
}

- (void)insertGroup:(NSMutableDictionary *)_group {
  [self->gid2GroupCache setObject:_group
       forKey:[_group objectForKey:@"gid"]];
  [self->name2GroupCache setObject:_group
       forKey:[_group objectForKey:@"description"]];
  [self->gid2AccountCache setObject:[NSMutableArray array]
       forKey:[_group objectForKey:@"gid"]];
}

- (void)flushCachesForLogin:(NSString *)_login {
  [self flushContextForLogin:_login];
  [self->login2AccountCache removeObjectForKey:_login];
}

- (void)flushCachesForGroupName:(NSString *)_name {
  [self->name2GroupCache removeObjectForKey:_name];
}

- (void)flushCachesForGid:(NSString *)_gid {
  NSString *n;

  [self removeGroupFromAccountsCache:_gid];
  
  n = [[self->gid2GroupCache objectForKey:_gid]
                                objectForKey:@"description"];
  
  [self->name2GroupCache removeObjectForKey:n];
  [self->gid2GroupCache removeObjectForKey:_gid];

}

- (void)flushCachesForUid:(NSString *)_uid {
  NSString *login;

  [self removeAccountFromGroupCache:_uid];
  
  login = [[self->uid2AccountCache objectForKey:_uid] objectForKey:@"login"];
  
  [self flushContextForLogin:login];
  [self->login2AccountCache removeObjectForKey:login];
  [self->uid2AccountCache removeObjectForKey:_uid];

}

- (void)removeAccountFromGroupCache:(NSString *)_uid {
  NSEnumerator *groups;
  id           obj, acc;

  acc    = [self->uid2AccountCache objectForKey:_uid];
  groups = [[self->uid2GroupCache objectForKey:_uid] objectEnumerator];
  
  while ((obj = [groups nextObject])) {
    [[self->gid2AccountCache objectForKey:[obj objectForKey:@"gid"]]
                             removeObject:acc];
                               
  }
  [self->uid2GroupCache removeObjectForKey:_uid];
}

- (void)removeGroupFromAccountsCache:(NSString *)_gid {
  NSEnumerator *accounts;
  id           obj, group;

  group    = [self->gid2GroupCache objectForKey:_gid];
  accounts = [[self->gid2AccountCache objectForKey:_gid] objectEnumerator];
  
  while ((obj = [accounts nextObject])) {
    [[self->uid2GroupCache objectForKey:[obj objectForKey:@"uid"]]
                             removeObject:group];
                               
  }
  [self->gid2AccountCache removeObjectForKey:_gid];
}

- (void)removeAccounts:(NSArray *)_accounts fromGroup:(NSString *)_id {
  NSEnumerator *enumerator;
  NSString     *account;

  enumerator = [_accounts objectEnumerator];
  while ((account = [enumerator nextObject])) {
    [[self->gid2AccountCache objectForKey:_id]
                             removeObject:
                             [self->uid2AccountCache objectForKey:account]];
    [[self->uid2GroupCache objectForKey:account] removeObject:_id];
  }
}

- (void)addAccounts:(NSArray *)_accounts toGroup:(NSString *)_id {
  NSEnumerator *enumerator;
  NSString     *account;

  enumerator = [_accounts objectEnumerator];
  while ((account = [enumerator nextObject])) {
    [[self->gid2AccountCache objectForKey:_id]
                             addObject:
                             [self->uid2AccountCache objectForKey:account]];
    [[self->uid2GroupCache objectForKey:account] addObject:_id];
  }
}

@end

