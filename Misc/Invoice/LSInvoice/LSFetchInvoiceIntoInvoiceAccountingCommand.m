/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#include <LSFoundation/LSDBObjectGetCommand.h>

/*
  Parameter:
  
  objects           - array of 'invoiceaccounting' objects
  relationKey       - relationKey for invoice
  actionRelationKey - relationKey for action
    !! this command calls invoiceaccounting::fetch-action !!
  
*/
   
@interface LSFetchInvoiceIntoInvoiceAccountingCommand : LSDBObjectGetCommand
{
  NSString *relationKey;
  NSString *actionRelationKey;
}

@end

#import "common.h"

@implementation LSFetchInvoiceIntoInvoiceAccountingCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->relationKey);
  RELEASE(self->actionRelationKey);
  [super dealloc];
}
#endif

- (NSString*)entityName {
  return @"Invoice";
}

//fetching...

- (NSArray *)_ids {
  NSMutableSet *idSet;
  NSEnumerator *listEnum;
  id           item;

  idSet    = [NSMutableSet set];
  listEnum = [[self object] objectEnumerator];

  while ((item = [listEnum nextObject])) {
    id pKey;

    pKey = [[item valueForKey:self->actionRelationKey]
                  valueForKey:@"invoiceId"];

    if (pKey != nil) {
      [idSet addObject:pKey];
    }
  }
  return [idSet allObjects];
}

- (EOSQLQualifier*)_qualifierWithIds:(NSArray*)_ids {
  id                   entity;
  EOSQLQualifier      *qual;
  NSString            *idsIn;
  NSArray             *ids;

  entity = [[self database] entityNamed:[self entityName]];
  ids = _ids;
  if ([ids count] > 1) {
    idsIn = [ids componentsJoinedByString:@","];
  } else {
    idsIn = [[ids lastObject] stringValue];
  }
  qual = [EOSQLQualifier alloc];
  qual =
    [qual initWithEntity:entity
          qualifierFormat:
          @"%A IN (%@)", @"invoiceId", idsIn];
  
  return AUTORELEASE(qual);
}

- (NSDictionary*)_mappedObjects {
  NSArray             *objs;
  NSMutableDictionary *objDict;
  NSString            *skey;
  NSEnumerator        *objEnum;
  id                   item;

  objs    = [self object];
  objDict = [NSMutableDictionary dictionary];
  skey    = @"invoiceId";
  objEnum = [objs objectEnumerator];

  while ((item = [objEnum nextObject])) {
    id       key;
    NSArray *mapObjs;

    key     = [[item valueForKey:self->actionRelationKey] valueForKey:skey];
    if (key == nil)
      continue;
    
    mapObjs = [objDict valueForKey:key];
    mapObjs = (mapObjs)
      ? [mapObjs arrayByAddingObject:item]
      : [NSArray arrayWithObject: item];
    
    [objDict setObject:mapObjs forKey:key];
  }
  
  return objDict;
}

- (NSArray *)_fetchRelations {
  NSZone              *z;
  EODatabaseChannel   *channel;
  NSArray             *allIds;
  int                 allIdsCount;

  z           = [self zone];
  channel     = [self databaseChannel];
  allIds      = [self _ids];
  allIdsCount = [allIds count];
  
  if (allIdsCount > 0) {
    NSDictionary       *mapDict       = nil;
    NSArray            *mapArr        = nil;
    NSEnumerator       *mapEnum       = nil;
    NSMutableArray     *relObjs       = nil;
    id                  relObj        = nil;
    id                  mapObj        = nil;
    id                  key           = nil;

    mapDict = [self _mappedObjects];
    relObjs = [NSMutableArray array];
          
    [self assert:
          [channel selectObjectsDescribedByQualifier:
                   [self _qualifierWithIds:allIds]
                   fetchOrder:nil]];

    while ((relObj = [channel fetchWithZone:z])) {
      key     = [relObj valueForKey:@"invoiceId"];
      mapArr  = [mapDict objectForKey:key];
      mapEnum = [mapArr objectEnumerator];
      
      [relObjs addObject:relObj];

      while ((mapObj = [mapEnum nextObject])) {
        [mapObj takeValue:relObj forKey:self->relationKey];
      }
    }
    return relObjs;
  }
  else
    return [NSArray array];
}

- (void)_executeInContext:(id)_context {
  NSArray* rels;
  
  LSRunCommandV(_context,
                @"invoiceaccounting",@"fetch-action",
                @"relationKey",      self->actionRelationKey,
                @"objects",          [self object],
                nil);

  rels = [self _fetchRelations];
  
  [self setReturnValue:rels];
}

//accessors

- (void)setRelationKey:(NSString *)_key {
  ASSIGN(self->relationKey, _key);
}
- (NSString *)relationKey {
  return self->relationKey;
}

- (void)setActionRelationKey:(NSString *)_key {
  ASSIGN(self->actionRelationKey, _key);
}
- (NSString *)actionRelationKey {
  return self->actionRelationKey;
}

// key/value coding

- (void)takeValue:(id)_val forKey:(id)_key {
  if ([_key isEqualToString:@"objects"]) {
    [self setObject:_val];
    return;
  }
  if ([_key isEqualToString:@"relationKey"]) {
    [self setRelationKey:_val];
    return;
  }
  if ([_key isEqualToString:@"actionRelationKey"]) {
    [self setActionRelationKey:_val];
    return;
  }
  [super takeValue:_val forKey:_key];
}

@end
