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

#include "Application.h"
#include "common.h"

@interface WOApplication(skyxmlrpcd)
- (id)_initializeSessionInContext:(id)_ctx;
@end

@implementation Application

- (id)init {
  if ((self = [super init])) {
    id handler = nil;
    
    handler= [[NSClassFromString(@"WODirectActionRequestHandler") alloc] init];
    
    [self setDefaultRequestHandler:handler];
    self->cred2sessionId = [[NSMutableDictionary alloc] initWithCapacity:8];
    [handler release];
  }
  return self;
}

- (void)dealloc {
  [self->cred2sessionId release];
  [self->credentials    release];
  [super dealloc];
}

/* accessors */

- (void)setCredentials:(NSString *)_credentials {
  ASSIGNCOPY(self->credentials, _credentials);
}
- (NSString *)credentials {
  return self->credentials;
}

/* sessions as cache objects */

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
    if (session == nil) {
      session = [super _initializeSessionInContext:_ctx];
      [self->cred2sessionId setObject:[session sessionID] forKey:cred];
    }
  }
  return session;
}

/* ensure simple parser */

- (BOOL)shouldUseSimpleHTTPParserForTransaction:(id)_tx {
  /* 
     Always use the simple parser for ZideStore, ignore
     WOHttpTransactionUseSimpleParser default.
  */
  return YES;
}

@end /* Application */

