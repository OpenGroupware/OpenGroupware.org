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

#ifndef __LSLogic_LSFoundation_LSCommandContext_H__
#define __LSLogic_LSFoundation_LSCommandContext_H__

#import  <Foundation/NSObject.h>
#import  <Foundation/NSDate.h>
#include <LSFoundation/LSCommandFactory.h>
#include <LSFoundation/LSCommand.h>
#include <LSFoundation/LSTypeManager.h>

@class NSMutableDictionary, NSDate, NSTimer, NSUserDefaults, SkyAccessManager;

/**
 * @class LSCommandContext
 * @brief Central execution context for OGo logic commands.
 *
 * LSCommandContext manages the database channel, transactions,
 * the command factory, and the authenticated user session. It
 * is the primary entry point for running commands:
 *
 *   [ctx runCommand:@"person::get", @"companyId", pid, nil];
 *
 * The context automatically opens database channels on demand,
 * manages transaction begin/commit/rollback, and supports
 * channel idle timeouts. It also provides access to shared
 * managers (type manager, property manager, link manager,
 * access manager).
 *
 * Contexts can be pushed/popped onto a thread-local stack via
 * -pushContext/-popContext for code that needs to retrieve the
 * active context without passing it explicitly.
 *
 * @see LSCommand
 * @see LSCommandFactory
 * @see LSBaseCommand
 */
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

- (BOOL)isRoot;

/* flushing caches */

- (void)flush;

/* key-value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key;
- (id)valueForKey:(NSString *)_key;

@end

/**
 * @category LSCommandContext(Logging)
 * @brief Logging convenience methods for the command context.
 */
@interface LSCommandContext(Logging)

- (void)logWithFormat:(NSString *)_format, ...;
- (void)debugWithFormat:(NSString *)_format, ...;

@end /* LSCommandContext(Logging) */

/**
 * @category LSCommandContext(LookupCommands)
 * @brief Methods for looking up command objects by domain
 *   and operation name without executing them.
 */
@interface LSCommandContext(LookupCommands)

/* you shouldn't use this stuff in GUI ! */

- (id<NSObject,LSCommandFactory>)commandFactory;

- (id<LSCommand>)lookupCommand:(NSString *)_comm inDomain:(NSString *)_domain;
- (id<LSCommand>)lookupCommand:(NSString *)_comm inDomain:(NSString *)_domain
  args:(NSString *)_arg1,...;

- (id<LSCommand>)lookupCommand:(NSString *)_comm inDomain:(NSString *)_domain
  arg0:(id)_arg0 vargs:(va_list *)_va;

@end /* LSCommandContext(LookupCommands) */

/**
 * @category LSCommandContext(RunningCommands)
 * @brief Methods for looking up, configuring, and executing
 *   commands in a single call.
 */
@interface LSCommandContext(RunningCommands)

- (id)runCommand:(NSString *)_command,...;
- (id)runCommand:(NSString *)_command vargs:(va_list *)_va;
- (id)runCommand:(NSString *)_command arguments:(NSDictionary *)_args;

/* private: */

- (id<LSCommand>)runCommand:(NSString *)_command inDomain:(NSString *)_domain
  arg0:(id)_arg0 vargs:(va_list *)_va;

@end /* LSCommandContext(RunningCommands) */

/**
 * @category LSCommandContext(Transactions)
 * @brief Database transaction management (begin, commit,
 *   rollback).
 */
@interface LSCommandContext(Transactions)

- (BOOL)begin;
- (BOOL)commit;
- (BOOL)rollback;
- (BOOL)isTransactionInProgress;

@end /* LSCommandContext */

/**
 * @category LSCommandContext(GlobalContext)
 * @brief Thread-local context stack for retrieving the active
 *   command context without explicit parameter passing.
 */
@interface LSCommandContext(GlobalContext)

- (void)pushContext;
- (void)popContext;
+ (LSCommandContext *)activeContext;

@end

/**
 * @category LSCommandContext(LDAP)
 * @brief LDAP authorization support.
 */
@interface LSCommandContext(LDAP)
+ (BOOL)useLDAPAuthorization;
@end

@class OGoContextManager;

/**
 * @category LSCommandContext(Init)
 * @brief Initialization with an OGoContextManager.
 */
@interface LSCommandContext(Init)
- (id)initWithManager:(OGoContextManager *)_lso;
@end

/**
 * @category LSCommandContext(LoginStuff)
 * @brief User authentication (login) and context switching
 *   (su) methods.
 */
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
