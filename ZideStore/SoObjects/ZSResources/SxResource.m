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

#include "SxResource.h"
#include "SxResourceGroupFolder.h"
#include <ZSFrontend/SxRenderer.h>
#include <ZSBackend/SxContactManager.h>
#include "common.h"

@implementation SxResource

/* zl */

- (int)zlGenerationCount {
  // TODO:
  return [[[self objectInContext:nil] valueForKey:@"objectVersion"] intValue];
}

/* updating/inserting */

- (NSString *)entityName {
  return @"Resource";
}
- (NSString *)updateCommandName {
  return @"resource::set";
}
- (NSString *)newCommandName {
  return @"resource::new";
}
+ (NSString *)getCommandName {
  return @"resource::get";
}
+ (NSString *)deleteCommandName {
  return @"resource::delete";
}

#if 0
- (Class)selfRendererClass {
  static Class RendererClass = Nil;
  static BOOL didInit = NO;
  if (!didInit) {
    NSString *className = @"SxZLGroupRenderer";
    didInit = YES;
    
    if ((RendererClass = NGClassFromString(className)) == Nil)
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

- (id)GETAction:(WOContext *)_ctx {
  SxContactManager *manager;
  NSEnumerator *e;
  id person;

  manager = [SxContactManager managerWithContext:
                              [self commandContextInContext:_ctx]];
  
  person = [self primaryKey];
  person = [EOKeyGlobalID globalIDWithEntityName:[self entityName]
                          keys:&person keyCount:1 zone:NULL];
  e = [manager idsAndVersionsAndVCardsForGlobalIDs:
               [NSArray arrayWithObject:person]];
  // taking new vCard renderer
  if ((person = [e nextObject]) == nil) {
    return [NSException exceptionWithHTTPStatus:500 /* forbidden */
                        reason:@"invalid person object"];
  }
  else {
    WOResponse *response;
    NSString *vCard;

    response = [WOResponse responseWithRequest:[_ctx request]];
      
    vCard = [person valueForKey:@"vCardData"];
    if (vCard != nil) {
      NSData *contentData;

      contentData = [NSData dataWithBytes:[vCard cString]
                            length:[vCard cStringLength]];
    
      [response setStatus:200];
      [response setContent:contentData];
    }
    else {
      [response setStatus:500];
      // vCard rendering failed
    }
    return response;
  }
}
#endif
  
@end /* SxResource */
