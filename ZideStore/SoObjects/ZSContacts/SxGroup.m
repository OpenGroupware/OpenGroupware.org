/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#include "SxGroup.h"
#include "SxGroupsFolder.h"
#include <ZSFrontend/SxRendererFactory.h>
#include <ZSFrontend/SxRenderer.h>
#include <ZSBackend/SxContactManager.h>
#include "common.h"

@implementation SxGroup

/* zl */

- (int)zlGenerationCount {
  return [[[self objectInContext:nil] valueForKey:@"objectVersion"] intValue];
}

/* updating/inserting */

- (NSString *)entityName {
  return @"Team";
}
- (NSString *)updateCommandName {
  return @"team::set";
}
- (NSString *)newCommandName {
  return @"team::new";
}
+ (NSString *)getCommandName {
  return @"team::get";
}
+ (NSString *)deleteCommandName {
  return @"team::delete";
}

- (Class)selfRendererClass {
  static Class RendererClass = Nil;
  static BOOL didInit = NO;
  if (!didInit) {
    NSString *className = @"SxZLGroupRenderer";
    didInit = YES;
    
    if ((RendererClass = NSClassFromString(className)) == Nil)
      [self logWithFormat:@"Note: attempt to access '%@'", className];
    // TODO: need a fallback renderer
  }
  return RendererClass;
}

- (id)davQueryOnSelf:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  /* Note: this is also called for bulk fetches */
  NSDictionary      *res;
  SxContactManager  *manager;
  id                render;
  
  manager = [SxContactManager managerWithContext:
				[self commandContextInContext:_ctx]];
  
  res = [manager fullGroupInfoForPrimaryKey:[self primaryKey]];

  if (res == nil) {
    [self logWithFormat:@"group does not exist: %@", [self nameInContainer]];
    return [NSException exceptionWithHTTPStatus:404 /* not found */
                        reason:@"tried to lookup invalid group key"];
  }
 
  if ((render = [self selfRendererClass]) != nil) {
    render = [render rendererWithFolder:(SxFolder *)[self container]
		     inContext:_ctx];
    res = [render renderEntry:res];
  }
  else /* fallback, return SoObject to SOPE WebDAV layer */
    res = (id)self;
  
  return [NSArray arrayWithObject:res];
}

@end /* SxGroup */
