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

#ifndef __LSFoundation_OGoContextSession_H__
#define __LSFoundation_OGoContextSession_H__

#include <stdlib.h>
#import <Foundation/NSObject.h>
#include <LSFoundation/LSCommandFactory.h>

@class NSString, NSDate, NSTimer, NSDictionary;
@class EODatabase, EODatabaseContext, EODatabaseChannel;
@class OGoContextManager, LSCommandContext;

/*
  Use command-context instead of this object !!
*/

@interface OGoContextSession : NSObject
{
@private
  OGoContextManager *lso;
  NSString          *login;
  EODatabase        *db;
  EODatabaseContext *dbContext;
  EODatabaseChannel *dbChannel;
  LSCommandContext  *cmdContext;
  id                loginAccount;
}

/* activation */

- (void)activate;
- (void)deactivate;
+ (OGoContextSession *)activeSession;

/* transactions: USE commandContext for tx handling ! */

/* running commands */

- (id)runCommand:(NSString *)_command,...;

/* debugging */

- (void)enableAdaptorDebugging;
- (void)disableAdaptorDebugging;

- (NSString *)activeLoginName; /* used in LSWSession */

@end

@interface OGoContextSession(PrivateMethods)

- (id)initWithCommandContext:(LSCommandContext *)_cmdCtx 
  manager:(OGoContextManager *)_lso;
- (id)initWithManager:(OGoContextManager *)_lso;

/* LSO */

- (LSCommandContext *)commandContext;
- (id<NSObject,LSCommandFactory>)commandFactory;

/* EOF */

- (EODatabase *)database;
- (EODatabaseContext *)databaseContext;
- (EODatabaseChannel *)databaseChannel;

@end

#endif /* __LSFoundation_OGoContextSession_H__ */
