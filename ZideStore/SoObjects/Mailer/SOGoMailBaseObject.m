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

#include "SOGoMailBaseObject.h"
#include "SOGoMailManager.h"
#include "common.h"
#include <NGObjWeb/SoObject+SoDAV.h>
#include <NGObjWeb/SoHTTPAuthenticator.h>
#include <NGExtensions/NSURL+misc.h>

@implementation SOGoMailBaseObject

#if 0
static BOOL debugOn = YES;
#endif

- (id)initWithImap4URL:(NSURL *)_url inContainer:(id)_container {
  NSString *n;
  
  n = [[_url path] lastPathComponent];
  if ((self = [self initWithName:n inContainer:_container])) {
    self->imap4URL = [_url retain];
  }
  return self;
}

- (void)dealloc {
  [self->imap4URL release];
  [super dealloc];
}

/* hierarchy */

- (SOGoMailAccount *)mailAccountFolder {
  if (![[self container] respondsToSelector:_cmd]) {
    [self warnWithFormat:@"weird container of mailfolder: %@",
            [self container]];
    return nil;
  }
  
  return [[self container] mailAccountFolder];
}

/* IMAP4 */

- (SOGoMailManager *)mailManager {
  return [SOGoMailManager defaultMailManager];
}

- (NSString *)relativeImap4Name {
  [self warnWithFormat:@"subclass should override %@", 
	  NSStringFromSelector(_cmd)];
  return nil;
}
- (NSURL *)baseImap4URL {
  if (![[self container] respondsToSelector:@selector(imap4URL)]) {
    [self warnWithFormat:@"container does not implement -imap4URL!"];
    return nil;
  }
  
  return [[self container] imap4URL];
}
- (NSURL *)imap4URL {
  NSString *sn;
  NSURL    *base;
  
  if (self->imap4URL != nil) 
    return self->imap4URL;
  
  if ((sn = [self relativeImap4Name]) == nil)
    return nil;
  
  if (![[self container] respondsToSelector:_cmd]) {
    [self warnWithFormat:@"container does not implement -imap4URL!"];
    return nil;
  }
  
  if ((base = [self baseImap4URL]) == nil)
    return nil;
  
  sn = [[base path] stringByAppendingPathComponent:sn];
  self->imap4URL = [[NSURL alloc] initWithString:sn relativeToURL:base];
  return self->imap4URL;
}

- (NSString *)imap4FolderName {
  return [[self mailManager] imap4FolderNameForURL:[self imap4URL]];
}

- (NSString *)imap4Login {
  if (![[self container] respondsToSelector:_cmd])
    return nil;
  
  return [[self container] imap4Login];
}
- (NSString *)imap4Password {
  return [(SOGoMailBaseObject *)[self mailAccountFolder] imap4Password];
}

- (NGImap4Client *)imap4ClientForURL:(NSURL *)_url password:(NSString *)_pwd {
  return [[self mailManager] imap4ClientForURL:_url password:_pwd];
}

- (NGImap4Client *)imap4Client {
  return [self imap4ClientForURL:[self imap4URL]
	       password:[self imap4Password]];
}

- (void)flushMailCaches {
  [[self mailManager] flushCachesForURL:[self imap4URL]];
}

/* IMAP4 names */

- (BOOL)isBodyPartKey:(NSString *)_key inContext:(id)_ctx {
  /*
    Every key starting with a digit is consider an IMAP4 mime part key, used in
    SOGoMailObject and SOGoMailBodyPart.
  */
  if ([_key length] == 0)
    return NO;
  
  if (isdigit([_key characterAtIndex:0]))
    return YES;
  
  return NO;
}

/* debugging */

- (NSString *)loggingPrefix {
  /* improve perf ... */
  return [NSString stringWithFormat:@"<0x%p[%@]:%@>",
		     self, NSStringFromClass([self class]),
		     [self nameInContainer]];
}
@end /* SOGoMailBaseObject */
