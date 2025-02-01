/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2006-2007 Helge Hess

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

#include "LSDBObjectNewKeyCommand.h"
#include "LSDBObjectNewCommand.h"
#include <GDLAccess/EOEntity+Factory.h>
#include "common.h"

@implementation LSDBObjectNewCommand

+ (int)version {
  return [super version] + 0; /* v1 */
}
+ (void)initialize {
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    [self takeValue:@"created"    forKey:@"logText"];
    [self takeValue:@"00_created" forKey:@"logAction"];
  }
  return self;
}

/* create enterprise object */

- (id)produceEmptyEOWithPrimaryKey:(NSDictionary *)_pkey
  entity:(EOEntity *)_entity
{
  id obj;

  obj = [_entity produceNewObjectWithPrimaryKey:_pkey];
  [_entity setAttributesOfObjectToEONull:obj];

  return obj;
}

/* create new Primary Key */

- (NSDictionary *)newPrimaryKeyDictForContext:(id)_ctx 
  keyName:(NSString *)_name
{
  id key;
  id<NSObject,LSCommand> nkCmd;
  
  nkCmd = LSLookupCommand(@"system", @"newkey");
  [nkCmd takeValue:[self entity] forKey:@"entity"];
  key = [nkCmd runInContext:_ctx];
  [self assert:(key != nil) reason:@"Could not get valid new primary key!\n"];
  return [NSDictionary dictionaryWithObject:key forKey:_name];
}

/* command operations */

- (void)_prepareForExecutionInContext:(id)_context {
  NSDictionary *pk = nil;
  id           obj = nil;

  pk  = [self newPrimaryKeyDictForContext:_context
              keyName:[self primaryKeyName]];
  obj = [self produceEmptyEOWithPrimaryKey:pk entity:[self entity]];

  [self setReturnValue:obj];

  NSAssert(self->recordDict, @"no record dict available");
  [self->recordDict setObject:@"inserted" forKey:@"dbStatus"];
  #if 0 // hh: 2025-02-01: should this set objectVersion? Or in change-trackers?
  [self->recordDict setObject:[NSNumber numberWithInt: 1]
                    forKey:@"objectVersion"];
  #endif
  [obj takeValuesFromDictionary:recordDict];
}

- (void)prepareChangeTrackingFields {
  /* this can be called by subclasses on demand */
  EOEntity    *e;
  EOAttribute *a;
  NSCalendarDate *now = nil; /* OGo often expects an NSCalendarDate */
  
  if ((e = [self entity]) == nil) {
    [self warnWithFormat:@"new-command has no assigned entity?!"];
    return;
  }
  
  if ([self->recordDict objectForKey:@"objectVersion"] == nil) {
    if ((a = [e attributeNamed:@"objectVersion"]) != nil) {
      [self->recordDict
	   setObject:[NSNumber numberWithUnsignedInt:1]
	   forKey:@"objectVersion"];
    }
  }
  
  if ([self->recordDict objectForKey:@"lastModified"] == nil) {
    if ((a = [e attributeNamed:@"lastModified"]) != nil) {
      NSNumber *lastMod;
    
      if (now == nil) now = [NSCalendarDate date];
      lastMod = [NSNumber numberWithDouble:[now timeIntervalSince1970]];
      [self->recordDict setObject:lastMod forKey:@"lastModified"];
    }
  }
  
  if ([self->recordDict objectForKey:@"creationDate"] == nil) {
    if ((a = [e attributeNamed:@"creationDate"]) != nil) {
      if (now == nil) now = [NSCalendarDate date];
      [self->recordDict setObject:now forKey:@"creationDate"];
    }
  }
  if ([self->recordDict objectForKey:@"lastmodifiedDate"] == nil) {
    if ((a = [e attributeNamed:@"lastmodifiedDate"]) != nil) {
      if (now == nil) now = [NSCalendarDate date];
      [self->recordDict setObject:now forKey:@"lastmodifiedDate"];
    }
  }
}

- (BOOL)shouldInsertObjectInObjInfoTable:(id)_object {
  NSString *en;
  
  if (_object == nil)
    return NO;
  
  en = [self entityName];
  if ([en hasSuffix:@"Assignment"])         return NO;
  if ([en isEqualToString:@"CompanyValue"]) return NO;
  
  return YES;
}

- (void)insertObjectInObjectInfoTable:(id)_object
  inContext:(LSCommandContext *)_ctx
{
  EOAdaptorChannel *adChannel;
  NSMutableString  *sql;
  NSNumber         *pkey;
  NSString         *entityName;
  NSException      *error;
  
  pkey       = [_object valueForKey:[self primaryKeyName]];
  entityName = [self entityName];
  
  if (![pkey isNotEmpty] && ![entityName isNotEmpty])
    return;
  
  /* build SQL */
  
  /* What we do here should be pretty safe wrt SQL injection given the
   * nature of the values. Would be better to do with the entity/adaptor
   * anyways */
  sql = [NSMutableString stringWithCapacity:256];
  [sql appendString:@"INSERT INTO obj_info ( obj_id, obj_type ) VALUES ( "];
  [sql appendString:[pkey stringValue]];
  [sql appendString:@", '"];
  [sql appendString:entityName];
  [sql appendString:@"' );"];
  
  /* perform insert */
  
  adChannel = [[self databaseChannel] adaptorChannel];
  if ((error = [adChannel evaluateExpressionX:sql]) != nil) {
    [self errorWithFormat:@"could not insert objinfo record: %@", error];
    return; /* not a huge problem */
  }
}

- (void)_executeInContext:(id)_context {
  BOOL isOk;
  
  isOk = [[self databaseChannel] insertObject:[self object]];
  
  if (!isOk) {
    if ([self->dbMessages isNotEmpty])
      [self assert:NO];
    else
      [self assert:NO reason:@"Insert failed!"];
  }
  
  [self assert:[[self databaseChannel] refetchObject:[self object]]
        reason:@"Could not refetch inserted object!"];
  
  if ([self shouldInsertObjectInObjInfoTable:[self object]])
    [self insertObjectInObjectInfoTable:[self object] inContext:_context];
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if (_value == nil) _value = [NSNull null];
    
  NSAssert(self->recordDict, @"no record dict available");
  [self->recordDict setObject:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  NSAssert(self->recordDict, @"no record dict available");
  return [self->recordDict objectForKey:_key];
}

@end /* LSDBObjectNewCommand */
