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

#include <LSFoundation/LSDBObjectGetCommand.h>

/*
  TODO: describe what it does
*/

@interface LSGetProjectCommand : LSDBObjectGetCommand
@end

#include "common.h"
#include <EOControl/EOKeyGlobalID.h>

@implementation LSGetProjectCommand

/* command methods */

- (void)_executeInContext:(id)_context {
  NSMutableDictionary *cache;
  id obj = nil;
  
  cache = [_context valueForKey:@"_cache_Projects"];
  
  if ([cache isNotNull]) {
    NSNumber *pid;

    pid = [self valueForKey:@"projectId"];
    if ([pid isNotNull]) {
      id p;
      
      if ((p = [cache objectForKey:pid])) {
        [self setReturnValue:p];
        return;
      }
    }
  }
  else {
    cache = [NSMutableDictionary dictionaryWithCapacity:64];
    [_context takeValue:cache forKey:@"_cache_Projects"];
  }
  [super _executeInContext:_context];

  obj = [self object];
  
  LSRunCommandV(_context, @"project", @"get-owner",
                @"objects",     obj,
                @"relationKey", @"owner", nil);
  LSRunCommandV(_context, @"project", @"get-team",
                @"objects",     obj,
                @"relationKey", @"team", nil);
  LSRunCommandV(_context, @"project", @"get-company-assignments",
                @"objects",     obj,
                @"relationKey", @"companyAssignments", nil);
  LSRunCommandV(_context, @"project", @"get-status", @"projects", obj, nil);
  
  {
    id p;
    
    p = LSRunCommandV(_context,
		      @"project", @"check-get-permission",
		      @"object",  obj, nil);
    [self setReturnValue:p];
    
    if (cache != nil) {
      if ([p isKindOfClass:[NSArray class]]) {
        NSEnumerator *enumerator = [p objectEnumerator];
        while ((p = [enumerator nextObject])) {
          [cache setObject:[NSArray arrayWithObject:p]
                 forKey:[p valueForKey:@"projectId"]];
        }
      }
      else {
        [cache setObject:[NSArray arrayWithObject:p]
             forKey:[p valueForKey:@"projectId"]];
      }
    }
  }
}

/* record initializer */

- (NSString *)entityName {
  return @"Project";
}

/* accessors */

- (void)setProjectGlobalID:(EOKeyGlobalID *)_gid {
  [self takeValue:(_gid ? [_gid keyValues][0] : nil) forKey:@"projectId"];
}
- (EOKeyGlobalID *)projectGlobalID {
  id v;
    
  v = [super valueForKey:@"projectId"];
  v = [EOKeyGlobalID globalIDWithEntityName:[self entityName]
		     keys:&v keyCount:1
		     zone:NULL];
  return v;
}

/* KVC */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"gid"]) {
    [self setProjectGlobalID:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"gid"])
    return [self projectGlobalID];
  
  return [super valueForKey:_key];
}

@end /* LSGetProjectCommand */
