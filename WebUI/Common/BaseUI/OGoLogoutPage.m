/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include "OGoLogoutPage.h"
#include "common.h"
#include <NGHttp/NGHttpCookie.h>
#include <NGHttp/NGHttpResponse.h>

@implementation OGoLogoutPage

- (NSString *)restartUrl {
  return [NSString stringWithFormat:@"%@/%@",
                     [[[self context] request] adaptorPrefix],
                     [(WOApplication *)[self application] name]];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  WOCookie *cookie;
  NSString *logoutURL;
  
  logoutURL =
    [[NSUserDefaults standardUserDefaults] stringForKey:@"SkyLogoutURL"];
  
  [super appendToResponse:_response inContext:_ctx];
  
  if ([logoutURL length] > 0) {
    [_response setStatus:302];
    [_response setHeader:logoutURL forKey:@"location"];
  }
  
  cookie = [WOCookie cookieWithName:@"LSOLoginState"
                     value:@"relogin"
                     path:[[[self application] baseURL] path]
                     domain:nil
                     expires:nil
                     isSecure:NO];
  [_response addCookie:cookie];
}

@end /* OGoLogoutPage */
