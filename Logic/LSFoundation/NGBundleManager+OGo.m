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

#include "NGBundleManager+OGo.h"
#include "common.h"

@implementation NGBundleManager(OGo)

static int      logBundleLoading        = -1;
static NSString *OGoBundlePathSpecifier = nil;
static NSString *FHSOGoBundleDir        = nil;

static void _ensureLogBundleLoadingDefault(void) {
  if (logBundleLoading == -1) {
    // TODO: make that a logger
    logBundleLoading = [[NSUserDefaults standardUserDefaults]
			 boolForKey:@"OGoLogBundleLoading"] ? 1 : 0;
  }
}

- (void)loadBundlesOfType:(NSString *)_type inPath:(NSString *)_p {
  NGBundleManager *bm;
  NSFileManager   *fm;
  NSEnumerator    *e;
  NSString        *p;

  _ensureLogBundleLoadingDefault();
  if (logBundleLoading)
    [self logWithFormat:@"  load bundles of type %@ in path %@", _type, _p];
  
  bm = [NGBundleManager defaultBundleManager];
  fm = [NSFileManager defaultManager];
  e  = [[[fm directoryContentsAtPath:_p] 
	  sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
  
  while ((p = [e nextObject]) != nil) {
    NSBundle *bundle;
    
    if (![[p pathExtension] isEqualToString:_type])
      continue;
    p = [_p stringByAppendingPathComponent:p];
    
    if ((bundle = [bm bundleWithPath:p]) == nil)
      continue;
    
    if (![bm loadBundle:bundle]) {
      [self logWithFormat:@"could not load bundle: %@", bundle];
      continue;
    }
    
    if (logBundleLoading) {
      [self logWithFormat:@"    did load bundle: %@", 
	    [[bundle bundlePath] lastPathComponent]];
    }
  }
}

- (void)loadBundlesOfType:(NSString *)_type typeDirectory:(NSString *)_dir
  inPaths:(NSArray *)_paths
{
  // eg called by OGoContextManager +loadCommandBundles
  NSEnumerator *e;
  NSString     *p;
  
  /* ensure category defaults */
  
  _ensureLogBundleLoadingDefault();
  
  if (OGoBundlePathSpecifier == nil) {
    OGoBundlePathSpecifier = [[[NSUserDefaults standardUserDefaults] 
				stringForKey:@"OGoBundlePathSpecifier"] copy];
  }
  if (FHSOGoBundleDir == nil) {
    FHSOGoBundleDir = [[[NSUserDefaults standardUserDefaults]
			 stringForKey:@"OGoFHSBundleSubPath"] copy];
  }
  
  if (logBundleLoading) 
    [self logWithFormat:@"load %@/%@ bundles ...", _type, _dir];
  
  /* load bundles */
  
  e = [_paths objectEnumerator];
  while ((p = [e nextObject]) != nil) {
    NSString *dp;
    
    if ([p rangeOfString:FHSOGoBundleDir].length > 0) {
      // this is an FHS path, use different lookup algorithm
      // TODO: somewhat a hack ..., fix somehow
      
      [self loadBundlesOfType:_type inPath:p];
      continue;
    }
    
    dp = [p stringByAppendingPathComponent:OGoBundlePathSpecifier];
    [self loadBundlesOfType:_type inPath:dp];
    
    if ([_dir length] > 0) {
      dp = [dp stringByAppendingPathComponent:_dir];
      [self loadBundlesOfType:_type inPath:dp];
    }
  }
}

@end /* NGBundleManager(OGo) */
