/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#include "SxFolder.h"
#include "SxObject.h"
#include "OLDavPropMapper.h"
#include "NGResourceLocator+ZSF.h"
#include <Main/SxAuthenticator.h>
#include <NGObjWeb/WEClientCapabilities.h>
#include <NGObjWeb/SoObjectResultEntry.h>
#include "common.h"
#include <time.h>

@interface NSObject(RSS)
- (id)rssInContext:(id)_ctx;
@end

@interface SxFolder(ZL2)
- (id)lookupRangeQueryFolder:(NSString *)_name inContext:(id)_ctx;
@end

@implementation SxFolder

static BOOL     explainOn   = YES;
static BOOL     debugLookup = NO;
static BOOL     debugOn     = NO;
static NSString *cachePath  = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  explainOn = [ud boolForKey:@"SxExplain"];
  debugOn   = [ud boolForKey:@"SxFolderDebugEnabled"];
  cachePath = [ud stringForKey:@"SxCachePath"];
  if (cachePath == nil) cachePath = @"/var/cache/zidestore";
}

- (NSArray *)subPropMapper {
  // DEPRECATED (was for ZL support)
  return nil;
}

- (id)initWithName:(NSString *)_name inContainer:(id)_container {
  if ((self = [super init])) {
    self->nameInContainer    = [_name copy];
    [self setContainer:_container];
  }
  return self;
}

- (void)dealloc {
  if ([self->container shouldRetainAsSoContainer])
    [self->container release];
  
  [self->subPropMapper   release];
  [self->baseURL         release];
  [self->nameInContainer release];
  [super dealloc];
}

/* accessors */

- (BOOL)doExplainQueries {
  return explainOn;
}

/* hierarchy */

- (void)setContainer:(id)_container {
  id tmp;
  
  if (self->container == _container)
    return;

  tmp = _container;
  if ([tmp shouldRetainAsSoContainer])
    tmp = [tmp retain];
  
  if ([self->container shouldRetainAsSoContainer])
    [self->container release];
  
  self->container = tmp;
}
- (id)container {
  return self->container;
}

- (void)setNameInContainer:(NSString *)_name {
  ASSIGNCOPY(self->nameInContainer, _name);
}
- (NSString *)nameInContainer {
  return self->nameInContainer;
}

/* OGo entry point */

- (LSCommandContext *)commandContextInContext:(id)_ctx {
  SxAuthenticator  *auth;
  LSCommandContext *ctx;
  
  if (_ctx == nil) 
    _ctx = [(WOApplication *)[WOApplication application] context];
  
  if ((auth = [self authenticatorInContext:_ctx]) == nil) {
    [self logWithFormat:@"ERROR: got no authenticator for context: %@", _ctx];
    return nil;
  }
  if ((ctx = [auth commandContextInContext:_ctx]) == nil) {
    [self logWithFormat:@"ERROR: got no OGo context from authenticator: %@",
            auth];
    return nil;
  }
  return ctx;
}

/* attribute mappings */

- (id)davAttributeMapInContext:(id)_ctx {
  static OLDavPropMapper *davMap = nil;
  if (davMap == nil) {
    davMap = [[OLDavPropMapper alloc] initWithDictionary:
		    [[self class] defaultWebDAVAttributeMap]];
  }
  return davMap;
}

/* ZideLook specialties */

- (NSString *)personalFolderInfoKey {
  WOContext *ctx;
  NSString *login;
  NSString *key;
  id auth;
  
  if ((ctx = [(WOApplication *)[WOApplication application] context]) == nil)
    return nil;
  if ((auth = [self authenticatorInContext:ctx]) == nil)
    return nil;
  
  if ((login = [[auth userInContext:ctx] login]) == nil)
    return nil;
  
  key = [NSString stringWithFormat:@"%@::%@", 
                    login, [self baseURLInContext:ctx]];
  [self logWithFormat:@"made key: %@", key];
  return key;
}

- (NSString *)associatedContentsPath {
  return [cachePath stringByAppendingPathComponent:
                      @"AssociatedContents.plist"];
}

- (void)setAssociatedContents:(NSString *)_value {
  NSMutableDictionary *dict;
  NSString *path;
  
  [self logWithFormat:@"set assoc contents: %@", _value];
  path = [self associatedContentsPath];
  dict = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
  if (dict == nil)
    dict = [[NSMutableDictionary alloc] initWithCapacity:4];
  
  if ([_value isNotNull])
    [dict setObject:_value forKey:[self personalFolderInfoKey]];
  else
    [dict removeObjectForKey:[self personalFolderInfoKey]];
  
  if (![dict writeToFile:path atomically:YES])
    [self logWithFormat:@"WARNING: could not write assoc contents: %@", path];
  
  [dict release];
}
- (NSString *)associatedContents {
  NSDictionary *dict;
  NSString *value;
  NSString *path;
  
  path = [self associatedContentsPath];
  dict = [[NSDictionary alloc] initWithContentsOfFile:path];
  if (dict == nil) return nil;
  
  value = [[[dict objectForKey:[self personalFolderInfoKey]] 
                  copy] autorelease];
  [dict release];
  [self logWithFormat:@"assoc-contents: %@", value];
  return value;
}

/* Exchange properties */

- (NSString *)outlookFolderClass {
  return @"IPF.Folder";
}

- (BOOL)isReadAllowed {
  return YES;
}
- (BOOL)isModificationAllowed {
  return YES;
}
- (BOOL)isItemCreationAllowed {
  return YES;
}
- (BOOL)isFolderCreationAllowed {
  return NO;
}
- (BOOL)isDeletionAllowed {
  /* folders should not be deleted */
  return NO;
}

/* file extension */

- (NSString *)fileExtensionForOutlook {
  /* either Evolution or Outlook */
  return @"EML";
}

- (NSString *)fileExtensionForFileSystem {
  /* Cadaver, MacOSX, Nautilus ... */
  return nil;
}

- (NSString *)fileExtensionForChildrenInContext:(id)_ctx {
  NSString *ua;
  
  ua = [[[(WOContext *)_ctx request] clientCapabilities] userAgentType];
  
  if ([ua hasPrefix:@"Cadaver"])     return [self fileExtensionForFileSystem];
  if ([ua hasPrefix:@"MacOSXDAVFS"]) return [self fileExtensionForFileSystem];
  if ([ua hasPrefix:@"GNOME-VFS"])   return [self fileExtensionForFileSystem];
  
  if ([ua hasPrefix:@"MSOutlook"])   return [self fileExtensionForOutlook];
  if ([ua hasPrefix:@"Evolution"])   return [self fileExtensionForOutlook];
  
  [self logWithFormat:@"delivering raw filename to: %@", ua];
  return nil;
}

/* URL processing */

- (NSString *)baseURLInContext:(id)_ctx {
  if (self->baseURL != nil) {
    if (_ctx != nil && _ctx != self->baseContext) {
      /* context changed */
      [self->baseURL release];
      self->baseURL = nil;
    }
  }
  if (self->baseURL == nil) {
    NSString *b;
    
    if (_ctx == nil) 
      _ctx = [(WOApplication *)[WOApplication application] context];
    
    if ((b = [super baseURLInContext:_ctx]) != nil) {
      if (![b hasSuffix:@"/"])
	b = [b stringByAppendingString:@"/"];
      
      self->baseURL = [b copy];
      self->baseContext = _ctx;
    }
  }
  return self->baseURL;
}

- (NSString *)baseURL {
  return [self baseURLInContext:
		 [(WOApplication *)[WOApplication application] context]];
}

/* name lookup */

- (NSString *)normalizeKey:(NSString *)_key {
  /* useful for content-negotiation */
  NSString *pe;
  
  if ([(pe = [_key pathExtension]) length] > 0)
    _key = [_key stringByDeletingPathExtension];

  return _key;
}

- (BOOL)isNewKey:(NSString *)_key inContext:(id)_ctx {
  if ([_key length] == 0)
    return YES;
  
  if ([_key rangeOfString:@" "].length > 0)
    return YES;
  if ([_key rangeOfString:@"@"].length > 0)
    return YES;
  if ([_key rangeOfString:@"-"].length > 0)
    return YES;
  
  if (!isdigit([_key characterAtIndex:0]))
    /* as long as we don't allow login names as keys ... */
    return YES;
  
  // TODO: what exactly is the gain of not fetching the EO? In which cases is
  //       the EO not used?
  //       maybe we should use the access manager to check for existance?
  
  return NO;
}

- (Class)recordClassForKey:(NSString *)_key {
  [self logWithFormat:@"Note: class does not specify class for key: '%@'",
	  _key];
  return Nil;
}

- (id)childForNewKey:(NSString *)_key inContext:(id)_ctx {
  [self logWithFormat:@"Note: class does not specify object for new key: '%@'",
	  _key];
  return nil;
}

- (id)childForExistingKey:(NSString *)_key inContext:(id)_ctx {
  Class recClass;
  id value;
  
  recClass = [self recordClassForKey:_key];
  if ([recClass instancesRespondToSelector:@selector(initWithName:inFolder:)])
    // TODO: deprecated?!
    value = [[recClass alloc] initWithName:_key inFolder:self];
  else
    value = [[recClass alloc] initWithName:_key inContainer:self];
  
  return [value autorelease];
}

- (BOOL)shouldIgnoreName:(NSString *)_name inContext:(id)_ctx {
  /* check some artificial keys ... */
  unsigned len = [_name length];
  
  if (len == 0)
    return NO;
  
  if ([_name characterAtIndex:0] == '.') {
    if ([_name hasPrefix:@"._"]) /* OSX resource forks */
      return YES;
    if ([_name isEqualToString:@".DS_Store"]) /* OSX indexer */
      return YES;
    if ([_name isEqualToString:@".hidden"]) /* OSX .hidden file */
      return YES;
    if ([_name isEqualToString:@".autodiskmounted"]) /* OSX */
      return YES;
  }
  return NO;
}

/* IDs and Versions */

- (NSString *)getIDsAndVersionsInContext:(id)_ctx {
  // return all IDs and Versions in this format:
  //   ID:Version\n
  [self logWithFormat:@"TODO: implement -getIDsAndVersionsInContext: !"];
  return @"";
}

- (id)getIDsAndVersionsAction:(id)_ctx {
  WOResponse *response;
  NSString *s;
  
  if ((s = [self getIDsAndVersionsInContext:_ctx]) == nil)
    return nil;
  
  response = [(WOContext *)_ctx response];
  [response setStatus:200]; /* OK */
  [response setHeader:@"text/plain" forKey:@"content-type"];
  [response setHeader:@"close"      forKey:@"connection"];
  [response appendContentString:s];
  return response;
}

- (id)performETagsQuery:(EOFetchSpecification *)_fspec inContext:(id)_ctx {
  // TODO: rewrite getIDsAndVersionsInContext: to return some array/dict
  NSMutableArray *entries;
  NSString *csv;
  NSArray  *lines;
  unsigned i, count;
  
  if ((csv = [self getIDsAndVersionsInContext:_ctx]) == nil)
    return nil;
  
  if ([csv length] == 0)
    return [NSArray array];
  
  lines   = [csv componentsSeparatedByString:@"\n"];
  count   = [lines count];
  entries = [NSMutableArray arrayWithCapacity:count];
  
  // [self logWithFormat:@"process lines: %@", lines];
  
  for (i = 0; i < count; i++) {
    NSDictionary *record;
    NSString *line, *pkey, *etag, *url;
    id       keys[3], values[3];
    NSRange  r;
    
    line = [lines objectAtIndex:i];
    r    = [line rangeOfString:@":"];
    if (r.length == 0) {
      [self logWithFormat:@"ERROR: malformed getIDsAndVersions file!"];
      continue;
    }
    
    /* NOTE: do _not_ change etag, used in other places! */
    pkey = [line substringToIndex:r.location];
    etag = line;
    
    url  = [[NSString alloc] initWithFormat:@"%@%@.ics", [self baseURL], pkey];
    
    keys[0] = @"{DAV:}href";      values[0] = url;
    keys[1] = @"davEntityTag";    values[1] = etag;
    keys[2] = @"davResourceType"; values[2] = @"";
    
    record = [[NSDictionary alloc] initWithObjects:values forKeys:keys
				   count:3];
    [entries addObject:record];
    [record release]; record = nil;
    [url    release]; url    = nil;
  }
  return entries;
}

/* name lookup */

- (id)lookupName:(NSString *)_name inContext:(id)_ctx acquire:(BOOL)_ac {
  NSString *nkey;
  id value;

  /* some special ZideStore things ... */
  
  if ([_name hasPrefix:@"_range_"])
    return [self lookupRangeQueryFolder:_name inContext:_ctx];
  if ([_name isEqualToString:@"getIDsAndVersions"])
    return [self getIDsAndVersionsAction:_ctx];
  
  if ([self shouldIgnoreName:_name inContext:_ctx])
    return nil; /* not found */
  
  if ([_name hasSuffix:@".rss"] || [_name hasSuffix:@".xml"]) {
    if ([self respondsToSelector:@selector(rssInContext:)])
      return [self rssInContext:_ctx];
  }
  
  /* check methods */
  
  if ((value = [super lookupName:_name inContext:_ctx acquire:_ac])) {
    if (debugLookup)
      [self debugWithFormat:@"  value from superclass: %@", value];
    return value;
  }
  
  /* to avoid a warning, let the dispatcher do the OPTIONS work */
  if ([_name isEqualToString:@"OPTIONS"])
    return nil;
  
  /* normalize key */
  
  nkey = [self normalizeKey:_name];
  //[self debugWithFormat:@"  normalized '%@'=>'%@'", _name, nkey];

  // TODO: add some validity checking based on type-cache
  
  /* check cache */
  // TODO: add a cache ...
  
  /* perform query */
  
  value = [self isNewKey:nkey inContext:_ctx]
    ? [self childForNewKey:nkey inContext:_ctx]
    : [self childForExistingKey:nkey inContext:_ctx];
  
  /*
    Important:
    
    We should *not* return a 404 exception. If the lookup fails, this will
    be handled by the object request handler! In case we return an exception
    all method dispatching will _stop_.
    
    For example a PUT for a new object would not succeed since the URL of the
    new object won't be found. (this 'path info' stuff is otherwise handled
    by the request handler if we correctly return nil)
    
    TODO: we changed this recently. Maybe other code depends on the 404?
  */
  return value;
}

/* actions */

- (NSString *)defaultMethodNameInContext:(id)_ctx {
  if ([[self soClass] hasKey:@"view" inContext:_ctx])
    return @"view";
  return nil;
}

- (id)GETAction:(id)_ctx {
  /* per default, return nothing ... */
  WOResponse *r = [(WOContext *)_ctx response];
  NSString   *defName;
  
  if ((defName = [self defaultMethodNameInContext:_ctx]) != nil) {
    [r setStatus:302 /* moved */];
    [r setHeader:[[self baseURL] stringByAppendingPathComponent:defName]
       forKey:@"location"];
    return r;
  }
  
  [r setStatus:200 /* Ok */];
  [self logWithFormat:@"GET on folder, returning nothing."];
  return r;
}

- (id)PUTAction:(id)_ctx {
  /* per default, return nothing ... */
  WOResponse *r;

  r = [(WOContext *)_ctx response];
  [r setStatus:405 /* forbidden */];
  [self logWithFormat:
	  @"PUT on folder (attempt to create an object?), path-info: '%@'", 
          [_ctx pathInfo]];
  return r;
}

- (id)DELETEAction:(id)_ctx {
  if (![self isDeletionAllowed]) {
    [self logWithFormat:@"tried to delete protected folder"];
    return [NSException exceptionWithHTTPStatus:403 /* forbidden */
			reason:@"folder is protected against deletion"];
  }
  
  return [NSException exceptionWithHTTPStatus:500
		      reason:@"folder deletion is not implemented"];
}

/* property sets */

- (NSDictionary *)propsetPlist {
  static NSDictionary *plist = nil;
  NGResourceLocator *locator;
  NSString *path;
  
  if (plist != nil)
    return plist;
    
  locator = [NGResourceLocator zsfResourceLocator];
  if ((path = [locator lookupFileWithName:@"DAVPropSets.plist"]) != nil)
    plist = [[NSDictionary alloc] initWithContentsOfFile:path];
  else
    [self logWithFormat:@"ERROR: did not find DAVPropSets.plist!"];
  return plist;
}

- (NSSet *)propertySetNamed:(NSString *)_name {
  static NSMutableDictionary *propsets = nil;
  NSDictionary *plist;
  NSArray      *array;
  NSSet        *set;
  NSEnumerator *enumerator;
  id           obj;

  enumerator = [[self subPropMapper] objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil) {
    id res;
    
    if ((res = [obj propertySetNamed:_name]))
      return res;
  }
  if ((set = [propsets objectForKey:_name]) != nil)
    return set;
  if (propsets == nil) 
    propsets = [[NSMutableDictionary alloc] init];
  
  if ((plist = [self propsetPlist]) == nil)
    return nil;
  if ((array = [plist objectForKey:_name]) == nil) {
    static NSMutableSet *warnSets = nil;
    if (warnSets == nil) warnSets = [[NSMutableSet alloc] initWithCapacity:8];
    if (![warnSets containsObject:_name]) {
      [self logWithFormat:@"Note: did not find property set '%@'", _name];
      [warnSets addObject:_name];
    }
    // TODO: we might want to fallback to some standard DAV property set
    return nil;
  }
  
  set = [[NSSet alloc] initWithArray:array];
  [propsets setObject:set forKey:_name];
  return [set autorelease];
}

/* queries common for all folders */

- (BOOL)isETagsQuery:(EOFetchSpecification *)_fs {
  // subfolders
  static NSSet *listSet  = nil;
  id propNames;
  
  if (listSet == nil) 
    listSet = [[self propertySetNamed:@"QueryETagsSet"] retain];
  
  if ((propNames = [_fs selectedWebDAVPropertyNames]) == nil)
    return NO;
  
  if ([propNames count] > [listSet count])
    return NO;
  
  propNames = [NSSet setWithArray:propNames];
  
  return [propNames isSubsetOfSet:listSet];
}

- (BOOL)isWebDAVListQuery:(EOFetchSpecification *)_fs {
  // subfolders
  static NSSet *listSet  = nil;
  id propNames;
  
  if (listSet == nil) 
    listSet = [[self propertySetNamed:@"CadaverListSet"] retain];
  
  if ((propNames = [_fs selectedWebDAVPropertyNames]) == nil)
    return NO;
  
  if ([propNames count] > [listSet count])
    return NO;
  
  propNames = [NSSet setWithArray:propNames];
  
  return [propNames isSubsetOfSet:listSet];
}

/* KVC */

- (id)valueForUndefinedKey:(NSString *)_key {
  if (debugOn) [self debugWithFormat:@"queried undefined KVC key: '%@'", _key];
  return nil;
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

- (NSString *)loggingPrefix {
  return [NSString stringWithFormat:@"|%@:%@|",
                     NSStringFromClass([self class]), 
                     [self nameInContainer]];
}

@end /* SxFolder */

@implementation NSObject(ContainerRetainManagement)

/* 
  Whether a child is supposed to retain this container.
*/
- (BOOL)shouldRetainAsSoContainer {
  return YES;
}

@end /* NSObject(ContainerRetainManagement) */
