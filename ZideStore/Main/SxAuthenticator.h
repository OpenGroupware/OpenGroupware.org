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

#ifndef __codeon_OLAuthenticator_H__
#define __codeon_OLAuthenticator_H__

#include <NGObjWeb/SoHTTPAuthenticator.h>

@class NSMutableDictionary, NSString, NSArray;
@class LSCommandContext;

@interface SxAuthenticator : SoHTTPAuthenticator
{
  id lso;
  NSMutableDictionary *credToContext;
  NSMutableDictionary *managerStore;
}

+ (id)sharedAuthenticator;

/* SKYRiX setup queries */

- (BOOL)cantConnectToDatabase;
- (NSMutableDictionary *)managerStore;

/* skyrix context cache */

- (void)flushContextForLogin:(NSString *)_login;
- (void)flushContextForCredentials:(NSArray *)_creds;
- (LSCommandContext *)commandContextInContext:(WOContext *)_ctx;

@end

#endif /* __codeon_OLAuthenticator_H__ */
