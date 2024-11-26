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

#include <OGoFoundation/LSWContentPage.h>

/*
  LSWStaff
  
  This is the main page containing the admin application (just some tabs which
  lead to other components).
*/

@class NSString, NSArray, NSDictionary;

@interface LSWStaff : LSWContentPage
{
@private
  NSArray      *accounts;
  NSArray      *aptResources;
  NSArray      *aptResourceGroups;  
  NSArray      *sessionLogs;  
  NSArray      *teams;
  NSDictionary *selectedAttribute;
  unsigned     startIndex;
  id           account;           
  id           team;
  id           sessionLog;
  BOOL         isDescending;
  BOOL         isLogDescending;
  NSString     *searchString;

  // for tab view
  NSString *tabKey;
}

@end

#include "common.h"
#include <NGMime/NGMimeType.h>
#include <OGoFoundation/LSWNotifications.h>
#include <OGoFoundation/OGoSession.h>

@interface NSObject(LSWStaff_PRIVATE)
- (void)setIsTemplateUser:(BOOL)_flag;
- (WOComponent *)search;
@end

@implementation LSWStaff

static NSNumber   *Yes     = nil;
static NSNumber   *No      = nil;
static NSNumber   *num1000 = nil;
static NSArray    *aptResourceAttrNames = nil;
static NSArray    *snLogAttrNames       = nil;
static BOOL       IsMailConfigEnabled   = NO;
static NGMimeType *eoPersonType         = nil;
static NGMimeType *eoTeamType           = nil;

+ (int)version {
  return [super version] + 1;
}
+ (void)initialize {
  // TODO: check superclass version
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  if (Yes     == nil) Yes     = [[NSNumber numberWithBool:YES] retain];
  if (No      == nil) No      = [[NSNumber numberWithBool:NO]  retain];
  if (num1000 == nil) num1000 = [[NSNumber numberWithInt:1000] retain];
  
  if (eoPersonType == nil)
    eoPersonType = [[NGMimeType mimeType:@"eo/person"] copy];
  if (eoTeamType == nil)
    eoTeamType = [[NGMimeType mimeType:@"eo/team"] copy];
  
  if (aptResourceAttrNames == nil) {
    aptResourceAttrNames = [[NSArray alloc] initWithObjects:
					      @"globalID",
  					      @"name",
					      @"email",
					      @"emailSubject",
					      @"category",
					      @"notificationTime", nil];
  }
  if (snLogAttrNames == nil) {
    snLogAttrNames = [[NSArray alloc] initWithObjects:
                                         @"globalID",
                                         @"accountId",
                                         @"action",
                                         @"logDate",
                                         @"account.login",
				      nil];
  }
  
  IsMailConfigEnabled = [ud boolForKey:@"MailConfigEnabled"];
}

- (id)init {
  id p;

  /* this component is a session-singleton */
  if ((p = [self persistentInstance]) != nil) {
    [self release];
    return [p retain];
  }
  
  if ((self = [super init]) != nil) {
    [self registerAsPersistentInstance];
    
    [self registerForNotificationNamed:LSWNewAccountNotificationName];
    [self registerForNotificationNamed:LSWDeletedAccountNotificationName];
    [self registerForNotificationNamed:LSWNewTeamNotificationName];
    [self registerForNotificationNamed:LSWDeletedTeamNotificationName];
    [self registerForNotificationNamed:LSWUpdatedAccountNotificationName];
    [self registerForNotificationNamed:LSWUpdatedTeamNotificationName];
    [self registerForNotificationNamed:@"LSWNewAptResourceNotification"];
    [self registerForNotificationNamed:@"LSWDeletedAptResourceNotification"];
    [self registerForNotificationNamed:@"LSWUpdatedAptResourceNotification"];    

    self->tabKey = @"accounts";
    self->isLogDescending    = YES;
  }
  return self;
}

- (void)dealloc {
  [self unregisterAsObserver];
  [self->sessionLog        release];
  [self->tabKey            release];
  [self->accounts          release];   
  [self->aptResources      release];
  [self->sessionLogs       release];
  [self->aptResourceGroups release];
  [self->teams             release];
  [self->searchString      release];
  [self->account           release];
  [self->team              release];
  [self->selectedAttribute release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self setErrorString:nil];
  [super sleep];
}

- (void)noteChange:(NSString *)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];

  if (_object == nil)
    return;
  
  if ([_cn isEqualToString:LSWNewAccountNotificationName]) {
      [self->accounts release]; self->accounts = nil;
      self->accounts = [[NSArray alloc] initWithObjects:&_object count:1];
      [self->searchString release]; self->searchString = @"";
      [self runCommand:
            @"account::teams",
            @"object",     _object,
            @"returnType", intObj(LSDBReturnType_ManyObjects), 
            nil];
  }
  else if ([_cn isEqualToString:LSWDeletedAccountNotificationName]) {
      NSMutableArray *a = [self->accounts mutableCopy];

      [a removeObject:_object];
      [self->accounts release];
      self->accounts = a;
  }
  else if ([_cn isEqualToString:LSWUpdatedAccountNotificationName]) {
      [self runCommand:
            @"account::teams",
            @"object",     _object,
            @"returnType", intObj(LSDBReturnType_ManyObjects), 
            nil];
  }
  else if ([_cn isEqualToString:LSWNewTeamNotificationName]) {
      [self->teams release]; self->teams = nil;
      self->teams = [[NSArray alloc] initWithObjects:&_object count:1];
      [self->searchString release]; self->searchString = @"";
      [self runCommand:
            @"team::members",
            @"object",     _object,
            @"returnType", intObj(LSDBReturnType_ManyObjects), 
            nil];
  }
  else if ([_cn isEqualToString:LSWDeletedTeamNotificationName]) {
      NSMutableArray *t = [self->teams mutableCopy];

      [t removeObject:_object];
      [self->teams release];
      self->teams = t;
  }
  else if ([_cn isEqualToString:LSWUpdatedTeamNotificationName]) {
      [self runCommand:
            @"team::members",
            @"object",     _object,
            @"returnType", intObj(LSDBReturnType_ManyObjects), 
            nil];
  }
  else if ([_cn isEqualToString:@"LSWNewAptResourceNotification"]) {
      [self->aptResources release]; self->aptResources = nil;
      self->aptResources = [[NSArray alloc] initWithObjects:&_object count:1];
      [self->searchString release]; self->searchString = @"";
  }
  else if ([_cn isEqualToString:@"LSWDeletedAptResourceNotification"] ||
	   [_cn isEqualToString:@"LSWUpdatedAptResourceNotification"]) {
    [self search];
  }
}

/* accessors */

- (int)blockSize {
  OGoSession *sn = (id)[self session]; 
  return [[[sn userDefaults] objectForKey:@"usermanager_blocksize"] intValue];
}

- (void)setTabKey:(NSString *)_key {
  ASSIGN(self->tabKey, _key);
}
- (NSString *)tabKey {
  return self->tabKey;
}

- (void)setSearchString:(NSString *)_searchString {
  ASSIGNCOPY(self->searchString, _searchString);
}
- (NSString *)searchString {
  return self->searchString;
}

- (void)setStart:(unsigned)_startIndex {
  self->startIndex = _startIndex;
}
- (unsigned)start {
  return self->startIndex;    
}

- (void)setIsDescending:(BOOL)_isDescending {
  self->isDescending = _isDescending;
}
- (BOOL)isDescending {
  return self->isDescending;    
}

- (void)setIsLogDescending:(BOOL)_isLogDescending {
  self->isLogDescending = _isLogDescending;
}
- (BOOL)isLogDescending {
  return self->isLogDescending;    
}

- (void)setSelectedAttribute:(NSDictionary *)_selectedAttribute {
  ASSIGN(self->selectedAttribute, _selectedAttribute);
}
- (NSDictionary *)selectedAttribute {
  return self->selectedAttribute;    
}

- (void)setAccount:(id)_account {
  ASSIGN(self->account, _account);
}
- (id)account {
  return self->account;    
}

- (void)setAccounts:(NSArray *)_accounts {
  ASSIGN(self->accounts, _accounts);
}
- (NSArray *)accounts {
  return self->accounts;
}

- (void)setTeam:(id)_team {
  ASSIGN(self->team, _team);
}
- (id)team {
  return self->team;     
}

- (void)setAptResources:(NSArray *)_aptResources {
  ASSIGN(self->aptResources, _aptResources);
}
- (NSArray *)aptResources {
  return self->aptResources;
}

- (NSArray *)sessionLogs {
  return self->sessionLogs;
}

- (void)setSessionLog:(id)_sessionLog {
  ASSIGN(self->sessionLog, _sessionLog);
}
- (id)sessionLog {
  return self->sessionLog;
}

- (NSArray *)teams {
  return self->teams;
}

- (NSString *)accountLogin {
  return [[self->sessionLog valueForKey:@"account"] valueForKey:@"login"];
}

/* actions */

- (id)viewAccount {
  return [self activateObject:self->account withVerb:@"viewPreferences"];
}
- (id)viewTeam {
  return [self activateObject:self->team withVerb:@"view"];
}

- (id)newAccount {
  WOComponent *ct;
  
  ct = [[self session] instantiateComponentForCommand:@"newAccount"
                       type:eoPersonType];
  return ct;
}

- (id)newTemplate {
  WOComponent *ct;
  
  ct = [[self session] instantiateComponentForCommand:@"newAccount"
                       type:eoPersonType];
  [ct setIsTemplateUser:YES];
  return ct;
}

- (id)newTeam {
  WOComponent *ct;
  
  ct = [[self session] instantiateComponentForCommand:@"new" type:eoTeamType];
  return ct;
}

- (id)tabClicked {
  self->selectedAttribute = nil;
  self->startIndex        = 0;
  [self->searchString release]; self->searchString = @"";
  return nil;
}

- (BOOL)isLogTabEnabled {
  return YES;
}

- (BOOL)canCreateAccounts {
  if ([LSCommandContext useLDAPAuthorization]) return NO;
  return [[self session] activeAccountIsRoot];
}

- (WOComponent *)_searchAccounts {
  NSArray  *result = nil;
  NSString *s;

  s = self->searchString;
  if ([s isEqualToString:@"*"]) s = @"%";
  
  result = [self runCommand:
                 @"account::extended-search",
                 @"operator",       @"OR",
                 @"name",           s,
                 @"firstname",      s,
                 @"description",    s,
                 @"login",          s,
                 @"maxSearchCount", num1000,
                 nil];

  ASSIGN(self->accounts, result);

  if ([self->accounts count] == 1) {
    [self setAccount:[self->accounts objectAtIndex:0]];
    return [self viewAccount];
  }
  return nil;
}

- (WOComponent *)_searchTeams {
  NSArray *result = nil;
  NSString *s;

  s = self->searchString;
  if ([s isEqualToString:@"*"]) s = @"%";

  result = [self runCommand:
                 @"team::extended-search",
                 @"operator",       @"OR",
                 @"description",    s,
                 @"maxSearchCount", num1000,
                 nil];
  
  ASSIGN(self->teams, result);

  [self runCommand:@"team::members",
          @"teams",      self->teams,
          @"returnType", intObj(LSDBReturnType_ManyObjects), nil];

  if ([self->teams count] == 1) {
    [self setTeam:[self->teams objectAtIndex:0]];
    return [self viewTeam];
  }
  return nil;
}

- (WOComponent *)_searchAptResources {
  NSArray *result = nil;
  NSString *s;

  s = self->searchString;
  if ([s isEqualToString:@"*"]) s = @"%";

  result = [self runCommand:
		   @"appointmentresource::extended-search",
                   @"fetchGlobalIDs", Yes,
                   @"operator",       @"OR",
                   @"name",           s,
                   @"maxSearchCount", num1000,
                 nil];
  result = [self runCommand:@"appointmentresource::get-by-globalid",
                   @"gids", result,
                   @"attributes", aptResourceAttrNames,
                 nil];
  
  ASSIGN(self->aptResources, result);

  return nil;
}

- (WOComponent *)_searchSessionLogs {
  NSArray *result = nil;

  if ([self->searchString isEqualToString:@"*"] ||
      [self->searchString isEqualToString:@"%"]) {
    result = [self runCommand:@"sessionlog::query", nil];
  }
  else {
    NSArray  *accountGids;
    NSString *s;

    s = self->searchString;
    
    accountGids = [self runCommand:
			  @"account::extended-search",
			  @"operator",       @"OR",
			  @"fetchGlobalIDs", Yes,
			  @"name",           s,
			  @"firstname",      s,
			  @"description",    s,
			  @"login",          s,
			  @"maxSearchCount", num1000,
                   nil];
    result = [self runCommand:@"sessionlog::query",
                   @"accounts", accountGids, nil];
  }
  result = [self runCommand:@"sessionlog::get-by-globalid",
                   @"gids", result,
                   @"attributes", snLogAttrNames,
                   nil];

  ASSIGN(self->sessionLogs, result);
  
  return nil;
}

- (WOComponent *)search {
  // TODO: make this "object oriented" ..., no case ...
  self->startIndex = 0;

  if ([self->tabKey isEqualToString:@"teams"])
    return [self _searchTeams];
  
  if ([self->tabKey isEqualToString:@"accounts"])
    return [self _searchAccounts];
  
  if ([self->tabKey isEqualToString:@"resourcestab"])
    return [self _searchAptResources];
  
  if ([self->tabKey isEqualToString:@"sessionlogs"])
    return [self _searchSessionLogs];
  
  return nil;
}
- (WOComponent *)searchAll {
  [self setSearchString:@"*"];
  return [self search];
}

- (BOOL)isMailConfigEnabled {
  return IsMailConfigEnabled;
}

/* Shutdown */

- (id)onShutdown {
  id page;
  BOOL logLogout;
  
  // TODO: isn't that a global default?
  logLogout = [[[[self session] userDefaults]
                       objectForKey:@"LSSessionAccountLogEnabled"] boolValue];
  if (logLogout) {
    id acc = [[self session] activeAccount];
    [[self session] runCommand:@"sessionlog::add",
                    @"account", acc,
                    @"action",  @"shutdown", nil];
  }
  [[self session] terminate];
  page = [[self application] pageWithName:@"OGoLogoutPage"];
  [[WOApplication application] terminate];

  return page;
}

@end /* LSWStaff */
