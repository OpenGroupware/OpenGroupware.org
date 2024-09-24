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

#include <OGoFoundation/OGoModuleManager.h>

@interface SkyProject4Module : OGoModuleManager
{
}

@end

#include "common.h"

@implementation SkyProject4Module

- (void)bundleManager:(NGBundleManager *)_manager
  didLoadBundle:(NSBundle *)_bundle
{
  WORequestHandler *rh;
  
  [super bundleManager:_manager didLoadBundle:_bundle];

#if DEBUG && 0
  NSLog(@"register URL handler classes ..");
#endif

  [NSURLHandle registerURLHandleClass:
                 NSClassFromString(@"WOHTTPURLHandle")];
  [NSURLHandle registerURLHandleClass:
                 NGClassFromString(@"SkyProjectURLHandle")];
  [NSURLHandle registerURLHandleClass:
                 NGClassFromString(@"SkyURLHandle")];

#if DEBUG && 0
  NSLog(@"register doc request handler ..");
#endif
  
  rh = [NGClassFromString(@"SkyP4DocumentRequestHandler") alloc];
  rh = [rh init];
  
  [[WOApplication application]
                  registerRequestHandler:rh
                  forKey:@"g"];
  [rh release]; rh = nil;
}

@end /* SkyProject4Module */
