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

#include "SDXmlRpcAction.h"
#include "common.h"
#include "SDApplication.h"
#include "SDAsyncResultProxy.h"
#include "SDXmlRpcFault.h"
#include <NGXmlRpc/NGXmlRpc.h>
#include <NGXmlRpc/XmlRpcMethodCall+WO.h>
#include <NGXmlRpc/XmlRpcMethodResponse+WO.h>

@interface NGXmlRpcAction(PrivateMethods)
+ (BOOL)coreOnFault;
@end /* NGXmlRpcAction(PrivateMethods) */

@implementation SDXmlRpcAction

+ (void)checkIfDaemonHasToBeShutdown {
  NSProcessInfo *pInfo;
  int rss, limit;
  SDApplication *app;

  app = (SDApplication *)[WOApplication application];
  limit = [app rssSizeLimit];

  if (limit == 0)
    return;
  
  pInfo = [NSProcessInfo processInfo];
  rss = [pInfo residentSetSize]/256;
  
  if (rss > limit) {
    [self logWithFormat:
          @"terminating app, RSS size limit (%d MB) has been reached"
          @" (currently %d MB)",
          limit, rss];
    [app terminate];
  }
}

- (NSNotificationCenter *)notificationCenter {
  return [NSNotificationCenter defaultCenter];
}

/* XML-RPC direct action dispatcher ... */

- (NSString *)authRealm {
  return @"SKYRiX";
}

- (id<WOActionResults>)commitFailedAction {
  WOResponse *resp;
    
  resp = [(WOResponse *)[WOResponse alloc] initWithRequest:[self request]];
  [resp setStatus:500 /* server error */];
  [resp appendContentString:@"tx commit failed ..."];
  
  return AUTORELEASE(resp);
}

- (id)performActionNamed:(NSString *)_actionName parameters:(NSArray *)_params{
  LSCommandContext *cmdctx = nil;
  id res;
  NSMutableString *log;

  log = [NSMutableString stringWithCapacity:255];
  [log appendFormat:@"[%@] - %@ - ",
       [NSCalendarDate calendarDate], _actionName];

  {
    NSEnumerator *paramEnum;
    id param;

    paramEnum = [_params objectEnumerator];
    while ((param = [paramEnum nextObject])) {
      if (![param isKindOfClass:[NSDictionary class]] &&
          ![param isKindOfClass:[NSArray class]])
        [log appendFormat:@"[%@] ", param];
      else
        [log appendString:@"[complex] "];
    }
  }
  
  if ([self requiresCommandContextForMethodCall:_actionName]) {
    if (![self hasAuthorizationHeader])
      return [self missingAuthAction];
    
    if ((cmdctx = [self commandContext]) == nil)
      return [self accessDeniedAction];

    if ([[self application] cantConnectToDatabase])
      return [SDXmlRpcFault databaseConnectionFault];

    if ([[self application] hasNoLicenseKey])
      return [SDXmlRpcFault invalidLicenseKeyFault];
  }

  NS_DURING {
    res = [[super performActionNamed:_actionName parameters:_params] retain];
  }
  NS_HANDLER {
    res = [localException retain];
    
    if ([[self class] coreOnFault])
      abort();
  }
  NS_ENDHANDLER;

  AUTORELEASE(res);
  
  if (cmdctx) {
    if ([cmdctx isTransactionInProgress]) {
      if (![cmdctx commit]) {
        [self logWithFormat:@"couldn't commit transaction ..."];
        return [self commitFailedAction];
      }
    }
  }

  if ([res isKindOfClass:[NSException class]])
    [log appendFormat:@"- failed (%@)", [res name]];
  else if (![res isKindOfClass:[NSDictionary class]] &&
           ![res isKindOfClass:[NSArray class]])
    [log appendFormat:@"- %@", res];
  else
    [log appendString:@"- complex"];
  
  NSLog(log);

  /* RSS size check */
  [[NSRunLoop currentRunLoop] performSelector:
                              @selector(checkIfDaemonHasToBeShutdown)
                              target:[self class]
                              argument:nil
                              order:1
                              modes:
                              [NSArray arrayWithObject:NSDefaultRunLoopMode]];
  return res;
}

/* command context */

- (BOOL)requiresCommandContextForMethodCall:(NSString *)_method {
  return NO;
}

/* command context */

- (void)flushCurrentCommandContext {
  return [[self application] flushContextForCredentials:[self credentials]];
}

- (LSCommandContext *)commandContext {
  return [[self application] contextForCredentials:[self credentials]];
}

@end /* SDXmlRpcAction */
