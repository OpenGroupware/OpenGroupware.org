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

#include "SkyObjectInfoAction.h"
#include "common.h"
#include "SkyObjectInfoAction+PrivateMethods.h"
#include <XmlRpc/XmlRpcMethodCall.h>

#include <OGoIDL/NGXmlRpcAction+Introspection.h>
#include <OGoDaemon/SDXmlRpcFault.h>

@implementation SkyObjectInfoAction

static NSMutableDictionary *entityCache = nil;

+ (NSArray *)xmlrpcNamespaces {
  return [NSArray arrayWithObjects:@"objectinfo",nil];
}

- (NSString *)xmlrpcComponentName {
  return @"objectinfo";
}

- (id)initWithContext:(WOContext *)_ctx {
  if ((self = [super initWithContext:_ctx])) {
    NSString *path;
    NSBundle *bundle;

    if (entityCache == nil) {
      NSLog(@"%s: initializing entity cache", __PRETTY_FUNCTION__);
      entityCache = [[NSMutableDictionary alloc] initWithCapacity:16];
    }
    
    bundle = [NSBundle bundleForClass:[self class]];
    
    path = [bundle pathForResource:@"INTERFACE" ofType:@"xml"];
    if (path != nil)
      [self registerInterfaceAtPath:path forComponentName:
            [self xmlrpcComponentName]];
    else
      [self logWithFormat:@"INTERFACE.xml not found in bundle path"];
  }
  return self;
}

- (BOOL)requiresCommandContextForMethodCall:(NSString *)_methodName {
  static NSArray *methodNames = nil;

  if (methodNames == nil) {
    methodNames = [[NSArray alloc] initWithObjects:
                            @"system.listMethods",
                            @"system.methodSignature",
                            @"system.methodHelp",
                            nil];
  }
  if ([methodNames containsObject:_methodName])
    return NO;
  
  return YES;
}

/* actions */

- (id)objectLogAction:(NSString *)_url {
  EOGlobalID *gid;
  id dm, ctx;

  if ((ctx = [self commandContext]) != nil) {
    dm = [self documentManager];

    if ((gid = [dm globalIDForURL:_url]) != nil) {
      id obj;

      NSLog(@"-- calling object::get-by-globalid");
      obj = [[ctx runCommand:@"object::get-by-globalid",
                 @"gid", gid,
                 nil] lastObject];
      [self _ensureCurrentTransactionIsCommitted];

      if (obj != nil) {
        NSArray *logs;

        NSLog(@"-- calling object::get-logs");
        logs = [ctx runCommand:@"object::get-logs",
                    @"object", obj,
                    nil];

        [self _ensureCurrentTransactionIsCommitted];

        if (logs != nil)
          return [self _dictionariesForLogRecords:logs
                       withActor:YES];
        else
          return [SDXmlRpcFault commandFailedFault:@"object::get-logs"];
      }
      else
        return [SDXmlRpcFault commandFailedFault:@"object::get-by-globalid"];
    }
    else
      return [SDXmlRpcFault invalidObjectFaultForId:_url entity:@"object"];
  }
  [self logWithFormat:@"Invalid command context"];
  return nil;
}

- (id)getEntitiesForPrimaryKeysAction:(NSArray *)_keys {
  id ctx;

  if (_keys != nil) {
    if ((ctx = [self commandContext]) != nil) {
      id result;

      NSLog(@"keys are %@", _keys);
      result = [ctx runCommand:@"object::get-type",
                    @"oids", _keys,
                    nil];

      if (result != nil)
        return result;
      return [SDXmlRpcFault commandFailedFault:@"object::get-type"];
    }
  }
  return [SDXmlRpcFault missingValueFaultForArgument:@"pKeys"];
}

- (id)getEntityForPrimaryKeyAction:(NSNumber *)_pKey {
  NSString *tmp;

  if (_pKey != nil) {
    if ([_pKey isKindOfClass:[NSString class]]) {
      _pKey = [NSNumber numberWithInt:[_pKey intValue]];
    }

    if ((tmp = [entityCache valueForKey:[_pKey stringValue]]) != nil) {
      return tmp;
    }
  
    if ([_pKey intValue] != 0) {
      NSString *result;
      result =  [[self getEntitiesForPrimaryKeysAction:
                       [NSArray arrayWithObject:_pKey]] lastObject];

      if (![result isKindOfClass:[NSException class]])
        [entityCache setObject:result forKey:[_pKey stringValue]];
      return result;
    }
  }
  [self logWithFormat:@"Invalid pKey parameter"];
  return [SDXmlRpcFault missingValueFaultForArgument:@"pKey"];
}
  
- (id)removeObjectLogAction:(NSString *)_url {
  if (_url != nil) {
    EOGlobalID *gid;

    if ((gid = [[self documentManager] globalIDForURL:_url]) != nil) {
      id object;

      object = [[self commandContext] runCommand:@"object::get-by-globalid",
                                      @"gid", gid,
                                      nil];
      if (object != nil) {
        id result;
      
        result = [[self commandContext] runCommand:@"object::remove-logs",
                                        @"object", object,
                                        nil];
        if (result != nil)
          return [NSNumber numberWithBool:YES];
        return [SDXmlRpcFault commandFailedFault:@"object::remove-log"];
      }
      else
        return [SDXmlRpcFault commandFailedFault:@"object::get-by-globalid"];
    }
    else
      return [SDXmlRpcFault invalidObjectFaultForId:_url entity:@"object"];
  }
  [self logWithFormat:@"ERROR: missing URL"];
  return [SDXmlRpcFault missingValueFaultForArgument:@"url"];
}

- (id)addObjectLogAction:(NSString *)_url
                        :(NSString *)_action
                        :(NSString *)_text
{
  if (_url != nil) {
    id result;
      
    result = [[self commandContext] runCommand:@"object::add-log",
                                    @"action", _action,
                                    @"logText", _text,
                                    @"objectId", [_url lastPathComponent],
                                    nil];
      
    if (result != nil)
      return [NSNumber numberWithBool:YES];
    return [SDXmlRpcFault commandFailedFault:@"object::add-log"];
  }
  [self logWithFormat:@"ERROR: missing URL"];
  return [SDXmlRpcFault missingValueFaultForArgument:@"url"];
}

@end /* SkyObjectLogAction */
