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

#include <OGoDaemon/WODirectAction+SkyDaemon.h>
#include <OGoDaemon/SDApplication.h>
#include <NGXmlRpc/WODirectAction+XmlRpc.h>
#include "common.h"

@implementation WODirectAction(SkyDaemon)

/* command context */

- (BOOL)hasAuthorizationHeader {
  WORequest *rq;
  NSString  *cred;
  
  if ((rq = [self request]) == nil)
    return NO;

  if ((cred = [rq headerForKey:@"authorization"]) == nil)
    return NO;
  
  return YES;
}

- (NSString *)credentials {
  WORequest *rq;
  NSString  *cred;
  NSRange   r;
  
  if ((rq = [self request]) == nil)
    return nil;
  if ((cred = [rq headerForKey:@"authorization"]) == nil)
    return nil;
  
  r = [cred rangeOfString:@" " options:NSBackwardsSearch];
  if (r.length == 0) {
    [self logWithFormat:@"invalid 'authorization' header: '%@'", cred];
    return nil;
  }
  return [cred substringFromIndex:(r.location + r.length)];
}

- (void)flushCurrentCommandContext {
  return [(SDApplication *)[WOApplication application]
                           flushContextForCredentials:[self credentials]];
}


- (LSCommandContext *)commandContext {
  return [(SDApplication *)[WOApplication application]
                           contextForCredentials:[self credentials]];
}

@end /* WODirectAction(SkyDaemon) */
