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

#ifndef __LSLogic_LSFoundation_LSCommandContext_H__
#define __LSLogic_LSFoundation_LSCommandContext_H__

#import  <Foundation/NSObject.h>
#import  <Foundation/NSDate.h>
#include <LSFoundation/LSCommandFactory.h>
#include <LSFoundation/LSCommand.h>
#include <LSFoundation/LSTypeManager.h>

@class NSMutableDictionary, NSDate, NSTimer, NSUserDefaults, SkyAccessManager;

@interface LSCommandContext : NSObject
{
@private
  BOOL                          wasLastCommandOk;
  id<NSObject,LSCommandFactory> commandFactory;
  NSMutableDictionary           *extraVariables;
  id<LSTypeManager,NSObject>    typeManager;
  id                            objectPropertyManager;
  id                            linkManager;
  
  SkyAccessManager              *accessManager;
  /* statistics */
  NSDate            *channelOpenTime;
  NSDate            *txStartTime;
  NSDate            *lastAccess;
  NSTimer           *channelCloseTimer;
  NSTimeInterval    channelTimeOut;
  int               cmdNestingLevel;

  /* profiling */
  NSMutableDictionary *profileCmdDict;
}

+ (id)context;

/* accessors */

- (BOOL)wasLastCommandOk;
- (void)setCommandFactory:(id<NSObject,LSCommandFactory>)_factory;
- (id<NSObject,LSCommandFactory>)commandFactory;

- (id<LSTypeManager>)typeManager;
- (id)propertyManager;
- (id)linkManager;
- (NSUserDefaults *)userDefaults;
- (SkyAccessManager *)accessManager;

/* flushing caches */

- (void)flush;

/* key-value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key;
- (id)valueForKey:(NSString *)_key;

@end

@interface LSCommandContext(Logging)

- (void)logWithFormat:(NSString *)_format, ...;
- (void)debugWithFormat:(NSString *)_format, ...;

@end /* LSCommandContext(Logging) */

@interface LSCommandContext(LookupCommands)

/* you shouldn't use this stuff in GUI ! */

- (id<NSObject,LSCommandFactory>)commandFactory;

- (id<LSCommand>)lookupCommand:(NSString *)_comm inDomain:(NSString *)_domain;
- (id<LSCommand>)lookupCommand:(NSString *)_comm inDomain:(NSString *)_domain
  args:(NSString *)_arg1,...;

- (id<LSCommand>)lookupCommand:(NSString *)_comm inDomain:(NSString *)_domain
  arg0:(id)_arg0 vargs:(va_list *)_va;

@end /* LSCommandContext(LookupCommands) */

@interface LSCommandContext(RunningCommands)

- (id)runCommand:(NSString *)_command,...;
- (id)runCommand:(NSString *)_command vargs:(va_list *)_va;
- (id)runCommand:(NSString *)_command arguments:(NSDictionary *)_args;

/* private: */

- (id<LSCommand>)runCommand:(NSString *)_command inDomain:(NSString *)_domain
  arg0:(id)_arg0 vargs:(va_list *)_va;

@end /* LSCommandContext(RunningCommands) */

@interface LSCommandContext(Transactions)

- (BOOL)begin;
- (BOOL)commit;
- (BOOL)rollback;
- (BOOL)isTransactionInProgress;

@end /* LSCommandContext */

@interface LSCommandContext(GlobalContext)

- (void)pushContext;
- (void)popContext;
+ (LSCommandContext *)activeContext;

@end

@interface LSCommandContext(LDAP)
+ (BOOL)useLDAPAuthorization;
@end

@class OGoContextManager;

@interface LSCommandContext(Init)
- (id)initWithManager:(OGoContextManager *)_lso;
@end

@interface LSCommandContext(LoginStuff)
- (BOOL)login:(NSString *)_login password:(NSString *)_pwd;
- (BOOL)login:(NSString *)_login password:(NSString *)_pwd
  isSessionLogEnabled:(BOOL)_isSessionLogEnabled;
- (BOOL)login:(NSString *)_login password:(NSString *)_pwd
  crypted:(BOOL)_crypted;
- (BOOL)login:(NSString *)_login password:(NSString *)_pwd
  crypted:(BOOL)_crypted isSessionLogEnabled:(BOOL)_isSessionLogEnabled;

- (LSCommandContext *)su_contextForLogin:(NSString *)_login
  isSessionLogEnabled:(BOOL)_isSessionLogEnabled;
@end

#endif /* __LSLogic_LSFoundation_LSCommandContext_H__ */
