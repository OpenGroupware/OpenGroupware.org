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

#include "common.h"
#include <GDLAccess/EOModel.h>

int main(int argc, char **argv, char **env) {
  NSAutoreleasePool *pool;
  NGBundleManager   *bm;
  NSException *e = nil;
  NSArray     *args;
  NSBundle    *modelBundle;
  NSString    *modelName;
  NSString    *modelPath;
  EOModel     *model;
  
  pool = [[NSAutoreleasePool alloc] init];
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif
  
  args = [[NSProcessInfo processInfo] arguments];
  if ([args count] < 2) {
    fprintf(stderr, "usage: %s modelname\n", argv[0]);
    exit(10);
  }
  modelName = [args objectAtIndex:1];

  /* find model */
  
  if ((bm = [NGBundleManager defaultBundleManager]) == nil) {
    fprintf(stderr, 
	    "ERROR: could not load model (failed to setup bundle manager).\n");
    exit(9);
  }

  modelBundle = [bm bundleProvidingResource:modelName ofType:@"EOModels"];
  if (modelBundle == nil) {
    fprintf(stderr,
	    "ERROR: did not find bundle for model %s (type=EOModels).\n",
	    [modelName cString]);
    exit(8);
  }
  
  modelPath = [modelBundle pathForResource:modelName ofType:@"eomodel"];
  if (modelPath == nil) {
    fprintf(stderr,
	    "ERROR: did not find path of model %s in bundle %s.\n\n",
	    [modelName cString], [[modelBundle bundlePath] cString]);
    exit(7);
  }
  
  /* load model */
  
  NS_DURING {
    model = [[EOModel alloc] initWithContentsOfFile:modelPath];
  }
  NS_HANDLER {
    fprintf(stderr, "ERROR: %s: %s\n",
	    [[e name]   cString],
	    [[e reason] cString]);
    model = nil;
  }
  NS_ENDHANDLER;

  if (model) {
    printf("did load model: %s\n", [modelPath cString]);
    exit(0);
  }
  
  if (e) {
    fprintf(stderr, "ERROR: failed to load model '%s' (path=%s): %s\n", 
	    [modelName cString], [modelPath cString],
	    [[e description] cString]);
  }
  else {
    fprintf(stderr, "ERROR: failed to load model '%s' (path=%s).\n", 
	    [modelName cString], [modelPath cString]);
  }
  
  exit (1);
  return 1;
}
