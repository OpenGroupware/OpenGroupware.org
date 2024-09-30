/*
  Copyright (C) 2000-2005 SKYRIX Software AG

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

#include "SkyDocumentManagerImp.h"
#include <LSFoundation/LSTypeManager.h>
#include <LSFoundation/LSCommandContext.h>
#include <EOControl/EOKeyGlobalID.h>
#include "common.h"

@interface NSObject(GIDs)
- (EOGlobalID *)globalID;
@end

@implementation SkyDocumentManager

- (id)initWithContext:(LSCommandContext *)_context {
  NSAssert(_context, @"missing context parameter ..");
  
  if ((self = [super init])) {
    self->context = [_context retain];
  }
  return self;
}
- (id)init {
  return [self initWithContext:nil];
}

- (void)dealloc {
  [self->urlToGID    release];
  [self->gidResolver release];
  [self->context     release];
  [super dealloc];
}

/* cache control */

- (void)flushCaches {
  [self->urlToGID release]; self->urlToGID = nil;
}

/* accessors */

- (id)context {
  return self->context;
}

/* resolver lookup */

- (id)_findResolverForGlobalID:(EOGlobalID *)_gid {
  static Class EOKeyGlobalIDClass = Nil;
  NGBundleManager *bm;
  NSEnumerator *resolverResources;
  NSDictionary *bundleConfig;
  NSString     *resourceName;
  NSBundle     *bundle;
  
  if (EOKeyGlobalIDClass == Nil)
    EOKeyGlobalIDClass = [EOKeyGlobalID class];
  
  if ((bm = [NGBundleManager defaultBundleManager]) == nil) {
    NSLog(@"%s: missing bundle manager ..", __PRETTY_FUNCTION__);
    return nil;
  }

#if DEBUG && 0
  NSLog(@"%s: find resolver for gid %@", __PRETTY_FUNCTION__, _gid);
#endif
  
  resolverResources =
    [[bm providedResourcesOfType:@"SkyDocumentGlobalIDResolver"]
         objectEnumerator];
  
  resourceName = nil;
  while ((bundleConfig = [resolverResources nextObject])) {
    id tmp;
    
#if DEBUG && 0
    if (![bundleConfig respondsToSelector:@selector(objectForKey:)]) {
      NSLog(@"%s: got invalid bundle config: %@",
            __PRETTY_FUNCTION__, bundleConfig);
      bundleConfig = nil;
    }
#endif

    if ((tmp = [bundleConfig objectForKey:@"GlobalIDClass"])) {
      if (NGClassFromString(tmp) != [_gid class])
        continue;
    }
    
    if ((tmp = [bundleConfig objectForKey:@"qualifier"])) {
      EOQualifier *q;
      
      q = [EOQualifier qualifierWithQualifierFormat:tmp];
      
      if (![(id<EOQualifierEvaluation>)q evaluateWithObject:_gid])
        continue;
    }
    
    /* got through */
    
    if ((resourceName = [bundleConfig objectForKey:@"name"]))
      break;
  }

  //NSLog(@"Found RESOLVER: %@, config %@", resourceName, bundleConfig);
  
  if (resourceName == nil) {
    NSLog(@"WARNING(%s): found no resolver for gid %@ in bundles ..",
          __PRETTY_FUNCTION__, _gid);
    return nil;
  }
  
  bundle = [bm bundleProvidingResource:resourceName
               ofType:@"SkyDocumentGlobalIDResolver"];
  
  if (bundle == nil) {
    NSLog(@"WARNING(%s): couldn't find resolver bundle for resource '%@'",
          __PRETTY_FUNCTION__, resourceName);
    return nil;
  }
  
  if (![bundle load]) {
    NSLog(@"WARNING(%s): couldn't load resolver bundle %@ for resolver '%@'",
          __PRETTY_FUNCTION__, bundle, resourceName);
  }
  
  /* locate class */
  {
    Class c;
    id resolver;
    
    if ((c = NGClassFromString(resourceName)) == Nil) {
      NSLog(@"WARNING(%s): couldn't resolve resolver class '%@'",
            __PRETTY_FUNCTION__, resourceName);
      return nil;
    }
    
    /* instantiate resolver */
    resolver = [[[c alloc] init] autorelease];
    
    return resolver;
  }
}

- (id<SkyDocumentGlobalIDResolver>)_resolverForGlobalID:(EOGlobalID *)_gid {
  NSEnumerator *e;
  id<SkyDocumentGlobalIDResolver> resolver;

  if (_gid == nil)
    return nil;
  
  e = [self->gidResolver objectEnumerator];
  while ((resolver = [e nextObject])) {
    if ([resolver canResolveGlobalID:_gid withDocumentManager:self])
      return resolver;
  }
  
  if ((resolver = [self _findResolverForGlobalID:_gid])) {
    if (self->gidResolver == nil)
      self->gidResolver = [[NSMutableArray alloc] initWithCapacity:16];
    [self->gidResolver addObject:resolver];
    return resolver;
  }
  
#if DEBUG
  NSLog(@"WARNING(%s): found no resolver for gid %@", __PRETTY_FUNCTION__, _gid);
#endif
  return nil;
}

/* base URL */

- (NSURL *)skyrixBaseURL {
  static NSURL *skybase = nil;
  NSString *skyid;
  NSString *urlstr;

  if (skybase != nil)
    return skybase;
  
  skyid = [[NSUserDefaults standardUserDefaults] stringForKey:@"skyrix_id"];
  if ([skyid length] == 0) {
    skyid = @"default";
    [self logWithFormat:
            @"WARNING: missing OGo database ID (skyrix_id default), "
            @"using: '%@'", skyid];
  }

  urlstr  = [NSString stringWithFormat:@"skyrix://%@/%@/",
                          [[NSHost currentHost] name],
                          skyid];
    
  skybase = [[NSURL alloc] initWithString:urlstr relativeToURL:nil];
  NSLog(@"OGo BaseURL: '%@'", skybase);
  return skybase;
}

/* GID->Doc */

- (NSArray *)_documentsForEntityNamed:(NSString *)_ename
  globalIDs:(NSArray *)_gids
{
  if ([_ename length] == 0)
    return nil;
  if (_gids == nil)
    return nil;
  if ([_gids count] == 0)
    return [NSArray array];
  
#if DEBUG
  NSLog(@"cannot (yet) fetch gids of entity %@: %@", _ename, _gids);
#endif
  return nil;
}

- (NSArray *)_documentsForForeignGlobalIDs:(NSArray *)_gids {
  if (_gids == nil)
    return nil;
  if ([_gids count] == 0)
    return [NSArray array];

#if DEBUG
  NSLog(@"WARNING(%s): couldn't fetch foreign gids: %@",
        __PRETTY_FUNCTION__, _gids);
#endif
  return nil;
}

- (NSArray *)documentsForGlobalIDs:(NSArray *)_gids {
  NSAutoreleasePool   *pool;
  NSMutableDictionary *resolverToGID = nil;
  NSMutableDictionary *resultMap;
  NSMutableArray      *results;
  unsigned            i, count;
  
  if (_gids == nil)
    return nil;
  if ((count = [_gids count]) == 0)
    return [NSArray array];
  
  pool = [[NSAutoreleasePool alloc] init];
  
  /* categorize gids */
  
  for (i = 0; i < count; i++) {
    EOGlobalID     *gid;
    id             resolver;
    NSMutableArray *gids;
    
    gid = [_gids objectAtIndex:i];
    
    /* locate resolver */
    
    if ((resolver = [self _resolverForGlobalID:gid]) == nil)
      /* found no proper GID resolver ... */
      continue;
    
    if (resolverToGID == nil) {
      resolverToGID = [NSMutableDictionary dictionaryWithCapacity:16];
      gids = [NSMutableArray arrayWithCapacity:16];
      [resolverToGID setObject:gids forKey:resolver];
    }
    else if ((gids = [resolverToGID objectForKey:resolver]) == nil) {
      gids = [NSMutableArray arrayWithCapacity:16];
      [resolverToGID setObject:gids forKey:resolver];
    }
    
    [gids addObject:gid];
  }
  
  /* process gids */
  
  resultMap = [NSMutableDictionary dictionaryWithCapacity:count];
  
#if DEBUG && 0
  NSLog(@"process using resolvers: %@", resolverToGID);
#endif
  
  if (resolverToGID) {
    NSEnumerator *resolvers;
    id<SkyDocumentGlobalIDResolver> resolver;
    
    resolvers = [resolverToGID keyEnumerator];
    
    while ((resolver = [resolvers nextObject])) {
      NSArray  *gids, *docs;
      unsigned i, count;
      
      gids = [resolverToGID objectForKey:resolver];
      docs = [resolver resolveGlobalIDs:gids withDocumentManager:self];
      
      for (i = 0, count = [docs count]; i < count; i++) {
        [resultMap setObject:[docs objectAtIndex:i]
                   forKey:[gids objectAtIndex:i]];
      }
    }
  }
  
  /* transfer results to result array */
  
  results = [NSMutableArray arrayWithCapacity:count];
  
  for (i = 0; i < count; i++) {
    EOGlobalID *gid;
    id         doc;
    
    gid = [_gids objectAtIndex:i];
    doc = [resultMap objectForKey:gid];
    
    [results addObject:(doc ? doc : (id)[NSNull null])];
  }
  
  results = [results shallowCopy];
  [pool release];
  
  return [results autorelease];
}

- (id)documentForGlobalID:(EOGlobalID *)_gid {
  NSArray *docs, *gids;
  id doc;

  if (_gid == nil) return nil;
  
  gids = [NSArray arrayWithObject:_gid];
  docs = [self documentsForGlobalIDs:gids];
  
  if ([docs count] == 0)
    return nil;

  doc = [docs objectAtIndex:0];
  if ([doc isNotNull])
    return doc;
  
  return nil;
}

- (EOGlobalID *)globalIDForDocument:(id)_doc {
  if ([_doc respondsToSelector:@selector(globalID)])
    return [_doc globalID];
  
  return [_doc valueForKey:@"globalID"];
}

/* URL->Doc */

- (NSArray *)documentsForURLs:(NSArray *)_urls {
  return [self documentsForGlobalIDs:[self globalIDsForURLs:_urls]];
}

- (id)documentForURL:(id)_url {
  EOGlobalID *gid;

  if (_url == nil)
    return nil;
  
  if ((gid = [self globalIDForURL:_url]) == nil) {
#if DEBUG
    NSLog(@"WARNING(%s): couldn't turn URL '%@' into global-id ..",
          __PRETTY_FUNCTION__, _url);
#endif
    return nil;
  }
  
  return [self documentForGlobalID:gid];
}
- (NSURL *)urlForDocument:(id)_doc {
  return [self urlForGlobalID:[self globalIDForDocument:_doc]];
}

/* GID/URL mappings */

- (NSArray *)globalIDsForURLs:(NSArray *)_urls {
  // TODO: can we improve speed using bulk ops?
  NSMutableArray *ma;
  unsigned i, count;
  
  if (_urls == nil)
    return nil;
  if ((count = [_urls count]) == 0)
    return [NSArray array];
  
  ma = [NSMutableArray arrayWithCapacity:(count + 1)];
  
  for (i = 0; i < count; i++) {
    EOGlobalID *gid;
    
    if ((gid = [self globalIDForURL:[_urls objectAtIndex:i]]) == nil)
      gid = (id)[NSNull null];
    
    [ma addObject:gid];
  }
  return ma;
}
- (NSArray *)urlsForGlobalIDs:(NSArray *)_gids {
  NSMutableArray *ma;
  unsigned i,count;
  
  if (_gids == nil)
    return nil;
  if ((count = [_gids count]) == 0)
    return [NSArray array];
  
  ma = [NSMutableArray arrayWithCapacity:(count + 1)];
  
  for (i = 0; i < count; i++) {
    NSURL *url;

    if ((url = [self urlForGlobalID:[_gids objectAtIndex:i]]) == nil)
      url = (id)[NSNull null];

    [ma addObject:url];
  }
  return ma;
}

- (NSNumber *)_pkeyFromString:(NSString *)_path {
  static NSCharacterSet *digits = nil;
  
  if (digits == nil)
    digits = [[NSCharacterSet decimalDigitCharacterSet] retain];

  if ([_path length] == 0)
    return nil;
  
  if (![digits characterIsMember:[_path characterAtIndex:0]])
    return nil;
  
  return [NSNumber numberWithInt:[_path intValue]];
}

- (EOGlobalID *)_globalIDForStringRelativeToBase:(NSString *)_path {
  NSNumber *pkey;
  
  if ([_path length] == 0)
    /* or return a SKYRiX 'root' gid ... */
    return nil;
  
  if ((pkey = [self _pkeyFromString:_path])) {
    /* ok, URL begins with a digit, considered a primary key ... */
    EOGlobalID        *gid;
    id<LSTypeManager> tm;
    
    tm = [self->context typeManager];
    
    if ((gid = [tm globalIDForPrimaryKey:pkey]))
      return gid;
  }
  
  [self logWithFormat:@"WARNING(%s): cannot convert relative URL to gid: '%@'",
          __PRETTY_FUNCTION__, _path];
  return nil;
}

- (BOOL)isInvalidURLParameter:(id)_url {
  if (_url == nil) return YES;
  if ([_url isKindOfClass:[NSDictionary class]]) return YES;
  if ([_url isKindOfClass:[NSArray class]])      return YES;
  return NO;
}

- (EOGlobalID *)globalIDForURL:(id)_url {
  // TODO: split up method
  NSURL    *url;
  NSString *baseURLString;
  EOGlobalID *gid;
  
  if (_url == nil) 
    return nil;
  if ([self isInvalidURLParameter:_url]) {
    [self logWithFormat:
	    @"ERROR(%s): got an invalid object as the URL parameter: %@",
	    __PRETTY_FUNCTION__, _url];
    return nil;
  }
  
  if ([_url isKindOfClass:[NSURL class]]) {
    url = _url;
  }
  else {
    /* parse SKYRiX URL, could be relative to -skyrixBaseURL */
    NSString *s;
    NSNumber *pkey;
    
    if ((s = [_url stringValue]) == nil)
      return nil;
    if ([s length] == 0)
      return nil;

    if ((gid = [self->urlToGID objectForKey:s]) != nil)
      return gid;
    
    if ((pkey = [self _pkeyFromString:s]) != nil) {
      /* ok, URL begins with a digit, considered a primary key ... */
      EOGlobalID        *gid;
      id<LSTypeManager> tm;
      
      tm = [self->context typeManager];
      if ((gid = [tm globalIDForPrimaryKey:pkey])) {
        if (self->urlToGID == nil)
          self->urlToGID = [[NSMutableDictionary alloc] initWithCapacity:128];
        [self->urlToGID setObject:gid forKey:s];
        
        return gid;
      }
    }
    
    /* treat argument as string with URL representation */
    url = [NSURL URLWithString:s relativeToURL:[self skyrixBaseURL]];
    if (url == nil)
      return nil;
  }
  
  if ((gid = [self->urlToGID objectForKey:[url absoluteString]]))
    return gid;
  
  if ([url conformsToProtocol:@protocol(SkyURLToGlobalIDConversion)]) {
    /* URL can transform to GID itself */
    gid =
      [(id<SkyURLToGlobalIDConversion>)url globalIDWithDocumentManager:self];

    if (gid) {
      if (self->urlToGID == nil)
        self->urlToGID = [[NSMutableDictionary alloc] initWithCapacity:128];
      [self->urlToGID setObject:gid forKey:[url absoluteString]];
    }
    
    return gid;
  }
  
  /* the URL object is a URL directly relative to the base URL */
  
  if ([[url baseURL] isEqual:[self skyrixBaseURL]]) {
    gid = [self _globalIDForStringRelativeToBase:[url relativeString]];
    if (gid) {
      if (self->urlToGID == nil)
        self->urlToGID = [[NSMutableDictionary alloc] initWithCapacity:128];
      [self->urlToGID setObject:gid forKey:[url absoluteString]];
    }
    return gid;
  }
  
  /* check whether the URL is indirectly relative to the base URL */
  
  baseURLString = [[self skyrixBaseURL] absoluteString];
  
  if ([[url absoluteString] hasPrefix:baseURLString]) {
    NSString *s;
    
    s = [url absoluteString];
    s = [s substringFromIndex:[baseURLString length]];
    
    gid = [self _globalIDForStringRelativeToBase:s];
    if (gid) {
      if (self->urlToGID == nil)
        self->urlToGID = [[NSMutableDictionary alloc] initWithCapacity:128];
      [self->urlToGID setObject:gid forKey:[url absoluteString]];
    }
    return gid;
  }
  
  /* the URL is not relative, don't know how to deal with that ... */
  
  NSLog(@"WARNING(%s): couldn't convert URL '%@' to global-id (base=%@)..",
        __PRETTY_FUNCTION__, _url, [self skyrixBaseURL]);
  return nil;
}

- (NSURL *)urlForGlobalID:(EOGlobalID *)_gid {
  if (_gid == nil) return nil;
  
  if ([_gid conformsToProtocol:@protocol(SkyGlobalIDToURLConversion)])
    /* GID can transform to URL itself */
    return [(id<SkyGlobalIDToURLConversion>)_gid urlWithDocumentManager:self];
  
  if ([_gid isKindOfClass:[EOKeyGlobalID class]]) {
    /* standard type (single pkey), transform to pkey-path ... */
    EOKeyGlobalID *kgid;
    
    kgid = (id)_gid;
    
    if ([kgid keyCount] == 1 && ([[kgid entityName] length] > 0)) {
      NSString *s;
      NSURL *url;
      
      s = [[kgid keyValues][0] stringValue];
      
      url = [[NSURL alloc] initWithString:s relativeToURL:[self skyrixBaseURL]];
      return [url autorelease];
    }
  }
  
  NSLog(@"WARNING(%s): couldn't convert global-id %@ to URL ..",
        __PRETTY_FUNCTION__, _gid);
  return nil;
}

@end /* SkyDocumentManager */
