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
// $Id: SxFolder.m 1 2004-08-20 11:17:52Z znek $

#include "SxFolder.h"
#include "SxObject.h"
#include "OLDavPropMapper.h"
#include "SxAuthenticator.h"
#include <NGObjWeb/WEClientCapabilities.h>
#include <NGObjWeb/SoObjectResultEntry.h>
#include "mapiflags.h"
#include "common.h"
#include <time.h>

@interface NSObject(RSS)
- (id)rssInContext:(id)_ctx;
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
  int DidCheckClass = -1;
  
  Class clazz;
  id    pm;
  
  if (self->subPropMapper) 
    return self->subPropMapper;

  if (DidCheckClass == 0)
    return nil;
  
  if ((clazz = NSClassFromString(@"ZLPropMapper")) == Nil) {
    static BOOL didNote = NO;
    if (!didNote)
      [self logWithFormat:@"Note: no ZideLook support installed."];
    didNote = YES;
    DidCheckClass = 0;
    return nil;
  }
  else
    DidCheckClass = 1;
  
  if ((pm = [[[clazz alloc] initWithDictionary:nil] autorelease]) == nil) {
    [self logWithFormat:@"could not instantiate prop mapper: %@", clazz];
    return nil;
  }
  
  if ([pm respondsToSelector:@selector(propertySetNamed:)])
    self->subPropMapper = [[NSArray alloc] initWithObjects:&pm count:1];
  else
    [self logWithFormat:@"ZLPropMapper has not propertySetNamed: ?"];
  
  return self->subPropMapper;
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
  
  if (_ctx == nil) _ctx = [[WOApplication application] context];
  
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
  
  if ((ctx = [[WOApplication application] context]) == nil)
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

/* common CDO attributes */

- (int)cdoContentUnread {
  return 0;
}
- (int)unreadcount {
  return [self cdoContentUnread];
}

- (int)cdoContentCount {
  // TODO: perform (a cached !) query using the backend
  [self logWithFormat:@"should deliver content-count ..."];
  return 10000;
}

- (int)cdoDisplayType {
  return 0;
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

- (int)cdoAccessLevel {
  return 1; /* TODO: don't know what this means :-( */
}

- (id)cdoAccess {
  // TODO: use proxy to find out, how we are supposed to format the number
  unsigned int permissionMask = 0;

  static NSDictionary *typing = nil;
  if (typing == nil) {
    typing = [[NSDictionary alloc] 
	       initWithObjectsAndKeys:
		 @"int", 
	         @"{urn:uuid:c2f41010-65b3-11d1-a29f-00aa00c14882/}dt",
	       nil];
  }
  
  permissionMask = 0;
  
  if ([self isReadAllowed])         
    permissionMask |= MAPI_ACCESS_READ; // 0x02
  if ([self isModificationAllowed]) 
    permissionMask |= MAPI_ACCESS_MODIFY; // 0x01
  if ([self isItemCreationAllowed]) 
    permissionMask |= MAPI_ACCESS_CREATE_CONTENTS;  // 0x10
  if ([self isFolderCreationAllowed]) 
    permissionMask |= MAPI_ACCESS_CREATE_HIERARCHY; // 0x08
  if ([self isDeletionAllowed])
    permissionMask |= MAPI_ACCESS_DELETE; // 0x04
  
  permissionMask |= 0x00000020; // always add leading (create assoc?)
  
  // found out why 63:
  // 63  - 111111
  // x01 - 000001 - modify
  // x02 - 000010 - read
  // x04 - 000100 - delete
  // x08 - 001000 - create hier
  // x10 - 010000 - create item
  // x20 - 100000 - ? (create associated ?)
  // permissionMask = 63; // 0x3F
  
  return [SoWebDAVValue valueForObject:[NSNumber numberWithInt:permissionMask]
			attributes:typing];
}

- (int)cdoContainerContents {
  return 1; /* TODO: don't know what this means :-( */
}

- (int)cdoFolderTypeCode {
  return 1; /* TODO: don't know what this means :-( */
}

- (BOOL)showHomePageURL {
  return NO;
}

- (NSString *)homePageURL {
  return @"http://www.skyrix.de/";
}

- (id)encodedHomePageURL {
  return [[self homePageURL] asEncodedHomePageURL:[self showHomePageURL]];
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
    if (_ctx == nil) _ctx = [[WOApplication application] context];
    if ((b = [super baseURLInContext:_ctx])) {
      if ([b hasSuffix:@"/"])
	self->baseURL = [b copy];
      else
	self->baseURL = [[b stringByAppendingString:@"/"] copy];
      self->baseContext = _ctx;
    }
  }
  return self->baseURL;
}

- (NSString *)baseURL {
  return [self baseURLInContext:[[WOApplication application] context]];
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
  
  return NO;
}

- (Class)recordClassForKey:(NSString *)_key {
  return Nil;
}

- (id)childForNewKey:(NSString *)_key inContext:(id)_ctx {
  return nil;
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

- (id)lookupRangeQueryFolder:(NSString *)_name inContext:(id)_ctx {
  // This method should be deprecated, the SoWebDAVDispatcher catches
  // the _range_ query, turns it into a WebDAV bulk-query and patches the 
  // URI of the request
  NSString *s;
  NSArray  *ids;
  
  s   = [_name substringFromIndex:7];
  ids = [s componentsSeparatedByString:@"_"];
  
  // TODO: translate this into a BPROPFIND !
  
  [self logWithFormat:
          @"process range query (this method should not be called anymore !): "
          @"%@: %@", _name, ids];
  return nil;
}

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
  [response appendContentString:s];
  return response;
}

- (id)lookupName:(NSString *)_name inContext:(id)_ctx acquire:(BOOL)_ac {
  NSString *nkey;
  Class    recClass;
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
  
  /* normalize key */
  
  nkey = [self normalizeKey:_name];
  //[self debugWithFormat:@"  normalized '%@'=>'%@'", _name, nkey];

  // TODO: add some validity checking based on type-cache
  
  /* check cache */
  // TODO: add a cache ...
  
  /* perform query */
  
  if ([self isNewKey:nkey inContext:_ctx])
    return [self childForNewKey:nkey inContext:_ctx];
  
  recClass = [self recordClassForKey:nkey];
  value = [[recClass alloc] initWithName:nkey inFolder:self];
  if (value == nil) {
    [self logWithFormat:@"ERROR: got no record for key %@", nkey];
    return nil;
  }
  value = [value autorelease];
  
  // TODO: add to cache
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
  [self logWithFormat:@"GET on folder, just saying OK"];
  return r;
}

- (id)PUTAction:(id)_ctx {
  /* per default, return nothing ... */
  WOResponse *r = [(WOContext *)_ctx response];
  [r setStatus:200 /* Ok */];
  [self logWithFormat:@"PUT on folder, just saying OK"];
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
  
  if (plist == nil) {
    NSBundle *bundle;
    NSString *path;
    
    bundle = [NSBundle bundleForClass:[SxFolder class]];
    path   = [bundle pathForResource:@"DAVPropSets" ofType:@"plist"];
    plist = [[NSDictionary alloc] initWithContentsOfFile:path];
  }
  return plist;
}

- (NSSet *)propertySetNamed:(NSString *)_name {
  static NSMutableDictionary *propsets = nil;
  NSDictionary *plist;
  NSArray *array;
  NSSet   *set;
  NSEnumerator *enumerator;
  id           obj;

  enumerator = [[self subPropMapper] objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    id res;
    
    if ((res = [obj propertySetNamed:_name]))
      return res;
  }
  if ((set = [propsets objectForKey:_name]))
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
    return nil;
  }
  
  set = [[NSSet alloc] initWithArray:array];
  [propsets setObject:set forKey:_name];
  return [set autorelease];
}

/* ZideLook queries common for all folders */

- (int)refreshInterval {
  static int ref = -1;
  if (ref == -1) {
    ref = [[[NSUserDefaults standardUserDefaults] 
             objectForKey:@"ZLFolderRefresh"] intValue];
  }
  return ref > 0 ? ref : 300; /* every five minutes */
}

- (int)zlGenerationCount {
  /* 
     This is used by ZideLook to track folder changes.
     TODO: implement folder-change detection ... (snapshot of last
     id/version set contained in the folder)
  */
  return (time(NULL) - 1047000000) / [self refreshInterval];
}

- (BOOL)isMsgInfoQuery:(EOFetchSpecification *)_fs {
  // ZL messages
  static NSSet *zlSet = nil;
  id propNames;
  
  if (zlSet == nil) 
    zlSet = [[self propertySetNamed:@"ZideLookFolderQuery1"] retain];
  if ((propNames = [_fs selectedWebDAVPropertyNames]) == nil)
    return NO;
  if ([propNames count] > [zlSet count])
    return NO;
  
  propNames = [NSSet setWithArray:propNames];
  if (![propNames isSubsetOfSet:zlSet])
    return NO;
  
  return YES;
}

- (BOOL)isSubFolderQuery:(EOFetchSpecification *)_fs {
  // subfolders
  static NSSet *zlSet  = nil;
  static NSSet *evoSet = nil;
  id propNames;

  if (zlSet == nil) 
    zlSet = [[self propertySetNamed:@"ZideLookFolderQuery2"] retain];
  if (evoSet == nil) 
    evoSet = [[self propertySetNamed:@"EvolutionSubFolderSet"] retain];
  
  if ((propNames = [_fs selectedWebDAVPropertyNames]) == nil)
    return NO;

  if ([propNames count] > [zlSet count] &&
      [propNames count] > [evoSet count])
    return NO;
  
  propNames = [NSSet setWithArray:propNames];
  
  if ([propNames isSubsetOfSet:zlSet])
    return YES;
  
  if ([propNames isSubsetOfSet:evoSet])
    return YES;
  
  return NO;
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

- (id)performMsgInfoQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  /* the second query by ZideLook, get basic message infos */
  /* davDisplayName,davResourceType,outlookMessageClass,cdoDisplayType */
  [self logWithFormat:@"ZL Messages Query [depth=%@] (returning nothing): %@",
          [[(WOContext *)_ctx request] headerForKey:@"depth"],
          [[_fs selectedWebDAVPropertyNames] componentsJoinedByString:@","]];
  return [NSArray array];
}

- (id)performSubFolderQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  /* the third query by ZideLook, get all subfolder infos */
  /*
    davDisplayName,davResourceType,cdoDepth,cdoParentDisplay,cdoRowType,
    cdoAccess,cdoContainerClass,cdoContainerHierachy,cdoContainerContents,
    cdoDisplayType,outlookFolderClass
  */
  static Class entryClass = Nil;
  NSArray        *names;
  NSMutableArray *objects;
  NSArray        *queriedAttrNames;
  unsigned i, count;
  
  if (entryClass == Nil) 
    entryClass = NSClassFromString(@"SoObjectResultEntry");
  if ([self doExplainQueries]) {
    [self logWithFormat:@"ZL Subfolder Query [depth=%@]: %@",
            [[(WOContext *)_ctx request] headerForKey:@"depth"],
            [[_fs selectedWebDAVPropertyNames] componentsJoinedByString:@","]];
  }
  
  if ((names = (id)[self davChildKeysInContext:_ctx]) == nil) {
    [self logWithFormat:@"%s: missing names for fs %@",
          __PRETTY_FUNCTION__, _fs];
    return [NSArray array];
  }

  names = [[[NSArray alloc] 
             initWithObjectsFromEnumerator:(id)names] autorelease];
  if ((count = [names count]) == 0)
    return [NSArray array];
  
  if ([self doExplainQueries]) {
    [self logWithFormat:@"  deliver objects for toOneRelation: %@", 
	    [names componentsJoinedByString:@","]];
  }
  
  queriedAttrNames = [_fs selectedWebDAVPropertyNames];
  objects = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSString *name, *url;
    id child, rec;
    
    name  = [names objectAtIndex:i];
    child = [self lookupName:name inContext:_ctx acquire:NO];

    if (child == nil)             continue;
    if (![child davIsCollection]) continue;
    
    url = [child baseURLInContext:_ctx];
    rec = (queriedAttrNames == nil)
      ? child
      : [child valuesForKeys:queriedAttrNames];
    rec = [[entryClass alloc] initWithURI:url object:child values:rec];
    [objects addObject:rec];
    [rec release];
  }
  return objects;
}

/* deprecated */

- (BOOL)isZideLookFolderQuery1:(EOFetchSpecification *)_fs {
  return [self isMsgInfoQuery:_fs];
}

- (BOOL)isZideLookFolderQuery2:(EOFetchSpecification *)_fs {
  return [self isSubFolderQuery:_fs];
}

- (id)performZideLookQuery1:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  return [self performMsgInfoQuery:_fs inContext:_ctx];
}

- (id)performZideLookQuery2:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  return [self performSubFolderQuery:_fs inContext:_ctx];
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
