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

#include "SOGoMailManager.h"
#include "SOGoMailConnectionEntry.h"
#include "common.h"

/*
  Could check read-write state:
    dict = [[self->context client] select:[self absoluteName]];
    self->isReadOnly = 
      [[dict objectForKey:@"access"] isEqualToString:@"READ-WRITE"]
      ? NoNumber : YesNumber;
*/

@implementation SOGoMailManager

static BOOL           debugOn    = NO;
static BOOL           debugCache = NO;
static BOOL           debugKeys  = NO;
static BOOL           poolingOff = NO;
static BOOL           alwaysSelect = NO;
static NSTimeInterval PoolScanInterval = 5 * 60;
static NSString       *imap4Separator  = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  debugOn      = [ud boolForKey:@"SOGoEnableIMAP4Debug"];
  debugCache   = [ud boolForKey:@"SOGoEnableIMAP4CacheDebug"];
  poolingOff   = [ud boolForKey:@"SOGoDisableIMAP4Pooling"];
  alwaysSelect = [ud boolForKey:@"SOGoAlwaysSelectIMAP4Folder"];
  
  if (debugOn)    NSLog(@"Note: SOGoEnableIMAP4Debug is enabled!");
  if (poolingOff) NSLog(@"WARNING: IMAP4 connection pooling is disabled!");

  if (alwaysSelect)
    NSLog(@"WARNING: 'SOGoAlwaysSelectIMAP4Folder' enabled (slow down)");
  
  imap4Separator = [[ud stringForKey:@"SOGoIMAP4StringSeparator"] copy];
  if ([imap4Separator length] == 0)
    imap4Separator = @"/";
  NSLog(@"Note(SOGoMailManager): using '%@' as the IMAP4 folder separator.", 
	imap4Separator);
}

+ (id)defaultMailManager {
  static SOGoMailManager *manager = nil; // THREAD
  if (manager == nil) 
    manager = [[self alloc] init];
  return manager;
}

- (id)init {
  if ((self = [super init])) {
    if (!poolingOff) {
      self->urlToEntry = [[NSMutableDictionary alloc] initWithCapacity:256];
    }
    
    self->gcTimer = [[NSTimer scheduledTimerWithTimeInterval:
				PoolScanInterval
			      target:self selector:@selector(_garbageCollect:)
			      userInfo:nil repeats:YES] retain];
  }
  return self;
}

- (void)dealloc {
  if (self->gcTimer) [self->gcTimer invalidate];
  [self->gcTimer release];
  
  [self->urlToEntry release];
  [super dealloc];
}

/* cache */

- (id)cacheKeyForURL:(NSURL *)_url {
  // protocol, user, host, port
  return [NSString stringWithFormat:@"%@://%@@%@:%@",
		   [_url scheme], [_url user], [_url host], [_url port]];
}

- (SOGoMailConnectionEntry *)entryForURL:(NSURL *)_url {
  if (_url == nil)
    return nil;
  
  return [self->urlToEntry objectForKey:[self cacheKeyForURL:_url]];
}
- (void)cacheEntry:(SOGoMailConnectionEntry *)_entry forURL:(NSURL *)_url {
  if (_entry == nil) _entry = (id)[NSNull null];
  [self->urlToEntry setObject:_entry forKey:[self cacheKeyForURL:_url]];
}

- (void)_garbageCollect:(NSTimer *)_timer {
  // TODO: scan for old IMAP4 channels
  [self debugWithFormat:@"should collect IMAP4 channels (%d active)",
	  [self->urlToEntry count]];
}

- (id)entryForURL:(NSURL *)_url password:(NSString *)_pwd {
  /*
    Three cases:
    a) not yet connected             => create new entry and connect
    b) connected, correct password   => return cached entry
    c) connected, different password => try to recreate entry
  */
  SOGoMailConnectionEntry *entry;
  NGImap4Client *client;

  /* check cache */
  
  if ((entry = [self entryForURL:_url]) != nil) {
    if ([entry isValidPassword:_pwd]) {
      if (debugCache)
	[self logWithFormat:@"valid password, reusing cache entry ..."];
      return entry;
    }
    
    /* different password, password could have changed! */
    if (debugCache)
      [self logWithFormat:@"different password than cached entry: %@", _url];
    entry = nil;
  }
  else
    [self debugWithFormat:@"no connection cached yet for url: %@", _url];
  
  /* try to login */
  
  client = [entry isValidPassword:_pwd]
    ? [entry client]
    : [self imap4ClientForURL:_url password:_pwd];
  
  if (client == nil)
    return nil;
  if ([client isKindOfClass:[NSException class]])
    return client;
  
  /* sideeffect of -imap4ClientForURL:password: is to create a cache entry */
  return [self entryForURL:_url];
}

/* client object */

- (NGImap4Client *)imap4ClientForURL:(NSURL *)_url password:(NSString *)_pwd {
  // TODO: move to some global IMAP4 connection pool manager
  SOGoMailConnectionEntry *entry;
  NGImap4Client *client;
  NSDictionary  *result;
  
  if (_url == nil)
    return nil;

  /* check connection pool */
  
  if ((entry = [self entryForURL:_url]) != nil) {
    if ([entry isValidPassword:_pwd]) {
      [self debugWithFormat:@"reused IMAP4 connection for URL: %@", _url];
      return [entry client];
    }
    
    /* different password, password could have changed! */
    entry = nil;
  }
  
  /* setup connection and attempt login */
  
  if ((client = [NGImap4Client clientWithURL:_url]) == nil)
    return nil;
  
  result = [client login:[_url user] password:_pwd];
  if (![[result valueForKey:@"result"] boolValue]) {
    [self errorWithFormat:
            @"IMAP4 login failed (host=%@,user=%@,pwd=%s,url=%@/%@/%@): %@", 
            [_url host], [_url user], [_pwd length] > 0 ? "yes" : "no", 
            [_url absoluteString], [_url baseURL],
            NSStringFromClass([[_url baseURL] class]),
            client];
    return [NSException exceptionWithHTTPStatus:401 /* Auth Required */
			reason:@"IMAP4 login failed"];
  }
  
  [self debugWithFormat:@"created new IMAP4 connection for URL: %@", _url];
  
  /* cache connection in pool */
  
  entry = [[SOGoMailConnectionEntry alloc] initWithClient:client 
					   password:_pwd];
  [self cacheEntry:entry forURL:_url];
  [entry release]; entry = nil;
  
  return client;
}

- (void)flushCachesForURL:(NSURL *)_url {
  SOGoMailConnectionEntry *entry;
  
  if ((entry = [self entryForURL:_url]) == nil) /* nothing cached */
    return;
  
  [entry flushFolderHierarchyCache];
  [entry flushMailCaches];
}

- (BOOL)selectFolder:(id)_url inClient:(NGImap4Client *)_client {
  NSDictionary *result;
  NSString     *newFolder;
  
  newFolder = [_url isKindOfClass:[NSURL class]]
    ? [self imap4FolderNameForURL:_url]
    : _url;
  
  if (!alwaysSelect) {
    if ([[_client selectedFolderName] isEqualToString:newFolder])
      return YES;
  }
  
  result = [_client select:newFolder];
  if (![[result valueForKey:@"result"] boolValue]) {
    [self errorWithFormat:@"could not select URL: %@: %@", _url, result];
    return NO;
  }

  return YES;
}

/* folder hierarchy */

- (NSArray *)_getDirectChildren:(NSArray *)_array folderName:(NSString *)_fn {
  /*
    Scans string '_array' for strings which start with the string in '_fn'.
    Then split on '/'.
  */
  NSMutableArray *ma;
  unsigned i, count, prefixlen;
  
  if ((count = [_array count]) < 2)
    /* one entry is the folder itself, so we need at least two */
    return [NSArray array];
  
  prefixlen = [_fn length] + 1;
  ma = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSString *p;
    
    p = [_array objectAtIndex:i];
    if ([p length] <= prefixlen)
      continue;
    if (![p hasPrefix:_fn])
      continue;
    
    /* cut of common part */
    p = [p substringFromIndex:prefixlen];
    
    /* check whether the path is a sub-subfolder path */
    if ([p rangeOfString:@"/"].length > 0)
      continue;
    
    [ma addObject:p];
  }
  
  [ma sortUsingSelector:@selector(compare:)];
  return ma;
}

- (NSString *)imap4Separator {
  return imap4Separator;
}

- (NSString *)imap4FolderNameForURL:(NSURL *)_url removeFileName:(BOOL)_delfn {
  /* a bit hackish, but should be OK */
  NSString *folderName;
  NSArray  *names;

  if (_url == nil)
    return nil;
  
  folderName = [_url path];
  if ([folderName length] == 0)
    return nil;
  if ([folderName characterAtIndex:0] == '/')
    folderName = [folderName substringFromIndex:1];
  
  if (_delfn) folderName = [folderName stringByDeletingLastPathComponent];
  
  if ([[self imap4Separator] isEqualToString:@"/"])
    return folderName;
  
  names = [folderName pathComponents];
  return [names componentsJoinedByString:[self imap4Separator]];
}
- (NSString *)imap4FolderNameForURL:(NSURL *)_url {
  return [self imap4FolderNameForURL:_url removeFileName:NO];
}

- (NSArray *)extractSubfoldersForURL:(NSURL *)_url
  fromResultSet:(NSDictionary *)_result
{
  NSString     *folderName;
  NSDictionary *result;
  NSArray      *names;
  NSArray      *flags;
  
  /* Note: the result is normalized, that is, it contains / as the separator */
  folderName = [_url path];
#if __APPLE__ 
  /* normalized results already have the / in front on libFoundation?! */
  if ([folderName hasPrefix:@"/"]) 
    folderName = [folderName substringFromIndex:1];
#endif
  
  result = [_result valueForKey:@"list"];
  
  /* Cyrus already tells us whether we need to check for children */
  flags = [result objectForKey:folderName];
  if ([flags containsObject:@"hasnochildren"]) {
    if (debugKeys)
      [self logWithFormat:@"folder %@ has no children.", folderName];
    return nil;
  }

  if (debugKeys)
    [self logWithFormat:@"all keys %@: %@", folderName, [result allKeys]];
  
  names = [self _getDirectChildren:[result allKeys] folderName:folderName];
  if (debugKeys) {
    [self debugWithFormat:@"subfolders of %@: %@", folderName, 
	    [names componentsJoinedByString:@","]];
  }
  return names;
}

- (NSArray *)extractFoldersFromResultSet:(NSDictionary *)_result {
  /* Note: the result is normalized, that is, it contains / as the separator */
  return [[_result valueForKey:@"list"] allKeys];
}

- (NSArray *)subfoldersForURL:(NSURL *)_url password:(NSString *)_pwd {
  SOGoMailConnectionEntry *entry;
  NSDictionary  *result;

  if (debugKeys)
    [self debugWithFormat:@"subfolders for URL: %@ ...",[_url absoluteString]];
  
  /* check connection cache */
  
  if ((entry = [self entryForURL:_url password:_pwd]) == nil)
    return nil;
  if ([entry isKindOfClass:[NSException class]])
    return (id)entry;
  
  /* check hierarchy cache */
  
  if ((result = [entry cachedHierarchyResults]) != nil)
    return [self extractSubfoldersForURL:_url fromResultSet:result];
  
  [self debugWithFormat:@"  no folders cached yet .."];
  
  /* fetch _all_ folders */
  
  result = [[entry client] list:@"INBOX" pattern:@"*"];
  if (![[result valueForKey:@"result"] boolValue]) {
    [self errorWithFormat:@"listing of folder failed!"];
    return nil;
  }
  
  /* cache results */
  
  if ([result isNotNull]) {
    if (entry == nil) /* required in case the entry was not setup */
      entry = [self entryForURL:_url];
    
    [entry cacheHierarchyResults:result];
    if (debugCache) {
      [self logWithFormat:@"cached results in entry %@: 0x%p(%d)", 
	      entry, result, [result count]];
    }
  }
  
  /* extract list */
  
  return [self extractSubfoldersForURL:_url fromResultSet:result];
}

- (NSArray *)allFoldersForURL:(NSURL *)_url password:(NSString *)_pwd {
  SOGoMailConnectionEntry *entry;
  NSDictionary  *result;

  if (debugKeys)
    [self debugWithFormat:@"folders for URL: %@ ...",[_url absoluteString]];
  
  /* check connection cache */
  
  if ((entry = [self entryForURL:_url password:_pwd]) == nil)
    return nil;
  if ([entry isKindOfClass:[NSException class]])
    return (id)entry;
  
  /* check hierarchy cache */
  
  if ((result = [entry cachedHierarchyResults]) != nil)
    return [self extractFoldersFromResultSet:result];
  
  [self debugWithFormat:@"  no folders cached yet .."];
  
  /* fetch _all_ folders */
  
  result = [[entry client] list:@"INBOX" pattern:@"*"];
  if (![[result valueForKey:@"result"] boolValue]) {
    [self logWithFormat:@"ERROR: listing of folder failed!"];
    return nil;
  }
  
  /* cache results */
  
  if ([result isNotNull]) {
    if (entry == nil) /* required in case the entry was not setup */
      entry = [self entryForURL:_url];
    
    [entry cacheHierarchyResults:result];
    if (debugCache) {
      [self logWithFormat:@"cached results in entry %@: 0x%p(%d)", 
	      entry, result, [result count]];
    }
  }
  
  /* extract list */
  return [self extractFoldersFromResultSet:result];
}

/* messages */

- (NSArray *)fetchUIDsInURL:(NSURL *)_url qualifier:(id)_qualifier
  sortOrdering:(id)_so password:(NSString *)_pwd
{
  /* 
     sortOrdering can be an NSString, an EOSortOrdering or an array of EOS.
  */
  SOGoMailConnectionEntry *entry;
  NSDictionary  *result;
  NSArray       *uids;
  
  /* check connection cache */
  
  if ((entry = [self entryForURL:_url password:_pwd]) == nil)
    return nil;
  if ([entry isKindOfClass:[NSException class]])
    return (id)entry;
  
  /* check cache */
  
  uids = [entry cachedUIDsForURL:_url qualifier:_qualifier sortOrdering:_so];
  if (uids != nil) {
    if (debugCache) [self logWithFormat:@"reusing uid cache!"];
    return [uids isNotNull] ? uids : nil;
  }
  
  /* select folder and fetch */
  
  if (![self selectFolder:_url inClient:[entry client]])
    return nil;
  
  result = [[entry client] sort:_so qualifier:_qualifier encoding:@"UTF-8"];
  if (![[result valueForKey:@"result"] boolValue]) {
    [self errorWithFormat:@"could not sort contents of URL: %@", _url];
    return nil;
  }
  
  uids = [result valueForKey:@"sort"];
  if (![uids isNotNull]) {
    [self errorWithFormat:@"got no UIDs for URL: %@: %@", _url, result];
    return nil;
  }
  
  /* cache */
  
  [entry cacheUIDs:uids forURL:_url qualifier:_qualifier sortOrdering:_so];
  return uids;
}

- (NSArray *)fetchUIDs:(NSArray *)_uids inURL:(NSURL *)_url
  parts:(NSArray *)_parts password:(NSString *)_pwd
{
  // currently returns a dict?!
  /*
    Allowed fetch keys:
      UID
      BODY.PEEK[<section>]<<partial>>
      BODY            [this is the bodystructure, supported]
      BODYSTRUCTURE   [not supported yet!]
      ENVELOPE        [this is a parsed header, but does not include type]
      FLAGS
      INTERNALDATE
      RFC822
      RFC822.HEADER
      RFC822.SIZE
      RFC822.TEXT
  */
  NGImap4Client *client;
  NSDictionary  *result;
  
  if (_uids == nil)
    return nil;
  if ([_uids count] == 0)
    return nil; // TODO: might break empty folders?! return a dict!
  
  if ((client = [self imap4ClientForURL:_url password:_pwd]) == nil)
    return nil;
  if ([client isKindOfClass:[NSException class]])
    return (id)client;
  
  /* select folder */

  if (![self selectFolder:_url inClient:client])
    return nil;
  
  /* fetch parts */
  
  // TODO: split uids into batches, otherwise Cyrus will complain
  //       => not really important because we batch before (in the sort)
  //       if the list is too long, we get a:
  //       "* BYE Fatal error: word too long"
  
  result = [client fetchUids:_uids parts:_parts];
  if (![[result valueForKey:@"result"] boolValue]) {
    [self errorWithFormat:@"could not fetch %d uids for url: %@",
	    [_uids count],_url];
    return nil;
  }
  
  //[self logWithFormat:@"RESULT: %@", result];
  return (id)result;
}

- (NSException *)expungeAtURL:(NSURL *)_url password:(NSString *)_pwd {
  NGImap4Client *client;
  NSString *p;
  id result;
  
  if ((client = [self imap4ClientForURL:_url password:_pwd]) == nil)
    return nil; // TODO: return error?
  if ([client isKindOfClass:[NSException class]])
    return (id)client;
  
  /* select folder */
  
  p = [self imap4FolderNameForURL:_url removeFileName:NO];
  if (![self selectFolder:p inClient:client])
    return nil;
  
  /* expunge */
  
  result = [client expunge];

  if (![[result valueForKey:@"result"] boolValue]) {
    [self errorWithFormat:@"could not expunge url: %@", _url];
    return nil;
  }
  //[self logWithFormat:@"RESULT: %@", result];
  return nil;
}

- (id)fetchURL:(NSURL *)_url parts:(NSArray *)_parts password:(NSString *)_pwd{
  // currently returns a dict
  NGImap4Client *client;
  NSDictionary  *result;
  NSString *uid;
  
  if (![_url isNotNull]) return nil;
  
  if ((client = [self imap4ClientForURL:_url password:_pwd]) == nil)
    return nil;
  
  /* select folder */
  
  if (![self selectFolder:[self imap4FolderNameForURL:_url removeFileName:YES]
	     inClient:client])
    return nil;
  
  /* fetch parts */
  
  uid = [[_url path] lastPathComponent];
  
  result = [client fetchUids:[NSArray arrayWithObject:uid] parts:_parts];
  if (![[result valueForKey:@"result"] boolValue]) {
    [self errorWithFormat:@"could not fetch url: %@", _url];
    return nil;
  }
  //[self logWithFormat:@"RESULT: %@", result];
  return (id)result;
}

- (NSData *)fetchContentOfBodyPart:(NSString *)_partId
  atURL:(NSURL *)_url password:(NSString *)_pwd
{
  NSString *key;
  NSArray  *parts;
  id result, fetch, body;
  
  if (_partId == nil) return nil;
  
  key   = [@"body[" stringByAppendingString:_partId];
  key   = [key stringByAppendingString:@"]"];
  parts = [NSArray arrayWithObjects:&key count:1];
  
  /* fetch */
  
  result = [self fetchURL:_url parts:parts password:_pwd];
  
  /* process results */
  
  result = [result objectForKey:@"fetch"];
  if ([result count] == 0) { /* did not find part */
    [self errorWithFormat:@"did not find part: %@", _partId];
    return nil;
  }
  
  fetch = [result objectAtIndex:0];
  if ((body = [fetch objectForKey:@"body"]) == nil) {
    [self errorWithFormat:@"did not find body in response: %@", result];
    return nil;
  }
  
  if ((result = [body objectForKey:@"data"]) == nil) {
    [self errorWithFormat:@"did not find data in body: %@", fetch];
    return nil;
  }
  return result;
}

- (NSException *)addOrRemove:(BOOL)_flag flags:(id)_f
  toURL:(NSURL *)_url password:(NSString *)_p
{
  NGImap4Client *client;
  id result;
  
  if (![_url isNotNull]) return nil;
  if (![_f   isNotNull]) return nil;
  
  if ((client = [self imap4ClientForURL:_url password:_p]) == nil)
    return nil;
  
  if (![_f isKindOfClass:[NSArray class]])
    _f = [NSArray arrayWithObjects:&_f count:1];
  
  result = [client storeUid:[[[_url path] lastPathComponent] intValue]
		   add:[NSNumber numberWithBool:_flag]
		   flags:_f];
  if (![[result valueForKey:@"result"] boolValue]) {
    [self logWithFormat:@"DEBUG: fail result %@", result];
    return [NSException exceptionWithHTTPStatus:500 /* server error */
			reason:@"failed to add flag to IMAP4 message"];
  }
  /* result contains 'fetch' key with the current flags */
  return nil;
}
- (NSException *)addFlags:(id)_f toURL:(NSURL *)_u password:(NSString *)_p {
  return [self addOrRemove:YES flags:_f toURL:_u password:_p];
}
- (NSException *)removeFlags:(id)_f toURL:(NSURL *)_u password:(NSString *)_p {
  return [self addOrRemove:NO flags:_f toURL:_u password:_p];
}

- (NSException *)markURLDeleted:(NSURL *)_url password:(NSString *)_p {
  return [self addOrRemove:YES flags:@"Deleted" toURL:_url password:_p];
}

- (NSException *)postData:(NSData *)_data flags:(id)_f
  toFolderURL:(NSURL *)_url password:(NSString *)_p
{
  NGImap4Client *client;
  id result;
  
  if (![_url isNotNull]) return nil;
  if (![_f   isNotNull]) _f = [NSArray array];
  
  if ((client = [self imap4ClientForURL:_url password:_p]) == nil)
    return nil;
  
  if (![_f isKindOfClass:[NSArray class]])
    _f = [NSArray arrayWithObjects:&_f count:1];
  
  result = [client append:_data 
		   toFolder:[self imap4FolderNameForURL:_url]
		   withFlags:_f];
  if (![[result valueForKey:@"result"] boolValue]) {
    [self logWithFormat:@"DEBUG: fail result %@", result];
    return [NSException exceptionWithHTTPStatus:500 /* server error */
			reason:@"failed to store message to IMAP4 message"];
  }
  /* result contains 'fetch' key with the current flags */
  return nil;
}

/* managing folders */

- (BOOL)isPermissionDeniedResult:(id)_result {
  if ([[_result valueForKey:@"result"] intValue] != 0)
    return NO;
  
  return [[_result valueForKey:@"reason"] 
	           isEqualToString:@"Permission denied"];
}

- (NSException *)createMailbox:(NSString *)_mailbox atURL:(NSURL *)_url
  password:(NSString *)_pwd
{
  SOGoMailConnectionEntry *entry;
  NSString *newPath;
  id       result;

  /* check connection cache */
  
  if ((entry = [self entryForURL:_url password:_pwd]) == nil) {
    return [NSException exceptionWithHTTPStatus:404 /* Not Found */
			reason:@"did not find IMAP4 folder"];
  }
  if ([entry isKindOfClass:[NSException class]])
    return (id)entry;

  /* construct path */
  
  newPath = [self imap4FolderNameForURL:_url];
  newPath = [newPath stringByAppendingString:[self imap4Separator]];
  newPath = [newPath stringByAppendingString:_mailbox];
  
  /* create */
  
  result = [[entry client] create:newPath];
  if ([self isPermissionDeniedResult:result]) {
    return [NSException exceptionWithHTTPStatus:403 /* forbidden */
			reason:@"creation of folders not allowed"];
  }
  else if ([[result valueForKey:@"result"] intValue] == 0) {
    return [NSException exceptionWithHTTPStatus:500 /* server error */
			reason:[result valueForKey:@"reason"]];
  }
  
  [entry flushFolderHierarchyCache];
  // [self debugWithFormat:@"created mailbox: %@: %@", newPath, result];
  return nil;
}

- (NSException *)deleteMailboxAtURL:(NSURL *)_url password:(NSString *)_pwd {
  SOGoMailConnectionEntry *entry;
  NSString *path;
  id       result;

  /* check connection cache */
  
  if ((entry = [self entryForURL:_url password:_pwd]) == nil) {
    return [NSException exceptionWithHTTPStatus:404 /* Not Found */
			reason:@"did not find IMAP4 folder"];
  }
  if ([entry isKindOfClass:[NSException class]])
    return (id)entry;
  
  /* delete */
  
  path   = [self imap4FolderNameForURL:_url];
  result = [[entry client] delete:path];
  
  if ([self isPermissionDeniedResult:result]) {
    return [NSException exceptionWithHTTPStatus:403 /* forbidden */
			reason:@"creation of folders not allowed"];
  }
  else if ([[result valueForKey:@"result"] intValue] == 0) {
    return [NSException exceptionWithHTTPStatus:500 /* server error */
			reason:[result valueForKey:@"reason"]];
  }

  [entry flushFolderHierarchyCache];
#if 0
  [self debugWithFormat:@"delete mailbox %@: %@", _url, result];
#endif
  return nil;
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

@end /* SOGoMailManager */
