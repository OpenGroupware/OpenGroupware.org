/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include "SkyPalmDataSourceViewer.h"
#include <OGoPalm/SkyPalmEntryDataSource.h>
#include "SkyPalmDataSourceViewerState.h"
#include <OGoPalm/SkyPalmDocument.h>
#include <OGoPalm/SkyPalmConstants.h>
#include "common.h"

@interface SkyPalmDataSourceViewer(PrivatMethods)
- (NSString *)newNotificationName;
- (NSString *)updateNotificationName;
- (NSString *)deleteNotificationName;
- (NSString *)palmDb;
- (NSString *)itemKey;
- (NSString *)primaryKey;
- (NSString *)newDirectActionName;
- (NSString *)viewDirectActionName;
@end

@interface OGoSession(SkyPalmEntryListMethods)
- (NSNotificationCenter *)notificationCenter;
@end

@implementation SkyPalmDataSourceViewer

- (id)init {
  if ((self = [super init])) {
    NSNotificationCenter *nc = nil;
    self->dataSource = nil;
    self->state      = nil;
    
    nc = [(id)[self session] notificationCenter];
    [nc addObserver:self selector:@selector(noteChange:)
        name:[self newNotificationName] object:nil];
    [nc addObserver:self selector:@selector(noteChange:)
        name:[self updateNotificationName] object:nil];
    [nc addObserver:self selector:@selector(noteChange:)
        name:[self deleteNotificationName] object:nil];

    self->isCached = NO;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  [self unregisterAsObserver];
  RELEASE(self->state);
  RELEASE(self->dataSource);
  RELEASE(self->record);
  [super dealloc];
}
#endif

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  [super takeValuesFromRequest:_req inContext:_ctx];
  [[self dataSource] setFetchSpecification:[[self state] fetchSpecification]];
}

- (void)noteChange:(NSString *)_cn {
  if (self->isCached) {
    [[self dataSource] clear];
  }
}

- (BOOL)synchronizesVariablesWithBindings {
  return NO;
}

// accessors
- (LSCommandContext *)_context {
  return [(id)[self session] commandContext];
}

- (void)setDataSource:(id)_ds {
  ASSIGN(self->dataSource,_ds);
}
- (id)dataSource {
  if (self->dataSource == nil) {
    id ds = [self valueForBinding:@"dataSource"];
    if (ds != nil) {
      [self setDataSource:ds];
      self->isCached =
        ([self->dataSource isKindOfClass:[EOCacheDataSource class]])
        ? YES : NO;
      return ds;
    }

    self->dataSource = 
      [SkyPalmEntryDataSource dataSourceWithContext:[self _context]
                              forPalmDb:[self palmDb]];
    self->dataSource =
      [[EOCacheDataSource alloc] initWithDataSource:self->dataSource];
    self->isCached = YES;
  }
  return self->dataSource;
}
- (id)palmDataSource {
  if (self->isCached)
    return [self->dataSource source];
  return self->dataSource;
}

- (void)setRecord:(id)_record {
  ASSIGN(self->record,_record);
  [self setValue:_record forBinding:[self itemKey]];
}
- (SkyPalmDocument *)record {
  return self->record;
}
- (id)recordIdentifier {
  id gid = [self->record valueForKey:@"globalID"];
  return [NSString stringWithFormat:@"%@%@",
                   [self palmDb], [[gid keyValuesArray] objectAtIndex:0]];
}

- (void)setState:(SkyPalmDataSourceViewerState *)_state {
  ASSIGN(self->state,_state);
  [[self dataSource] setFetchSpecification:[state fetchSpecification]];
}
- (SkyPalmDataSourceViewerState *)state {
  if (self->state == nil)
    [self setState:[self valueForBinding:@"state"]];
  return self->state;
}

- (id)action {
  return [self valueForBinding:@"action"];
}

- (BOOL)hasAction {
  // has current record view action??
  return YES;
}
- (BOOL)hasNoAction {
  return ([self hasAction]) ? NO : YES;
}

// accessors
- (NSString *)syncState {
  return [[self record] syncState];
}
// direct action support
- (NSString *)newDirectActionURL {
  id ctx = [self context];
  id sid = [(id)[self session] sessionID];
  return [ctx directActionURLForActionNamed:[self newDirectActionName]
              queryDictionary:
              [NSDictionary dictionaryWithObject:sid
                            forKey:@"sid"]];
}
- (NSString *)viewDirectActionURL {
  id ctx = [self context];
  id sid = [(id)[self session] sessionID];
  id oid = [self->record valueForKey:[self primaryKey]];

  NSString *href =
    [ctx directActionURLForActionNamed:[self viewDirectActionName]
         queryDictionary:
         [NSDictionary dictionaryWithObjectsAndKeys:
                       oid,  @"oid",
                       sid,  @"sid",
                       nil]];
  return href;
}

- (NSString *)syncTypeKey {
  return [NSString stringWithFormat:@"sync_type_%d",
                   [[self record] syncType]];
}
- (NSString *)syncTypeShortKey {
  return [NSString stringWithFormat:@"sync_type_short_%d",
                   [[self record] syncType]];
}
- (NSString *)skyrixSyncStateKey {
  return [NSString stringWithFormat:@"sync_state_%d",
                   [[self record] skyrixSyncState]];
}
- (NSString *)skyrixSyncStateShortKey {
  return [NSString stringWithFormat:@"sync_state_short_%d",
                   [[self record] skyrixSyncState]];
}

- (NSString *)skyrixSyncStateColor {
  switch ([[self record] skyrixSyncState]) {
    case SYNC_STATE_BOTH_CHANGED:
      return @"red";
  }
  return @"black";
}

- (BOOL)skyrixSyncStateBothChanged {
  return [[self record] skyrixSyncState] == SYNC_STATE_BOTH_CHANGED;
}

- (NSString *)skyrixSyncTypeIcon {
  switch ([[self record] syncType]) {
    case SYNC_TYPE_DO_NOTHING:
      return @"icon_palm_donothing.gif";
    case SYNC_TYPE_SKY_OVER_PALM:
      return @"icon_palm_skyrixoverpalm.gif";
    case SYNC_TYPE_PALM_OVER_SKY:
      return @"icon_palm_palmoverskyrix.gif";
  }
  return @"icon_palm_sync_entry.gif";
}
- (NSString *)skyrixSyncTypeString {
  return [NSString stringWithFormat:@"%@\n(%@)",
                   [[self labels] valueForKey:[self syncTypeKey]],
                   [[self labels] valueForKey:[self skyrixSyncStateKey]]];
}

// actions
- (id)refresh {
  if (self->isCached) {
    [[self dataSource] clear];
  }
  return nil;
}
- (id)viewAction {
  id page = nil;

  page = [self action];
  if (page != nil)
    return [self performParentAction:page];
  page = [[[self session] navigation] activateObject:self->record
                                      withVerb:@"view"];
  return page;
}

- (id)viewSkyrixRecord {
  id page;

  page = [[[self session] navigation]
                 activateObject:[self->record skyrixRecord]
                 withVerb:@"view"];
  return page;
}

- (id)viewSkyrixRecordComponentAction {
  id gid = nil;

  gid = [[[self record] skyrixRecord] valueForKey:@"globalID"];

  if (gid) {
    [[self session] transferObject:gid owner:self];
    [self executePasteboardCommand:@"view"];
  }

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

// methods to overwrite
- (NSString *)palmDb {
  NSLog(@"palmDb is NOT overwriten! this won't work!");
  return nil;
}
- (NSString *)itemKey {
  NSLog(@"itemKey is NOT overwriten! this won't work!");
  return nil;
}
- (NSString *)updateNotificationName {
  NSLog(@"updateNotificationName is NOT overwriten! this won't work!");
  return nil;
}
- (NSString *)deleteNotificationName {
  NSLog(@"deleteNotificationName is NOT overwriten! this won't work!");
  return nil;
}
- (NSString *)newNotificationName {
  NSLog(@"newNotificationName is NOT overwriten! this won't work!");
  return nil;
}
- (NSString *)newDirectActionName {
  NSLog(@"newDirectActionName is NOT overwriten! this won't work!");
  return nil;
}
- (NSString *)viewDirectActionName {
  NSLog(@"viewDirectActionName is NOT overwriten! this won't work!");
  return nil;
}
- (NSString *)primaryKey {
  NSLog(@"primaryKey is NOT overwriten! this won't work!");
  return nil;
}


@end /* SkyPalmDataSourceViewer */
