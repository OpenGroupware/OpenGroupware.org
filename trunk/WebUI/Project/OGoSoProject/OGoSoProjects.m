/*
  Copyright (C) 2005 SKYRIX Software AG

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

#import <Foundation/NSObject.h>

/*
  OGoSoProjects
  
  Represents the root node to the project application. Child objects are
  the actual project records in the database.
  
  The object will trigger the project desktop when being access using the
  web browser.
*/

@interface OGoSoProjects : NSObject
{
}

@end

#include "OGoSoProject.h"
#include "common.h"

@implementation OGoSoProjects

/* methods */

- (id)defaultAction:(id)_c {
  WOComponent *page;
  
  page = [[_c application] pageWithName:@"SkyProject4Desktop" inContext:_c];
  // TODO: we might want to support some parameters, eg tab selection
  [[[_c session] navigation] enterPage:page];
  return page;
}

- (id)GETAction:(id)_c {
  return [self defaultAction:_c];
}
- (id)indexAction:(id)_c {
  return [self defaultAction:_c];
}
- (id)viewAction:(id)_c {
  return [self defaultAction:_c];
}

/* lookup */

- (BOOL)isProjectID:(NSString *)_name {
  return ([_name length] > 0) 
    ? (isdigit([_name characterAtIndex:0]) ? YES : NO) : NO;
}

- (id)projectWithName:(NSString *)_name inContext:(id)_ctx {
  return [[[OGoSoProject alloc] initWithName:_name inContainer:self] 
	   autorelease];
}

- (id)lookupName:(NSString *)_name inContext:(id)_ctx acquire:(BOOL)_ac {
  id p;

  /* check SoClass method names */
  
  if ((p = [super lookupName:_name inContext:_ctx acquire:NO]) != nil)
    return p;
  
  /* TODO: lookup project by number */
  if ([self isProjectID:_name])
    return [self projectWithName:_name inContext:_ctx];
  
  // TODO: stop acquistion?
  return nil;
}

@end /* OGoSoProjects */
