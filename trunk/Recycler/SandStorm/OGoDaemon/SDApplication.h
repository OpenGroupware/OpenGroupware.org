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

#ifndef __SDApplication_H__
#define __SDApplication_H__

#include <NGObjWeb/WOApplication.h>

/*
  This is an application object which caches credentials.

  It also sets up WODirectActionRequestHandler as the default request
  handler;
*/

@class NSMutableDictionary, NGMutableHashMap;
@class LSCommandContext, OGoContextManager;
@class SxComponent;

@interface SDApplication : WOApplication
{
  OGoContextManager   *lso;
  NSMutableDictionary *credToContext;
  NGMutableHashMap    *loginToCred;
  SxComponent         *registry;
  NSArray             *namespaces;

  int                 rssSizeLimit;
}

+ (int)loadDaemonBundle:(NSString *)_bundleName;

- (NSString *)defaultRequestHandlerClassName;
- (OGoContextManager *)lso;
/* context */

- (LSCommandContext *)contextForCredentials:(NSString *)_creds;
- (void)flushContextForCredentials:(NSString *)_creds;
- (void)flushContextForLogin:(NSString *)_login;

- (BOOL)hasNoLicenseKey;
- (BOOL)cantConnectToDatabase;

- (int)rssSizeLimit;

@end

@interface SDApplication(Registration)

- (NSString *)xmlrpcComponentNamespacePrefix;
- (NSString *)registryNamespace;

@end /* SDApplication(Registration) */

#endif /* __SDApplication_H__ */
