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

@implementation LSModuleManager

+ (int)version {
  return 1;
}

- (id)initForBundle:(NSBundle *)_bundle bundleManager:(NGBundleManager *)_mng {
  if ((self = [super init])) {
#if 0
    NSLog(@"initializing command BUNDLE %@.",
          [[_bundle bundlePath] lastPathComponent]);
#endif
    [self registerDefaults];

    self->moduleName =
      [[[[_bundle bundlePath] lastPathComponent]
                  stringByDeletingPathExtension]
                  copyWithZone:[self zone]];
    self->moduleBundle = RETAIN(_bundle);
    
    [self registerDefaultsOfBundle:_bundle];
  }  
  return self;
}

- (id)initWithModule:(NSString *)_name fromBundle:(NSBundle *)_bundle {
  if ((self = [super init])) {
    self->moduleName   = [_name copyWithZone:[self zone]];
    self->moduleBundle = RETAIN(_bundle);

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
    [self logWithFormat:
            @"WARNING(%s): couldn't load defaults of bundle %@ (path=%@)",
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

@end /* LSModuleManager */
