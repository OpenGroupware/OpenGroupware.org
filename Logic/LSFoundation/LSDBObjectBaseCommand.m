/*
  Copyright (C) 2000-2005 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

#include "LSDBObjectBaseCommand.h"
#include "LSDBObjectTransactionCommand.h"
#include "LSCommandContext.h"
#include "common.h"

@implementation LSDBObjectBaseCommand

+ (int)version {
  return [super version] + 0; /* v1 */
}
+ (void)initialize {
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain]) != nil) {
    self->recordDict     = [[NSMutableDictionary alloc] init];
    self->sybaseMessages = [[NSMutableArray alloc] init];
    self->returnType     = LSDBReturnType_OneObject;
    
    [self assert:(self->recordDict != nil)
          reason:@"could not create record dictionary .."];
  }
  return self;
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain
  initDictionary:(NSDictionary *)_init
{
  if ((self = [self initForOperation:_operation inDomain:_domain])) {
    self->entityName = [[_init objectForKey:@"entity"] copy];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->entityName     release];
  [self->recordDict     release];
  [self->sybaseMessages release]; // TODO: rename to dbMessages
  [super dealloc];
}

/* command type */

- (BOOL)requiresChannel {
  return YES;
}
- (BOOL)requiresTransaction {
  return YES;
}

/* command methods */

- (void)_logContext:(id)_context text:(NSString *)_text {
  printf("LOG(context): [%s %s] <%s>",
         [[self domain] cString], [[self operation] cString],
         [NSStringFromClass([self class]) cString]);
  
  if (_text) printf(" <%s>", [_text cString]);
  printf("\n");
}

- (void)_validateKeysForContext:(id)_context {
  /*
    This method checks whether the values provided in the record-dict
    properly match the value types defined in the model.
    
    Currently it only checks for NSCalendarDate, which are often passed
    in a wrong way ;-)
  */
  NSEnumerator *keys;
  id           key;
  
  [self assert:(self->recordDict != nil) reason:@"no record dict available !"];
  
  keys = [self->recordDict keyEnumerator];
  while ((key = [keys nextObject])) {
    EOAttribute    *attr;
    NSCalendarDate *date = nil;
    NSString       *fmt;
    id             value;
    
    attr = [[self entity] attributeNamed:key];
#if 0
    [self assert:(attr != nil)
          format:@"key: %@ is not valid in domain '%@' for operation '%@'.",
                 key, [self domain], [self operation]];
#endif
    
    if (![[attr valueClassName] isEqual:@"NSCalendarDate"])
      /* we only validate date keys */
      continue;
    
    value = [self->recordDict valueForKey:key];
    if (![value isNotNull])
      /* value is NSNull or nil */
      continue;
    if ([value isKindOfClass:[NSCalendarDate class]])
      /* value is a calendar date */
      continue;
    
    if ([value isKindOfClass:[NSDate class]]) {
      /* value is a date, make a calendar date */
      date = [[NSCalendarDate alloc] initWithTimeIntervalSinceReferenceDate:
                                       [value timeIntervalSinceReferenceDate]];
      [self->recordDict takeValue:date forKey:key];
      [date release]; date = nil;
      continue;
    }
    
    [self warnWithFormat:
            @"date command argument '%@' is not a date (%@): %@", 
            key, NSStringFromClass([value class]), value];
    
    /* coerce a value to a date */
    
    fmt  = [attr calendarFormat];
    date = [NSCalendarDate dateWithString:[value stringValue]
                           calendarFormat:fmt];
    if (date == nil) {
      [self errorWithFormat:
              @"Could not convert key %@ (%@:%@) to date, format is %@",
	      key, NSStringFromClass([value class]), value,
              [attr calendarFormat]];
    }
    
    [self->recordDict takeValue:date forKey:key];
  }
}

- (void)_prepareForExecutionInContext:(id)_context {
  NSAssert([self->recordDict isKindOfClass:[NSMutableDictionary class]] ||
           (self->recordDict == nil),
           @"recordDict is broken");
}

- (void)_executeInContext:(id)_context {
  NSAssert([self->recordDict isKindOfClass:[NSMutableDictionary class]] ||
           (self->recordDict == nil),
           @"recordDict is broken");
}

- (void)_validateInContext:(id)_context {
  NSAssert([self->recordDict isKindOfClass:[NSMutableDictionary class]] ||
           (self->recordDict == nil),
           @"recordDict is broken");

  self->isCommandOk = YES;
}

- (void)primaryRunInContext:(id)_context {
  [[NSNotificationCenter defaultCenter]
                         addObserver:self
                         selector:@selector(gotSybaseMessage:)
                         name:@"Sybase10Notification"
                         object:[self databaseAdaptor]];

  [self _checkPermissionInContext:_context];
  [self _validateKeysForContext:_context];
  [self _prepareForExecutionInContext:_context];
  [self _executeInContext:_context];
  [self _executeCommandsInContext:_context];
  [self _validateInContext:_context];
}

/* notifications */

- (void)gotSybaseMessage:(NSNotification *)_notification {
  NSException *msg;
  
  msg = [[_notification userInfo] objectForKey:@"message"];
  [self->sybaseMessages addObject:[msg reason]]; 
}

/* accessors */

- (void)setEntityName:(NSString *)_entityName {
  if (self->entityName == _entityName)
    return;
  
  [self->entityName autorelease]; self->entityName = nil;
  self->entityName = [_entityName copy];
}
- (NSString *)entityName {
  return self->entityName;
}

- (void)setReturnType:(unsigned)_returnType {
  self->returnType = _returnType;
}
- (unsigned)returnType {
  return self->returnType;
}

/* database context */

- (EODatabase *)database {
  return [activeContext valueForKey:LSDatabaseKey];
}
- (EODatabaseContext *)databaseContext {
  return [activeContext valueForKey:LSDatabaseContextKey];
}
- (EODatabaseChannel *)databaseChannel {
  return [activeContext valueForKey:LSDatabaseChannelKey];
}

/* derived database methods */

- (EOAdaptor *)databaseAdaptor {
  return [[self database] adaptor];
}
- (EOModel *)databaseModel {
  EODatabase *db = [self database];
  EOAdaptor  *ad = [db   adaptor];
  EOModel    *m  = [ad   model];
  
  [self assert:(activeContext != nil) reason:@"context not set in command"];
  [self assert:(db != nil) reason:@"database not set in context"];
  [self assert:(ad != nil) reason:@"adaptor not set in database"];
  [self assert:(m  != nil) reason:@"model not set in adaptor"];
  
  return m;
  //return [[[self database] adaptor] model];
}

- (EOEntity *)entity {
  return [[self databaseModel] entityNamed:[self entityName]];
}
- (EOAttribute *)attributeNamed:(NSString *)_name {
  return [[self entity] attributeNamed:_name];
}
- (EORelationship *)relationshipNamed:(NSString *)_name {
  return [[self entity] relationshipNamed:_name];
}

- (NSString *)primaryKeyName { // valid in runInContext:
  EOEntity *entity = [self entity];
  NSArray  *pkeys  = [entity primaryKeyAttributeNames];

  if ([pkeys count] != 1) {
    [self errorWithFormat:
            @"%s: can only handle entities with one primary key "
            @"(entity=%@, keys=%@)!", __PRETTY_FUNCTION__, entity, pkeys];
    return nil;
  }

  return [pkeys objectAtIndex:0];
}

- (void)setPrimaryKeyValue:(id)_value {
  [self takeValue:_value forKey:[self primaryKeyName]];
}

- (id)primaryKeyValue {
  return [self valueForKey:[self primaryKeyName]];
}

- (void)takeValuesFromDictionary:(NSDictionary *)_dict {
  /* TODO: optimize method calls */
  NSEnumerator *keys;
  id           key;

  keys = [_dict keyEnumerator];
  while ((key = [keys nextObject]))
    [self takeValue:[_dict valueForKey:key] forKey:key];
}

/* convenience methods */

- (NSArray *)extractPrimaryKeysNamed:(NSString *)_pkeyName
  fromObjectArray:(NSArray *)_array
  inContext:(LSCommandContext *)_cmdctx
{
  NSMutableArray *pkeys;
  unsigned       i, count;
  
  if (![_array isNotEmpty])
    return nil;

  count = [_array count];
  pkeys = [NSMutableArray arrayWithCapacity:count];
  
  for (i = 0; i < count; i++) {
    id object, tmp;
    
    if (![(object = [_array objectAtIndex:i]) isNotNull]) {
      [self warnWithFormat:@"given list contained null object (pkey %@)",
	      _pkeyName];
      continue;
    }
    
    /* check for global IDs */
    
    if ([object isKindOfClass:[EOKeyGlobalID class]]) {
      [pkeys addObject:[(EOKeyGlobalID *)object keyValues][0]];
      continue;
    }

    /* check for NSNumber (primary keys) */

    if ([object isKindOfClass:[NSNumber class]]) {
      [pkeys addObject:object];
      continue;
    }

    /* try to extract primary key from object */
    
    if ([(tmp = [object valueForKey:_pkeyName]) isNotNull]) {
      [pkeys addObject:tmp];
      continue;
    }

    /* try to extract globalID from object */
    
    if ([(tmp = [object valueForKey:@"globalID"]) isNotNull]) {
      [pkeys addObject:[(EOKeyGlobalID *)object keyValues][0]];
      continue;
    }

    /* could not process given object */
    
    [self errorWithFormat:
	    @"got an object which I cannot extract the pkey (%@) from: %@", 
	    _pkeyName, object];
  }
  
  return pkeys;
}

- (NSArray *)fetchAllForQualifier:(EOSQLQualifier *)_qualifier
  fetchOrder:(NSArray *)_order
{
  EODatabaseChannel *channel;
  NSMutableArray *result;
  id             obj     = nil;
  
  channel = [self databaseChannel];
  if (![channel selectObjectsDescribedByQualifier:_qualifier 
                fetchOrder:_order])
    return nil;

  result = [NSMutableArray arrayWithCapacity:16];
  while ((obj = [channel fetchWithZone:NULL]))
    [result addObject:obj];
  obj = nil;
  return result;
}
- (NSArray *)fetchAllForQualifier:(EOSQLQualifier *)_qualifier {
  return [self fetchAllForQualifier:_qualifier fetchOrder:nil];
}

- (NSString *)joinPrimaryKeysFromArrayForIN:(NSArray *)_ids {
  // TODO: should we filter out DUPs?
  NSMutableString *ms;
  NSString        *s;
  unsigned        i, count;
  BOOL            isFirst;
  
  if ((count = [_ids count]) == 0)
    return nil;
  
  ms = [[NSMutableString alloc] initWithCapacity:(count * 7)];
  
  for (i = 0, isFirst = YES; i < count; i++) {
    id pkey;
    
    pkey = [_ids objectAtIndex:i];
    if (![pkey isNotNull]) {
      [self warnWithFormat:@"found null in primary-key array!"
	      @" (usually due to a broken constraint in the DB!)"];
      continue;
    }
    
    if (isFirst) isFirst = NO;
    else [ms appendString:@","];
    
    [ms appendString:[pkey stringValue]];
  }
  
  s = [ms copy];
  [ms release];
  return [s autorelease];
}

- (EOSQLQualifier *)createSqlInQualifierOnEntity:(EOEntity *)_entity
  attributePath:(NSString *)_attrName
  primaryKeys:(NSArray *)_keys
{
  EOSQLQualifier *q;
  NSString       *instr;
  
  if ([_keys count] == 0)
    return nil;
  
  instr = [self joinPrimaryKeysFromArrayForIN:_keys];
  q = [[EOSQLQualifier alloc] initWithEntity:_entity
			      qualifierFormat:@"%A IN (%@)", _attrName, instr];
  return q;
}

/* assertions */

- (void)assert:(BOOL)_condition {
  // raises with sybaseMessages
  NSString *s;
  
  s = [self->sybaseMessages isNotEmpty]
    ? [self->sybaseMessages description]
    : (NSString *)@"unknown reason (no database messages found)";
  [self assert:_condition reason:s];
}

/* description */

- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:128];
  
  [ms appendFormat:@"<DBCommand: %@::%@ entity=%@ ",
        [self domain], [self operation],
        [self entityName]];
  
  if ([[self commands] isNotEmpty])
    [ms appendString:@" has-subcmds"];
  
  [ms appendString:@">"];
  return ms;
}

@end /* LSDBObjectBaseCommand */
