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

#include "Change.h"
#include "common.h"

@implementation Change

- (id)init {
  if ((self = [super init])) {
    changeType = [[NSString alloc] init];
    changeDate = [[NSDate alloc] init];
    actions    = [[NSMutableArray alloc] init];
  }
  return self;
}

+ (Change *)changeWithChangeType:(NSString *)_type {
  Change *change = nil;

  change = [[self alloc] init];
  [change setChangeType:_type];
  [change setChangeDate:[NSDate date]];

  return AUTORELEASE(change);
}

- (void)dealloc {
  RELEASE(self->changeType);
  RELEASE(self->changeDate);
  RELEASE(self->actions);
  
  [super dealloc];
}

- (NSString *)changeType {
  return self->changeType;
}
- (void)setChangeType:(NSString *)_changeType {
  ASSIGNCOPY(self->changeType, _changeType);
}

- (NSDate *)changeDate {
  return self->changeDate;
}
- (void)setChangeDate:(NSDate *)_changeDate {
  ASSIGN(self->changeDate, _changeDate);
}  

- (NSDictionary *)dictionary {
  NSMutableDictionary *dict = nil;

  dict = [NSMutableDictionary dictionaryWithCapacity:2];
  [dict setObject:self->changeDate forKey:@"lastModification"];
  [dict takeValue:self->changeType forKey:@"type"];

  return dict;
}

- (NSString *)description {
  NSMutableString *string = nil;

  string =  [NSMutableString stringWithFormat:
                             @"<%@[0x%08X]: type: %@ lastMod: %@ actions: %d>",
                             NSStringFromClass([self class]), self,
                             self->changeType, self->changeDate,
                             [self->actions count]];

  return string;
}

- (void)addAction:(id)_action {
  [self->actions addObject:_action];
}

- (void)runActions {
  if ([self->actions count] > 0) {
    [self->actions makeObjectsPerformSelector:@selector(run)];
  }
}

- (void)updateValues:(Change *)_change {
  [self setChangeDate:[_change changeDate]];
  [self setChangeType:[_change changeType]];
}

- (NSArray *)actions {
  NSMutableArray *changes    = nil;
  NSEnumerator   *actionEnum = nil; 
  id             action      = nil;

  if ([self->actions count] > 0) {
  
    changes = [NSMutableArray arrayWithCapacity:[self->actions count]];
    actionEnum = [self->actions objectEnumerator];

    while((action = [actionEnum nextObject])) {
      NSMutableDictionary *dict;

      dict = [NSMutableDictionary dictionaryWithCapacity:2];
      [dict takeValue:NSStringFromClass([action class]) forKey:@"type"];
      [dict takeValue:[action arguments] forKey:@"arguments"];

      [changes addObject:dict];
    }
    return changes;
  }
  return nil;
}

@end /* Change */
