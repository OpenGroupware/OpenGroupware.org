/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include "PLRConnectionSet.h"
#include "common.h"
#include <OGoClient/OGoClientConnection.h>
#include <OGoClient/OGoClientManager.h>

@implementation PLRConnectionSet

+ (id)sharedConnectionSet {
  static PLRConnectionSet *sharedSet = nil;

  if (sharedSet) return sharedSet;
  sharedSet = [[self alloc] init];
  return sharedSet;
}

- (id)initWithClientMap:(NSDictionary *)_map {
  if ((self = [super init])) {
    NSMutableDictionary *md;
    NSEnumerator *e;
    NSString     *rpcURL;
    
    self->clientMap = [_map copy];
    
    md = [[NSMutableDictionary alloc] init];
    e = [self->clientMap keyEnumerator];
    while ((rpcURL = [e nextObject])) {
      OGoClientManager *rpc;
      NSURL *url;
      
      if ((url = [NSURL URLWithString:[rpcURL stringValue]]) == nil) {
        [self logWithFormat:@"WARNING: could not parse URL: '%@'", rpcURL];
        continue;
      }
      
      rpc = [[OGoClientManager alloc] initWithURL:url];
      [self debugWithFormat:@"RPC: %@ => %@", rpcURL, rpc];
      
      [md setObject:rpc forKey:url];
      [rpc release];
    }
    self->rpcMap = [md copy];
    [md release];
  }
  return self;
}
- (id)init {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  return [self initWithClientMap:[ud dictionaryForKey:@"PLRClientMap"]];
}

- (void)dealloc {
  [self->rpcMap    release];
  [self->clientMap release];
  [super dealloc];
}

/* instances ... */

- (NSString *)uriForRpcURL:(NSURL *)_url {
  NSString *uri, *absu;
  
  absu = [_url absoluteString];
  if ((uri = [self->clientMap objectForKey:absu]))
    return uri;
  
  [self debugWithFormat:@"got no client URI for URL: %@ ('%@')", _url, absu];
  return nil;
}

/* operations */

- (NSArray *)connectionsForLogin:(NSString *)_login password:(NSString *)_pwd {
  NSEnumerator     *e;
  OGoClientManager *rpc;
  NSMutableArray   *ma = nil;
  
  if ([_login length] == 0)
    return nil;
  if ([_pwd length] == 0) {
    [self debugWithFormat:
            @"Note: rejecting login of user '%@', missing password", _login];
    return nil;
  }
  
  [self debugWithFormat:@"check login: '%@'", _login];
  
  e = [self->rpcMap objectEnumerator];
  while ((rpc = [e nextObject])) {
    OGoClientConnection *connection;
    
    [self debugWithFormat:@"  check server: %@", rpc];
    
    if (![rpc isLoginAuthorized:_login password:_pwd]) {
      [self debugWithFormat:@"    not authorized on server: %@", rpc];
      continue;
    }
    
    [self debugWithFormat:@"  login OK!"];
    
    if ((connection = [rpc login:_login password:_pwd]) == nil) {
      [self debugWithFormat:@"    could not login on server: %@", rpc];
      continue;
    }
    
    [self debugWithFormat:@"  connection: %@", connection];
    if (ma == nil) ma = [NSMutableArray arrayWithCapacity:4];
    [ma addObject:connection];
  }
  
  return ma;
}

@end /* PLRConnectionSet */
