/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2007      Helge Hess

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

#include "LSDBObjectSetCommand.h"
#include "common.h"
#include <EOControl/EOKeyGlobalID.h>
#include <GDLAccess/EOSQLQualifier.h>
#include <LSFoundation/LSFoundation.h>

@implementation LSDBObjectSetCommand

+ (int)version {
  return 2;
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    [self takeValue:@"05_changed" forKey:@"logAction"];
    [self takeValue:@"changed"    forKey:@"logText"];
    self->checkAccess = [[NSNumber numberWithBool:YES] retain];
  }
  return self;
}

/* database commands */

- (NSArray  *)_fetchRelationForEntity:(EOEntity *)_entity {
  NSString *pKeyName;
  id       pKey;
  EODatabaseChannel *dbChannel;
  NSMutableArray    *results;
  id                obj;
  EOSQLQualifier    *dbQualifier;

  pKeyName = [self primaryKeyName];
  if ((pKey = [[self object] valueForKey:pKeyName]) == nil)
    return nil;

  dbQualifier = [[EOSQLQualifier alloc]
                  initWithEntity:_entity
                  qualifierFormat:@"%A=%@", pKeyName, pKey];
 
  dbChannel = [self databaseChannel];
  [dbChannel selectObjectsDescribedByQualifier:dbQualifier fetchOrder:nil];
  [dbQualifier release]; dbQualifier = nil;
  
  results = [NSMutableArray arrayWithCapacity:16];
  while ((obj = [dbChannel fetchWithZone:NULL]) != nil)
    [results addObject:obj];
    
  return results;
}

- (id)_fetchRecord {
  EODatabaseChannel *dbChannel   = [self databaseChannel];
  EOSQLQualifier    *dbQualifier = nil;
  id obj = nil;

  dbQualifier = [[EOSQLQualifier alloc] initWithEntity:[self entity]
                                        qualifierFormat:@"%A=%@",
                                          [self primaryKeyName],
                                          [self primaryKeyValue]];
  [dbChannel selectObjectsDescribedByQualifier:dbQualifier fetchOrder:nil];
  [dbQualifier release]; dbQualifier = nil;

  if ((obj = [dbChannel fetchWithZone:NULL]) == nil)
    return nil;

  if ([dbChannel fetchWithZone:NULL] != nil) {
    [self warnWithFormat:@"got more than one object for primary key !\n"];
    [dbChannel cancelFetch];
  }
#if 0
  [self debugWithFormat:@"%s: fetched object entity=%@ pkey=%@\n",
          __PRETTY_FUNCTION__,
          [self entityName],
          [obj valueForKey:[self primaryKeyName]]];
#endif
  return obj;
}

- (BOOL)hasWriteAccessInContext:(id)_ctx {
  return [[_ctx accessManager] operation:@"w"
			       allowedOnObjectID:[[self object] globalID]];
}

- (void)_prepareForExecutionInContext:(id)_context {
  id obj = [self object];

  NSAssert(self->recordDict, @"no record dict available");
  
  [self->recordDict takeValue:@"updated" forKey:@"dbStatus"];

  if (![[obj valueForKey:@"globalID"] isNotNull]) {
    EOKeyGlobalID *gid;
    id            values[1];
    
    values[0] = [self primaryKeyValue];
    gid = [EOKeyGlobalID globalIDWithEntityName:[self entityName]
                         keys:values keyCount:1 zone:NULL];
    [obj takeValue:gid forKey:@"globalID"];
  }
  if ([[self checkAccess] boolValue]) {
    [self assert:[self hasWriteAccessInContext:_context]
	  reason:@"Object update failed due to missing write access!"];
  }

  if (obj == nil) {
    [self assert:((obj = [self _fetchRecord]) != nil)];
    [self setObject:obj];
  }

  [self assert:(obj != nil) reason:@"could not prepare object for update !"];

  NSAssert(self->recordDict, @"no record dict available");
  [obj takeValuesFromDictionary:self->recordDict];
}

- (void)_executeInContext:(id)_context {
  BOOL isOk;
  id   obj;

  obj = [self object];

  [self assert:(obj != nil) reason:@"no object to update !"];
  
  isOk = [[self databaseChannel] updateObject:obj];
  
  if (!isOk && [self->dbMessages isNotEmpty])
    [self assert:NO];
  else if (!isOk && ![self->dbMessages isNotEmpty])
    [self assert:NO reason:@"Save failed! Record was edited by another user!"];

  [self setReturnValue:obj];
}

- (void)bumpChangeTrackingFields {
  /* this can be called by subclasses on demand */
  EOEntity    *e;
  EOAttribute *a;
  NSDate      *now = nil;
  id          obj;
  
  if ((obj = [self object]) == nil)
    [self warnWithFormat:@"missing object !!!"];
  
  if ((e = [self entity]) == nil) /* try to retrieve from object */
    e = [obj valueForKey:@"entity"];
  
  if (e == nil) {
    [self warnWithFormat:@"command has no assigned entity?!"];
    return;
  }
  
  if ((a = [e attributeNamed:@"objectVersion"]) != nil) {
    NSNumber *v = [obj valueForKey:@"objectVersion"];
    v = [NSNumber numberWithUnsignedInt:
		    ([v isNotNull] ? ([v unsignedIntValue] + 1) : 1)];
    
    // TBD: not sure what is *really* necessary
    [self takeValue:v forKey:@"objectVersion"];
    [obj  takeValue:v forKey:@"objectVersion"];
  }

  if ((a = [e attributeNamed:@"lastModified"]) != nil) {
    NSNumber *lastMod;
    
    if (now == nil) now = [NSCalendarDate date];
    lastMod = [NSNumber numberWithDouble:[now timeIntervalSince1970]];
    
    [self takeValue:lastMod forKey:@"lastModified"];
    [obj  takeValue:lastMod forKey:@"lastModified"];
  }
  
  if ((a = [e attributeNamed:@"lastmodifiedDate"]) != nil) {
    if (now == nil) now = [NSCalendarDate date];
    
    [self takeValue:now forKey:@"lastmodifiedDate"];
    [obj  takeValue:now forKey:@"lastmodifiedDate"];
  }
  
  // dbStatus is already set in _prepareForExecutionInContext:
}

/* accessors */

- (void)setCheckAccess:(NSNumber *)_n { // TODO: why not a BOOL?
  ASSIGNCOPY(self->checkAccess, _n);
}
- (NSNumber *)checkAccess {
  return self->checkAccess;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"primaryKey"])
    [self setPrimaryKeyValue:_value];
  else if ([_key isEqualToString:@"object"])
    [self setObject:_value];
  else if ([_key isEqualToString:@"checkAccess"])
    [self setCheckAccess:_value];
  else {
    if (_value == nil) _value = [NSNull null];
    
    NSAssert(self->recordDict, @"no record dict available");
    [self->recordDict setObject:_value forKey:_key];
  }
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"primaryKey"])
    return [self primaryKeyValue];
  if ([_key isEqualToString:@"checkAccess"])
    return [self checkAccess];
  if ([_key isEqualToString:@"object"])
    return [self object];

  NSAssert(self->recordDict, @"no record dict available");
  return [self->recordDict objectForKey:_key];
}

@end /* LSDBObjectSetCommand */
