/*
  Copyright (C) 2006 Helge Hess

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

#import <Foundation/NSObject.h>

/*
  GDataAccounts

  This is mapped to /accounts and does the Google authentication.
*/

@interface GDataAccounts : NSObject
@end

#include <Main/SxAuthenticator.h>
#include "common.h"

@implementation GDataAccounts

- (id)clientLoginInContext:(id)_ctx {
  WORequest  *rq = [_ctx request];
  WOResponse *rp = [_ctx response];
  NSString   *login, *pwd;
  id auth;

  login = [rq formValueForKey:@"Email"];
  pwd   = [rq formValueForKey:@"Passwd"];

  [rp setHeader:@"text/plain" forKey:@"content-type"];
  
  auth = [self authenticatorInContext:_ctx];
  if (![auth checkLogin:login password:pwd]) {
    [rp setStatus:403 /* Forbidden */];
    [rp appendContentString:@"Error=BadAuthentication\r\n"];
  }
  else {
    [self logWithFormat:@"user logged in: %@ ...", login];
    
    /*
      We use HTTP basic authentication over Google-auth. This is supported by
      SOPE ...
    */
    [rp appendContentString:@"Auth=Basic "];
    
    login = [[login stringByAppendingString:@":"] stringByAppendingString:pwd];
    [rp appendContentString:[login stringByEncodingBase64]];
    
    [rp appendContentString:@"\r\n"];
  }
  return rp;
}

@end /* GDataAccounts */
