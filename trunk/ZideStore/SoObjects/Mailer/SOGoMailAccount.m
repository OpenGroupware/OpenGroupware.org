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

#include "SOGoMailAccount.h"
#include "SOGoMailFolder.h"
#include "SOGoMailManager.h"
#include "SOGoDraftsFolder.h"
#include <NGObjWeb/SoHTTPAuthenticator.h>
#include "common.h"

@implementation SOGoMailAccount

static NSArray  *rootFolderNames  = nil;
static NSString *inboxFolderName  = @"INBOX";
static NSString *draftsFolderName = @"Drafts";
static NSString *sieveFolderName  = @"Filters";

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  if ([ud boolForKey:@"SOGoEnableSieveFolder"]) {
    rootFolderNames = [[NSArray alloc] initWithObjects:
					inboxFolderName, 
				        draftsFolderName, 
				        sieveFolderName, 
				      nil];
  }
  else {
    rootFolderNames = [[NSArray alloc] initWithObjects:
					inboxFolderName, 
				        draftsFolderName, 
				      nil];
  }
}

/* listing the available folders */

- (NSArray *)toManyRelationshipKeys {
  // TODO: hardcoded, if we want to support shared fldrs, this needs to change
  return rootFolderNames;
}

/* hierarchy */

- (SOGoMailAccount *)mailAccountFolder {
  return self;
}

- (NSArray *)allFolderPathes {
  NSArray *pathes;
  
  pathes = [[self mailManager] allFoldersForURL:[self imap4URL] 
			       password:[self imap4Password]];
  pathes = [pathes sortedArrayUsingSelector:@selector(compare:)];
  return pathes;
}

/* IMAP4 */

- (BOOL)useSSL {
  return NO;
}

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

- (NSURL *)imap4URL {
  /* imap://agenortest@mail.opengroupware.org/INBOX/withsubdirs/subdir1 */
  NSString *s;
  NSRange  r;
  
  if (self->imap4URL != nil)
    return self->imap4URL;
  
  s = [self nameInContainer];
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

- (NSString *)imap4Login {
  return [[self imap4URL] user];
}

/* name lookup */

- (id)lookupFolder:(NSString *)_key ofClassNamed:(NSString *)_cn
  inContext:(id)_cx
{
  Class clazz;

  if ((clazz = NSClassFromString(_cn)) == Nil) {
    [self logWithFormat:@"ERROR: did not find class '%@' for key: '%@'", 
	    _cn, _key];
    return [NSException exceptionWithHTTPStatus:500 /* server error */
			reason:@"did not find mail folder class!"];
  }
  return [[[clazz alloc] initWithName:_key inContainer:self] autorelease];
}

- (id)lookupImap4Folder:(NSString *)_key inContext:(id)_cx {
  return [self lookupFolder:_key ofClassNamed:@"SOGoMailFolder" inContext:_cx];
}
- (id)lookupDraftsFolder:(NSString *)_key inContext:(id)_ctx {
  return [self lookupFolder:_key ofClassNamed:@"SOGoDraftsFolder" 
	       inContext:_ctx];
}
- (id)lookupFiltersFolder:(NSString *)_key inContext:(id)_ctx {
  return [self lookupFolder:_key ofClassNamed:@"SOGoSieveScriptsFolder" 
	       inContext:_ctx];
}

- (id)lookupName:(NSString *)_key inContext:(id)_ctx acquire:(BOOL)_flag {
  id obj;
  
  /* first check attributes directly bound to the application */
  if ((obj = [super lookupName:_key inContext:_ctx acquire:NO]) != nil)
    return obj;
  
  // TODO: those should be product.plist bindings? (can't be class bindings
  //       though because they are 'per-account')
  if ([_key isEqualToString:draftsFolderName]) {
    if ((obj = [self lookupDraftsFolder:_key inContext:_ctx]) != nil)
      return obj;
  }
  if ([_key isEqualToString:sieveFolderName]) {
    if ((obj = [self lookupFiltersFolder:_key inContext:_ctx]) != nil)
      return obj;
  }
  
  if ((obj = [self lookupImap4Folder:_key inContext:_ctx]) != nil)
    return obj;
  
  /* return 404 to stop acquisition */
  return [NSException exceptionWithHTTPStatus:404 /* Not Found */];
}

/* special folders */

- (NSString *)inboxFolderNameInContext:(id)_ctx {
  return inboxFolderName; /* cannot be changed in Cyrus ? */
}
- (NSString *)draftsFolderNameInContext:(id)_ctx {
  return draftsFolderName; /* SOGo managed folder */
}
- (NSString *)sieveFolderNameInContext:(id)_ctx {
  return sieveFolderName;  /* SOGo managed folder */
}
- (NSString *)sentFolderNameInContext:(id)_ctx {
  /* OGo issue #1225 */
  static NSString *s = nil;
  
  if (s == nil) {
    NSUserDefaults *ud;
    
    ud = [NSUserDefaults standardUserDefaults];
    s = [[ud stringForKey:@"SOGoSentFolderName"] copy];
    if ([s length] == 0) s = @"Sent";
    NSLog(@"Note: using SOGoSentFolderName: '%@'", s);
  }
  return s;
}
- (NSString *)trashFolderNameInContext:(id)_ctx {
  /* OGo issue #1225 */
  static NSString *s = nil;
  
  if (s == nil) {
    NSUserDefaults *ud;
    
    ud = [NSUserDefaults standardUserDefaults];
    s = [[ud stringForKey:@"SOGoTrashFolderName"] copy];
    if ([s length] == 0) s = @"Trash";
    NSLog(@"Note: using SOGoTrashFolderName: '%@'", s);
  }
  return s;
}

- (SOGoMailFolder *)inboxFolderInContext:(id)_ctx {
  // TODO: use some profile to determine real location, use a -traverse lookup
  SOGoMailFolder *folder;
  
  if (self->inboxFolder != nil)
    return self->inboxFolder;
  
  folder = [self lookupName:[self inboxFolderNameInContext:_ctx]
		 inContext:_ctx acquire:NO];
  if ([folder isKindOfClass:[NSException class]]) return folder;
  
  return ((self->inboxFolder = [folder retain]));
}

- (SOGoMailFolder *)sentFolderInContext:(id)_ctx {
  // TODO: use some profile to determine real location, use a -traverse lookup
  SOGoMailFolder *folder;
  
  if (self->sentFolder != nil)
    return self->sentFolder;
  
  folder = [self inboxFolderInContext:_ctx];
  if ([folder isKindOfClass:[NSException class]]) return folder;
  
  folder = [folder lookupName:[self sentFolderNameInContext:_ctx]
		   inContext:_ctx acquire:NO];
  if ([folder isKindOfClass:[NSException class]]) return folder;
  
  if (![folder isNotNull]) {
    return [NSException exceptionWithHTTPStatus:404 /* not found */
			reason:@"did not find Sent folder!"];
  }
  
  return ((self->sentFolder = [folder retain]));
}

- (SOGoMailFolder *)trashFolderInContext:(id)_ctx {
  // TODO: use some profile to determine real location
  SOGoMailFolder *folder;
  
  if (self->trashFolder != nil)
    return self->trashFolder;

  folder = [self inboxFolderInContext:_ctx];
  if ([folder isKindOfClass:[NSException class]]) return folder;
  
  folder = [folder lookupName:[self trashFolderNameInContext:_ctx]
		   inContext:_ctx acquire:NO];
  if ([folder isKindOfClass:[NSException class]]) return folder;
  
  if (![folder isNotNull]) {
    return [NSException exceptionWithHTTPStatus:404 /* not found */
			reason:@"did not find Trash folder!"];
  }
  
  return ((self->trashFolder = [folder retain]));
}

/* WebDAV */

- (BOOL)davIsCollection {
  return YES;
}

- (NSString *)shortTitle {
  NSString *s, *login, *host;
  NSRange r;

  s = [self nameInContainer];
  
  r = [s rangeOfString:@"@"];
  if (r.length > 0) {
    login = [s substringToIndex:r.location];
    host  = [s substringFromIndex:(r.location + r.length)];
  }
  else {
    login = nil;
    host  = s;
  }
  
  r = [host rangeOfString:@"."];
  if (r.length > 0)
    host = [host substringToIndex:r.location];
  
  if ([login length] == 0)
    return host;
  
  return [NSString stringWithFormat:@"%@ (%@)", host, login];
}

- (NSString *)davDisplayName {
  return [self shortTitle];
}

@end /* SOGoMailAccount */
