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
// $Id$

#include "Application.h"
#include "common.h"

@interface WOApplication(skyxmlrpcd)
- (id)_initializeSessionInContext:(id)_ctx;
@end

@implementation Application

+ (void)initialize {
  static BOOL isInitialized = NO;

  if (! isInitialized) {
    NSMutableDictionary *defaults = nil;
    NSMutableDictionary *account  = nil;
    NSMutableDictionary *accounts = nil;

    isInitialized = YES;

    defaults = [NSMutableDictionary dictionaryWithCapacity:0];
    accounts = [NSMutableDictionary dictionaryWithCapacity:0];

    account  = [NSMutableDictionary dictionaryWithCapacity:8];

    [account setObject:@"$HTTP_USER$"          forKey:@"username"];
    [account setObject:@"$HTTP_PWD$"           forKey:@"password"];
    [account setObject:@"smart.in.skyrix.com"  forKey:@"receive_server"];
    [account setObject:@"143"                  forKey:@"receive_port"];
    [account setObject:@"imap4"                forKey:@"receive_protocol"];
    [account setObject:@"smart.in.skyrix.com"  forKey:@"send_server"];
    [account setObject:@"25"                   forKey:@"send_port"];
    [account setObject:@"smtp"                 forKey:@"send_protocol"];

    [accounts setObject:account forKey:@"smart.in.skyrix.com"];

    account  = [NSMutableDictionary dictionaryWithCapacity:8];

    [account setObject:@"$HTTP_USER$"          forKey:@"username"];
    [account setObject:@"$HTTP_PWD$"           forKey:@"password"];
    [account setObject:@"skyrix.in.skyrix.com" forKey:@"receive_server"];
    [account setObject:@"143"                  forKey:@"receive_port"];
    [account setObject:@"imap4"                forKey:@"receive_protocol"];
    [account setObject:@"skyrix.in.skyrix.com" forKey:@"send_server"];
    [account setObject:@"25"                   forKey:@"send_port"];
    [account setObject:@"smtp"                 forKey:@"send_protocol"];

    [accounts setObject:account forKey:@"skyrix.in.skyrix.com"];

    [defaults setObject:accounts forKey:@"skymaild.accounts"];

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
  }
}

- (id)init {
  if ((self = [super init])) {
    id handler = nil;

    handler = [[NSClassFromString(@"WODirectActionRequestHandler")alloc] init];

    [self setDefaultRequestHandler:handler];
    self->cred2sessionId = [[NSMutableDictionary alloc] initWithCapacity:8];

    RELEASE(handler);
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->cred2sessionId);
  RELEASE(self->credentials);

  [super dealloc];
}
#endif

- (NSString *)credentials {
  return self->credentials;
}
- (void)setCredentials:(NSString *)_credentials {
  ASSIGNCOPY(self->credentials, _credentials);
}

- (id)_initializeSessionInContext:(WOContext *)_ctx {
  id        cred       = nil;
  NSString  *sessionId = nil;
  WOSession *session   = nil;

  cred = [self credentials];
  NSAssert1((cred != nil), @"%s: credentials is nil!", __PRETTY_FUNCTION__);

  sessionId = [self->cred2sessionId objectForKey:cred];

  if (sessionId == nil) {
    session = [super _initializeSessionInContext:_ctx];
    [self->cred2sessionId setObject:[session sessionID] forKey:cred];
  }
  else {
    session = [self restoreSessionWithID:sessionId inContext:_ctx];
  }
  
  return session;
}

@end /* Application */
