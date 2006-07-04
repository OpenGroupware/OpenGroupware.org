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

#include "OGoContextSession.h"
#include "OGoContextManager.h"
#include "common.h"
#include <LSFoundation/LSCommandContext.h>
#include <LSFoundation/LSFoundation.h>

@interface OGoContextSession(CommandLookup)
- (id<LSCommand>)lookupCommand:(NSString *)_command inDomain:(NSString *)_do;
- (id<LSCommand>)lookupCommand:(NSString *)_command;
@end

@interface OGoContextSession(LoginPrivates)
- (BOOL)login:(NSString *)_login password:(NSString *)_password
  crypted:(BOOL)_crypted isSessionLogEnabled:(BOOL)_isSessionLogEnabled;
- (BOOL)logout;
@end

@interface LSCommandContext(LoginPrivates)
- (BOOL)logout;
@end

@implementation OGoContextSession

+ (int)version {
  return 1;
}

- (id)initWithCommandContext:(LSCommandContext *)_cmdCtx 
  manager:(OGoContextManager *)_lso 
{
  if (_lso == nil) {
    [self errorWithFormat:@"%s: missing OGo context manager!", 
            __PRETTY_FUNCTION__];
    [self release];
    return nil;
  }
  if (_cmdCtx == nil) {
    [self errorWithFormat:@"%s: missing OGo command context!", 
            __PRETTY_FUNCTION__];
    [self release];
    return nil;
  }
  
  if ((self = [super init])) {
    self->lso        = [_lso    retain];
    self->cmdContext = [_cmdCtx retain];
    
    self->db = [[self->cmdContext valueForKey:LSDatabaseKey] retain];
    self->dbContext =
      [[self->cmdContext valueForKey:LSDatabaseContextKey] retain];
    self->dbChannel =
      [[self->cmdContext valueForKey:LSDatabaseChannelKey] retain];
  }
  return self;
}

- (id)initWithManager:(OGoContextManager *)_lso {
  LSCommandContext *cctx;
  
  if (_lso == nil) {
    [self errorWithFormat:@"%s: missing OGo context manager!", 
            __PRETTY_FUNCTION__];
    [self release];
    return nil;
  }
  
  if ((cctx = [[LSCommandContext alloc] initWithManager:_lso]) == nil) {
    [self logWithFormat:@"could not setup command context .."];
    [self release];
    return nil;
  }
  return [self initWithCommandContext:cctx manager:_lso];
}

- (id)init {
  return [self initWithManager:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [self->dbChannel  release];
  [self->dbContext  release];
  [self->db         release];
  [self->cmdContext release];
  [self->lso        release];
  [self->login      release];
  [super dealloc];
}

/* activation */

// MT, THREAD
static OGoContextSession *activeSession = nil;

- (void)activate {
  if (activeSession != self)
    [activeSession deactivate];
  
  ASSIGN(activeSession, self);
  
  //[self debugWithFormat:@"session was activated."];
}

- (void)deactivate {
  if (activeSession == self) {
    //[self debugWithFormat:@"session was deactivated."];    
    [activeSession release];
    activeSession = nil;
  }
  else {
    [self warnWithFormat:@"tried to deactivate inactive session !"];
    [self warnWithFormat:@"activeSession: %@, self: %@", activeSession, self];
    [activeSession release];
    activeSession = nil;
    //abort();
  }
}

+ (OGoContextSession *)activeSession {
  return activeSession;
}

/* accessors */

- (LSCommandContext *)commandContext {
  return self->cmdContext;
}

- (EODatabase *)database {
  return self->db;
}
- (EODatabaseContext *)databaseContext {
  return self->dbContext;
}
- (EODatabaseChannel *)databaseChannel {
  return self->dbChannel;
}

/* command lookup */

- (id<NSObject,LSCommandFactory>)commandFactory {
  return [self->cmdContext commandFactory];
}
- (id<LSCommand>)lookupCommand:(NSString *)_command inDomain:(NSString *)_do {
  return LSCommandLookup([self commandFactory], _do, _command);
}

- (id<LSCommand>)lookupCommand:(NSString *)_command
  inDomain:(NSString *)_domain
  args:(NSString *)_arg1,...
{
  va_list       va;
  id<LSCommand> command;

  va_start(va, _arg1);
  command = [self->cmdContext lookupCommand:_command inDomain:_domain
                              arg0:_arg1 vargs:&va];
  va_end(va);
  return command;
}

/* running commands */

- (id)runCommand:(NSString *)_command
  fromDomain:(NSString *)_domain
  args:(NSString *)_arg1,...
{
  id result;
  va_list va;
  
  va_start(va, _arg1);
  result = [self->cmdContext runCommand:_command inDomain:_domain
                             arg0:_arg1 vargs:&va];
  va_end(va);
  return result;
}

- (id)runCommand:(NSString *)_command,... {
  id      result;
  va_list va;

  va_start(va, _command);
  result = [self->cmdContext runCommand:_command vargs:&va];
  va_end(va);
  
  return result;
}

- (id)runCommand:(NSString *)_command vargs:(va_list *)_va {
  return [self->cmdContext runCommand:_command vargs:_va];
}
- (id)runCommand:(NSString *)_command arguments:(NSDictionary *)_args {
  return [self->cmdContext runCommand:_command arguments:_args];
}

/* transactions */

- (BOOL)isTransactionInProgress {
  return [self->cmdContext isTransactionInProgress];
}
- (BOOL)rollback {
  return [self->cmdContext rollback];
}
- (BOOL)commit {
  return [self->cmdContext commit];
}

/* login/logout */

- (NSString *)activeLoginName {
  return self->login;
}

- (BOOL)login:(NSString *)_login password:(NSString *)_pwd {
  return [self login:_login password:_pwd crypted:NO isSessionLogEnabled:YES];
}

- (BOOL)login:(NSString *)_login password:(NSString *)_pwd
  isSessionLogEnabled:(BOOL)_isSessionLogEnabled
{
  return [self login:_login password:_pwd crypted:NO
               isSessionLogEnabled:_isSessionLogEnabled];
}

- (BOOL)login:(NSString *)_login password:(NSString *)_pwd
  crypted:(BOOL)_crypted
{
  return [self login:_login password:_pwd crypted:_crypted
               isSessionLogEnabled:YES];
}

- (BOOL)login:(NSString *)_login password:(NSString *)_pwd
  crypted:(BOOL)_crypted isSessionLogEnabled:(BOOL)_isSessionLogEnabled
{
  NSUserDefaults *ud;
  
  if (self->login) {
    if (![self logout]) {
      [self logWithFormat:@"couldn't logout."];
      return NO;
    }
  }

  ud = [NSUserDefaults standardUserDefaults];
  
  // HACK to make OGo password available to IMAP4 client
  if ([ud boolForKey:@"UseSkyrixLoginForImap"])
    [self->cmdContext takeValue:_pwd forKey:@"LSUser_P_W_D_Key"];
  
  NSAssert(self->login        == nil, @"login is still set");
  NSAssert(self->loginAccount == nil, @"login account is still set");
  
  if ([ud boolForKey:@"LSUseLowercaseLogin"])
    _login = [_login lowercaseString];
  
  if ([_login length] < 1) {
    [self logWithFormat:@"login name is not valid (contains no chars)!"];
    return NO;
  }

#if 0
  if (![_pwd isNotEmpty])
    [self warnWithFormat:@"missing password!"];
#endif  
  
  self->loginAccount = [self runCommand:@"account::login",
                               @"login",    _login,
                               @"password", _pwd,
                               @"crypted",  [NSNumber numberWithBool:_crypted],
                               @"isSessionLogEnabled",
                               [NSNumber numberWithBool:_isSessionLogEnabled],
                               nil];
  self->loginAccount = [self->loginAccount retain];
  
  if ([self commit]) {
    self->login = [_login copy];
    
    [self debugWithFormat:@"account '%@' is logged in.", _login];
    return (self->loginAccount != nil) ? YES : NO;
  }

  [self->login        release]; self->login        = nil;
  [self->loginAccount release]; self->loginAccount = nil;
  return NO;
}

- (BOOL)logout {
  NSString *tmp;
  
  if ([self->cmdContext isTransactionInProgress]) {
    if (![self commit])
      return NO;
  }
  tmp = [[self->login retain] autorelease];
  
  [self->login        release]; self->login        = nil;
  [self->loginAccount release]; self->loginAccount = nil;
  
  return [self->cmdContext logout];
}

/* logging */

- (void)logWithFormat:(NSString *)_format, ... {
  NSString *value = nil;
  va_list  ap;

  va_start(ap, _format);
  value = [[NSString alloc] initWithFormat:_format arguments:ap];
  va_end(ap);

  NSLog(@"OGo[%@]: %@",
        self->login ? self->login : @"no login",
        value);
  [value release];
}
- (void)debugWithFormat:(NSString *)_format, ... {
  static char showDebug = 2;
  NSString *value = nil;
  va_list  ap;

  if (showDebug == 2) {
    showDebug = [[[NSUserDefaults standardUserDefaults]
                                  objectForKey:@"LSDebuggingEnabled"]
                                  boolValue] ? 1 : 0;
  }

  if (!showDebug) return;
  
  va_start(ap, _format);
  value = [[NSString alloc] initWithFormat:_format arguments:ap];
  va_end(ap);
  
  NSLog(@"OGo[%@]D: %@", self->login ? self->login : @"no login", value);
  [value release];
}

/* debugging */

- (void)enableAdaptorDebugging {
  [[[self databaseChannel] adaptorChannel] setDebugEnabled:YES];
}
- (void)disableAdaptorDebugging {
  [[[self databaseChannel] adaptorChannel] setDebugEnabled:NO];
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@[0x%p]: login=%@ tx=%s>",
                     NSStringFromClass([self class]), self,
                     self->login ? self->login : @"<no login>",
                     [self->cmdContext isTransactionInProgress] ? "yes" : "no"];
}

@end /* OGoContextSession */
