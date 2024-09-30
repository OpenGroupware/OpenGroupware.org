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

#include "common.h"
#include <LSFoundation/LSTypeManager.h>
#include <LSFoundation/LSCommandKeys.h>
#include <LSFoundation/LSCommandContext.h>

@interface LSTypeManager : NSObject < LSTypeManager >
{
@private
  LSCommandContext *context; /* non-retained */
  NSMapTable *pkeyToGid;
}

- (id)initWithContext:(LSCommandContext *)_ctx;
- (void)invalidate;

@end

@interface NSObject(Misc)
- (EOGlobalID *)globalID;
@end

@implementation LSTypeManager

+ (int)version {
  return 1;
}

- (id)initWithContext:(LSCommandContext *)_ctx {
  self->context = _ctx;
  self->pkeyToGid = NSCreateMapTable(NSIntMapKeyCallBacks,
                                     NSObjectMapValueCallBacks,
                                     1000);
  return self;
}

- (void)invalidate {
  self->context = nil;
  if (self->pkeyToGid) {
    NSFreeMapTable(self->pkeyToGid);
    self->pkeyToGid = NULL;
  }
}

- (void)dealloc {
  [self invalidate];
  [super dealloc];
}

/* entity names */

- (NSArray *)entityNamesForObjects:(NSArray *)_objects {
  NSArray  *array;
  unsigned oc;

  array = nil;
  if ((oc = [_objects count])) {
    NSString *names[oc];
    unsigned i;

    for (i = 0; i < oc; i++) {
      id eo;

      eo       = [_objects objectAtIndex:i];
      names[i] = [self entityNameForObject:eo];
    }
    array = [NSArray arrayWithObjects:names count:oc];
  }
  return array;
}
- (NSArray *)entityNamesForGlobalIDs:(NSArray *)_gids {
  NSArray  *array;
  unsigned oc;

  array = nil;
  if ((oc = [_gids count])) {
    NSString *names[oc];
    unsigned i;

    for (i = 0; i < oc; i++) {
      EOGlobalID *gid;

      gid      = [_gids objectAtIndex:i];
      names[i] = [self entityNameForGlobalID:gid];
    }
    array = [NSArray arrayWithObjects:names count:oc];
  }
  return array;
}

- (NSString *)entityNameForObject:(id)_object {
  if (_object == nil)
    return nil;
  
  if ([_object respondsToSelector:@selector(entityName)])
    return [_object entityName];
  
  if ([_object respondsToSelector:@selector(globalID)]) {
    EOGlobalID *gid;
    
    gid = [_object globalID];
    return [self entityNameForGlobalID:gid];
  }
  return nil;
}
- (NSString *)entityNameForGlobalID:(EOGlobalID *)_globalId {
  static Class EOKeyGlobalIDClass = Nil;
  if (EOKeyGlobalIDClass == Nil) EOKeyGlobalIDClass = [EOKeyGlobalID class];

  if (_globalId == nil)
    return nil;

  if ([_globalId respondsToSelector:@selector(entityName)])
    return [(id)_globalId entityName];
  
  return nil;
}

/* primary keys */

- (NSArray *)globalIDsForObjects:(NSArray *)_objects {
  unsigned oc;
  NSArray *array;

  // hh(2024-09-19): unused, but maybe the query has a side effect?
  /*EODatabaseContext *dbCtx=*/[self->context valueForKey:LSDatabaseContextKey];
  
  array = nil;
  if ((oc = [_objects count]) > 0) {
    EOGlobalID *gids[oc];
    unsigned   i;

    for (i = 0; i < oc; i++) {
      id eo;

      gids[i] = nil;
      
      eo = [_objects objectAtIndex:i];
      
      if ([eo respondsToSelector:@selector(globalID)])
        gids[i] = [eo globalID];
    }
    array = [NSArray arrayWithObjects:gids count:oc];
  }
  return array;
}

- (NSDictionary *)objectsKeyedByEntityName:(NSArray *)_objects {
  unsigned     oc;
  NSDictionary *dict;
  
  dict = nil;
  if ((oc = [_objects count]) > 0) {
    NSMutableDictionary *md;
    NSArray *entityNames;
    unsigned i;
    
    md          = [[NSMutableDictionary alloc] initWithCapacity:32];
    entityNames = [self entityNamesForObjects:_objects];

    for (i = 0; i < oc; i++) {
      NSString       *entityName;
      NSMutableArray *objects;
      id eo;
      
      entityName = [entityNames objectAtIndex:i];
      eo         = [_objects    objectAtIndex:i];
      
      if ((objects = [md objectForKey:entityName]) == nil) {
        objects = [[NSMutableArray alloc] initWithCapacity:64];
        [md setObject:objects forKey:entityName];
        [objects release];
      }
      
      [objects addObject:eo];
    }
    
    dict = [md copy];
    [md release];
  }
  return [dict autorelease];
}

- (NSDictionary *)globalIDsKeyedByEntityName:(NSArray *)_gids {
  NSMutableDictionary *md;
  NSArray *entityNames;
  unsigned i;
  unsigned     oc;
  NSDictionary *dict;
  
  dict = nil;
  if ((oc = [_gids count]) == 0)
    return nil;
    
  md          = [[NSMutableDictionary alloc] initWithCapacity:32];
  entityNames = [self entityNamesForGlobalIDs:_gids];

  for (i = 0; i < oc; i++) {
    NSString       *entityName;
    NSMutableArray *objects;
    EOGlobalID     *gid;
      
    entityName = [entityNames objectAtIndex:i];
    gid        = [_gids       objectAtIndex:i];

    if ((objects = [md objectForKey:entityName]) == nil) {
      objects = [[NSMutableArray alloc] initWithCapacity:64];
      [md setObject:objects forKey:entityName];
      [objects release];
    }
      
    [objects addObject:gid];
  }
  dict = [md copy];
  [md release];
  return [dict autorelease];
}

/* PrimaryKeyTypes */

- (EOGlobalID *)globalIDForPrimaryKey:(id)_pkey {
  EOGlobalID    *gid;
  id            pkey;
  unsigned long pkeyInt;
  NSString      *entityName;
  
  pkeyInt = [_pkey unsignedLongValue];
  
  if (pkeyInt == 0) /* '0' as pkey is not allowed here */
    return nil;

  if ((gid = NSMapGet(self->pkeyToGid, (void*)pkeyInt)))
    return gid;
  
  pkey = [NSNumber numberWithInt:pkeyInt];
  
  entityName =
    [self->context runCommand:@"system::get-object-type", @"oid", pkey, nil];
  
  if (entityName == nil) {
    /* could not determine entity .. */
    return nil;
  }

  gid = [EOKeyGlobalID globalIDWithEntityName:entityName
                       keys:&pkey keyCount:1
                       zone:NULL];
  if (gid != nil) 
    NSMapInsert(self->pkeyToGid, (void*)pkeyInt, gid);

  return gid;
}

- (NSArray *)globalIDsForPrimaryKeys:(NSArray *)_pkeys {
  NSArray  *entityNames;
  unsigned i, pc = [_pkeys count];
  id       gids[pc + 1]; // TODO: replace with malloced array?
  
  if (pc == 0)
    return _pkeys;

  /* first check in cache */
  
  for (i = 0; i < pc; i++) {
    NSNumber      *pkey;
    unsigned long pkeyInt;
    
    pkey    = [_pkeys objectAtIndex:i];
    pkeyInt = [pkey intValue];
    
    gids[i] = NSMapGet(self->pkeyToGid, (void*)pkeyInt);
    if (gids[i] == nil)
      break;
  }
  if (i == pc) /* all found in cache*/
    return [NSArray arrayWithObjects:gids count:pc];
  
  /* then query entities */
  
  entityNames =
    [self->context runCommand:@"system::get-object-type", @"oids", _pkeys,nil];
  
  for (i = 0; i < pc; i++) {
    NSString      *eName;
    EOKeyGlobalID *gid;
    id            pkey;
    unsigned long pkeyInt;
    
    eName   = [entityNames objectAtIndex:i];

    if ([eName isNotNull]) {
      pkey    = [_pkeys objectAtIndex:i];
      pkeyInt = [pkey unsignedLongValue];
    
      gid = [EOKeyGlobalID globalIDWithEntityName:eName
                           keys:&pkey keyCount:1
                           zone:NULL];
      if (gid)
        NSMapInsert(self->pkeyToGid, (void *)pkeyInt, gid);
    
      gids[i] = gid;
      if (gids[i] == nil)
        gids[i] = [NSNull null];
    }
    else {
      gids[i] = [NSNull null];
    }
  }
  return [NSArray arrayWithObjects:gids count:pc];
}

/* description */

- (NSString *)description {
  NSMutableString *ms;

  ms = [NSMutableString stringWithCapacity:128];
  [ms appendFormat:@"<%p[%@]:", self, NSStringFromClass([self class])];

  [ms appendFormat:@" ctx=%p", self->context];
  
  if (self->pkeyToGid != NULL)
    [ms appendFormat:@" #pkey-map=%d", NSCountMapTable(self->pkeyToGid)];
  
  [ms appendString:@">"];
  return ms;
}

@end /* LSTypeManager */
