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

#include "OGoMailAccount.h"

#include <NGObjWeb/SoHTTPAuthenticator.h>
#include <LSFoundation/LSCommandContext.h>
#include "common.h"

@interface SOGoMailAccount(UsedPrivates)
- (BOOL)useSSL;
@end

@implementation ZSOGoMailAccount

/* IMAP4 */

- (NSString *)imap4LoginFromHTTP {
  WORequest *rq;
  NSString  *s;
  NSArray   *creds;
  
  rq = [[(WOApplication *)[WOApplication application] context] request];
  
  s = [rq headerForKey:@"x-webobjects-remote-user"];
  if ([s length] > 0)
    return s;
  
  if ((s = [rq headerForKey:@"authorization"]) == nil) {
    /* no basic auth */
    return nil;
  }
  
  creds = [SoHTTPAuthenticator parseCredentials:s];
  if ([creds count] < 2)
    /* somehow invalid */
    return nil;
  
  return [creds objectAtIndex:0]; /* the user */
}

- (NSString *)loginAndHostFromDefaults {
  NSUserDefaults *ud;
  WOContext *ctx;
  NSString  *s, *t;
  
  ctx = [(WOApplication *)[WOApplication application] context];
  ud  = [[self commandContextInContext:ctx] userDefaults];
  
  s = [ud stringForKey:@"imap_host"];
  if (![s isNotNull] || [s length] == 0)
    s = @"localhost";
  
  if ([(t = [ud stringForKey:@"imap_login"]) isNotNull]) {
    if ([t length] > 0)
      s = [[t stringByAppendingString:@"@"] stringByAppendingString:s];
  }
  return s;
}

- (NSURL *)imap4URL {
  /* imap://agenortest@mail.opengroupware.org/INBOX/withsubdirs/subdir1 */
  NSString *s;
  NSRange  r;
  
  if (self->imap4URL != nil)
    return self->imap4URL;

  s = [self loginAndHostFromDefaults];
  
  r = [s rangeOfString:@"@"];
  if (r.length == 0) {
    NSString *u;
    
    u = [self imap4LoginFromHTTP];
    if ([u length] == 0) {
      [self errorWithFormat:@"missing login in account folder name: %@", s];
      return nil;
    }
    s = [[u stringByAppendingString:@"@"] stringByAppendingString:s];
  }
  if ([s hasSuffix:@":80"]) { // HACK
    [self logWithFormat:@"WARNING: incorrect value for IMAP4 URL: '%@'", s];
    s = [s substringToIndex:([s length] - 3)];
  }
  
  s = [([self useSSL] ? @"imaps://" : @"imap://") stringByAppendingString:s];
  s = [s stringByAppendingString:@"/"];
  
  self->imap4URL = [[NSURL alloc] initWithString:s];
  return self->imap4URL;
}

@end /* ZSOGoMailAccount */