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

#include "SxPage.h"
#include "common.h"
#include <Main/SxAuthenticator.h>
#include <Main/ZideStore.h>

#include <LSFoundation/LSCommandContext.h>
#include <LSFoundation/LSCommandKeys.h>

@implementation SxPage

- (LSCommandContext *)commandContext {
  SxAuthenticator *auth;
  id ctx;

  ctx = [self context];

  if ((auth = [[self application] authenticatorInContext:ctx]))
    return [auth commandContextInContext:ctx];

  return nil;
}

- (id)account {
  if (self->account == nil) {
    LSCommandContext *cmdctx;

    if ((cmdctx = [self commandContext]) != nil) {
      id result;
      
      result = [cmdctx valueForKey:LSAccountKey];
      ASSIGN(self->account, result);
    }
  }
  return self->account;
}

- (NSString *)zsBaseURL {
  NSString *base;
  
  base = (id)[[[self context] clientObject] baseURL];

  base = [base stringByDeletingLastPathComponent];
  return [base stringByAppendingPathComponent:
               [[self account] valueForKey:@"login"]];
}

@end /* SxPage */
