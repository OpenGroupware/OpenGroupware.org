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

#include "PPDataStore.h"
#include <EOControl/EOControl.h>

@implementation PPDataStore

/* initialization */

- (void)initializeObject:(id)_object
  withGlobalID:(EOGlobalID *)_oid
  ppTransaction:(PPTransaction *)_ec
{
}

/* faults */

- (NSArray *)arrayFaultWithSourceGlobalID:(EOGlobalID *)_oid
  relationshipName:(NSString *)_relship
  ppTransaction:(PPTransaction *)_ec
{
  return [self subclassResponsibility:_cmd];
}

- (id)faultForGlobalID:(EOGlobalID *)_oid
  ppTransaction:(PPTransaction *)_ec
{
  return [self subclassResponsibility:_cmd];
}

- (id)faultForRow:(id)_row
  entityNamed:(NSString *)_entityName
  ppTransaction:(PPTransaction *)_ec
{
  return [self subclassResponsibility:_cmd];
}

- (void)refaultObject:(id)_object
  withGlobalID:(EOGlobalID *)_oid
  ppTransaction:(PPTransaction *)_ec
{
  [self subclassResponsibility:_cmd];
}

/* object registry */

- (void)invalidateAllObjects {
}
- (void)invalidateObjectsWithGlobalIDs:(NSArray *)_oids {
}

/* fetching */

- (NSArray *)objectsForSourceGlobalID:(EOGlobalID *)_oid
  relationshipName:(NSString *)_relName
  ppTransaction:(PPTransaction *)_ec
{
  return [self subclassResponsibility:_cmd];
}  

- (NSArray *)objectsWithFetchSpecification:(EOFetchSpecification *)_fspec
  ppTransaction:(PPTransaction *)_ec
{
  return [self subclassResponsibility:_cmd];
}

/* locking */

- (void)lockObjectWithGlobalID:(EOGlobalID *)_oid
  ppTransaction:(PPTransaction *)_ec
{
  [self subclassResponsibility:_cmd];
}
- (BOOL)isObjectLockedWithGlobalID:(EOGlobalID *)_oid
  ppTransaction:(PPTransaction *)_ec
{
  [self subclassResponsibility:_cmd];
  return NO;
}

/* saving */

- (void)saveChangesInTransaction:(PPTransaction *)_ec {
  [self subclassResponsibility:_cmd];
}

@end /* PPDataStore */
