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

#include <OGoFoundation/OGoResourceManager.h>
#include "common.h"
#include "used_privates.h"

/* 
   this category can be used to support XML Form files as OpenGroupware.org
   NGObjWeb components 
*/

// TODO: is this still required ??

@implementation OGoResourceManager(LookupXML)

#if 1

- (WOComponentDefinition *)_definitionWithName:(NSString *)_name
  path:(NSString *)_path
  baseURL:(NSString *)_baseURL
  frameworkName:(NSString *)_fwname
{
  /* definition factory */
  
  if ([[_path pathExtension] isEqualToString:@"sfm"]) {
    return [[SkyComponentDefinition alloc]
                                    initWithName:_name path:_path
                                    baseURL:_baseURL frameworkName:_fwname];
  }
  
  return [super _definitionWithName:_name path:_path
                baseURL:_baseURL frameworkName:_fwname];
}

#else

- (id)definitionForComponent:(NSString *)_name
  languages:(NSArray *)_languages
{
  id       cdef;
  NSString *path;
  NSBundle *bundle;
  
  bundle = [[self bundleManager]
                  bundleProvidingResource:_name
                  ofType:@"WOComponents"];
  
  path = [bundle pathForResource:_name ofType:@"xml"];
  
  if (path == nil) {
    if ((cdef = [super definitionForComponent:_name languages:_languages])) {
      //NSLog(@"%s: found component: %@", __PRETTY_FUNCTION__, _name);
      return cdef;
    }
    return nil;
  }
  
  NSLog(@"Found XML component %@: %@", _name, path);
  
  cdef = [[SkyComponentDefinition alloc]
                                  initWithName:_name
                                  path:path
                                  baseURL:nil
                                  frameworkName:nil];
  if (cdef == nil)
    return nil;

  return [cdef autorelease];
}
#endif

@end /* WOResourceManager(LookupXML) */
