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

#include "OGoModuleManager.h"
#include "common.h"

#if !LIB_FOUNDATION_LIBRARY
#  define USE_NGPropertyListParser 1
#endif

#if USE_NGPropertyListParser
#  include <NGExtensions/NGPropertyListParser.h>
#endif

@implementation OGoModuleManager

static BOOL debugOn = NO;

+ (int)version {
  return 2;
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

@end /* OGoModuleManager */

/* for compatibility, to be removed */

@implementation LSWModuleManager
@end /* LSWModuleManager */
