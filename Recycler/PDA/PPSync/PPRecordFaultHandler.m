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

#include "PPRecordFaultHandler.h"
#include "PPRecordDatabase.h"
#include "PPSyncContext.h"
#include "common.h"

#include "PPTransaction.h"

@implementation PPRecordFaultHandler

- (id)initWithDatabase:(PPRecordDatabase *)_db oid:(EOGlobalID *)_oid {
  self->db  = [_db  retain];
  self->oid = [_oid retain];
  return self;
}

- (void)dealloc {
  [self->db  release];
  [self->oid release];
  [super dealloc];
}

- (void)completeInitializationOfObject:(id)_fault {
  NSData *data;
  int attrs, category;
  
  RETAIN(self); // keep reference if fault releases it's handler
  [EOFault clearFault:_fault];
  
  /* assign values */
  data = [[self->db syncContext]
                    fetchRecordByID:self->oid
                    fromDatabase:self->db
                    attributes:&attrs
                    category:&category];
  
  [_fault awakeFromDatabase:self->db
          objectID:self->oid
          attributes:attrs
          category:category
          data:data];

  [_fault awakeFromFetchInEditingContext:[self ppTransaction]];
  
  [self release];
}

/* description */

- (NSString *)descriptionForObject:(id)_fault {
  return [NSString stringWithFormat:@"<%@[%p]: on=%@ oid=%@ db=%@>",
                     NSStringFromClass(*(Class *)_fault),
                     _fault,
                     NSStringFromClass([self targetClass]),
                     self->oid,
                     [self->db databaseName]];
}

@end /* PPRecordFaultHandler */
