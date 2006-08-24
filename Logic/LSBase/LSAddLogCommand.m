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

#include <LSFoundation/LSDBObjectNewCommand.h>

@interface LSAddLogCommand : LSDBObjectNewCommand
{
@private
  id objectToLog;
}

@end

#include <EOControl/EOKeyGlobalID.h>
#include "common.h"

@implementation LSAddLogCommand

- (void)dealloc {
  [self->objectToLog release];
  [super dealloc];
}

- (BOOL)isObjectLogEnabledInContext:(id)_ctx {
  return YES;
}

- (BOOL)shouldInsertObjectInObjInfoTable:(id)_object {
  return NO;
}

- (void)_prepareForExecutionInContext:(id)_context {
  id owner;

  if (![self isObjectLogEnabledInContext:_context])
    return;
  
  owner = [_context valueForKey:LSAccountKey];
  
  if ([self valueForKey:@"objectId"] == nil) {
    if ([self->objectToLog isKindOfClass:[NSNumber class]])
      [self takeValue:self->objectToLog forKey:@"objectId"];
    else if ([self->objectToLog isKindOfClass:[EOKeyGlobalID class]]) {
      [self takeValue:[(EOKeyGlobalID *)self->objectToLog keyValues][0]
	    forKey:@"objectId"];
    }
    else if ([self->objectToLog isNotNull]) {
      EOEntity *objectEntity;
      NSNumber *objectId;

      objectEntity = [[self->objectToLog classDescription] entity];
      objectId = [self->objectToLog valueForKey:
			[[objectEntity primaryKeyAttributeNames] lastObject]];
      [self takeValue:objectId  forKey:@"objectId"];
    }
  }
  
  [self assert:([self valueForKey:@"objectId"] != nil)
        reason:@"no objectId set !"];
  
  owner = [owner valueForKey:@"companyId"];
  if (owner == nil)
    owner = [NSNumber numberWithInt:10000 /* Root */]; // root
  
  [self assert:(owner != nil) reason:@"no owner set (login!)"];
  
  [self takeValue:[NSCalendarDate date]  forKey:@"creationDate"];
  [self takeValue:owner                  forKey:@"accountId"];
  
  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {
  if (![self isObjectLogEnabledInContext:_context])
    return;
  
  //  NSLog(@"Adding Log for %@",[self objectToLog]);
  [self assert:([self valueForKey:@"objectId"] != nil)
	reason:@"no objectId set"];
  [self assert:([[self valueForKey:@"logText"] length] > 0)
	reason:@"no logText set"];
  [super _executeInContext:_context];
}

- (NSString *)entityName {
  return @"Log";
}

/* accessors */

- (void)setObjectToLog: (id)_objectToLog {
  ASSIGN(self->objectToLog,_objectToLog);
}
- (id)objectToLog {
  return self->objectToLog;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"objectToLog"]) {
    [self setObjectToLog: _value];
    return;
  }
  else if ([_key isEqualToString:@"oid"])
    _key = @"objectId";
  
  [super takeValue:_value forKey:_key];
}
- (id)valueForKey:(NSString *)_key {
  return [super valueForKey:_key];
}

@end /* LSAddLogCommand */
