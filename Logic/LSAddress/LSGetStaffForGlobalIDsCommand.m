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

#include <LSFoundation/LSDBObjectBaseCommand.h>

/*
  This command fetches team-objects based on a list of EOGlobalIDs.
*/

@interface LSGetStaffForGlobalIDsCommand : LSDBObjectBaseCommand
{
  NSArray  *gids;
  NSArray  *attributes;
  NSArray  *sortOrderings;
  NSString *groupBy;
  BOOL     singleFetch;
}
@end

#include <LSFoundation/LSCommandKeys.h>
#import <EOControl/EOControl.h>
#import <GDLAccess/GDLAccess.h>
#include "common.h"

@implementation LSGetStaffForGlobalIDsCommand

- (void)dealloc {
  [self->groupBy       release];
  [self->sortOrderings release];
  [self->attributes    release];
  [self->gids          release];
  [super dealloc];
}

/* execution */

- (void)_executeInContext:(id)_context {
  NSAutoreleasePool *pool;
  NSMutableArray *teams, *persons;
  NSMutableArray *objects;
  NSEnumerator *e;
  EOGlobalID   *gid;
  NSArray      *tmp;
  id           results;
  
  pool = [[NSAutoreleasePool alloc] init];

  teams   = [NSMutableArray arrayWithCapacity:[self->gids count]];
  persons = [NSMutableArray arrayWithCapacity:[self->gids count]];
  
  /* sort gids by type */
  e = [self->gids objectEnumerator];
  while ((gid = [e nextObject]) != nil) {
    NSString *eName;
    
    eName = [(EOKeyGlobalID *)gid entityName];
    
    if ([eName isEqualToString:@"Person"])
      [persons addObject:gid];
    else if ([eName isEqualToString:@"Team"])
      [teams addObject:gid];
    else {
      [self logWithFormat:@"cannot handle gid %@", gid];
    }
  }

  objects = [NSMutableArray arrayWithCapacity:[self->gids count]];

  if ([teams isNotEmpty]) {
    tmp = LSRunCommandV(_context, @"team", @"get-by-globalid",
                        @"gids",       teams,
                        @"attributes", self->attributes,
                        nil);
    [objects addObjectsFromArray:tmp];
  }
  
  if ([persons isNotEmpty]) {
    tmp = LSRunCommandV(_context, @"person", @"get-by-globalid",
                        @"gids",       persons,
                        @"attributes", self->attributes,
                        nil);
    [objects addObjectsFromArray:tmp];
  }
  
  if (self->groupBy != nil) {
    id eo;
    
    results = [NSMutableDictionary dictionaryWithCapacity:[objects count]];
    
    e = [objects objectEnumerator];
    while ((eo = [e nextObject]) != nil) {
      [(NSMutableDictionary *)results
                              setObject:eo
                              forKey:[eo valueForKey:self->groupBy]];
    }
  }
  else if ([self->sortOrderings isNotEmpty]) {
    results = (id)
      [objects sortedArrayUsingKeyOrderArray:self->sortOrderings];
  }
  else
    results = [[objects copy] autorelease];
  
  [self setReturnValue:results];
  
  [pool release];
}

/* accessors */

- (void)setGlobalIDs:(NSArray *)_gids {
  id tmp;
  
  if (self->gids == _gids)
    return;

  tmp = self->gids;
  if ([_gids isKindOfClass:[NSSet class]])
    self->gids = [[(NSSet *)_gids allObjects] retain];
  else
    self->gids = [_gids copy];
  [tmp release];
}
- (NSArray *)globalIDs {
  return self->gids;
}

- (void)setGlobalID:(EOGlobalID *)_gid {
  [self setGlobalIDs:[NSArray arrayWithObject:_gid]];
  self->singleFetch = YES;
}
- (EOGlobalID *)globalID {
  return [self->gids lastObject];
}

- (void)setAttributes:(NSArray *)_attributes {
  ASSIGN(self->attributes, _attributes);
}
- (NSArray *)attributes {
  return self->attributes;
}

- (void)setSortOrderings:(NSArray *)_orderings {
  ASSIGN(self->sortOrderings, _orderings);
}
- (NSArray *)sortOrderings {
  return self->sortOrderings;
}

/* key-value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"gid"])
    [self setGlobalID:_value];
  else if ([_key isEqualToString:@"gids"])
    [self setGlobalIDs:_value];
  else if ([_key isEqualToString:@"attributes"])
    [self setAttributes:_value];
  else if ([_key isEqualToString:@"groupBy"]) {
    id tmp = self->groupBy;
    
    self->groupBy = [_value copy];
    [tmp release];
  }
  else if ([_key isEqualToString:@"sortOrderings"])
    [self setSortOrderings:_value];
  else if ([_key isEqualToString:@"sortOrdering"])
    [self setSortOrderings:[NSArray arrayWithObject:_value]];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  id v;
  
  if ([_key isEqualToString:@"gid"])
    v = [self globalID];
  else if ([_key isEqualToString:@"groupBy"])
    v = self->groupBy;
  else if ([_key isEqualToString:@"gids"])
    v = [self globalIDs];
  else if ([_key isEqualToString:@"attributes"])
    v = [self attributes];
  else if ([_key isEqualToString:@"sortOrderings"])
    v = [self sortOrderings];
  else if ([_key isEqualToString:@"sortOrdering"]) {
    v = [self sortOrderings];
    v = [v objectAtIndex:0];
  }
  else 
    v = [super valueForKey:_key];
  
  return v;
}

@end /* LSGetStaffForGlobalIDsCommand */
