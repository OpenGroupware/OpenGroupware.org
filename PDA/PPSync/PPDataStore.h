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

#ifndef __PPDataStore_H__
#define __PPDataStore_H__

#import <Foundation/NSObject.h>
#include <EOControl/EOGlobalID.h>

@class NSArray;
@class EOFetchSpecification, PPTransaction;

@interface PPDataStore : NSObject

/* initialization */

- (void)initializeObject:(id)_object
  withGlobalID:(EOGlobalID *)_oid
  ppTransaction:(PPTransaction *)_ec;

/* faults */

- (NSArray *)arrayFaultWithSourceGlobalID:(EOGlobalID *)_oid
  relationshipName:(NSString *)_relship
  ppTransaction:(PPTransaction *)_ec;

- (id)faultForGlobalID:(EOGlobalID *)_oid
  ppTransaction:(PPTransaction *)_ec;

- (id)faultForRow:(id)_row
  entityNamed:(NSString *)_entityName
  ppTransaction:(PPTransaction *)_ec;

- (void)refaultObject:(id)_object
  withGlobalID:(EOGlobalID *)_oid
  ppTransaction:(PPTransaction *)_ec;

/* object registry */

- (void)invalidateAllObjects;
- (void)invalidateObjectsWithGlobalIDs:(NSArray *)_oids;

/* fetching */

- (NSArray *)objectsForSourceGlobalID:(EOGlobalID *)_oid
  relationshipName:(NSString *)_relName
  ppTransaction:(PPTransaction *)_ec;

- (NSArray *)objectsWithFetchSpecification:(EOFetchSpecification *)_fspec
  ppTransaction:(PPTransaction *)_ec;

/* locking */

- (void)lockObjectWithGlobalID:(EOGlobalID *)_oid
  ppTransaction:(PPTransaction *)_ec;
- (BOOL)isObjectLockedWithGlobalID:(EOGlobalID *)_oid
  ppTransaction:(PPTransaction *)_ec;

/* saving */

- (void)saveChangesInTransaction:(PPTransaction *)_ec;

@end

#endif /* __PPDataStore_H__ */
