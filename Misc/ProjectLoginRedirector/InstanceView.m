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

#include <NGObjWeb/WOComponent.h>

@class OGoClientConnection;

@interface InstanceView : WOComponent
{
  OGoClientConnection *connection;
  id columnGroup;
  id project;
}

@end

#include "PLRConnectionSet.h"
#include "NSArray+ColGroups.h"
#include <OGoClient/OGoClientConnection.h>
#include "common.h"

@implementation InstanceView

- (void)dealloc {
  [self->columnGroup release];
  [self->project     release];
  [self->connection  release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self->connection  release]; self->connection  = nil;
  [self->columnGroup release]; self->columnGroup = nil;
  [self->project     release]; self->project     = nil;
  [super sleep];
}

/* accessors */

- (void)setConnection:(OGoClientConnection *)_connection {
  ASSIGN(self->connection, _connection);
}
- (OGoClientConnection *)connection {
  return self->connection;
}

- (void)setColumnGroup:(id)_value {
  ASSIGN(self->columnGroup, _value);
}
- (id)columnGroup {
  return self->columnGroup;
}

- (void)setProject:(id)_value {
  ASSIGN(self->project, _value);
}
- (id)project {
  return self->project;
}

- (NSURL *)rpcURL {
  return [[self connection] url];
}

- (NSString *)connectionWebAppURI {
  return [[PLRConnectionSet sharedConnectionSet] uriForRpcURL:[self rpcURL]];
}

/* operations */

- (unsigned)projectFetchLimit {
  return 20;
}

- (EOFetchSpecification *)projectFetchSpecification {
  EOFetchSpecification *fs;
  EOQualifier *q;
  NSArray     *sortOrderings;

  // HACK (XML-RPC encoding/decoding of qualifiers is broken!
#if 1
  q = (id)@"type='common'";
#else
  q  = [EOQualifier qualifierWithQualifierFormat:
                      @"type!=%@", @"archived"];
#endif
  
  sortOrderings = [NSArray arrayWithObjects:
                             [EOSortOrdering sortOrderingWithKey:@"name"
                                             selector:EOCompareAscending],
                           nil];
  
  fs = [[[EOFetchSpecification alloc] init] autorelease];
  [fs setQualifier:q];
  [fs setSortOrderings:sortOrderings];
  [fs setFetchLimit:[self projectFetchLimit]];
  return fs;
}

- (EODataSource *)projectDataSource {
  EODataSource *ds;
  
  ds = [[self connection] projectDataSource];
  [ds setFetchSpecification:[self projectFetchSpecification]];
  return ds;
}

- (NSArray *)fetchObjects {
  return [[self projectDataSource] fetchObjects];
}

- (int)numberOfColumns {
  return 2;
}
- (NSString *)columnPercentage {
  return [NSString stringWithFormat:@"%i%%", (100 / [self numberOfColumns])];
}
- (NSArray *)columnGroupedProjects {
  return [[self fetchObjects] 
           arrayByGroupingIntoColumns:[self numberOfColumns]];
}

@end /* InstanceView */
