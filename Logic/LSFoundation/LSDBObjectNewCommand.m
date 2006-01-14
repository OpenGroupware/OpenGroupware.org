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
  [obj takeValuesFromDictionary:recordDict];
}

- (BOOL)shouldInsertObjectInObjInfoTable:(id)_object {
  NSString *en;
  
  if (_object == nil)
    return NO;
  
  en = [self entityName];
  if ([en hasSuffix:@"Assignment"])
    return NO;
  if ([en isEqualToString:@"CompanyValue"])
    return NO;
  
  return YES;
}

- (void)insertObjectInObjectInfoTable:(id)_object inContext:(id)_ctx {
  // TODO: implement
  [self debugWithFormat:@"TODO: register in objinfo: %@ / %@",
	[self entityName],
	[_object valueForKey:[self primaryKeyName]]];
}

- (void)_executeInContext:(id)_context {
  BOOL isOk = NO;

  isOk = [[self databaseChannel] insertObject:[self object]];
  
  if (!isOk && [self->sybaseMessages count] > 0)
    [self assert:NO];
  else if (!isOk && [self->sybaseMessages count] == 0)
    [self assert:NO reason:@"Insert failed!"];

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
