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

#include "SkyPalmAssignEntry.h"
#import <Foundation/Foundation.h>
#include <OGoFoundation/OGoFoundation.h>
#include <OGoPalm/SkyPalmConstants.h>
#include <OGoPalm/SkyPalmEntryDataSource.h>
#include <EOControl/EOKeyGlobalID.h>

@interface SkyPalmAssignEntry(PrivatMethods)
- (void)setDoc:(SkyPalmDocument *)_doc;
@end

@implementation SkyPalmAssignEntry

- (id)init {
  if ((self = [super init])) {
    self->doc          = nil;
    self->skyrixRecord = nil;
    self->syncType     = SYNC_TYPE_DO_NOTHING;
    self->item         = nil;
    self->activationCommand = nil;
    
    self->skyrixRecords = [[NSMutableArray alloc] init];
    self->palmRecords   = [[NSMutableArray alloc] init];
    self->ds            = nil;
    self->index         = 0;
    self->devices       = nil;
    self->deviceId      = nil;
  }
  return self;
}

- (void)dealloc {
  [self->doc               release];
  [self->skyrixRecord      release];
  [self->item              release];
  [self->activationCommand release];

  [self->skyrixRecords release];
  [self->palmRecords   release];
  [self->ds            release];
  [self->devices       release];
  [self->deviceId      release];
  [super dealloc];
}

- (BOOL)isEditorPage {
  return YES;
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
                               type:(NGMimeType *)_type
                      configuration:(id)_cfg
{
  id obj = [[self session] getTransferObject];

  if ([obj isKindOfClass:[SkyPalmDocumentSelection class]]) {
    id cp = [[obj docs] mutableCopy];
    [self setPalmRecords:cp];
    [cp release];
    obj = [self->palmRecords lastObject];
  }
  else {
    [self setDoc:obj];
  }

  ASSIGN(self->activationCommand,_command);

  // check for deviceId

  if (obj == nil) {
    [self setErrorString:
          @"Got on valid Palm-Entry!\n"
          @"Could not set default device-id!\n"
          @"First sync with Palm-Device!\n"];
    return NO;
  }
  if ([obj deviceId] == nil) {
    [self setErrorString:
          @"No Entries found in database!\n"
          @"Could not set default device-id!\n"
          @"First sync with Palm-Device!\n"];
    return NO;
  }
  
  return YES;
}

/* overwriting */

- (id)fetchSkyrixRecord {
  [self logWithFormat:@"<%@> fetchSkyrixRecord not overwritten!!", self];
  return nil;
}
- (NSString *)primarySkyKey {
  [self logWithFormat:@"<%@> primarySkyKey not overwritten!!", self];
  return nil;
}

/* accessors */

- (void)setSkyrixRecord:(id)_rec {
  ASSIGN(self->skyrixRecord,_rec);
}
- (id)skyrixRecord {
  return self->skyrixRecord;
}

- (void)setDoc:(SkyPalmDocument *)_doc {
  ASSIGN(self->doc,_doc);
  [self setSkyrixRecord:[self fetchSkyrixRecord]];
  [self setSyncType:[_doc syncType]];
  [self setDeviceId:[_doc deviceId]];
}
- (id)doc {
  return self->doc;
}

- (void)setSyncType:(int)_type {
  self->syncType = _type;
}
- (int)syncType {
  return self->syncType;
}

- (void)setDeviceId:(NSString *)_deviceId {
  ASSIGN(self->deviceId,_deviceId);
}
- (NSString *)deviceId {
  if (self->deviceId == nil) {
    NSArray  *devs = [self devices];
    if ([devs count] > 0) {
      [self setDeviceId:[devs objectAtIndex:0]];
    }
  }
  return self->deviceId;
}


- (NSString *)syncTypeKey {
  return [NSString stringWithFormat:@"sync_type_%@", self->item];
}

- (void)setItem:(id)_item {
  ASSIGN(self->item,_item);
}
- (id)item {
  return self->item;
}
- (void)setIndex:(int)_idx {
  self->index = _idx;
}
- (int)index {
  return self->index;
}

- (void)setPalmRecords:(NSMutableArray *)_recs {
  if (![self assignToRecord])
    ASSIGN(self->palmRecords,_recs);
  else {
    RELEASE(self->palmRecords);
    self->palmRecords = nil;
  }
}
- (NSMutableArray *)palmRecords {
  if ([self assignToRecord])
    return nil;
  return self->palmRecords;
}
- (void)setSkyrixRecords:(NSMutableArray *)_recs {
  if (![self assignToRecord])
    ASSIGN(self->skyrixRecords,_recs);
  else {
    RELEASE(self->skyrixRecords);
    self->skyrixRecords = nil;
  }
}
- (NSMutableArray *)skyrixRecords {
  if ([self assignToRecord])
    return nil;
  return self->skyrixRecords;
}

- (SkyPalmEntryDataSource *)dataSource {
  return self->ds;
}

- (BOOL)assignToRecord {
  return [self->activationCommand isEqualToString:@"assign-skyrix-record"]
    ? YES : NO;
}
- (BOOL)createNewRecord {
  return [self->activationCommand isEqualToString:@"create-skyrix-record"]
    ? YES : NO;
}
- (BOOL)createFromRecord {
  return [self->activationCommand isEqualToString:@"new-from-skyrix-record"]
    ? YES : NO;
}
- (BOOL)isSingleSelection {
  if ([self assignToRecord])
    return YES;
  if (((self->palmRecords == nil)   || ([self->palmRecords count] == 0)) &&
      ((self->skyrixRecords == nil) || ([self->skyrixRecords count] == 0)))
    return YES;
  return NO;
}
- (NSString *)titleKey {
  return self->activationCommand;
}
- (BOOL)hasSinglePalmDoc {
  if ([[self doc] globalID] == nil)
    return NO;
  return [self isSingleSelection];
}

- (NSArray *)devices {
  if (self->devices == nil) {
    if ([self isSingleSelection])
      self->devices = [[self doc] devices];
    else
      self->devices = [[self dataSource] devices];
    RETAIN(self->devices);
  }
  return self->devices;
}


// overwrite
- (SkyPalmDocument *)newPalmDoc {
  NSLog(@"%s not overwritten !!", __PRETTY_FUNCTION__);
  return nil;
}
- (id)newSkyrixRecordForPalmDoc:(SkyPalmDocument *)_doc {
  NSLog(@"%s not overwritten !!", __PRETTY_FUNCTION__);
  return nil;
}

// actions
- (id)back {
  return [[[self session] navigation] leavePage];
}
- (void)_saveDoc:(id)_doc withSkyrixRecord:(id)_skyRec {
  [_doc setSyncType:self->syncType];
  if (self->deviceId != nil)
    [_doc setDeviceId:self->deviceId];
  [_doc setSkyrixId:
        [[(EOKeyGlobalID *)[_skyRec globalID]
                           keyValuesArray] objectAtIndex:0]];
  if (self->syncType == SYNC_TYPE_TWO_WAY) {
    // handle first time sync
    if ([self createNewRecord])
      // creating a new skyrix record
      [_doc forcePalmOverSkyrixSync];
    else if ([self createFromRecord]) {
      // creating a new palm record
      [_doc forceSkyrixOverPalmSync];
    }
  }
  else
    [_doc syncWithSkyrixRecord];
}
- (id)multipleSave {
  if ([self assignToRecord])
    return [self cancel];
  
  if ([self createNewRecord]) {
    // create new skyrix records
    NSEnumerator *e  = [self->palmRecords objectEnumerator];
    id           one = nil;

    [self setSyncType:SYNC_TYPE_PALM_OVER_SKY];
    while ((one = [e nextObject])) {
      [self _saveDoc:one
            withSkyrixRecord:[self newSkyrixRecordForPalmDoc:one]];
    }
  }
  else if ([self createFromRecord]) {
    // create new palm records
    NSEnumerator *e  = [self->skyrixRecords objectEnumerator];
    id           one = nil;

    [self setSyncType:SYNC_TYPE_SKY_OVER_PALM];
    while ((one = [e nextObject])) {
      [self _saveDoc:[self newPalmDoc]
            withSkyrixRecord:one];
    }
  }
  return [self back];
}

- (id)save {
  if (![self isSingleSelection])
    return [self multipleSave];

  if ([self createFromRecord]) 
    [self setSyncType:SYNC_TYPE_SKY_OVER_PALM];
  if ([self createNewRecord])
    [self setSyncType:SYNC_TYPE_PALM_OVER_SKY];
  
  [self _saveDoc:self->doc withSkyrixRecord:[self skyrixRecord]];
  return [self back];
}

- (id)cancel {
  return [self back];
}

// kvc
- (void)takeValue:(id)_val forKey:(id)_key {
  if ([_key isEqualToString:@"dataSource"])
    ASSIGN(self->ds, _val);
  else
    [super takeValue:_val forKey:_key];
}

@end /* SkyPalmAssignEntry */
