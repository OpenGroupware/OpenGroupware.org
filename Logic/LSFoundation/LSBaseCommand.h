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

#ifndef __LSLogic_LSFoundation_LSBaseCommand_H__
#define __LSLogic_LSFoundation_LSBaseCommand_H__

#import  <Foundation/NSObject.h>
#include <LSFoundation/LSCommandFactory.h>
#include <LSFoundation/LSCommand.h>

/*
  LSBaseCommand

  This is the command base class which is used by all other commands in OGo.

  TODO: more documentation

  On a -runInContext: the following methods are called:
  
    runInContext:ctx
    {
      sets activeContext

      primaryRunInContext:ctx
      {
        _prepareForExecutionInContext:ctx
          prepares command for execution
  
        _executeInContext:ctx
          executes command (subclass responsibility)
  
        _executeCommandsInContext:ctx
        {
          sets 'parent' key
          foreach <added command>
            command runInContext:ctx
          restores old 'parent' key
        }
  
        _validateInContext:ctx
          constraint checks whether the command was successful
      }
      resets activeContext
    }
*/

#define LSLookupCommand(_domain, _command) \
  LSCommandLookup([self commandFactory], _domain, _command)

#define LSLookupCommandV(_domain, _command, arg1...) \
  LSCommandLookupV([self commandFactory], _domain, _command, ##arg1)

#define LSRunCommandV(_ctx_, _domain_, _command_, arg1...) \
  LSCommandRunV(_ctx_, [self commandFactory], _domain_, _command_, ##arg1)

@class NSString, NSMutableArray, NSArray;
@class LSBaseCommand;

static inline void LSCommandSet(LSBaseCommand *_cmd, NSString *_argument, id _value);
static inline id   LSCommandGet(LSBaseCommand *_cmd, NSString *_argument);
static inline id   LSCommandLookup(id _factory, NSString *_domain, NSString *_command);
id LSCommandLookupV(id _factory, NSString *_domain, NSString *_command, ...);
id LSCommandRunV(id _ctx, id _factory, NSString *_domain, NSString *_command, ...);

@interface LSBaseCommand : NSObject < LSCommand >
{
@private
  NSMutableArray *commands;
  NSString       *operation;
  NSString       *domain;

@private
  id   object;
  
@protected
  // valid during runInContext:
  id   activeContext;
  BOOL isCommandOk;
}

+ (void)setDebuggingEnabled:(BOOL)_flag;
+ (BOOL)isDebuggingEnabled;

// desig. i.
- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain;

/* accessors */

- (NSString *)operation;
- (NSString *)domain;

- (NSArray *)commands; // TODO: DEPRECATED

- (void)setReturnValue:(id)_object;
- (id)returnValue;
- (void)setObject:(id)_object;
- (id)object;

- (BOOL)isCommandOk;

/* command type */

- (BOOL)requiresChannel;
- (BOOL)requiresTransaction;

/* command methods */

- (id)runInContext:(id)_context;
- (void)primaryRunInContext:(id)_context;

- (void)_checkPermissionInContext:(id)_context;
- (void)_prepareForExecutionInContext:(id)_context;
- (void)_executeInContext:(id)_context;
- (void)_executeCommandsInContext:(id)_context;
- (void)_validateInContext:(id)_context;

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key;
- (id)valueForKey:(NSString *)_key;

/* context functions */

- (id<NSObject,LSCommandFactory>)commandFactory;

/* logging */

- (void)logWithFormat:(NSString *)_format, ...;
- (void)debugWithFormat:(NSString *)_format, ...;

/* assertions */

- (void)assert:(BOOL)_condition;
- (void)assert:(BOOL)_condition reason:(NSString *)_reason;
#if USE_VA_LIST_PTR
- (void)assert:(BOOL)_condition format:(NSString *)_fmt 
  arguments:(va_list *)_ap;
#else
- (void)assert:(BOOL)_condition format:(NSString *)_fmt arguments:(va_list)_ap;
#endif
- (void)assert:(BOOL)_condition format:(NSString *)_reason, ...;
- (BOOL)foundInvalidSetKey:(NSString *)_key;
- (id)foundInvalidGetKey:(NSString *)_key;
  
@end

static void LSCommandSet(LSBaseCommand *_cmd, NSString *_argument, id _value) {
  [_cmd takeValue:_value forKey:_argument];
}
static id LSCommandGet(LSBaseCommand *_cmd, NSString *_argument) {
  return [_cmd valueForKey:_argument];
}

static id LSCommandLookup(id _factory, NSString *_domain, NSString *_command) {
  return [_factory command:_command inDomain:_domain];
}

#endif /* __LSLogic_LSFoundation_LSBaseCommand_H__ */
