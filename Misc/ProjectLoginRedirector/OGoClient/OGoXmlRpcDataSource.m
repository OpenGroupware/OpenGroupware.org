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

#include "OGoXmlRpcDataSource.h"
#include "OGoClientConnection.h"
#include "common.h"

@implementation OGoXmlRpcDataSource

- (id)initWithClientConnection:(OGoClientConnection *)_con {
  if ((self = [super init])) {
    self->connection = [_con retain];
  }
  return self;
}

- (void)dealloc {
  [self->lastException release];
  [self->fspec         release];
  [self->connection    release];
  [super dealloc];
}

/* accessors */

- (OGoClientConnection *)connection {
  return self->connection;
}
- (NGXmlRpcClient *)client {
  return [[self connection] client];
}

- (NSException *)lastException {
  return self->lastException;
}
- (void)resetLastException {
  [self->lastException release];
  self->lastException = nil;
}

- (void)setFetchSpecification:(EOFetchSpecification *)_fspec {
  if ([self->fspec isEqual:_fspec])
    return;
  
  [self->fspec autorelease];
  self->fspec = [_fspec copy];
  
  [self postDataSourceChangedNotification];
}
- (EOFetchSpecification *)fetchSpecification {
  return self->fspec;
}

/* fetching */

- (NSString *)xmlRpcFetchMethodName {
  [self logWithFormat:
          @"subclass must override: %@", NSStringFromSelector(_cmd)];
  return nil;
}
- (BOOL)doesHandleFetchSpecificationOnServer {
  return YES;
}

- (NSArray *)fetchObjects {
  NSAutoreleasePool *pool;
  NSString *m;
  NSArray  *result;
  
  [self resetLastException];
  
  if ((m = [self xmlRpcFetchMethodName]) == nil)
    return nil;

  pool = [[NSAutoreleasePool alloc] init];
  
  if ([self doesHandleFetchSpecificationOnServer]) {
    result = [[self client] invoke:m params:[self fetchSpecification], nil];
  }
  else {
    /* fetch using method, then sort on the client */
    EOQualifier *q;
    NSArray     *sort;
    
    q    = [self->fspec qualifier];
    sort = [self->fspec sortOrderings];
    
    result = [[self client] invokeMethodNamed:m];
    
    if (q == nil) {
      if (sort)
        result = [result sortedArrayUsingKeyOrderArray:sort];
      else
        result = [[result copy] autorelease];
    }
    else {
      result = [result filteredArrayUsingQualifier:q];
      if (sort) result = [result sortedArrayUsingKeyOrderArray:sort];
    }
  }
  
  result = [result copy];
  [pool release];
  return [result autorelease];
}

@end /* OGoXmlRpcDataSource */
