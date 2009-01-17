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

#include "LSDBObjectDeleteCommand.h"
#include "common.h"
#include <GDLAccess/EOSQLQualifier.h>

@implementation LSDBObjectDeleteCommand

+ (int)version {
  return [super version] + 0; /* v1 */
}
+ (void)initialize {
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  NSUserDefaults *ud;

  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    self->reallyDelete = YES;
  }
  ud = [NSUserDefaults standardUserDefaults];
  self->tombstoneOn = [ud boolForKey:@"LSTombstoneOnDeleteEnabled"];
  self->disableLogDelete = [ud boolForKey:@"LSDisableLogDeletion"];
  return self;
}

// database commands

- (void)_deleteRelations:(NSArray *)_relations inContext:(id)_context {
  int i = [_relations count];

  while (i--) {
    EORelationship *rs = [_relations objectAtIndex:i];
    
    if ([rs isToMany]) {
      id  fault;
      int j;

      fault = [(NSDictionary *)[self object] objectForKey:[rs name]];
      
#if 0
      NSLog(@"relation: %@", [rs name]);
#endif
      j = [fault count];

      while (j--) {
        id                      obj;
        LSDBObjectDeleteCommand *dCmd;

        obj   = [fault objectAtIndex:j];
          
        dCmd = LSLookupCommand([[rs destinationEntity] name], @"delete");
        [dCmd takeValue:obj forKey:@"object"];
        [dCmd setReallyDelete:self->reallyDelete];
        [dCmd runInContext:_context];        
      }
    }
  }
}

- (BOOL)_fetchRecord {
  EODatabaseChannel *dbChannel;
  EOSQLQualifier    *dbQualifier;
  id                obj          = nil;
  
  dbQualifier = [[EOSQLQualifier alloc] initWithEntity:[self entity]
                                        qualifierFormat:@"%A=%@",
                                          [self primaryKeyName],
                                          [self primaryKeyValue]];

  dbChannel = [self databaseChannel];
  [dbChannel selectObjectsDescribedByQualifier:dbQualifier fetchOrder:nil];
  [dbQualifier release]; dbQualifier = nil;
  
  if ((obj = [dbChannel fetchWithZone:NULL])) {
    [self setObject:obj];
    
    if ([dbChannel fetchWithZone:NULL]) {
      [self logWithFormat:@"! got more than one object for primary key !"];
      [dbChannel cancelFetch];
    }

#if 0
    [self debugWithFormat:@"fetched object %@: %@",
            [self entityName],
            [obj valueForKey:[self primaryKeyName]]];
#endif
    
    return YES;
  }
  return NO;
}

- (void)_prepareForExecutionInContext:(id)_context {
  id obj;
  
  if ((obj = [self object]) == nil) {
    [self assert:[self _fetchRecord] reason:@"Could not fetch record."];
    obj = [self object];
  }

  if (!self->reallyDelete)
    [obj takeValue:@"archived" forKey:@"dbStatus"];
}

- (void)_executeInContext:(id)_context {
#if 0
  [self debugWithFormat:@"! trying to delete %@ (reallyDelete=%s)!",
             [[self object] valueForKey:[self primaryKeyName]],
             self->reallyDelete ? "yes" : "no"];
#endif
  
  if (self->reallyDelete) {
    [self assert:[[self databaseChannel] deleteObject:[self object]]];
  }
  else {
    [self assert:[[self databaseChannel] updateObject:[self object]]];
  }
}

- (BOOL)isDeleteLogsEnabled {
  return (!(self->disableLogDelete));
}

- (BOOL)isTombstoneEnabled {
  return self->tombstoneOn;
}

/* accessors */

- (void)setReallyDelete:(BOOL)_reallyDelete {
  self->reallyDelete = _reallyDelete;
}

- (BOOL)reallyDelete {
  return self->reallyDelete;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  [self assert:[_key isKindOfClass:[NSString class]]
        reason:@"key must be a string"];
  
  if ([_key isEqualToString:@"object"])
    [self setObject:_value];
  else if ([_key isEqualToString:@"reallyDelete"])
    [self setReallyDelete:[_value boolValue]];
  else if ([_key isEqualToString:@"primaryKey"])
    [self setPrimaryKeyValue:_value];
  else {
    if (_key == nil) {
      //NSLog(@"%s: invalid key; value: %@", __PRETTY_FUNCTION__, _value);
      return;
    }
    if (_value == nil) {
      //NSLog(@"%s: invalid value; key: %@", __PRETTY_FUNCTION__, _key);
      return;
    }
    
    [self assert:(self->recordDict != nil) reason:@"no record dict available"];
    [self->recordDict setObject:_value forKey:_key];
  }
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"object"])
    return [self object];
  if ([_key isEqualToString:@"reallyDelete"])
    return [NSNumber numberWithBool:[self reallyDelete]];
  if ([_key isEqualToString:@"primaryKey"])
    return [self primaryKeyValue];
  
  return [self->recordDict objectForKey:_key];
}

@end /* LSDBObjectDeleteCommand */
