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

#include "OGoClientConnection.h"
#include "OGoXmlRpcDataSource.h"
#include "common.h"

@implementation OGoClientConnection

- (id)initWithXmlRpcClient:(NGXmlRpcClient *)_client url:(NSURL *)_url {
  if ((self = [super init])) {
    id tmp;
    
    self->client = [_client retain];
    self->url    = [_url    copy];

    tmp = [_client invokeMethodNamed:@"system.listMethods"];
    if ([tmp isKindOfClass:[NSException class]]) {
      [self logWithFormat:@"WARNING: failed to get available methods: %@",
              tmp];
      [self release];
    }
    
    self->methods = [tmp copy];
  }
  return self;
}
- (void)dealloc {
  [self->methods release];
  [self->url     release];
  [self->client  release];
  [super dealloc];
}

/* accessors */

- (NGXmlRpcClient *)client {
  return self->client;
}
- (NSURL *)url {
  return self->url;
}

- (NSArray *)availableXmlRpcMethods {
  return self->methods;
}

/* datasource classes */

- (Class)projectDataSourceClass {
  return NSClassFromString(@"OGoClientProjectDataSource");
}

/* datasources */

- (EODataSource *)projectDataSource {
  Class clazz;
  
  clazz = [self projectDataSourceClass];
  return [[[clazz alloc] initWithClientConnection:self] autorelease];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return YES;
}

- (NSString *)description {
  NSMutableString *ms;

  ms = [NSMutableString stringWithCapacity:128];
  [ms appendFormat:@"<0x%08X[%@]:", self, NSStringFromClass([self class])];
  
  if (self->client) {
    [ms appendFormat:@" login=%@", [self->client userName]];
    [ms appendFormat:@" uri=%@",   [self->client uri]];
  }
  
  [ms appendString:@">"];
  return ms;
}

@end /* OGoClientConnection */
