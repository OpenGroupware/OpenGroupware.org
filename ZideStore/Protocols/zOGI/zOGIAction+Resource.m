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
       [self NIL:[eoResource valueForKey:@"notificationTime"]], @"notificationTime",
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
}

/* Retrieves a resource by its *EXACT* name.
   _arg is the resource name 
   Returns either nil or an EOGenericRecord */
-(id)_getResourceByName:(NSString *)_arg {
  id             res;

  res = [[self getCTX] runCommand:@"appointmentresource::get",
                   @"name", _arg,
                   @"returnType",
                     [NSNumber numberWithInt:LSDBReturnType_OneObject],
                 nil];
  if ([res isKindOfClass:[NSArray class]]) {
     return [res lastObject];
    }
  return nil;
}

-(NSArray *)_getUnrenderedResourcesForKeys:(id)_arg {
  NSArray       *resources;

  resources = [[[self getCTX] runCommand:@"appointmentresource::get-by-globalid",
                                        @"gids", [self _getEOsForPKeys:_arg],
                                        nil] retain];
  return resources;
}

-(id)_getResourcesForKeys:(id)_arg withDetail:(NSNumber *)_detail {
  return [self _renderResources:[self _getUnrenderedResourcesForKeys:_arg] 
                     withDetail:_detail];
}

-(id)_getResourceForKey:(id)_pk withDetail:(NSNumber *)_detail {
  return [[self _getResourcesForKeys:[NSArray arrayWithObject:_pk] withDetail:_detail] objectAtIndex:0];
}


-(id)_searchForResources:(NSDictionary *)_query 
              withDetail:(NSNumber *)_detail {
  NSMutableDictionary   *query;
  NSArray               *keys, *result;
  NSString              *key;
  id                    value;
  int                   count;
  

  query = [[NSMutableDictionary alloc] initWithCapacity:[_query count]];
  keys = [_query allKeys];
  for (count = 0; count < [keys count]; count++) {
    key = [keys objectAtIndex:count];
    value = [_query objectForKey:key];
    if ([key isEqualToString:@"objectId"]) {
      [query setObject:value forKey:@"projectId"];
    } else if ([key isEqualToString:@"ownerObjectId"]) {
      [query setObject:value forKey:@"ownerId"];
    } else if ([key isEqualToString:@"placeHolder"]) {
      [query setObject:value forKey:@"isFake"];
    } else if ([key isEqualToString:@"placeHolder"]) {
      [query setObject:value forKey:@"isFake"];
    } else if ([key isEqualToString:@"conjunction"]) {
      /* TODO: Verify this is AND or OR */
      [query setObject:value forKey:@"operator"];
    } else [query setObject:value forKey:key];
   }
  if ([query objectForKey:@"operator"] == nil)
    result = [[self getCTX] runCommand:@"appointmentresource::get" 
                             arguments:query];
   else
     result = [[self getCTX] runCommand:@"appointmentresource::extended-search"
                              arguments:query];
  return [self _renderResources:result withDetail:_detail];
}


@end /* End zOGIAction(Resource) */