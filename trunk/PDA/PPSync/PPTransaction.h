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

#ifndef __PPTransaction_H__
#define __PPTransaction_H__

#import <Foundation/NSLock.h>
#import <Foundation/NSHashTable.h>
#import <Foundation/NSMapTable.h>
#include <PPSync/PPDataStore.h>
#include <EOControl/EOObserver.h>

@class NSArray, NSRecursiveLock, NSException;
@class NSMutableArray, NSDictionary;
@class EOGlobalID;
@class PPPostSync;

/*
  Editing contexts manage EOs in memory. They are an in-memory view of
  an object store.
*/

@interface PPTransaction : PPDataStore < NSLocking, EOObserving >
{
  NSRecursiveLock   *lock;
  PPDataStore       *store;
  id                delegate;       /* non-retained */
  id                messageHandler; /* non-retained */
  NSArray           *editors;
  NSMutableArray    *pools;         /* pools setup during -lock */

  /* changes trackers */
  NSHashTable       *inserted;
  NSHashTable       *deleted;
  NSHashTable       *updated;
  NSHashTable       *uInserted;
  NSHashTable       *uDeleted;
  NSHashTable       *uUpdated;

  /* mapping tables */
  NSMapTable        *idToInfo;
  NSMapTable        *oidToInfo;
  BOOL              retainsRegisteredObjects;

  /* post sync */
  NSMutableArray *registeredPostSyncs;
}

+ (void)setDefaultParentObjectStore:(PPDataStore *)_store;
+ (PPDataStore *)defaultParentObjectStore;

+ (BOOL)instancesRetainRegisteredObjects;

- (id)initWithParentObjectStore:(PPDataStore *)_objectStore;

/* accessors */

- (void)setDelegate:(id)_delegate;
- (id)delegate;
- (void)setMessageHandler:(id)_delegate;
- (id)messageHandler;

- (PPDataStore *)parentObjectStore;
- (PPDataStore *)rootObjectStore;

/* object graph */

- (BOOL)hasChanges;
- (NSArray *)deletedObjects;
- (NSArray *)updatedObjects;
- (NSArray *)insertedObjects;
- (NSArray *)registeredObjects;

- (void)insertObject:(id)_object withGlobalID:(EOGlobalID *)_oid;
- (void)insertObject:(id)_object;
- (void)deleteObject:(id)_object;
- (void)objectWillChange:(id)_object;

- (void)revert;

/* object registry */

- (EOGlobalID *)globalIDForObject:(id)_object;
- (id)objectForGlobalID:(EOGlobalID *)_oid;
- (void)recordObject:(id)_object globalID:(EOGlobalID *)_oid;
- (void)forgetObject:(id)_object;
- (void)reset;

/* faults */

- (void)refaultObjects;
- (void)invalidateAllObjects;

/* snapshots */

- (NSDictionary *)committedSnapshotForObject:(id)_eo;
- (NSDictionary *)currentEventSnapshotForObject:(id)_eo;

/* object locking */

- (void)lockObject:(id)_object;
- (BOOL)locksObjectsBeforeFirstModification;

/* fetching */

- (NSArray *)objectsWithFetchSpecification:(EOFetchSpecification *)_fspec;

/* processing */

- (BOOL)stopsValidationAfterFirstError;
- (BOOL)propagatesDeletesAtEndOfEvent;

- (void)processRecentChanges;
- (void)saveChanges;
- (NSException *)tryToSaveChanges;

/* editors */

- (void)addEditor:(id)_editor;
- (void)removeEditor:(id)_editor;
- (NSArray *)editors;

/* transaction methods */
/* this is to enable post syncs processes
   after the pilot-connection is closed
*/
- (void)registerPostSync:(PPPostSync *)_postSync;
- (NSArray *)registeredPostSyncs;

@end

@interface PPTransaction(Actions)

- (void)refetch:(id)_sender;
- (void)refault:(id)_sender;
- (void)redo:(id)_sender;
- (void)undo:(id)_sender;
- (void)revert:(id)_sender;
- (void)saveChanges:(id)_sender;

@end

@interface NSObject(PPTransaction)

- (PPTransaction *)ppTransaction;

@end

/* delegate */

@interface NSObject(PPTxDelegate)

- (void)ppTransactionWillSaveChanges:(PPTransaction *)_ec;

- (NSArray *)ppTransaction:(PPTransaction *)_ec
  shouldFetchObjectsDescribedByFetchSpecification:(EOFetchSpecification *)_fs;

@end

#endif /* __PPTransaction_H__ */
