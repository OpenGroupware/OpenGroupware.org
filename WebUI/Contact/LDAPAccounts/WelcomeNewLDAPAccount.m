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

#include <NGObjWeb/WOComponent.h>

@class NSString;
@class LSCommandContext;
@class NGLdapEntry;

@interface WelcomeNewLDAPAccount : WOComponent
{
  NSString         *login;
  NSString         *password;
  NGLdapEntry      *entry;
  LSCommandContext *cmdctx;
}

- (id)logout;

@end

#include <LSFoundation/OGoContextManager.h>
#include <LSFoundation/OGoContextSession.h>
#include <LSFoundation/LSCommandContext.h>
#include <LSFoundation/LSCommandKeys.h>
#include <LSFoundation/LSBaseCommand.h>
#include <OGoFoundation/OGoSession.h>
#include <OGoFoundation/OGoNavigation.h>
#include "common.h"
#include <NGObjWeb/NGObjWeb.h>
#include <NGLdap/NGLdap.h>
#include "NGLdapConnection+DNSearch.h"

@interface OGoSession(ConfigLogin)
- (BOOL)configureForLSOfficeSession:(OGoContextSession *)_sn;
@end

@implementation WelcomeNewLDAPAccount

- (id)init {
  if ((self = [super init])) {
    OGoContextManager *lso;
    
    if (![LSCommandContext useLDAPAuthorization]) {
      [self release];
      return nil;
    }
    
    if ((lso = [[WOApplication application] valueForKey:@"lsoServer"]) == nil){
      [self logWithFormat:@"did not find OGo server .."];
      [self release];
      return nil;
    }
    
    self->cmdctx = [[LSCommandContext alloc] initWithManager:lso];
    [self logWithFormat:@"got cmd ctx %@", self->cmdctx];
  }
  return self;
}

- (void)dealloc {
  [self->cmdctx   release];
  [self->entry    release];
  [self->login    release];
  [self->password release];
  [super dealloc];
}

/* accessors */

- (void)setLogin:(NSString *)_login {
  ASSIGNCOPY(self->login, _login);
  
  if ([_login length] > 0)
    [self->cmdctx takeValue:_login forKey:@"authorizedLDAPLogin"];
}
- (NSString *)login {
  return self->login;
}

- (void)setPassword:(NSString *)_password {
  ASSIGNCOPY(self->password, _password);
}

- (id)entry {
  return self->entry;
}

/* handle ldap */

- (void)_process {
  NGLdapConnection *con;
  NSUserDefaults   *ud;
  NSString         *host, *root;
  int              port;
  NSString         *dn;
  BOOL             didBind;
  NSString         *uid;

  ud       = [NSUserDefaults standardUserDefaults];
  host     = [ud stringForKey:@"LSAuthLDAPServer"];
  root     = [ud stringForKey:@"LSAuthLDAPServerRoot"];
  port     = [[ud objectForKey:@"LSAuthLDAPServerPort"] intValue];
  uid      = [self login];
  
  con = [[NGLdapConnection alloc] initWithHostName:host port:port];
  if (con == nil) {
    [self logWithFormat:@"couldn't access LDAP server '%@:%i' !.",
          host, port];
    return;
  }

  dn = [con dnForUID:[self login] atBase:root];

  if (dn == nil) {
    [self logWithFormat:@"didn't find valid DN for uid '%@'", uid];
    didBind = NO;
  }
  else {
    NS_DURING
      didBind = [con bindWithMethod:@"simple"
                     binddn:dn
                     credentials:self->password];
    NS_HANDLER
      didBind = NO;
    NS_ENDHANDLER;
  }
  
  if (!didBind) {
    [self logWithFormat:@"couldn't bind LDAP server '%@:%i' as dn %@ !.",
            host, port, dn];
    [con release];
    return;
  }

  self->entry = [[con entryAtDN:dn attributes:nil] retain];
  [con release];
}

/* account creation */

- (NSArray *)_teamsForAccount:(NSArray *)_names {
  NSMutableArray *teams;
  NSEnumerator *allTeams;
  NSSet *teamSet;
  id team;
  
  allTeams = [[self->cmdctx runCommand:@"team::get-all", nil]
                            objectEnumerator];
  if (allTeams == nil)
    return nil;

  if (_names == nil)
    _names = [NSArray array];
  
  teamSet = [NSSet setWithArray:_names];
  teams   = [NSMutableArray arrayWithCapacity:[_names count]];

  while ((team = [allTeams nextObject])) {
    NSString *teamName;

    teamName = [team valueForKey:@"description"];

    if ([teamSet containsObject:teamName])
      [teams addObject:team];
  }
  
  return teams;
}

- (void)_applyPhonesOnAccount:(id)account inContext:(LSCommandContext *)_cmdctx
{
  NSEnumerator    *phones;
  NGLdapAttribute *attr;
  id phone;

  phones = [[account valueForKey:@"telephones"] objectEnumerator];
  
  while ((phone = [phones nextObject])) {
    if ([[phone valueForKey:@"type"] isEqualToString:@"01_tel"]) {
      attr = [[self entry] attributeWithName:@"telephoneNumber"];
        
      if ([attr count] > 0) {
        [_cmdctx runCommand:@"telephone::set",
             @"object", phone,
             @"number", [attr stringValueAtIndex:0],
             @"checkAccess", [NSNumber numberWithBool:NO],                 
             nil];
      }
    }
    else if ([[phone valueForKey:@"type"] isEqualToString:@"03_tel_funk"]) {
      attr = [[self entry] attributeWithName:@"mobile"];
        
      if ([attr count] > 0) {
        [_cmdctx runCommand:@"telephone::set",
             @"object", phone,
             @"number", [attr stringValueAtIndex:0],
             @"checkAccess", [NSNumber numberWithBool:NO],                 
             nil];
      }
    }
    else if ([[phone valueForKey:@"type"] isEqualToString:@"10_fax"]) {
      attr = [[self entry] attributeWithName:@"facsimileTelephoneNumber"];
        
      if ([attr count] > 0) {
        [_cmdctx runCommand:@"telephone::set",
                 @"object", phone,
                 @"number", [attr stringValueAtIndex:0],
                 @"checkAccess", [NSNumber numberWithBool:NO],                 
                 nil];
      }
    }
  }
}

- (void)_applyAddressesOnAccount:(id)account
  inContext:(LSCommandContext *)_cmdctx
{
  NGLdapAttribute     *attr;
  NSMutableDictionary *addrDict;
  NSArray             *addrs;
  id                  addr = nil;
  
  NSAssert(account, @"missing account object ..");
  NSAssert(_cmdctx, @"missing command context ..");
  
  addrs = [_cmdctx runCommand:@"address::get",
                   @"companyId", [account valueForKey:@"companyId"],
                   @"type",      @"mailing",
                   @"operator",  @"AND",
                   @"checkAccess", [NSNumber numberWithBool:NO],
                   @"returnType",
                   [NSNumber numberWithInt:LSDBReturnType_ManyObjects],
                   nil];

  if (addrs != nil) {
    addr = [addrs lastObject];
  }
  else {
    [self logWithFormat:@"missing 'mailing' address .."];
    return;
  }
  
  addrDict = [NSMutableDictionary dictionaryWithCapacity:16];
  
  [addrDict setObject:addr forKey:@"object"];
  
  attr = [[self entry] attributeWithName:@"cn"];
  if ([attr count] > 0)
    [addrDict setObject:[attr stringValueAtIndex:0] forKey:@"name1"];
        
  attr = [[self entry] attributeWithName:@"street"];
  if ([attr count] > 0)
    [addrDict setObject:[attr stringValueAtIndex:0] forKey:@"street"];
        
  attr = [[self entry] attributeWithName:@"postalCode"];
  if ([attr count] > 0)
    [addrDict setObject:[attr stringValueAtIndex:0] forKey:@"zip"];

  attr = [[self entry] attributeWithName:@"st"];
  if ([attr count] > 0)
    [addrDict setObject:[attr stringValueAtIndex:0] forKey:@"state"];

  attr = [[self entry] attributeWithName:@"l"];
  if ([attr count] > 0)
    [addrDict setObject:[attr stringValueAtIndex:0] forKey:@"city"];

  [addrDict setObject:[NSNumber numberWithBool:NO] forKey:@"checkAccess"];
  [_cmdctx runCommand:@"address::set" arguments:addrDict];
}

- (BOOL)canCreateAccount {
  return YES;
}

/* actions */

- (id)createAndLogin {
  NSMutableDictionary *snapshot;
  NSArray         *teams;
  NGLdapAttribute *attr;
  id              ownerId;
  id              templId;
  id              account;

  if (![self canCreateAccount]) {
    [self logWithFormat:
          @"can't create account. number of named users exhausted"];
    return [self logout];
  }
  
  //NSLog(@"create account in ctx %@", self->cmdctx);
  
  ownerId = [NSNumber numberWithInt:10000 /* root */];
  templId = [NSNumber numberWithInt:9999];
  
  snapshot = [NSMutableDictionary dictionaryWithCapacity:32];

  [snapshot setObject:
              [NSString stringWithFormat:
                          @"account created based on LDAP entry '%@'",
                          [[self entry] dn]]
            forKey:@"logText"];
  
  [snapshot setObject:ownerId forKey:@"ownerId"];
  [snapshot setObject:templId forKey:@"templateUserId"];
  
  [snapshot setObject:self->login forKey:@"login"];
  
  if ((attr = [[self entry] attributeWithName:@"skyrixteams"]))
    teams = [self _teamsForAccount:[attr allStringValues]];
  else {
    teams = [self->cmdctx runCommand:@"team::get",
                 @"companyId", [NSNumber numberWithInt:10003], nil];  
  }
  [snapshot setObject:teams forKey:@"groups"];
  
  if ([(attr = [[self entry] attributeWithName:@"sn"]) count] > 0)
    [snapshot setObject:[attr stringValueAtIndex:0] forKey:@"name"];

  if ([(attr = [[self entry] attributeWithName:@"title"]) count] > 0)
    [snapshot setObject:[attr stringValueAtIndex:0] forKey:@"degree"];
  
  if ([(attr = [[self entry] attributeWithName:@"givenName"]) count] > 0)
    [snapshot setObject:[attr stringValueAtIndex:0] forKey:@"firstname"];

  if ([(attr = [[self entry] attributeWithName:@"initials"]) count] > 0)
    /* nickname */
    [snapshot setObject:[attr stringValueAtIndex:0] forKey:@"description"];
  
  if ([(attr = [[self entry] attributeWithName:@"mail"]) count] > 0)
    [snapshot setObject:[attr stringValueAtIndex:0] forKey:@"email1"];

  if ([(attr = [[self entry] attributeWithName:@"labeledURI"]) count] > 0) {
    NSString *tmp;
    NSRange  r;

    tmp = [attr stringValueAtIndex:0];
    r = [tmp rangeOfString:@" "];
    if (r.length > 0)
      tmp = [tmp substringToIndex:r.location];
    
    [snapshot setObject:tmp forKey:@"url"];
  }
  
  //[self debugWithFormat:@"create account: %@", snapshot];

  account = [self->cmdctx runCommand:@"account::new" arguments:snapshot];

  if (account == nil) {
    [self logWithFormat:@"couldn't create account for LDAP entry."];
    [self->cmdctx rollback];
    return [self logout];
  }

  if (![self->cmdctx commit]) {
    [self logWithFormat:@"couldn't commit created account for LDAP entry."];
    return [self logout];
  }
  
  //[self logWithFormat:@"got account: %@", account];
  
  /* login */
  {
    OGoContextSession *sn;
    OGoContextManager *lso;
    id page;

    lso = [[WOApplication application] valueForKey:@"lsoServer"];
    
    if ((sn = [lso login:self->login password:self->password]) == nil) {
      [self logWithFormat:
              @"ERROR: account %@ created from LDAP account, "
              @"but can't login ?.", [account valueForKey:@"number"]];
      return [self logout];
    }

    [self->cmdctx release];
    self->cmdctx = nil;
    
    [sn activate];

    account = [[sn commandContext] runCommand:@"account::get",
                                  @"companyId",
                                 [account valueForKey:@"companyId"],
                                  @"checkAccess", [NSNumber numberWithBool:NO],
                                  nil];

    account = [account lastObject];

    if (account != nil) {
      [self _applyAddressesOnAccount:account inContext:[sn commandContext]];
      [self _applyPhonesOnAccount:account    inContext:[sn commandContext]];
    
      if (![[sn commandContext] commit]) {
        [self logWithFormat:@"couldn't commit addrs/phones for LDAP entry."];
        return [self logout];
      }
    }

    /* apply debugging defaults */

    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"s"] boolValue])
      [sn enableAdaptorDebugging];
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"sa"] boolValue])
      [LSBaseCommand setDebuggingEnabled:YES];

    /* configure WO session */
    
    if (![(OGoSession *)[self session] configureForLSOfficeSession:sn]) {
      [[self session] terminate];
      [self logWithFormat:@"failed to configure session !"];
      return [self pageWithName:@"OGoLogoutPage"];
    }
    
    /* start page */

    page = [[(OGoSession *)[self session] navigation] activePage];

    if (page == nil) {
      [self logWithFormat:@"failed to load start page !"];
    
      [[WOApplication application] terminate];
      return [self pageWithName:@"OGoLogoutPage"];
    }

    /* reset to default session timeout */
    
    [[self session] setTimeOut:[[WOApplication sessionTimeOut] intValue]];

    /* return page */

    return page;
  }
}

- (id)logout {
  [[self session] terminate];
  return [[self application] pageWithName:@"OGoLogoutPage"];
}

- (BOOL)isLDAPLicensed {
  // TODO: deprecated
  return YES;
}

/* response generation */

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  [self _process];
  [super appendToResponse:_response inContext:_ctx];
}

@end /* WelcomeNewLDAPAccount */
