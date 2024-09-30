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

#include "OGoClientManager.h"
#include "OGoClientConnection.h"
#include "common.h"

@implementation OGoClientManager

+ (id)clientManagerForURL:(id)_url {
  return [[[self alloc] initWithURL:_url] autorelease];
}

- (id)initWithNSURL:(NSURL *)_url {
  if ((self = [super init])) {
    self->url = [_url copy];
  }
  return self;
}
- (id)initWithURL:(id)_url {
  if (![_url isKindOfClass:[NSURL class]])
    _url = [NSURL URLWithString:[_url stringValue]];
  
  return [self initWithNSURL:_url];
}

- (void)dealloc {
  [self->url release];
  [super dealloc];
}

/* accessors */

- (NSURL *)url {
  return self->url;
}

/* credentials */

- (BOOL)_checkLogin:(NSString *)_login  password:(NSString *)_pwd {
  if ([_login length] == 0)
    return NO;
  
  if ([_pwd length] == 0) {
    [self logWithFormat:
            @"Note: rejected login of user '%@', no password specified!",
            _login];
    return NO;
  }
  return YES;
}

- (BOOL)isLoginAuthorized:(NSString *)_login password:(NSString *)_pwd {
  NGXmlRpcClient *authClient;
  id result;
  
  if (![self _checkLogin:_login password:_pwd])
    return NO;
  
  [self debugWithFormat:@"check login: '%@'", _login];
  
  authClient = [[[NGXmlRpcClient alloc] initWithURL:[self url]] autorelease];
  [authClient setUserName:_login];
  [authClient setPassword:_pwd];
  
  result = [authClient invokeMethodNamed:@"system.getServerTime"];
  
  if (![result isKindOfClass:[NSException class]]) {
    [self debugWithFormat:@"  login OK, server time: %@", result];
    return YES;
  }
  
  if ([[result name] isEqualToString:@"NGCouldNotConnectException"]) {
    [self logWithFormat:@"WARNING: server is down: %@", 
            [[self url] absoluteString]];
    return NO;
  }

  if ([[result name] isEqualToString:@"XmlRpcCallFailed"]) {
    int status;
    
    status = [[[result userInfo] objectForKey:@"HTTPStatusCode"] intValue];
    if (status == 401) {
      [self debugWithFormat:@"Note: invalid login: '%@'", _login];
      return NO;
    }

    [self logWithFormat:@"unexpected fail-exception: %@", result];
    return NO;
  }
  
  [self logWithFormat:@"unexpected exception: %@", result];
  return NO;
}

/* connection */

- (OGoClientConnection *)login:(NSString *)_login password:(NSString *)_pwd {
  NGXmlRpcClient      *client;
  OGoClientConnection *connection;
  
  if (![self _checkLogin:_login password:_pwd])
    return nil;
  
  client = [[[NGXmlRpcClient alloc] initWithURL:[self url]] autorelease];
  [client setUserName:_login];
  [client setPassword:_pwd];

  // TODO: pre-authenticate
  
  connection = 
    [[OGoClientConnection alloc] initWithXmlRpcClient:client url:[self url]];
  
  return [connection autorelease];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return YES;
}

- (NSString *)description {
  NSMutableString *ms;

  ms = [NSMutableString stringWithCapacity:128];
  [ms appendFormat:@"<%p[%@]:", self, NSStringFromClass([self class])];

  if (self->url) [ms appendFormat:@" url=%@", [self->url absoluteString]];

  [ms appendString:@">"];
  return ms;
}

@end /* OGoClientManager */
