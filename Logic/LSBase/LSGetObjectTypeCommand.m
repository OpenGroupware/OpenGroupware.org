/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include "LSGetObjectTypeCommand.h"
#include "common.h"
#include <GDLAccess/EOSQLQualifier.h>
#include <GDLAccess/EONull.h>

@implementation LSGetObjectTypeCommand

- (void)dealloc {
  [self->oids release];
  [super dealloc];
}

/* accessors */

- (void)setObjectId:(id)_oid {
  id old = self->oids;
  
  self->oids = [[NSArray alloc] initWithObjects:&_oid count:1];
  [old release];
  self->singleFetch = YES;
}
- (id)objectId {
  return [self->oids objectAtIndex:0];
}

- (void)setObjectIds:(id)_oids {
  ASSIGN(self->oids, _oids);
}
- (id)objectIds {
  return self->oids;
}

/* execution */

- (BOOL)_isEntityEOEntity:(EOEntity *)_entity {
  NSString *eName;
  
  if (_entity == nil)
    return NO;

  if ((eName = [_entity name]) == nil)
    return NO;

  /* check if it's the Staff entity */
  if ([eName isEqualToString:@"Staff"])
    return NO;

  /* is it an n:m table ? */
  if ([eName rangeOfString:@"ssignment"].length > 0)
    return NO;

  /* is it the product_info table ? */
  if ([eName isEqualToString:@"ProductInfo"])
    return NO;

  if ([eName isEqualToString:@"ObjectInfo"])
    return NO;
  
  if ([eName isEqualToString:@"ObjectProperty"])
    return NO;

  return YES;
}

- (id)_typeOfManyOidsInContext:(id)_context 
  cache:(NSMutableDictionary *)keyToType 
{
  // TODO: split up this big method!
  // TODO: describe what this method does
  NSString          **types;
  NSArray           *result;
  unsigned          i, count;
  NSEnumerator      *entities;
  EOEntity          *entity;
  EOAdaptorChannel  *adChannel;
  NSMutableString   *inString;
  NSMapTable        *idToIdx;
  unsigned          openCount;
  
  if ((count = [self->oids count]) == 0)
    return nil;
  
  openCount = count;
  types     = calloc(count + 1, sizeof(NSString *));
  inString  = [[NSMutableString alloc] init];  
  idToIdx   = NSCreateMapTable(NSObjectMapKeyCallBacks,
                               NSIntMapValueCallBacks,
                               64);
  for (i = 0; i < count; i++) {
    id oid;
    
    oid      = [self->oids objectAtIndex:i];
    types[i] = [keyToType objectForKey:oid];
    
    if (types[i] == nil) {
      if ([inString length] > 0)
        [inString appendString:@","];
      [inString appendString:[oid stringValue]];
      NSMapInsert(idToIdx, oid, (void *)(i + 1));
    }
    else
      openCount--;
  }
  
  adChannel = [[self databaseChannel] adaptorChannel];
  [self assert:(adChannel != nil) reason:@"no adaptor channel available !"];

  /* first take look in ObjectInfo table */

  if (openCount > 0 && ([inString length] > 0)) {
    EOEntity       *entity;
    EOSQLQualifier *qualifier;
    NSArray        *attrs;

    entity    = [[self databaseModel] entityNamed:@"ObjectInfo"];
    attrs     = [entity attributes];
    qualifier = [[EOSQLQualifier alloc] initWithEntity:entity
                                        qualifierFormat:@"%A IN (%@)",
                                          @"objectId", inString];
    
    if ([adChannel selectAttributes:[entity attributes]
                   describedByQualifier:qualifier fetchOrder:nil
                   lock:NO]) {
      NSDictionary *row;
      
      while ((row = [adChannel fetchAttributes:attrs withZone:NULL])) {
        id oid;
        
        if ((oid = [row objectForKey:@"objectId"])) {
          unsigned idx;

          idx = (unsigned)NSMapGet(idToIdx, oid);
          if (idx == 0)
            continue;
          idx--;
        
          types[idx] = [row objectForKey:@"objectType"];
        
          [keyToType setObject:types[idx] forKey:oid];
          openCount--;
        }
      }
    }
    else
      NSLog(@"ObjectInfo select failed");
  }
  [inString release];

  /* then search all tables */
  
  inString = [[NSMutableString alloc] init];
  for (i = 0; i < count; i++) {
    if (types[i] == nil) {
      if ([inString length] > 0)
        [inString appendString:@","];
      
      [inString appendString:[[self->oids objectAtIndex:i] stringValue]]; 
    }
  }
  if (openCount > 0 && [inString length] == 0) {
    [self logWithFormat:@"got empty SQL IN select string"];
    openCount = 0; // hack?
  }
  
  /* search all tables */
  entities = [[[self databaseModel] entities] objectEnumerator];
  while ((openCount > 0) && (entity = [entities nextObject])) {
    NSString       *eName;
    NSString       *pkeyName;
    EOAttribute    *attribute;
    NSArray        *attributes;
    EOSQLQualifier *qualifier;
    NSDictionary   *row;
    
    if (![self _isEntityEOEntity:entity])
      continue;
    
    if ((eName = [entity name]) == nil)
      continue;
      
    if ((pkeyName = [[entity primaryKeyAttributeNames] lastObject]) == nil)
      continue;

    /* handle fake-primary keys in 1:1 relationships */
      
    if ([eName isEqualToString:@"CompanyInfo"])
      pkeyName = @"companyInfoId";
      
    if ((attribute = [entity attributeNamed:pkeyName]) == nil)
      continue;

    [self assert:(pkeyName != nil)  reason:@"missing primary key name !"];
    [self assert:(attribute != nil) reason:@"missing attribute object !"];
    
    attributes = [NSArray arrayWithObject:attribute];
    
    qualifier = [[EOSQLQualifier alloc] initWithEntity:entity
                                        qualifierFormat:@"%A IN (%@)",
                                          pkeyName, inString];
    
    if (qualifier == nil)
      continue;
    
    if (![adChannel selectAttributes:attributes
                    describedByQualifier:qualifier
                    fetchOrder:nil
                    lock:NO]) {
      continue;
    }
    [qualifier release]; qualifier = nil;
    
    while ((row = [adChannel fetchAttributes:attributes withZone:NULL])) {
      id oid;
      
      if ((oid = [row objectForKey:pkeyName])) {
        unsigned idx;

        idx = (unsigned)NSMapGet(idToIdx, oid);
        if (idx == 0)
          continue;
        idx--;
        
        types[idx] = eName;
        
        [keyToType setObject:eName forKey:oid];
        openCount--;
      }
    }
  }
  
  if (idToIdx) NSFreeMapTable(idToIdx); idToIdx = NULL;
  [inString release]; inString = nil;
  {
    int i;
    BOOL modifyArray;

    modifyArray = NO;
    for (i = 0; i < count; i++) {
      if (!types[i]) {
        modifyArray = YES;
        break;
      }
    }
    if (modifyArray) {
      NSMutableArray *array;

      array = [[NSMutableArray alloc] initWithCapacity:count];

      for (i = 0; i < count; i++) {
        if (types[i])
          [array addObject:types[i]];
        else
          [array addObject:[EONull null]];
      }
      result = [[array shallowCopy] autorelease];
      [array release];
    }
    else {
      result = [NSArray arrayWithObjects:types count:count];
    }
  }
  if (types) free(types);
  return result;
}

- (id)_typeOfSingleOidInContext:(id)_context 
  cache:(NSMutableDictionary *)keyToType 
{
  // TODO: split up this big method
  NSString          *type;
  NSEnumerator      *entities;
  EOEntity          *entity;
  EOAdaptorChannel  *adChannel;
  
  if ((type = [keyToType objectForKey:[self objectId]]))
    return type;
  
  adChannel = [[self databaseChannel] adaptorChannel];
  [self assert:(adChannel != nil) reason:@"no adaptor channel available !"];

  /* first take look in ObjectInfo table */

  {
    EOEntity       *entity    = nil;
    EOSQLQualifier *qualifier = nil;
    NSArray        *attrs     = nil;

    entity    = [[self databaseModel] entityNamed:@"ObjectInfo"];
    attrs     = [entity attributes];
    qualifier = [[EOSQLQualifier alloc] initWithEntity:entity
                                        qualifierFormat:@"%A=%@",
                                          @"objectId", [self objectId]];
    
    if ([adChannel selectAttributes:[entity attributes]
                   describedByQualifier:qualifier fetchOrder:nil
                   lock:NO]) {
      NSDictionary *row;
      
      if ((row = [adChannel fetchAttributes:attrs withZone:NULL])) {
        type = [row objectForKey:@"objectType"];
        [self assert:(type != nil)       reason:@"missing entity name !"];
        [keyToType setObject:type forKey:[self objectId]];
      }
      [adChannel cancelFetch];
    }
    else
      [self logWithFormat:@"ObjectInfo select failed"];
  }
  
  entities = [[[self databaseModel] entities] objectEnumerator];
  
  while ((type == nil) && (entity = [entities nextObject])) {
    NSString       *eName;
    EOSQLQualifier *sqlQualifier = nil;
    NSString       *pkeyName;
    NSDictionary   *pkey;
    EOAttribute    *attribute;
    NSArray        *attributes;
    
    if (![self _isEntityEOEntity:entity])
      continue;
      
    if ((eName = [entity name]) == nil)
      continue;
      
    if ((pkeyName = [[entity primaryKeyAttributeNames] lastObject]) == nil)
      continue;

    /* handle fake-primary keys in 1:1 relationships */
      
    if ([eName isEqualToString:@"CompanyInfo"])
      pkeyName = @"companyInfoId";
      
    if ((attribute = [entity attributeNamed:pkeyName]) == nil)
      continue;

    [self assert:(pkeyName != nil)  reason:@"missing primary key name !"];
    [self assert:(attribute != nil) reason:@"missing attribute object !"];
      
    pkey = [NSDictionary dictionaryWithObject:[self objectId] forKey:pkeyName];
    attributes = [NSArray arrayWithObject:attribute];
      
    sqlQualifier = (id)
      [[EOSQLQualifier alloc] initWithEntity:entity
                              qualifierFormat:@"%A=%@",
                              pkeyName, [self objectId]];
    [sqlQualifier autorelease];
#if 0
    [EOSQLQualifier qualifierForPrimaryKey:pkey entity:entity];
#endif
      
    if (sqlQualifier == nil)
      continue;
    
    if (![adChannel selectAttributes:attributes
                    describedByQualifier:sqlQualifier
                    fetchOrder:nil
                    lock:NO]) {
      continue;
    }
      
    if ((pkey = [adChannel fetchAttributes:attributes withZone:NULL])) {
      type = eName;
      [self assert:(type != nil)       reason:@"missing entity name !"];
      [self assert:(self->oids != nil) reason:@"missing objectId !"];
      [keyToType setObject:type forKey:[self objectId]];
      [adChannel cancelFetch];
      break;
    }
    [adChannel cancelFetch];
  }
  return type;
}

- (void)_executeInContext:(id)_context {
  NSMutableDictionary *keyToType;
  id results;
  
  if ([self->oids count] == 0) {
    [self setReturnValue:nil];
    return;
  }
  
  if ((keyToType = [_context valueForKey:@"LSObjectIdToType"]) == nil) {
    keyToType = [NSMutableDictionary dictionaryWithCapacity:64];
    [_context takeValue:keyToType forKey:@"LSObjectIdToType"];
  }
  
  results = self->singleFetch
    ? [self _typeOfSingleOidInContext:_context cache:keyToType]
    : [self _typeOfManyOidsInContext:_context  cache:keyToType];
  
  [self setReturnValue:results];
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  [self assert:(_key != nil) 
        reason:@"passed invalid key to -takeValue:forKey:"];
  
  if ([_key isEqualToString:@"objectId"])
    [self setObjectId:_value];
  else if ([_key isEqualToString:@"oid"])
    [self setObjectId:_value];
  else if ([_key isEqualToString:@"oids"])
    [self setObjectIds:_value];
  else 
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  [self assert:(_key != nil) 
        reason:@"passed invalid key to -takeValue:forKey:"];

  if ([_key isEqualToString:@"objectId"])
    return [self objectId];
  if ([_key isEqualToString:@"oid"])
    return [self objectId];
  if ([_key isEqualToString:@"oids"])
    return [self objectIds];

  return [super valueForKey:_key];
}

@end /* LSGetObjectTypeCommand */
