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

#include "SkyPalmEntryViewer.h"

#import <Foundation/Foundation.h>
#include <LSFoundation/LSFoundation.h>
#include <OGoFoundation/OGoFoundation.h>
#include <OGoPalm/SkyPalmEntryDataSource.h>
#import <EOControl/EOQualifier.h>
#import <EOControl/EOFetchSpecification.h>
#import <EOControl/EOKeyGlobalID.h>
#include <OGoPalm/SkyPalmDocument.h>
#include <OGoDocuments/LSCommandContext+Doc.h>
#include <OGoDocuments/SkyDocumentManager.h>

@interface SkyPalmEntryViewer(PrivatMethods)
- (NSString *)updateNotificationName;
- (NSString *)deleteNotificationName;
- (NSString *)palmDb;
- (NSString *)primaryKey;
- (NSString *)entityName;
@end

@implementation SkyPalmEntryViewer

- (id)init {
  if ((self = [super init])) {
    [self registerForNotificationNamed:[self updateNotificationName]];
    [self registerForNotificationNamed:[self deleteNotificationName]];
    self->fetchObject = NO;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  [self unregisterAsObserver];
  [super dealloc];
}
#endif

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  object:(id)_object
{
  id obj = _object;
  if ([obj isKindOfClass:[EOKeyGlobalID class]]) {
    id<SkyDocumentManager> dm;
    dm = [[[self session] commandContext] documentManager];
    obj = [dm documentForGlobalID:obj];
    if (obj == nil) {
      NSLog(@"failed loading object for gid");
      return NO;
    }
  }
  [self setObject:obj];
  return YES;
}

// overwriting
- (NSString *)updateNotificationName {
  return nil;
}
- (NSString *)deleteNotificationName {
  return nil;
}
- (NSString *)palmDb {
  return nil;
}
- (NSString *)primaryKey {
  return [NSString stringWithFormat:@"%@_id", [self entityName]];
}
- (NSString *)entityName {
  return nil;
}

// accessors
- (SkyPalmDocument *)record {
  return [self object];
}

- (void)_fetchObject {
  [[self record] reload];
  self->fetchObject = NO;
}

- (void)noteChange:(NSString *)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];
  if ([_cn isEqualToString:[self deleteNotificationName]]) {
    if ([_object isEqual:[self object]]) {
      [self setObject:nil];
    }
  }
  if ([_cn isEqualToString:[self updateNotificationName]]) {
    self->fetchObject = YES;
  }
}

- (void)syncAwake {
  [super syncAwake];

  if (self->fetchObject)
    [self _fetchObject];
}

// accessors
- (NSString *)syncState {
  id r = [self record];
  return [NSString stringWithFormat:@"record_%@", [r syncState]];
}
- (NSString *)syncTypeKey {
  return [NSString stringWithFormat:@"sync_type_%d",
                   [[self record] syncType]];
}
- (NSString *)syncStateKey {
  return [NSString stringWithFormat:@"sync_state_%d",
                   [[self record] skyrixSyncState]];
}

- (id)deleteRecord {
  //  if ([[self record] delete] == nil)
  //    return [self back];
  //  return nil;
  [[self record] delete];
  return [self back];
}

- (id)undeleteRecord {
  if ([[self record] undelete] == nil)
    return [self back];
  return nil;
}

- (id)editRecord {
  id page = nil;
  page = [[[self session] navigation]
                 activateObject:[self record] withVerb:@"edit"];
  return page;
}

- (id)assignSkyrixRecord {
  id page = nil;
  page = [[[self session] navigation]
                 activateObject:[self record]
                 withVerb:@"assign-skyrix-record"];
  return page;
}
- (id)createNewSkyrixRecord {
  id page = nil;
  page = [[[self session] navigation]
                 activateObject:[self record]
                 withVerb:@"create-skyrix-record"];
  return page;
}
- (id)detachSkyrixRecord {
  [[self record] setSkyrixId:nil];
  [[self record] saveWithoutReset];
  return nil;
}

- (id)viewSkyrixRecord {
  id page = nil;
  page = [[[self session] navigation]
                 activateObject:[[self record] skyrixRecord]
                 withVerb:@"view"];
  return page;
}

- (id)syncWithSkyrixRecord {
  [[self record] syncWithSkyrixRecord];
  return nil;
}

- (id)forcePalmOverOGo {
  [[self record] forcePalmOverSkyrixSync];
  return nil;
}
- (id)forceOGoOverPalm {
  [[self record] forceSkyrixOverPalmSync];
  return nil;
}


@end /* SkyPalmEntryViewer */
