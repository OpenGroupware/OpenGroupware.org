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

#include "LoginPanel.h"
#include "RunMethod.h"
#include "Session.h"
#include <SxComponents/SxComponentInvocation.h>
#include <SxComponents/SxComponentException.h>
#include <SxComponents/SxBasicAuthCredentials.h>
#include "common.h"

@implementation LoginPanel

- (void)dealloc {
  RELEASE(self->userName);
  RELEASE(self->password);
  RELEASE(self->runPage);
  RELEASE(self->invocation);
  RELEASE(self->credentials);
  [super dealloc];
}

/* notifications */

- (void)sleep {
  ASSIGN(self->password, nil);
  [super sleep];
}

/* accessors */

- (void)setInvocation:(SxComponentInvocation *)_invocation {
  ASSIGN(self->invocation, _invocation);
}
- (SxComponentInvocation *)invocation {
  return self->invocation;
}

- (void)setCredentials:(id)_creds {
  ASSIGN(self->credentials, _creds);
}
- (id)credentials {
  return self->credentials;
}

- (void)setRunPage:(RunMethod *)_page {
  ASSIGN(self->runPage, _page);
}
- (RunMethod *)runPage {
  return self->runPage;
}

- (void)setUserName:(NSString *)_creds {
  ASSIGN(self->userName, _creds);
}
- (NSString *)userName {
  return self->userName;
}

- (void)setPassword:(NSString *)_creds {
  ASSIGN(self->password, _creds);
}
- (NSString *)password {
  return self->password;
}

/* actions */

- (id)rerun {
  id result;
  
  [self->credentials
       setCredentials:[self userName]
       password:[self password]];
  [self->invocation setCredentials:self->credentials];
  
  if (![self->invocation invoke]) {
    id exc;
    
    exc = [self->invocation lastException];
    if ([exc isCredentialsRequiredException]) {
      [self logWithFormat:@"creds failed ..."];
      return nil;
    }
    result = exc;
  }
  else {
    result = [self->invocation returnValue];
    //[self logWithFormat:@"got result: %@", result];
  }
  
  [self->runPage setResult:result];
  return self->runPage;
}

@end /* LoginPanel */
