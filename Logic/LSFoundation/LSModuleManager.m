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

#include "LSModuleManager.h"
#include "common.h"

#if NeXT_Foundation_LIBRARY || COCOA_Foundation_LIBRARY
#  include <NGExtensions/NGPropertyListParser.h>
#endif

@interface LSModuleManager(PrivateMethods)
- (void)registerDefaults;
- (void)registerDefaultsOfBundle:(NSBundle *)_bundle;
@end

@interface NSObject(OGoModuleManagerLoad)

+ (void)lsModuleManager:(LSModuleManager *)_manager 
  didLoadClassFromBundle:(NSBundle *)_bundle;

@end /* NSObject(OGoModuleManagerLoad) */

@implementation LSModuleManager

+ (int)version {
  return 1;
}

- (id)initForBundle:(NSBundle *)_bundle bundleManager:(NGBundleManager *)_mng {
  if ((self = [super init])) {
    NSString *s;
    
#if 0
    [self debugWithFormat:@"initializing command BUNDLE %@.",
          [[_bundle bundlePath] lastPathComponent]];
#endif
    
    [self registerDefaults];
    
    s = [_bundle bundlePath];
    s = [[s lastPathComponent] stringByDeletingPathExtension];
    self->moduleName   = [s copy];
    self->moduleBundle = [_bundle retain];
    
    [self registerDefaultsOfBundle:_bundle];
  }  
  return self;
}

- (id)initWithModule:(NSString *)_name fromBundle:(NSBundle *)_bundle {
  if ((self = [super init])) {
    self->moduleName   = [_name copy];
    self->moduleBundle = [_bundle retain];

    [self registerDefaultsOfBundle:_bundle];
  }
  return self;
}
- (id)init {
  return [self initWithModule:NSStringFromClass([self class])
               fromBundle:[NGBundle bundleForClass:[self class]]];
}

- (void)dealloc {
  [self->moduleName   release];
  [self->moduleBundle release];
  [super dealloc];
}

/* NSUserDefaults */

- (void)registerDefaultsOfBundle:(NSBundle *)_bundle {
  NSDictionary *defaults;
  NSString *path;

  if ((path = [_bundle pathForResource:@"Defaults" ofType:@"plist"]) == nil) 
    return;

#if NeXT_Foundation_LIBRARY || COCOA_Foundation_LIBRARY
  defaults = NGParsePropertyListFromFile(path);
#else
  defaults = [NSDictionary dictionaryWithContentsOfFile:path];
#endif
  
  if (defaults == nil) {
    [self warnWithFormat:
            @"%s: couldn't load defaults of bundle %@ (path=%@)",
            __PRETTY_FUNCTION__,
            [_bundle bundleName], path];
    return;
  }
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

/* configuration */

- (void)registerDomain:(NSString *)_name factory:(id)_factory {
}

- (void)configureDomain:(NSString *)_name
  withDictionary:(NSDictionary *)_cfg
  factory:(id)_factory
{
  NSDictionary *operations = nil;

  operations = [_cfg objectForKey:@"operations"];
}

- (void)configureWithDictionary:(NSDictionary *)_cfg factory:(id)_factory {
  NSArray      *domains;
  NSDictionary *domainCfg;
  int     i;

  domains   = [_cfg objectForKey:@"domainList"];
  domainCfg = [_cfg objectForKey:@"domains"];
  
  for (i = 0; i < [domains count]; i++) {
    NSString *domainName = [domains objectAtIndex:i];

    [self registerDomain:domainName factory:_factory];
    
    [self configureDomain:domainName
          withDictionary:[domainCfg objectForKey:domainName]
          factory:_factory];
  }
}

/* module accessors */

- (NSString *)moduleName {
  return self->moduleName
    ? self->moduleName
    : NSStringFromClass([self class]);
}

- (NSBundle *)moduleBundle {
  return self->moduleBundle
    ? self->moduleBundle : [NGBundle bundleForClass:[self class]];
}

- (int)moduleMajorVersion {
  return 1;
}
- (int)moduleMinorVersion {
  return 0;
}

/* defaults */

- (void)registerDefaults {
  if (![[self class] respondsToSelector:_cmd])
    return;
  
  [(id)[self class] performSelector:_cmd];
}

/* postprocessing */

- (void)registerClassesOfBundle:(NSBundle *)_bundle {
  /* ensure that +initialize is called right after loading the plugin */
  NSEnumerator *classes;
  NSDictionary *classDict;
  
  classes = [[_bundle providedResourcesOfType:@"classes"] objectEnumerator];
  while ((classDict = [classes nextObject]) != nil) {
    NSString *clazzName;
    Class    clazz;
    
    if ((clazzName = [classDict objectForKey:@"name"]) == nil) {
      [self errorWithFormat:@"got invalid 'classes' dict: %@", classDict];
      continue;
    }
    
    if ((clazz = NSClassFromString(clazzName)) == Nil) {
      [self warnWithFormat:
	      @"did not find class as registered in bundle: '%@'\n  "
	      @"%@", clazzName, _bundle];
      continue;
    }
    
    [clazz lsModuleManager:self didLoadClassFromBundle:_bundle];
  }
}

/* Bundle Load Notification */

- (void)bundleManager:(NGBundleManager *)_manager
  didLoadBundle:(NSBundle *)_bundle
{
  [self registerClassesOfBundle:_bundle];
  
#if DEBUG && 0
  NSLog(@"%s: loaded bundle: %@", __PRETTY_FUNCTION__, [_bundle bundleName]);
#endif
}

@end /* LSModuleManager */

@implementation NSObject(LSModuleManagerLoad)

+ (void)lsModuleManager:(LSModuleManager *)_manager 
  didLoadClassFromBundle:(NSBundle *)_bundle
{
  // do nothing, +initialize will be called by the runtime
}

@end /* NSObject(LSModuleManagerLoad) */
