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
// $Id$

#include "LSWModuleManager.h"
#include "common.h"

#if !LIB_FOUNDATION_LIBRARY
#  define USE_NGPropertyListParser 1
#endif

#if USE_NGPropertyListParser
#  include <NGExtensions/NGPropertyListParser.h>
#endif

@interface OGoModuleManager_MissingResource : NSObject
@end

@implementation OGoModuleManager_MissingResource
@end

@implementation OGoModuleManager

static OGoModuleManager_MissingResource *missing = nil;
static BOOL debugOn     = NO;
static BOOL debugConfig = NO;

+ (int)version {
  return 2;
}
+ (void)initialize {
  if (missing == nil)
    missing = [[OGoModuleManager_MissingResource alloc] init];
}

- (void)dealloc {
  if (self->componentsConfig)
    NSFreeMapTable(self->componentsConfig);
  [super dealloc];
}

/* NSUserDefaults */

- (void)registerDefaultsAtPath:(NSString *)_path {
  // UNICODE
  NSDictionary *defaults;

  if (debugOn) [self logWithFormat:@"register bundle defaults: %@", _path];
  
  if ([_path length] < 2) return;
  
#if USE_NGPropertyListParser
  defaults = NGParsePropertyListFromFile(_path);
  if (![defaults isKindOfClass:[NSDictionary class]]) {
    [self logWithFormat:@"property list is not a dictionary: '%@'", _path];
    defaults = nil;
  }
#else
  defaults = [NSDictionary dictionaryWithContentsOfFile:_path];
#endif
  if (defaults == nil) {
    [self logWithFormat:
	    @"WARNING(%s): could not load defaults of bundle %@ (path=%@)",
	    __PRETTY_FUNCTION__, 
	    [[NSBundle bundleForClass:[self class]] bundleName], 
	    _path];
    return;
  }
  
  if (debugOn)
    [self logWithFormat:@"  register bundle defaults: %@", defaults];
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (void)registerDefaultsOfBundle:(NSBundle *)_bundle {
  NSString *path;
  
  if ((path = [_bundle pathForResource:@"Defaults" ofType:@"plist"]))
    [self registerDefaultsAtPath:path];
  else if (debugOn)
    [self logWithFormat:@"no Defaults.plist in bundle: %@", _bundle];
}

/* Bundle Load Notification */

- (void)bundleManager:(NGBundleManager *)_manager
  didLoadBundle:(NSBundle *)_bundle
{
  [self registerDefaultsOfBundle:_bundle];
  
#if DEBUG && 0
  NSLog(@"%s: loaded bundle: %@", __PRETTY_FUNCTION__, [_bundle bundleName]);
#endif
}

- (id)_loadCfgInBundle:(NSBundle *)bundle name:(NSString *)_name 
  language:(NSString *)_language
{
  NSDictionary *plist;
  NSString *path;
  
  if ([_name length] == 0)
    return nil;
  
  NSCAssert(bundle, @"missing bundle ..");
  
  /* first check whether there is a cfg for the component itself */
  
  path = [bundle pathForResource:_name ofType:@"ccfg"
                 languages:[NSArray arrayWithObject:_language]];
  if (path) {
    if ((plist = [NSDictionary dictionaryWithContentsOfFile:path])) {
      if (debugConfig) {
	NSLog(@"%s: found %@:%@ in ccfg: %@", __PRETTY_FUNCTION__,
	      _name, _language, path);
      }
      return plist;
    }
  }
  
  /* then check whether there is a global cfg for the module */
  
  path = [bundle pathForResource:[bundle bundleName] ofType:@"ccfg"
                 languages:[NSArray arrayWithObject:_language]];
  if (path != nil) {
    if ((plist = [NSDictionary dictionaryWithContentsOfFile:path]))
      plist = [plist objectForKey:_name];
    if (plist != nil) {
      if (debugConfig) {
	NSLog(@"%s: found %@:%@ in ccfg: %@", __PRETTY_FUNCTION__,
	      _name, _language, path);
      }
      return plist;
    }
  }

  /* then look into components cfg of the main bundle */
  
  bundle = [NGBundle mainBundle];

  path = [bundle pathForResource:@"components" ofType:@"cfg"
                 languages:[NSArray arrayWithObject:_language]];
  if (path) {
    if ((plist = [NSDictionary dictionaryWithContentsOfFile:path]))
      plist = [plist objectForKey:_name];
    if (plist != nil) {
      if (debugConfig) {
	NSLog(@"%s: found %@:%@ in ccfg: %@", __PRETTY_FUNCTION__,
	      _name, _language, path);
      }
      return plist;
    }
  }
  if (debugConfig) {
    [self logWithFormat:@"%s: did not found config for %@:%@ in bundle: %@", 
	  __PRETTY_FUNCTION__, _name, _language, 
	  [[NGBundle bundleForClass:[self class]] bundlePath]];
  }
  return nil;
}

static inline id
_cfgValueForKey(OGoModuleManager *self, NSBundle *bundle, NSString *_key,
                NSString *_name, NSString *_language)
{
  NSString     *lname;
  NSDictionary *cfg;
  
  lname = [[NSString alloc] initWithFormat:@"%@:%@", _name, _language];
  
  if (self->componentsConfig == NULL) {
    self->componentsConfig = NSCreateMapTable(NSObjectMapKeyCallBacks,
                                              NSObjectMapValueCallBacks,
                                              64);
  }
  
  if ((cfg = NSMapGet(self->componentsConfig, lname)) == nil) {
    cfg = [self _loadCfgInBundle:bundle name:_name language:_language];
    if (cfg == nil)
      cfg = (id)missing;
    NSMapInsert(self->componentsConfig, lname, cfg);
  }
  if (cfg == (id)missing)
    cfg = nil;
  
  [lname release];
  return [cfg objectForKey:_key];
}

- (id)configValueForKey:(NSString *)_key
  inComponent:(WOComponent *)_component
  languages:(NSArray *)_languages
{
  NSBundle *bundle;
  NSString *name;
  int i, count;
  id value = nil;

  if (_component == nil) {
    [self logWithFormat:
	    @"WARNING: got no component for lookup of config key: '%@'", _key];
    return nil;
  }
  if ((name = [_component name]) == nil) {
    [self logWithFormat:
	    @"WARNING: got no name for component (required for lookup of "
	    @"config key '%@'): %@", _key, _component];
    return nil;
  }
  bundle = [NGBundle bundleForClass:[self class]];

#ifdef DEBUG
  if (bundle != [NGBundle bundleForClass:[_component class]]) {
    NSLog(@"WARNING(%s): tried to lookup config of component %@ in %@",
          __PRETTY_FUNCTION__, name, [bundle bundleName]);
  }
#endif
  
  if (debugConfig) {
    NSLog(@"%s: lookup %@ of %@ in %@ for languages %@",
	  __PRETTY_FUNCTION__,
	  _key, name, [bundle bundleName], [_languages objectAtIndex:0]);
  }
  
  for (i = 0, count = [_languages count]; (value == nil) && (i < count); i++) {
    value = _cfgValueForKey(self, bundle, _key, name,
                            [_languages objectAtIndex:i]);
  }
  return value;
}

@end /* OGoModuleManager */

/* for compatibility, to be removed */

@implementation LSWModuleManager
@end /* LSWModuleManager */
