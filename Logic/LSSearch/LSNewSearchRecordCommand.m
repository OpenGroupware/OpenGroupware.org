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

#include "common.h"
#include "LSGenericSearchRecord.h"
#include "LSNewSearchRecordCommand.h"

@implementation LSNewSearchRecordCommand

// command methods

- (void)_executeInContext:(id)_context {
  NSMutableArray        *records = [[NSMutableArray alloc] init];
  LSGenericSearchRecord *record  = [[LSGenericSearchRecord alloc] init];

  [record setEntity:[self entity]];
  [record takeValuesFromDictionary:self->recordDict];

  [records addObject:record];
  [self setReturnValue:record];

  RELEASE(record);  record  = nil;
  RELEASE(records); records = nil;
}

// initialize records

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"entity"]) {
    [self setEntityName:_value];
    return;
  }
  else
    [self->recordDict takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"entity"])
    return [self entityName];
  else
    return [self->recordDict valueForKey:_key];
}

@end /* LSNewSearchRecordCommand */
