/*
  Copyright (C) 2006-2007 Whitemice Consulting

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
#include "zOGIAction.h"
#include "zOGIAction+Object.h"
#include "zOGIAction+Resource.h"

@implementation zOGIAction(Resource)

-(NSArray *)_renderResources:(NSArray *)_resources withDetail:(NSNumber *)_detail {
  NSMutableArray *result;
  NSDictionary   *eoResource;
  int             count;

  result = [NSMutableArray arrayWithCapacity:[_resources count]];
  for (count = 0; count < [_resources count]; count++) {
    eoResource = [_resources objectAtIndex:count];
    [result addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys: 
       [eoResource valueForKey:@"appointmentResourceId"], @"objectId",
       @"Resource", @"entityName",
       [self NIL:[eoResource valueForKey:@"category"]], @"category",
       [self NIL:[eoResource valueForKey:@"email"]], @"email",
       [self NIL:[eoResource valueForKey:@"emailSubject"]], @"emailSubject",
       [self NIL:[eoResource valueForKey:@"name"]], @"name",
       [self ZERO:[eoResource valueForKey:@"notificationTime"]], @"notificationTime",
       nil]];
     if([_detail intValue] > 0)
       [[result objectAtIndex:count] setObject:eoResource forKey:@"*eoObject"];
   }
  if([_detail intValue] > 0) {
    for (count = 0; count < [result count]; count++) {
      [self _addObjectDetails:[result objectAtIndex:count] withDetail:_detail];
     }
   }
  return result;
} /* end _renderResources */

/* Retrieves a resource by its *EXACT* name.
   _arg is the resource name 
   Returns either nil or an EOGenericRecord */
-(id)_getResourceByName:(NSString *)_arg {
  id             res;

  if ([_arg length] == 0) {
    [self warnWithFormat:@"A get resource request was made without a name"];  
    return nil;
  }
  res = [[self getCTX] runCommand:@"appointmentresource::get",
                   @"name", _arg,
                   @"returnType",
                     [NSNumber numberWithInt:LSDBReturnType_OneObject],
                 nil];
  if ([res isKindOfClass:[NSArray class]]) {
     return [res lastObject];
    }
  return nil;
} /* end _getResourceByName */

/* Render resources whose names are provided in list */
-(NSArray *)_renderNamedResources:(NSArray *)_names {
  NSMutableArray      *resources;
  id                   resource;
  NSEnumerator        *enumerator;
  NSString            *name;

  enumerator = [_names objectEnumerator];
  resources = [NSMutableArray arrayWithCapacity:[_names count]];
  while ((name = [enumerator nextObject]) != nil) {
    resource = [self _getResourceByName:name];
    if (resource == nil)
      [self warnWithFormat:@"Unknown resource requested by name '%@'",
         name];
    else [resources addObject:resource];
  }
  return [self _renderResources:resources 
                     withDetail:[NSNumber numberWithInt:0]];
} /* end _renderNamedResources */

-(NSArray *)_getUnrenderedResourcesForKeys:(id)_arg {
  NSArray       *resources;

  resources = [[[self getCTX] runCommand:@"appointmentresource::get-by-globalid",
                                        @"gids", [self _getEOsForPKeys:_arg],
                                        nil] retain];
  return resources;
} /* end _getUnrenderedResourcesForKeys */

-(NSDictionary *)_getUnrenderedResourceForKey:(id)_arg {
  id	resource;

  resource = [[[self getCTX] runCommand:@"appointmentresource::get-by-globalid",
                                        @"gid", [self _getEOForPKey:_arg],
                                        @"returnType", intObj(LSDBReturnType_OneObject),
                                        nil] retain];
  return [resource lastObject];
} /* end _getUnrenderedResourceForKey */


-(id)_getResourcesForKeys:(id)_arg withDetail:(NSNumber *)_detail {
  return [self _renderResources:[self _getUnrenderedResourcesForKeys:_arg] 
                     withDetail:_detail];
}

-(id)_getResourceForKey:(id)_pk withDetail:(NSNumber *)_detail {
  return [[self _getResourcesForKeys:[NSArray arrayWithObject:_pk] withDetail:_detail] objectAtIndex:0];
}


-(id)_searchForResources:(NSDictionary *)_query 
              withDetail:(NSNumber *)_detail
               withFlags:(NSDictionary *)_flags {
  NSMutableDictionary   *query;
  NSArray               *keys, *result;
  NSString              *key;
  id                    value;
  int                   count;

  query = [NSMutableDictionary dictionaryWithCapacity:[_query count]];

  keys = [_query allKeys];
  for (count = 0; count < [keys count]; count++) {
    key = [keys objectAtIndex:count];
    value = [_query objectForKey:key];
    if ([key isEqualToString:@"objectId"]) {
      [query setObject:value forKey:@"appointmentResourceId"];
    } else if ([key isEqualToString:@"conjunction"]) {
      /* TODO: Verify this is AND or OR */
      [query setObject:value forKey:@"operator"];
    } else [query setObject:value forKey:key];
  }

  if ([query count] == 0)
  {
    if ([self isDebug])
      [self logWithFormat:@"retrieving all resources, empty criteria"];
    result = [[self getCTX] runCommand:@"appointmentresource::get",
                  @"returnType",
                  [NSNumber numberWithInt:LSDBReturnType_ManyObjects],
                  @"maxSearchCount", [_flags objectForKey:@"limit"],
                  nil];
  } else if ([query objectForKey:@"operator"] == nil)
    {
      if ([self isDebug])
        [self logWithFormat:@"performing fuzzy search for resources"];
      [query setObject:[NSNumber numberWithInt:LSDBReturnType_ManyObjects]
                forKey:@"returnType"];
      [query setObject:[_flags objectForKey:@"limit"] 
                forKey:@"maxSearchCount"];
      result = [[self getCTX] runCommand:@"appointmentresource::get" 
                               arguments:query];
    } else
      {
        [query setObject:[_flags objectForKey:@"limit"]
                  forKey:@"maxSearchCount"];
        if ([self isDebug])
          [self logWithFormat:@"performing exact search for resources"];
        result = [[self getCTX] runCommand:@"appointmentresource::extended-search"
                                arguments:query];
      }
  return [self _renderResources:result withDetail:_detail];
}


@end /* End zOGIAction(Resource) */
