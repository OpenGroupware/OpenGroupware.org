/*
  Copyright (C) 2002-2004 SKYRIX Software AG

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

#include <NGObjWeb/SoApplication.h>
#include "SoWCAPRenderer.h"
#include <Main/SxAuthenticator.h>
#include <ZSFrontend/SxUserFolder.h>
#include "common.h"

@interface SoApplication(ZideStore)
- (id)userFolderForKey:(NSString *)_key;
@end

@implementation SoApplication(WCAP)

static BOOL debugWCAP = YES;

/* WCAP Support */

- (id)wcapCreateSessionForUser:(NSString *)_user password:(NSString *)_pwd
  language:(NSString *)_lang inContext:(id)_ctx
{
  // need a specialized WCAP authenticator ??
  id      auth, user;
  NSArray *roles;
  id      sn;
  
  if (debugWCAP)
    [self logWithFormat:@"shall create WCAP session (%@)", _user];
  
  if ((auth = [self authenticatorInContext:_ctx]) == nil) {
    if (debugWCAP) [self logWithFormat:@"ERROR: found no authenticator !"];
    return [NSException exceptionWithHTTPStatus:500
                        reason:@"missing authenticator object"];
  }
  
  if (![auth checkLogin:_user password:_pwd]) {
    if (debugWCAP) 
      [self logWithFormat:@"WCAP user '%@' did not authenticate !"];
    return [NSException exceptionWithHTTPStatus:403 /* access denied */
                        reason:@"invalid user or password"];
  }
  
  roles = [auth rolesForLogin:_user];
  user  = [[SoUser alloc] initWithLogin:_user roles:roles];
  if (debugWCAP) [self logWithFormat:@"  created WCAP user object: %@", user];
  
  sn = [_ctx session];
  if (debugWCAP) [self logWithFormat:@"  created session: %@", sn];
  
  [sn takeValue:user forKey:@"SoUser"];
  [sn takeValue:_pwd forKey:@"WCAPPassword"]; // should encrypt pwd ?
  [user release]; user = nil;
  
  return sn;
}
- (id)wcapSessionForID:(NSString *)_sid inContext:(id)_ctx {
  id sn;
  
  if (debugWCAP) [self logWithFormat:@"lookup WCAP session '%@'", _sid];
  
  sn = [self restoreSessionWithID:_sid inContext:_ctx];
  if (sn == nil) {
    [self logWithFormat:@"found no WCAP session with ID '%@' !"];
    return nil;
  }
  if (debugWCAP) 
    [self logWithFormat:@"  found WCAP session for ID '%@': %@", _sid, sn];
  return sn;
}
- (id)wcapCheckIDInContext:(id)_ctx {
  NSException *error;
  NSString    *sid;
  BOOL ok;
  
  sid = [[_ctx request] formValueForKey:@"id"];
  if ([sid length] == 0)
    ok = NO;
  else
    ok = [self restoreSessionWithID:sid inContext:_ctx] ? YES : NO;

  ok = YES; //hack
  
  error = [[SoWCAPRenderer sharedRenderer] 
            renderObject:[NSNumber numberWithBool:ok] inContext:_ctx];
  if (error) return error;
  
  return [_ctx response];
}

- (id)wcapPingInContext:(id)_ctx {
  [self logWithFormat:@"should do wcap ping ..."];
  return [NSException exceptionWithHTTPStatus:501 /* not implemented */];
}
- (id)wcapLoginInContext:(id)_ctx {
  static SoWCAPRenderer *wr = nil;
  WORequest   *rq;
  NSException *error;
  id sn;
  
  if (wr == nil) wr = [[SoWCAPRenderer sharedRenderer] retain];
  
  /* try to create session */
  
  rq = [_ctx request];
  sn = [self wcapCreateSessionForUser:[rq formValueForKey:@"user"]
             password:[rq formValueForKey:@"password"]
             language:[rq formValueForKey:@"lang"]
             inContext:_ctx];
  if ([sn isKindOfClass:[NSException class]] || sn == nil)
    return sn;
  
  // TODO: let SOPE select the renderer
  /* render session */
  if ((error = [wr renderObject:sn inContext:_ctx]))
    return error;
  return [_ctx response];
}

- (id)wcapGenIDsInContext:(id)_ctx {
  [self logWithFormat:@"WCAP get_guids not (yet) implemented ..."];
  return [NSException exceptionWithHTTPStatus:501 /* not implemented */];
}
- (id)wcapVersionInContext:(id)_ctx {
  [self logWithFormat:@"WCAP version not (yet) implemented ..."];
  return [NSException exceptionWithHTTPStatus:501 /* not implemented */];
}

- (id)lookupWCAPCommand:(NSString *)_key inContext:(id)_ctx {
  NSString     *sid;
  id           sn, user, pwd;
  SxUserFolder *userFolder;
  
  sid = [[_ctx request] formValueForKey:@"id"];
  if (debugWCAP)
    [self logWithFormat:@"lookup WCAP method: '%@' (sid=%@) ...", _key, sid];
  
  if ((sn = [self wcapSessionForID:sid inContext:_ctx]) == nil) {
    if (debugWCAP)
      [self logWithFormat:@"provided invalid WCAP session-id '%@'", sid];
    return nil;
  }
  
  if ((user = [sn valueForKey:@"SoUser"]) == nil) {
    if (debugWCAP)
      [self logWithFormat:@"invalid WCAP session (no user): %@", sn];
    [sn terminate];
    return nil;
  }
  pwd = [sn valueForKey:@"WCAPPassword"];
  
  if (debugWCAP) {
    [self logWithFormat:@"should handle using WCAP session: %@", sn];
    [self logWithFormat:@"  WCAP user: %@", user];
  }
  
  if ((userFolder = [self userFolderForKey:[user login]]) == nil) {
    [self logWithFormat:@"found no folder for user: %@", user];
    [sn terminate];
    return nil;
  }
  if (debugWCAP) [self logWithFormat:@"  user folder: %@", userFolder];
  
  return [userFolder lookupName:_key inContext:_ctx acquire:NO];
}

@end /* SoApplication(WCAP) */
