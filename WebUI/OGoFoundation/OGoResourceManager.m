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

#include "OGoResourceManager.h"
#include "OGoResourceKey.h"
#include "OGoStringTableManager.h"
#include "common.h"

@implementation OGoResourceManager

static BOOL          debugOn         = NO;
static BOOL          debugComponents = NO;
static NSArray       *wsPathes       = nil;
static NSArray       *templatePathes = nil;
static NSString      *suffix   = nil;
static NSString      *prefix   = nil;
static NSFileManager *fm   = nil;
static NSNull        *null = nil;

/* locate resource directories */

+ (NSArray *)findResourceDirectoryPathesWithName:(NSString *)_name
  fhsName:(NSString *)_fhs
{
  NSEnumerator   *e;
  NSFileManager  *fm;
  NSMutableArray *ma;
  NSDictionary   *env;
  BOOL           isDir;
  id tmp;

  fm  = [NSFileManager defaultManager];
  ma  = [NSMutableArray arrayWithCapacity:8];
  env = [[NSProcessInfo processInfo] environment];
    
  if ((tmp = [env objectForKey:@"GNUSTEP_PATHPREFIX_LIST"]) == nil)
    tmp = [env objectForKey:@"GNUSTEP_PATHLIST"];
  tmp = [tmp componentsSeparatedByString:@":"];
  e   = [tmp objectEnumerator];
  
  while ((tmp = [e nextObject]) != nil) {
    if (![tmp hasSuffix:@"/"])
      tmp = [tmp stringByAppendingString:@"/"];
    
    tmp = [tmp stringByAppendingString:_name];
    if ([ma containsObject:tmp]) continue;
    
    if (debugOn) [self logWithFormat:@"CHECK: %@", tmp];
    if (![fm fileExistsAtPath:tmp isDirectory:&isDir])
      continue;
      
    if (!isDir) continue;
    
    [ma addObject:tmp];
  }

  /* hack in FHS pathes */
  
  tmp = [NSArray arrayWithObjects:@"/usr/local/", @"/usr/", nil];
  e   = [tmp objectEnumerator];
  
  while ((tmp = [e nextObject]) != nil) {
    tmp = [tmp stringByAppendingString:@"share/opengroupware.org-1.0a/"];
    tmp = [tmp stringByAppendingString:_fhs];
    if ([ma containsObject:tmp]) continue;
    
    if (![fm fileExistsAtPath:tmp isDirectory:&isDir])
      continue;
    if (!isDir) {
      [self logWithFormat:@"path is not a directory: %@", tmp];
      continue;
    }
    
    [ma addObject:tmp];
  }
  
  return ma;
}

+ (int)version {
  return [super version] + 0 /* v4 */;
}
+ (void)initialize {
  static BOOL isInitialized = NO;
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  if (isInitialized) return;
  isInitialized = YES;
  
  NSAssert2([super version] == 4,
	    @"invalid superclass (%@) version %i !",
	    NSStringFromClass([self superclass]), [super version]);

  null = [[NSNull null] retain];
  
  if ((debugOn = [ud boolForKey:@"OGoResourceManagerDebugEnabled"]))
    NSLog(@"Note: OGoResourceManager debugging is enabled.");
  debugComponents = [ud boolForKey:@"OGoResourceManagerComponentDebugEnabled"];
  if (debugComponents)
    NSLog(@"Note: OGoResourceManager component debugging is enabled.");
  
  fm = [[NSFileManager defaultManager] retain];
  
  suffix = [[ud stringForKey:@"WOApplicationSuffix"] copy];
  prefix = [[ud stringForKey:@"WOResourcePrefix"]    copy];
  
  wsPathes = [[self findResourceDirectoryPathesWithName:
		      @"WebServerResources/" fhsName:@"www/"] copy];
  if (debugOn)
    NSLog(@"WebServerResources pathes: %@", wsPathes);
  
  // TODO: use appname to enable different setups, maybe some var too
  templatePathes = [[self findResourceDirectoryPathesWithName:
			    @"Library/OpenGroupware.org-1.0a/Templates/"
			  fhsName:@"templates/"] copy];
  if (debugOn)
    NSLog(@"template pathes: %@", templatePathes);
  if ([templatePathes count] == 0)
    NSLog(@"WARNING: found no directories containing OGo templates!");
}

- (id)initWithPath:(NSString *)_path {
  if ((self = [super initWithPath:_path])) {
    if ([WOApplication isCachingEnabled]) {
      self->keyToComponentPath =
	[[NSMutableDictionary alloc] initWithCapacity:128];
      
      self->keyToPath = [[NSMutableDictionary alloc] initWithCapacity:1024];
      self->keyToURL = [[NSMutableDictionary alloc] initWithCapacity:1024];
    }
    else
      [self logWithFormat:@"Note: component path caching is disabled!"];
    
    self->labelManager = [[OGoStringTableManager alloc] init];
    
    self->cachedKey = [[OGoResourceKey alloc] initCachedKey];
  }
  return self;
}

- (void)dealloc {
  [self->cachedKey          release];
  [self->labelManager       release];
  [self->keyToURL           release];
  [self->keyToPath          release];
  [self->keyToComponentPath release];
  [super dealloc];
}

/* accessors */

- (NGBundleManager *)bundleManager {
  static NGBundleManager *bm = nil; // THREAD
  if (bm == nil) bm = [[NGBundleManager defaultBundleManager] retain];
  return bm;
}

/* resource cache */

static id
checkCache(NSDictionary *_cache, OGoResourceKey *_key,
	   NSString *_n, NSString *_fw, NSString *_l)
{
  if (_cache == nil) {
    if (debugOn) NSLog(@"cache disabled.");
    return nil; /* caching disabled */
  }
  
  /* setup cache key (THREAD) */
  _key->hashValue     = 0; /* reset, calculate on next access */
  _key->name          = _n;
  _key->frameworkName = _fw;
  _key->language      = _l;
  
  return [_cache objectForKey:_key];
}

- (void)cacheValue:(id)_value inCache:(NSMutableDictionary *)_cache {
  OGoResourceKey *k;
  
  if (_cache == nil) return; /* caching disabled */
  
  /* we need to dup, because the cachedKey does not retain! */
  k = [self->cachedKey duplicate];
  
  if (debugOn) {
    [self debugWithFormat:@"cache key %@(#%d): %@", k, [self->keyToPath count],
	    _value];
  }
  
  [_cache setObject:(_value ? _value : (id)null) forKey:k];
  [k release]; k = nil;
}

/* locate Resources */

- (BOOL)shouldLookupResourceInWebServerResources:(NSString *)_name {
  if ([_name isEqualToString:@"components.cfg"])
    return NO;
  
  return [super shouldLookupResourceInWebServerResources:_name];
}

- (NSString *)_checkPath:(NSString *)_p forOGoResourceNamed:(NSString *)_name
  inFramework:(NSString *)_frameworkName
  language:(NSString *)_language
{
  NSString *path;
  
  path = [_frameworkName length] > 0
    ? [_p stringByAppendingPathComponent:_frameworkName]
    : _p;
      
  /* check language */
  if (_language != nil) {
    path = [path stringByAppendingPathComponent:_language];
    path = [path stringByAppendingPathExtension:@"lproj"];
  }
  
  path = [path stringByAppendingPathComponent:_name];
  if (debugOn) [self debugWithFormat:@"  check path: '%@'", path];
      
  if (![fm fileExistsAtPath:path])
    return nil;
  
  return path;
}

- (NSString *)_checkPathes:(NSArray *)_p forOGoResourceNamed:(NSString *)_name
  inFramework:(NSString *)_frameworkName
  language:(NSString *)_language
{
  NSEnumerator *e;
  NSString     *path;
  
  e = [_p objectEnumerator];
  while ((path = [e nextObject]) != nil) {
    path = [self _checkPath:path forOGoResourceNamed:_name
		 inFramework:_frameworkName language:_language];
    if (path != nil) {
      if (debugOn) [self debugWithFormat:@"FOUND: '%@'", path];
      return path;
    }
  }
  return nil;
}

- (NSString *)_pathForOGoResourceNamed:(NSString *)_name
  inFramework:(NSString *)_fwName
  language:(NSString *)_lang
{
  // TODO: a lot of DUP code with _urlForResourceNamed, needs some refacturing
  /* Note: this looks only in WebServerResources! */
  NSString *path;
  
  if (![self shouldLookupResourceInWebServerResources:_name]) {
    if (debugOn) {
      [self debugWithFormat:
	      @"  not looking for resource in WebServerResources: '%@'", 
	      _name];
    }
    return nil;
  }
  
  if (debugOn) [self debugWithFormat:@"lookup OGo resource '%@'", _name];
  
  /* check cache */
  
  path = checkCache(self->keyToPath, self->cachedKey, _name, _fwName, _lang);
  if (path != nil) {
    if (debugOn) [self debugWithFormat:@"  found in cache: %@", path];
    return [path isNotNull] ? path : nil;
  }
  
  /* check for framework resources (webserver resources + framework) */

  if (debugOn) 
    [self debugWithFormat:@"check framework WebServerResources ..."];
  path = [self _checkPathes:wsPathes forOGoResourceNamed:_name
	       inFramework:_fwName language:_lang];
  if (path != nil) {
    [self cacheValue:path inCache:self->keyToPath];
    return path;
  }
  
  /* check in basepath of webserver resources */
  
  if (debugOn) [self debugWithFormat:@"check global WebServerResources ..."];
  path = [self _checkPathes:wsPathes forOGoResourceNamed:_name
	       inFramework:_fwName language:_lang];
  if (path != nil) {
    [self cacheValue:path inCache:self->keyToPath];
    return path;
  }
  
  /* finished processing */
  if (debugOn) 
    [self debugWithFormat:@"NOT FOUND: %@ (%@)", _name, self->cachedKey];
  return nil;
}

- (NSString *)pathForResourceNamed:(NSString *)_name
  inFramework:(NSString *)_fwName
  languages:(NSArray *)_langs
{
  /* 
     Note: this is also called by the superclass method 
           -pathToComponentNamed:inFramework: for each registered component
	   extension.
  */
  NSEnumerator *e;
  NSString     *language;
  NSString     *rpath;
  
  if ([_name length] == 0) {
    if (debugOn) [self logWithFormat:@"got no name for resource lookup?!"];
    return nil;
  }
  
  if (debugOn) {
    [self debugWithFormat:@"pathForResourceNamed: %@ (languages: %@)",
	    _name, [_langs componentsJoinedByString:@","]];
  }
  
  if ([self shouldLookupResourceInWebServerResources:_name]) {
    /* 
       Note: currently the OGo lookup method only checks the webserver 
             resources
    */
    
    /* check languages */
  
    e = [_langs objectEnumerator];
    while ((language = [e nextObject])) {
      NSString *rpath;
    
      if (debugOn) [self logWithFormat:@"  check language: '%@'", language];
      rpath = [self _pathForOGoResourceNamed:_name inFramework:_fwName
		    language:language];
      if (rpath != nil) {
	if (debugOn) [self logWithFormat:@"  FOUND: %@", rpath];
	return rpath;
      }
    }
  
    /* check without language */
  
    rpath = [self _pathForOGoResourceNamed:_name inFramework:_fwName
		  language:nil];
    if (rpath != nil)
      return rpath;
  
    if (debugOn) {
      [self debugWithFormat:
	      @"did not find resource in OGo, try SOPE lookup: %@", _name];
    }
  }
  else if (debugOn) {
    [self debugWithFormat:
	    @"  not looking for resource in WebServerResources: '%@'", 
	    _name];
  }
  
  /* look using OWResourceManager */
  
  rpath = [super pathForResourceNamed:_name inFramework:_fwName
		 languages:_langs];
  return rpath;
}

/* locate WebServerResources */

- (NSString *)_urlForResourceNamed:(NSString *)_name
  inFramework:(NSString *)_fwName
  language:(NSString *)_lang
  applicationName:(NSString *)_appName
{
  NSString     *url;
  NSEnumerator *e;
  NSString     *path;
  
  if (debugOn) {
    [self logWithFormat:@"lookup URL of resource: '%@'/%@/%@", 
	    _name, _fwName, _lang];
  }
  
  /* check cache */
  
  url = checkCache(self->keyToURL, self->cachedKey, _name, _fwName, _lang);
  if (url != nil) {
    if (debugOn) {
      [self debugWithFormat:@"  found in cache: %@ (#%d)", url, 
	      [self->keyToURL count]];
    }
    return [url isNotNull] ? url : nil;
  }
  
  if (debugOn) {
    [self debugWithFormat:@"  not found in cache: %@ (%@,#%d)", 
	    url, self->cachedKey, [self->keyToURL count]];
  }
  
  /* check for framework resources */
  
  if ([_fwName length] > 0) {
    if (debugOn) 
      [self debugWithFormat:@"check framework: '%@'", _fwName];
    e = [wsPathes objectEnumerator];
    while ((path = [e nextObject])) {
      NSMutableString *ms;
      
      path = [path stringByAppendingPathComponent:_fwName];

      /* check language */
      if (_lang) {
        path = [path stringByAppendingString:_lang];
        path = [path stringByAppendingPathExtension:@"lproj"];
      }
      
      path = [path stringByAppendingPathComponent:_name];
      if (debugOn) [self debugWithFormat:@"  check path: '%@'", path];
      
      if (![fm fileExistsAtPath:path])
	continue;
        
      ms = [[NSMutableString alloc] initWithCapacity:256];
        
      if (prefix) [ms appendString:prefix];
      if (![ms hasSuffix:@"/"]) [ms appendString:@"/"];
      [ms appendString:_appName];
      if (suffix) [ms appendString:suffix];
      [ms appendString:[ms hasSuffix:@"/"] 
            ? @"WebServerResources/" : @"/WebServerResources/"];
      [ms appendString:_fwName];
      [ms appendString:@"/"];
      if (_lang) {
          [ms appendString:_lang];
          [ms appendString:@".lproj/"];
      }
      [ms appendString:_name];
      
      url = [ms copy];
      [ms release]; ms = nil;
      if (debugOn) [self debugWithFormat:@"FOUND: '%@'", url];
      goto done;
    }
  }
  
  /* check for global resources */
  
  if (debugOn) [self debugWithFormat:@"check global WebServerResources ..."];
  e = [wsPathes objectEnumerator];
  while ((path = [e nextObject])) {
    NSMutableString *ms;
    NSString *fpath, *basepath;
    
    /* check language */
    if (_lang) {
      basepath = [path stringByAppendingString:_lang];
      basepath = [basepath stringByAppendingPathExtension:@"lproj"];
    }
    else
      basepath = path;
    
    fpath = [basepath stringByAppendingPathComponent:_name];
    if (debugOn) {
      [self debugWithFormat:
	      @"  check path: '%@'\n base: %@\n name: %@\n "
	      @" path: %@\n lang: %@", 
	      fpath, basepath, _name, path, _lang];
    }
    
    if (![fm fileExistsAtPath:fpath])
      continue;
      
    ms = [[NSMutableString alloc] initWithCapacity:256];
      
    if (prefix) [ms appendString:prefix];
    if (![ms hasSuffix:@"/"]) [ms appendString:@"/"];
    [ms appendString:_appName];
    if (suffix) [ms appendString:suffix];
    [ms appendString:[ms hasSuffix:@"/"] 
          ? @"WebServerResources/" : @"/WebServerResources/"];
    if (_lang) {
      [ms appendString:_lang];
      [ms appendString:@".lproj/"];
    }
    [ms appendString:_name];
      
    url = [ms copy];
    [ms release]; ms = nil;
    if (debugOn) [self debugWithFormat:@"FOUND: '%@'", url];
    goto done;
  }
  
  /* finished processing */
  if (debugOn) {
    [self debugWithFormat:@"NOT FOUND: %@ (%@,#%d)", _name, self->cachedKey,
	    [self->keyToURL count]];
  }
  
 done:
  [self cacheValue:url inCache:self->keyToURL];
  return url;
}

- (NSString *)urlForResourceNamed:(NSString *)_name
  inFramework:(NSString *)_fwName
  languages:(NSArray *)_langs
  request:(WORequest *)_request
{
  NSEnumerator *e;
  NSString     *language;
  NSString     *url;
  NSString     *appName;
  
  if ([_name length] == 0) {
    if (debugOn) [self logWithFormat:@"got no name for resource URL lookup?!"];
    return nil;
  }
  
  if (debugOn) [self debugWithFormat:@"urlForResourceNamed: %@", _name];
  
  if (_langs == nil) {
    _langs = [_request browserLanguages];
    if (debugOn) {
      [self debugWithFormat:@"using browser languages: %@", 
	      [_langs componentsJoinedByString:@", "]];
    }
  }
  else if (debugOn) {
    [self debugWithFormat:@"using given languages: %@", 
	    [_langs componentsJoinedByString:@","]];
  }
  
  appName = [(WOApplication *)[WOApplication application] name];
  if (appName == nil)
    appName = [_request applicationName];
  
  /* check languages */
  
  e = [_langs objectEnumerator];
  while ((language = [e nextObject])) {
    NSString *url;
    
    if (debugOn) [self logWithFormat:@"  check language: '%@'", language];
    url = [self _urlForResourceNamed:_name
                inFramework:_fwName
                language:language
                applicationName:appName];
    if (url) {
      if (debugOn) [self logWithFormat:@"  FOUND: %@", url];
      return url;
    }
  }
  
  /* check without language */
  
  url = [self _urlForResourceNamed:_name
              inFramework:_fwName
              language:nil
              applicationName:appName];
  if (url != nil)
    return url;

  if (debugOn) {
    [self debugWithFormat:
	    @"did not find resource in OGo, try SOPE lookup: %@", _name];
  }
  
  url = [super urlForResourceNamed:_name
               inFramework:_fwName
               languages:_langs
               request:_request];

  return url;
}

/* locate components */

- (NSString *)lookupComponentInStandardPathes:(NSString *)_name
  inFramework:(NSString *)_framework theme:(NSString *)_theme
{
  // TODO: what about languages/themes?!
  NSEnumerator *e;
  NSString *path;
  
  [self logWithFormat:@"LOOKUP %@-%@-%@", _name, _framework, _theme];
  
  e = [templatePathes objectEnumerator];
  while ((path = [e nextObject])) {
    NSString *pe;

    if (_theme != nil) {
      // TODO: should be lower case for FHS? or use a different path?
      path = [path stringByAppendingPathComponent:@"Themes"];
      path = [path stringByAppendingPathComponent:_theme];
    }
    
    if ([_framework length] > 0) {
      NSString *pureName;
      
      pureName = [_framework lastPathComponent];
      pureName = [pureName stringByDeletingPathExtension];
      path = [path stringByAppendingPathComponent:pureName];
    }
    
    path = [path stringByAppendingPathComponent:_name];
    
    pe = [path stringByAppendingPathExtension:@"wox"];
    if ([fm fileExistsAtPath:pe])
      return pe;

    [self logWithFormat:@"  path: %@", path];

    pe = [path stringByAppendingPathExtension:@"html"];
    if ([fm fileExistsAtPath:pe]) {
      /* 
	 Note: we are passing in the path of the HTML template, this is some
	       kind of hack to make the wrapper template builder look for the
               $name.html/$name.wod in there.
      */
      return pe;
    }
  }
  
  return nil;
}
- (NSString *)lookupComponentInStandardPathes:(NSString *)_name
  inFramework:(NSString *)_framework languages:(NSArray *)_langs
{
  NSString *path;
  NSString *theme;
  
  /* extract theme from language array (we do not support nested themes ATM) */
  
  theme = nil;
  if ([_langs count] > 1) {
    NSRange r;
    
    theme = [_langs objectAtIndex:0];
    r = [theme rangeOfString:@"_"];
    theme = (r.length > 0)
      ? [theme substringFromIndex:(r.location + r.length)]
      : nil;
  }
  else
    theme = nil;

  /* check theme dirs */
  
  if (theme != nil) {
    path = [self lookupComponentInStandardPathes:_name inFramework:_framework
		 theme:theme];
    if (path != nil)
      return path;
  }

  /* check base dirs */
  
  path = [self lookupComponentInStandardPathes:_name inFramework:_framework
	       theme:nil];
  if (path != nil)
    return path;

  return nil;
}

- (NSString *)lookupComponentPathUsingBundleManager:(NSString *)_name {
  // TODO: is this ever invoked?
  NSFileManager *fm = nil;
  NSString *wrapper = nil;
  NSBundle *bundle  = nil;
  NSString *path;
  
  bundle = [[self bundleManager]
                  bundleProvidingResource:_name
                  ofType:@"WOComponents"];
  if (bundle == nil) {
    [self debugWithFormat:@"did not find a bundle providing component: %@", 
	    _name];
    return nil;
  }
  
  if (debugOn) {
    [self debugWithFormat:@"bundle %@ for component %@",
            [[bundle bundlePath] lastPathComponent], _name];
  }
  
  [bundle load];
  
  fm      = [NSFileManager defaultManager];
  wrapper = [_name stringByAppendingPathExtension:@"wo"];
  
  path = [[bundle bundlePath] stringByAppendingPathComponent:@"Resources"];
  path = [path stringByAppendingPathComponent:wrapper];
  if ([fm fileExistsAtPath:path])
    return path;
  
  path = [[bundle bundlePath] stringByAppendingPathComponent:wrapper];
  if ([fm fileExistsAtPath:path])
    return path;
  
  return nil;
}

- (NSString *)pathToComponentNamed:(NSString *)_name
  inFramework:(NSString *)_fw languages:(NSArray *)_langs
{
  // TODO: what about languages in lookup?
  NSString *path;
  
  if (debugComponents) {
    [self logWithFormat:@"%s: lookup component: %@|%@",
	  __PRETTY_FUNCTION__, _name, _fw];
  }
  
  /* first check cache */
  
  path = checkCache(self->keyToComponentPath, self->cachedKey, _name, _fw,
		    [_langs count] > 0 ? [_langs objectAtIndex:0]:@"English");
  if (path != nil) {
    if (debugComponents)
      [self logWithFormat:@"  use cached location: %@", path];
    return [path isNotNull] ? path : nil;
  }
  
  /* look in FHS locations */

  path = [self lookupComponentInStandardPathes:_name inFramework:_fw
	       languages:_langs];
  if (path != nil) {
    if (debugComponents)
      [self logWithFormat:@"  found in standard pathes: %@", path];
    goto done;
  }
  
  /* try to find component by standard NGObjWeb method */
  
  path = [super pathToComponentNamed:_name inFramework:_fw languages:_langs];
  if (path != nil) {
    if (debugComponents)
      [self logWithFormat:@"  found using OWResourceManager: %@", path];
    goto done;
  }
  
  /* find component using NGBundleManager */
  
  if ((path = [self lookupComponentPathUsingBundleManager:_name]) != nil) {
    if (debugComponents)
      [self logWithFormat:@"  found using bundle manager: %@", path];
    goto done;
  }
  
  /* did not find component */
 done:
  [self cacheValue:path inCache:self->keyToComponentPath];
  return path;
}

/* string tables */

- (NSString *)labelForKey:(NSString *)_key component:(WOComponent *)_component{
  return [self->labelManager labelForKey:_key component:_component];
}

- (NSString *)stringForKey:(NSString *)_key
  inTableNamed:(NSString *)_tableName
  withDefaultValue:(NSString *)_default
  languages:(NSArray *)_langs
{
  NSString *s;
  
  s = [self->labelManager 
	   stringForKey:_key inTableNamed:_tableName
	   withDefaultValue:_default languages:_langs];
  if (s != nil) return s;
  
  /* is the default lookup really used in the OGo context? */

  s = [super stringForKey:_key inTableNamed:_tableName
	     withDefaultValue:_default
	     languages:_langs];
  if (s != nil) return s;
  
  return s != nil ? s : _default;
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}
- (NSString *)loggingPrefix {
  return @"[ogo-rm]";
}

@end /* OGoResourceManager */
