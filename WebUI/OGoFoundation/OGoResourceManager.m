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
#include "common.h"

@interface _OGoStringTable : NSObject
{
@protected
  NSString     *path;
  NSDictionary *data;
  NSDate       *lastRead;
}

+ (id)stringTableWithPath:(NSString *)_path;
- (id)initWithPath:(NSString *)_path;
- (NSString *)stringForKey:(NSString *)_key withDefaultValue:(NSString *)_def;

@end

@interface OWResourceManager(UsedPrivates)
- (NSString *)pathToComponentNamed:(NSString *)_name
  inFramework:(NSString *)_framework;
@end

@implementation OGoResourceManager

static BOOL debugOn = NO;
static NSArray  *wsPathes = nil;
static NSString *suffix = nil;
static NSString *prefix = nil;

/* locate resource directories */

+ (NSArray *)findResourceDirectoryPathesWithName:(NSString *)_name
  fhsName:(NSString *)_fhs
{
  NSFileManager  *fm;
  NSMutableArray *ma;
  NSDictionary   *env;
  NSString       *key;
  BOOL           isDir;
  id tmp;

  fm  = [NSFileManager defaultManager];
  ma  = [NSMutableArray arrayWithCapacity:8];
  env = [[NSProcessInfo processInfo] environment];
    
  if ((tmp = [env objectForKey:@"GNUSTEP_PATHPREFIX_LIST"]) == nil)
    tmp = [env objectForKey:@"GNUSTEP_PATHLIST"];
  tmp = [tmp componentsSeparatedByString:@":"];
  tmp = [tmp objectEnumerator];
  
  while ((key = [tmp nextObject])) {
    NSString *tmp;
    
    if ((tmp = [env objectForKey:key]) == nil)
      continue;
    
    if (![tmp hasSuffix:@"/"])
      tmp = [tmp stringByAppendingString:@"/"];
      
    tmp = [tmp stringByAppendingString:_name];
    if ([ma containsObject:tmp]) continue;
      
    if (![fm fileExistsAtPath:tmp isDirectory:&isDir])
      continue;
      
    if (!isDir) continue;
    
    [ma addObject:tmp];
  }

  /* hack in FHS pathes */
  
  key = @"/usr/local/share/opengroupware.org-1.0a/www/";
  if ([fm fileExistsAtPath:key isDirectory:&isDir]) {
    if (isDir) 
      [ma addObject:key];
    else
      [self logWithFormat:@"path is not a directory: %@", key];
  }
  
  key = @"/usr/share/opengroupware.org-1.0a/www/";
  if ([fm fileExistsAtPath:key isDirectory:&isDir]) {
    if (isDir) 
      [ma addObject:key];
    else
      [self logWithFormat:@"path is not a directory: %@", key];
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
  
  debugOn = [ud boolForKey:@"OGoResourceManagerDebugEnabled"];
  suffix  = [[ud stringForKey:@"WOApplicationSuffix"] copy];
  prefix  = [[ud stringForKey:@"WOResourcePrefix"]    copy];
  
  wsPathes = [[self findResourceDirectoryPathesWithName:
		      @"WebServerResources/" fhsName:@"www/"] copy];
  if (debugOn)
    [self debugWithFormat:@"WebServerResources pathes: %@", wsPathes];
}

- (void)dealloc {
  [self->compLabelCache  release];
  [self->keyToURL        release];
  [self->nameToTable     release];
  [self->componentToPath release];
  [super dealloc];
}

/* accessors */

- (NGBundleManager *)bundleManager {
  return [NGBundleManager defaultBundleManager];
}

- (NSString *)findResourceDirectoryNamed:(NSString *)_name
  fhsName:(NSString *)_fhs
{
  static NSDictionary *env = nil;
  NSFileManager *fm;
  NSString      *path;
  id tmp;
  
  if (env == nil) env = [[[NSProcessInfo processInfo] environment] retain];
  fm = [NSFileManager defaultManager];

  /* look in GNUstep pathes */
  
  if ((tmp = [env objectForKey:@"GNUSTEP_PATHPREFIX_LIST"]) == nil)
    tmp = [env objectForKey:@"GNUSTEP_PATHLIST"];
  tmp = [tmp componentsSeparatedByString:@":"];
  
  tmp = [tmp objectEnumerator];
  while ((path = [tmp nextObject])) {
    path = [path stringByAppendingPathComponent:_name];
    
    if ([fm fileExistsAtPath:path])
      return path;
  }

  /* look in FHS pathes */
  
  tmp = [NSArray arrayWithObjects:@"/usr/local", @"/usr", nil];
  tmp = [tmp objectEnumerator];
  while ((path = [tmp nextObject])) {
    path = [path stringByAppendingPathComponent:_fhs];
    if ([fm fileExistsAtPath:path])
      return path;
  }
  return nil;
}

/* locate WebServerResources */

- (NSString *)_urlForResourceNamed:(NSString *)_name
  inFramework:(NSString *)_frameworkName
  language:(NSString *)_language
  applicationName:(NSString *)_appName
{
  NSString      *key;
  NSString      *url;
  NSEnumerator  *e;
  NSString      *path;
  NSFileManager *fm;
  
  key = [NSString stringWithFormat:@"%@++%@++%@",
                    _frameworkName?_frameworkName:@"-",
                    _name,
                    _language?_language:@"-"];
  
  if ((url = [self->keyToURL objectForKey:key]) != nil) {
    if (![url isNotNull])
      return nil;
    return url;
  }
  
  if (debugOn) [self logWithFormat:@"LOOKUP '%@'", _name];
  
  fm  = [NSFileManager defaultManager];
  
  /* check for framework resources */
  
  if ([_frameworkName length] > 0) {
    if (debugOn) 
      [self debugWithFormat:@"check framework: '%@'", _frameworkName];
    e = [wsPathes objectEnumerator];
    while ((path = [e nextObject])) {
      NSMutableString *ms;
      
      path = [path stringByAppendingPathComponent:_frameworkName];

      /* check language */
      if (_language) {
        path = [path stringByAppendingString:_language];
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
      [ms appendString:_frameworkName];
      [ms appendString:@"/"];
      if (_language) {
          [ms appendString:_language];
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
    if (_language) {
      basepath = [path stringByAppendingString:_language];
      basepath = [basepath stringByAppendingPathExtension:@"lproj"];
    }
    else
      basepath = path;
    
    fpath = [basepath stringByAppendingPathComponent:_name];
    if (debugOn) {
      [self debugWithFormat:
	      @"  check path: '%@'\n base: %@\n name: %@\n "
	      @" path: %@\n lang: %@", 
	      fpath, basepath, _name, path, _language];
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
    if (_language) {
      [ms appendString:_language];
      [ms appendString:@".lproj/"];
    }
    [ms appendString:_name];
      
    url = [ms copy];
    [ms release]; ms = nil;
    if (debugOn) [self debugWithFormat:@"FOUND: '%@'", url];
    goto done;
  }
  
  /* finished processing */
  if (debugOn) [self debugWithFormat:@"NOT FOUND: %@", _name];
  
 done:
  if (self->keyToURL == nil)
    self->keyToURL = [[NSMutableDictionary alloc] initWithCapacity:1024];
  
  if (url) 
    [self->keyToURL setObject:url forKey:key];
  else
    [self->keyToURL setObject:[NSNull null] forKey:key];
  
  return url;
}

- (NSString *)urlForResourceNamed:(NSString *)_name
  inFramework:(NSString *)_frameworkName
  languages:(NSArray *)_languages
  request:(WORequest *)_request
{
  NSEnumerator *e;
  NSString     *language;
  NSString     *url;
  NSString     *appName;
  
  if ([_name length] == 0)
    return nil;

  if (debugOn) [self debugWithFormat:@"urlForResourceNamed: %@", _name];
  
  if (_languages == nil) {
    _languages = [_request browserLanguages];
    if (debugOn) {
      [self debugWithFormat:@"using browser languages: %@", 
	      [_languages componentsJoinedByString:@", "]];
    }
  }
  else if (debugOn)
    [self debugWithFormat:@"using given languages: %@", _languages];
  
  appName = [(WOApplication *)[WOApplication application] name];
  if (appName == nil)
    appName = [_request applicationName];
  
  /* check languages */
  
  e = [_languages objectEnumerator];
  while ((language = [e nextObject])) {
    NSString *url;
    
    if (debugOn) [self logWithFormat:@"  check language: '%@'", language];
    url = [self _urlForResourceNamed:_name
                inFramework:_frameworkName
                language:language
                applicationName:appName];
    if (url) {
      if (debugOn) [self logWithFormat:@"  FOUND: %@", url];
      return url;
    }
  }
  
  /* check without language */
  
  url = [self _urlForResourceNamed:_name
              inFramework:_frameworkName
              language:nil
              applicationName:appName];
  if (url)
    return url;
  
  url = [super urlForResourceNamed:_name
               inFramework:_frameworkName
               languages:_languages
               request:_request];

  return url;
}

/* locate components */

- (NSString *)pathToComponentNamed:(NSString *)_name
  inFramework:(NSString *)_framework
{
  NSFileManager *fm = nil;
  NSString *path    = nil;
  NSString *wrapper = nil;
  NSBundle *bundle  = nil;

  if (self->componentToPath == nil) {
    self->componentToPath =
      [[NSMutableDictionary allocWithZone:[self zone]] initWithCapacity:128];
  }

  if ((path = [self->componentToPath objectForKey:_name]))
    return path;
  
  if ((path = [super pathToComponentNamed:_name inFramework:_framework])) {
    [self->componentToPath setObject:path forKey:_name];
    return path;
  }
  
  bundle = [[self bundleManager]
                  bundleProvidingResource:_name
                  ofType:@"WOComponents"];
  if (bundle == nil)
    return nil;
  
  if (debugOn) {
    NSLog(@"OGoResourceManager: bundle %@ for component %@",
          [[bundle bundlePath] lastPathComponent], _name);
  }
  
  [bundle load];
  
  fm      = [NSFileManager defaultManager];
  wrapper = [_name stringByAppendingPathExtension:@"wo"];
  
  path = [[bundle bundlePath] stringByAppendingPathComponent:@"Resources"];
  path = [path stringByAppendingPathComponent:wrapper];
  if ([fm fileExistsAtPath:path]) {
    [self->componentToPath setObject:path forKey:_name];
    return path;
  }
  
  path = [[bundle bundlePath] stringByAppendingPathComponent:wrapper];
  if ([fm fileExistsAtPath:path]) {
    [self->componentToPath setObject:path forKey:_name];
    return path;
  }

  return nil;
}

/* string tables */

static NSNull *null = nil;

- (NSString *)labelForKey:(NSString *)_key component:(WOComponent *)_component {
  WOApplication   *app;
  NSArray         *langs;
  NSBundle        *bundle;
  id              value = nil;
  NGBundleManager *bm;
  NSString        *cname;
  id cacheKey;
  
  if ([_key length] == 0)
    return _key;
  if (_component == nil)
    return _key;

  if (null == nil) null = [[NSNull null] retain];
  
  cname = [_component name];
  langs = [(WOSession *)[_component session] languages];
  
  /* cache ?? */

  {
    /* cache cachekeys here ;-) */
    cacheKey = [NSArray arrayWithObjects:_key, cname, langs, nil];
  }
  
  if ((value = [self->compLabelCache objectForKey:cacheKey])) {
    if (value == null) value = nil;
    return value;
  }
  
  if (self->compLabelCache == nil)
    self->compLabelCache = [[NSMutableDictionary alloc] initWithCapacity:512];
  
  /* lookup bundle */
  
  app = [WOApplication application];
  
  bm = [NGBundleManager defaultBundleManager];
  bundle = [bm bundleProvidingResource:cname ofType:@"WOComponents"];
  if (bundle == nil)
    bundle = [NGBundle bundleForClass:[_component class]];
  
  /* look in BundleName.strings */
  
  value = [self stringForKey:_key
                inTableNamed:[bundle bundleName]
                withDefaultValue:nil
                languages:langs];
  if (value)
    goto done;
  
  /* look in App.strings */
  value = [self stringForKey:_key
                inTableNamed:cname
                withDefaultValue:nil
                languages:langs];
  if (value)
    goto done;
  
  /* no string found, use key as string */
  value = _key;
  
 done:
#if DEBUG
  NSAssert(value, @"missing value ..");
#endif
  
  [self->compLabelCache setObject:value forKey:cacheKey];
  //NSLog(@"%s: label cache size now: %i", __PRETTY_FUNCTION__,
  //      [self->compLabelCache count]);
  return value;
}

- (NSString *)_cachedStringForKey:(NSString *)_key
  inTableNamed:(NSString *)_tableName
  withDefaultValue:(NSString *)_default
  languages:(NSArray *)_languages
{
  if (_tableName == nil) _tableName = @"default";

  /* look into string cache */
  
  if ([_languages count] > 0) {
    NSString *tname;
    NSRange  r;
    NSString *language;
    id       table;
    
    language = [_languages objectAtIndex:0];
    
    r = [language rangeOfString:@"_"];
    if (r.length > 0)
      language = [language substringToIndex:r.location];
    
    tname = [language stringByAppendingString:@"+++"];
    tname = [tname stringByAppendingString:_tableName];
    
    if ((table = [self->nameToTable objectForKey:tname])) {
      if (debugOn) {
        NSLog(@"resolved label %@ table %@ in lang %@ (languages=%@)",
              _key, _tableName, language,
              [_languages componentsJoinedByString:@","]);
      }
      return [table stringForKey:_key withDefaultValue:_default];
    }
  }
  else if ([_languages count] == 0) {
    id table;
    
    NSLog(@"WARNING: called %s without languages array %@ !",
          __PRETTY_FUNCTION__, _languages);
    
    if ((table = [self->nameToTable objectForKey:_tableName]))
      return [table stringForKey:_key withDefaultValue:_default];
  }
  
  return nil;
}

- (NSString *)_bundleStringForKey:(NSString *)_key
  inTableNamed:(NSString *)_tableName
  withDefaultValue:(NSString *)_default
  languages:(NSArray *)_languages
{
  NSBundle     *bundle;
  NSString     *path;
  NSEnumerator *e;
  NSString     *language;
  
  if (_tableName == nil) _tableName = @"default";
  
  bundle = [[self bundleManager]
                  bundleProvidingResource:_tableName
                  ofType:@"strings"];
  if (bundle == nil)
    return nil;

  e = [_languages objectEnumerator];
  while ((language = [e nextObject])) {
    NSArray *ls;
    NSRange r;
      
    r = [language rangeOfString:@"_"];
    if (r.length > 0)
      language = [language substringToIndex:r.location];
      
    ls = [NSArray arrayWithObject:language];
      
    path = [bundle pathForResource:_tableName
                   ofType:@"strings"
                   languages:ls];
    if (path) {
      NSString *tname;
      id table;
      
      tname = [language stringByAppendingString:@"+++"];
      tname = [tname stringByAppendingString:_tableName];
        
      table = [_OGoStringTable stringTableWithPath:path];
      [self->nameToTable setObject:table forKey:tname];
      
      return [table stringForKey:_key withDefaultValue:_default];
    }
  }
    
  path = [bundle pathForResource:_tableName
                 ofType:@"strings"
                 languages:nil];
    
  if (path) {
    _OGoStringTable *table;
    
    table = [_OGoStringTable stringTableWithPath:path];
    if (self->nameToTable == nil)
      self->nameToTable = [[NSMutableDictionary alloc] initWithCapacity:16];
    
    [self->nameToTable setObject:table forKey:_tableName];
      
    return [table stringForKey:_key withDefaultValue:_default];
  }
  else if (debugOn) {
    NSLog(@"WARNING: missing string table %@ in bundle %@",
          _tableName, [bundle bundlePath]);
  }
  return _default;
}

- (NSString *)_resourceStringForKey:(NSString *)_key
  inTableNamed:(NSString *)_tableName
  withDefaultValue:(NSString *)_default
  languages:(NSArray *)_languages
{
  NSString      *rpath, *path;
  NSEnumerator  *e;
  NSString      *language;
  NSFileManager *fm;
  
  if (_tableName == nil) _tableName = @"default";
  
  fm = [NSFileManager defaultManager];
  rpath = [self findResourceDirectoryNamed:@"Resources" 
		fhsName:@"share/opengroupware.org-1.0a/translations/"];
  if (rpath == nil) {
    [self logWithFormat:@"missing $GNUSTEP_USER_ROOT/Resources directory ..."];
    return nil;
  }
  
  /* look into language projects .. */
  
  e = [_languages objectEnumerator];
  while ((language = [e nextObject])) {
    _OGoStringTable *table;
    NSArray  *ls;
    NSRange  r;
    NSString *tname;
      
    r = [language rangeOfString:@"_"];
    if (r.length > 0)
      language = [language substringToIndex:r.location];
    
    ls = [NSArray arrayWithObject:language];
    
    path = [_tableName stringByAppendingPathExtension:@"strings"];
    path = [[language stringByAppendingPathExtension:@"lproj"]
                      stringByAppendingPathComponent:path];
    path = [rpath stringByAppendingPathComponent:path];
    
    if (![fm fileExistsAtPath:path])
      continue;
    
    tname = [language stringByAppendingString:@"+++"];
    tname = [tname stringByAppendingString:_tableName];
    
    table = [_OGoStringTable stringTableWithPath:path];
    [self->nameToTable setObject:table forKey:tname];
    
    return [table stringForKey:_key withDefaultValue:_default];
  }
  
  /* look into resource dir */
  
  path = [_tableName stringByAppendingPathExtension:@"strings"];
  path = [rpath stringByAppendingPathComponent:path];

  if ([fm fileExistsAtPath:path]) {
    _OGoStringTable *table;
    
    table = [_OGoStringTable stringTableWithPath:path];
    if (self->nameToTable == nil)
      self->nameToTable = [[NSMutableDictionary alloc] initWithCapacity:16];
    
    [self->nameToTable setObject:table forKey:_tableName];
    
    return [table stringForKey:_key withDefaultValue:_default];
  }
  
  if (debugOn)
    NSLog(@"WARNING: missing string table %@ in %@", _tableName, path);
  
  return _default;
}

- (NSString *)stringForKey:(NSString *)_key
  inTableNamed:(NSString *)_tableName
  withDefaultValue:(NSString *)_default
  languages:(NSArray *)_languages
{
  NSString *s;
  
  if (_tableName == nil) _tableName = @"default";
  
  /* look into string cache */

  s = [self _cachedStringForKey:_key
            inTableNamed:_tableName
            withDefaultValue:_default
            languages:_languages];
  if (s) return s;
  
  if (self->nameToTable == nil)
    self->nameToTable = [[NSMutableDictionary alloc] initWithCapacity:16];
  
  /* search for string */

  s = [self _resourceStringForKey:_key
            inTableNamed:_tableName
            withDefaultValue:nil
            languages:_languages];
  if (s) return s;
  
  s = [self _bundleStringForKey:_key
            inTableNamed:_tableName
            withDefaultValue:nil
            languages:_languages];
  if (s) return s;
  
  s = [super stringForKey:_key inTableNamed:_tableName
             withDefaultValue:_default
             languages:_languages];
  
  return s ? s : _default;
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

@end /* OGoResourceManager */

@implementation _OGoStringTable

+ (id)stringTableWithPath:(NSString *)_path {
  return [[(_OGoStringTable *)[self alloc] initWithPath:_path] autorelease];
}

- (id)initWithPath:(NSString *)_path {
  self->path = [_path copyWithZone:[self zone]];
  return self;
}

- (void)dealloc {
  [self->path     release];
  [self->lastRead release];
  [self->data     release];
  [super dealloc];
}

/* loading */

- (NSException *)reportParsingError:(NSException *)_error {
  NSLog(@"%s: could not load strings file '%@': %@", 
        __PRETTY_FUNCTION__, self->path, _error);
  return nil;
}

- (void)checkState {
  NSString     *tmp;
  NSDictionary *plist;
  
  if (self->data)
    return;
  
  if ((tmp = [NSString stringWithContentsOfFile:self->path]) == nil) {
    self->data = nil;
    return;
  }
  
  self->data = nil;
  NS_DURING {
    if ((plist = [tmp propertyListFromStringsFileFormat]) == nil) {
      NSLog(@"%s: could not load strings file '%@'",
            __PRETTY_FUNCTION__,
            self->path);
    }
    self->data = [plist copy];
    self->lastRead = [[NSDate date] retain];
  }
  NS_HANDLER
    [[self reportParsingError:localException] raise];
  NS_ENDHANDLER;
}

/* access */

- (NSString *)stringForKey:(NSString *)_key withDefaultValue:(NSString *)_def {
  NSString *value;
  [self checkState];
  value = [self->data objectForKey:_key];
  return value ? value : _def;
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

@end /* _OGoStringTable */
