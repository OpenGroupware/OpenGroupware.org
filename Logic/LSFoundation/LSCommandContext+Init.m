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

#include <LSFoundation/LSCommandContext.h>
#include <LSFoundation/OGoContextManager.h>
#include "LSDBTransaction.h"
#include "common.h"

@interface LSCommandContext(InitPrivates)
- (id)_init;
@end

@implementation LSCommandContext(Init)

- (id)initWithManager:(OGoContextManager *)_lso {
  if (_lso == nil) {
    NSLog(@"ERROR(%s): missing OGoContextManager object !",
          __PRETTY_FUNCTION__);
    [self release];
    return nil;
  }
  
  if ((self = [self _init])) {
    EODatabase        *db;
    EODatabaseContext *dbContext;
    EODatabaseChannel *dbChannel;
    LSDBTransaction   *tx;
    
    /* init command factory */
    
    [self takeValue:[_lso commandFactory]
          forKey:LSCommandFactoryKey];

    /* setup GDL stuff */

    db = [[[EODatabase alloc] initWithAdaptor:[_lso adaptor]] autorelease];
    dbContext = [db        createContext];
    dbChannel = [dbContext createChannel];
    
    if (db == nil) {
      [self logWithFormat:@"could not create database object !"];
      [self release];
      return nil;
    }
    if (dbContext == nil) {
      [self logWithFormat:@"could not create database context for db %@!", db];
      [self release];
      return nil;
    }
    if (dbChannel == nil) {
      [self logWithFormat:@"could not create database channel for ctx %@ !",
              dbContext];
      [self release];
      return nil;
    }

    [self takeValue:db        forKey:LSDatabaseKey];
    [self takeValue:dbContext forKey:LSDatabaseContextKey];
    [self takeValue:dbChannel forKey:LSDatabaseChannelKey];

    /* setup LSOffice transaction object */

    tx = [[LSDBTransaction alloc]
                           initWithDatabaseContext:dbContext
                           andDatabaseChannel:dbChannel];
    tx = [tx autorelease];

    if (tx == nil) {
      [self logWithFormat:@"could not create LSOffice transaction object !"];
      [self release];
      return nil;
    }
    
    [self takeValue:tx forKey:LSDBTransactionKey];
    
#if 0
    /* setup notifications */
    [nc addObserver:self
        selector:@selector(handleContextNotification:)
        name:nil
        object:self->dbContext];
    [nc addObserver:self
        selector:@selector(handleChannelNotification:)
        name:nil
        object:self->dbChannel];
#endif
  }
  return self;
}

@end /* LSCommandContext(Init) */
