/*
  Copyright (C) 2002-2004 SKYRIX Software AG

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

#include "SxPerson.h"
#include "SxPersonFolder.h"
#include "SxVCardPersonRenderer.h"
#include <ZSBackend/SxContactManager.h>
#include <ZSBackend/SxUpdatePerson.h>
#include <ZSFrontend/SxFolder.h>
#include <ZSFrontend/SxRendererFactory.h>
#include <ZSFrontend/SxRenderer.h>
#include "common.h"

@implementation SxPerson

/* updating/inserting */

- (void)clearVars {
  [super clearVars];
  [self->enterprise release]; self->enterprise = nil;
}

- (NSString *)entityName {
  return @"Person";
}
- (NSString *)updateCommandName {
  return @"person::set";
}
- (NSString *)newCommandName {
  return @"person::new";
}

+ (NSString *)getCommandName {
  return @"person::get";
}
+ (NSString *)deleteCommandName {
  return @"person::delete";
}

/* updating */

- (BOOL)fillCompanyRecord:(NSMutableDictionary *)values
  from:(NSDictionary *)_setProps
  keySet:(NSMutableArray *)keys
{
  return [super fillCompanyRecord:values from:_setProps keySet:keys];
}

- (Class)selfRendererClass {
  static Class RendererClass = Nil;
  static BOOL didInit = NO;
  if (!didInit) {
    NSString *className = @"SxZLFullPersonRenderer";
    didInit = YES;
    
    if ((RendererClass = NSClassFromString(className)) == Nil)
      [self logWithFormat:@"Note: attempt to access '%@'", className];
    // TODO: need a fallback renderer
  }
  return RendererClass;
}

- (id)davQueryOnSelf:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  /* Note: this is also called for bulk fetches */
  NSDictionary           *res;
  SxContactManager       *manager;
  id                     render;
  
  manager =
    [SxContactManager managerWithContext:[self commandContextInContext:_ctx]];

#if 0
  res = [manager fullPersonInfoForPrimaryKey:[self primaryKey]];
#else
  res = [[manager fullObjectInfosForPrimaryKeys:
		    [NSArray arrayWithObject:[self primaryKey]]
		  withSetIdentifier:
                    [(SxPersonFolder *)[self container] contactSetID]]
                  lastObject];
  
#endif
  if (res == nil) {
    [self logWithFormat:@"person does not exist: %@", [self nameInContainer]];
    return [NSException exceptionWithHTTPStatus:404 /* not found */
                        reason:@"tried to lookup invalid person key"];
  }
  
  if ((render = [self selfRendererClass]) != Nil) {
    render = [render rendererWithContext:_ctx
		     baseURL:[(SxFolder *)[self container] baseURL]];
    res = [render renderEntry:res];
  }
  else /* fallback, return SoObject to SOPE WebDAV layer */
    res = (id)self;
  
  return [NSArray arrayWithObject:res];
}

- (id)GETAction:(WOContext *)_ctx {
  SxContactManager *manager;
  id renderer, res;
  
  manager = [SxContactManager managerWithContext:
				[self commandContextInContext:_ctx]];
  
  { // taking new vCard renderer
    NSEnumerator *e;
    id person;

    person = [self primaryKey];
    person = [EOKeyGlobalID globalIDWithEntityName:[self entityName]
                          keys:&person keyCount:1 zone:NULL];
    e = [manager idsAndVersionsAndVCardsForGlobalIDs:
                 [NSArray arrayWithObject:person]];

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
  
  if ((res = [manager fullPersonInfoForPrimaryKey:[self primaryKey]]) == nil) {
    return [NSException exceptionWithHTTPStatus:500 /* forbidden */
                        reason:@"invalid person object"];
  }

  if ((renderer = [SxVCardPersonRenderer renderer]) != nil) {
    return [renderer vCardResponseForObject:res inContext:_ctx
                     container:[self container]];
  }

  return [NSException exceptionWithHTTPStatus:500 /* forbidden */
                      reason:@"initializing renderer failed"];
}

- (Class)updateClass {
  static Class SxUpdatePersonClass = NULL;

  if (SxUpdatePersonClass == NULL) {
   SxUpdatePersonClass =
      NSClassFromString(@"SxUpdatePerson");
  }
  return SxUpdatePersonClass;
}

- (Class)zideLookParserClass {
  static Class SxZLFullPersonParserClass = NULL;

  if (SxZLFullPersonParserClass == NULL) {
    SxZLFullPersonParserClass =
      NSClassFromString(@"SxZLFullPersonParser");
  }
  return SxZLFullPersonParserClass;
}

- (Class)evolutionParserClass {
  static Class SxEvoFullPersonParserClass = NULL;

  if (SxEvoFullPersonParserClass == NULL) {
    SxEvoFullPersonParserClass =
      NSClassFromString(@"SxEvoFullPersonParser");
  }
  return SxEvoFullPersonParserClass;
}

@end /* SxPerson */
