/*
  Copyright (C) 2004-2005 SKYRIX Software AG

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

#include "SOGoMailAccounts.h"
#include "common.h"
#include <NGObjWeb/SoObject+SoDAV.h>
#include <SOGoLogic/AgenorUserManager.h>

@implementation SOGoMailAccounts

/* listing the available mailboxes */

- (NSArray *)toManyRelationshipKeys {
  static AgenorUserManager *um = nil;
  NSString *uid, *account;
  
  if (um == nil)
    um = [[AgenorUserManager sharedUserManager] retain];
  
  uid     = [[self container] davDisplayName];
  account = [um getIMAPAccountStringForUID:uid];
  
  return account ? [NSArray arrayWithObject:account] : nil;
}

/* name lookup */

- (BOOL)isValidMailAccountName:(NSString *)_key {
  if ([_key length] == 0)
    return NO;
  
  return YES;
}

- (id)mailAccountWithName:(NSString *)_key inContext:(id)_ctx {
  static Class ctClass = Nil;
  id ct;
  
  if (ctClass == Nil)
    ctClass = NSClassFromString(@"SOGoMailAccount");
  if (ctClass == Nil) {
    [self errorWithFormat:@"missing SOGoMailAccount class!"];
    return nil;
  }
  
  ct = [[ctClass alloc] initWithName:_key inContainer:self];
  return [ct autorelease];
}

- (id)lookupName:(NSString *)_key inContext:(id)_ctx acquire:(BOOL)_flag {
  id obj;
  
  /* first check attributes directly bound to the application */
  if ((obj = [super lookupName:_key inContext:_ctx acquire:NO]))
    return obj;
  
  if ([self isValidMailAccountName:_key])
    return [self mailAccountWithName:_key inContext:_ctx];

  /* return 404 to stop acquisition */
  return [NSException exceptionWithHTTPStatus:404 /* Not Found */];
}

/* WebDAV */

- (BOOL)davIsCollection {
  return YES;
}

@end /* SOGoMailAccounts */
