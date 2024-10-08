/*
  Copyright (C) 2004-2006 Helge Hess

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

#include "OGoWebBundleLoader.h"
#include <NGObjWeb/SoProductRegistry.h>
#include "common.h"

@implementation OGoWebBundleLoader

static BOOL logBundleLoading          = NO;
static BOOL loadWebUIBundlesOnStartup = YES;

// TODO: derive versions from Version file (see SaxXMLReaderFactory.m)
#if CONFIGURE_64BIT
static NSString *FHSOGoBundleDir = @"lib64/opengroupware.org-5.5/";
#else
static NSString *FHSOGoBundleDir = @"lib/opengroupware.org-5.5/";
#endif
static NSArray  *FHSPathes = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  logBundleLoading = [ud boolForKey:@"OGoLogBundleLoading"];
  
  // TODO: should be some search path, eg LD_LIBRARY_SEARCHPATH?
  if (FHSPathes == nil) {
    FHSPathes = 
      [[NSArray alloc] initWithObjects:
#ifdef FHS_INSTALL_ROOT
			 FHS_INSTALL_ROOT,
#endif
			 @"/usr/local/", @"/usr/", nil];
  }
}

+ (id)bundleLoader {
  return [[[self alloc] init] autorelease];
}

- (void)dealloc {
  [super dealloc];
}

/* loading */

- (void)loadBundlesOfType:(NSString *)_type inPath:(NSString *)_p {
  // TODO: use NGBundleManager+OGo in LSFoundation
  //       => cannot ATM, because we also register in the product registry
  SoProductRegistry *reg;
  NGBundleManager *bm;
  NSFileManager   *fm;
  NSEnumerator *e;
  NSString     *p;
  
  reg = [SoProductRegistry sharedProductRegistry];
  
  if (logBundleLoading) {
    [self logWithFormat:@"  load bundles of type '%@' in path: '%@'", 
	  _type, _p];
  }
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
      [self errorWithFormat:@"could not load bundle: %@", bundle];
      continue;
    }
    
    if (logBundleLoading) {
      [self logWithFormat:@"    did load bundle: %@", 
	    [[bundle bundlePath] lastPathComponent]];
    }
    
    // TODO: this should happen automagically? (SoProductRegistry listens for
    //       bundle load notifications?)
    [reg registerProductBundle:bundle];
  }
}

- (NSString *)bundlePathSpecifier {
  return [[NSUserDefaults standardUserDefaults]
	                  stringForKey:@"OGoBundlePathSpecifier"];
}

- (void)loadBundles {
  NGBundleManager *bm;
  NSEnumerator *e;
  NSString     *p;
  NSArray      *pathes;
  NSString     *OGoBundlePathSpecifier;
  NSArray      *oldPathes;
  
  OGoBundlePathSpecifier = [self bundlePathSpecifier];

  /* find pathes */
  
  pathes = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
					       NSAllDomainsMask,
					       YES);
  if ([FHSOGoBundleDir isNotEmpty]) {
    unsigned i, count;
    
    for (i = 0, count = [FHSPathes count]; i < count; i++) {
      p = [FHSPathes objectAtIndex:i];
      p = [p stringByAppendingPathComponent:FHSOGoBundleDir];
      p = [p stringByAppendingPathComponent:@"webui/"];
      pathes = [pathes arrayByAddingObject:p];
    }
  }
  
  /* temporarily patch bundle search path */
  
  bm = [NGBundleManager defaultBundleManager];
  oldPathes = [[bm bundleSearchPaths] copy];
  if ([pathes isNotEmpty]) {
    /* add default fallback */
    [bm setBundleSearchPaths:[pathes arrayByAddingObjectsFromArray:oldPathes]];
  }
  
  /* load WebUI bundles */
  
  if (loadWebUIBundlesOnStartup) {
    if (logBundleLoading) [self logWithFormat:@"load WebUI plugins ..."];
    e = [pathes objectEnumerator];
    while ((p = [e nextObject]) != nil) {

      if ([p rangeOfString:FHSOGoBundleDir].length > 0) {
        // this is an FHS path, use different lookup algorithm
        // TODO: somewhat a hack ..., fix somehow
        
        [self loadBundlesOfType:@"lso" inPath:p];
        continue;
      }
      
      p = [p stringByAppendingPathComponent:OGoBundlePathSpecifier];
      [self loadBundlesOfType:@"lso" inPath:p];
      p = [p stringByAppendingPathComponent:@"WebUI"];
      [self loadBundlesOfType:@"lso" inPath:p];
    }
  }
  
  /* unpatch bundle search path */
  
  [bm setBundleSearchPaths:oldPathes];
  [oldPathes release];
  
  /* load SoProducts */
  
  [[SoProductRegistry sharedProductRegistry] loadAllProducts];
}

@end /* OGoWebBundleLoader */
