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

#include "SkyPalmEntryList.h"
#include "SkyPalmEntryListState.h"
#include "common.h"
#include <OGoPalm/SkyPalmEntryDataSource.h>
#include <OGoPalm/SkyPalmDocument.h>

#define SKYPALM_MAX_IMPORT_ENTRIES 20

@interface OGoSession(SkyPalmEntryListMethods)
- (NSNotificationCenter *)notificationCenter;
@end

@interface SkyPalmEntryList(PrivatMethods)
- (NSString *)palmDb;
@end
@interface SkyPalmDataSourceViewer(EntryList)
- (void)setRecord:(id)_rec;
@end

@interface SkyPalmEntryListState(EntryList)
- (NSArray *)attributes;
@end

@interface SkyPalmDataSourceViewer(SkyPalmEntryList)
- (void)noteChange:(NSString *)_cn;
@end

@implementation SkyPalmEntryList

- (id)init {
  if ((self = [super init])) {
    NSNotificationCenter *nc = nil;
    
    self->selections = [[NSMutableArray allocWithZone:[self zone]] init];
    self->item       = nil;
    self->index      = 0;
    self->clickKey   = nil;
    self->possibleKeys = nil;
    self->hasDescAttr = NO;

    nc = [(id)[self session] notificationCenter];
    [nc addObserver:self selector:@selector(noteDefaultChange:)
        name:@"NSUserDefaultsChanged" object:nil];
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  [self unregisterAsObserver];
  RELEASE(self->item);
  RELEASE(self->selections);
  RELEASE(self->clickKey);
  RELEASE(self->possibleKeys);
  [super dealloc];
}
#endif

- (void)syncSleep {
  [[self state] synchronize];
  RELEASE(self->possibleKeys);  self->possibleKeys = nil;
  [super syncSleep];
}

// notification

- (void)clearSelections {
  [self->selections removeAllObjects];
}
- (void)noteChange:(NSString *)_cn {
  [super noteChange:_cn];
  [self clearSelections];
}

- (void)noteDefaultChange:(NSString *)_cn {
  self->hasDescAttr = NO;
  RELEASE(self->clickKey);  self->clickKey = nil;
}

// accessors

- (NSString *)subKey {
  NSString *sk = [self valueForBinding:@"subKey"];
  return (sk == nil) ? (id)@"" : sk;
}

- (SkyPalmEntryListState *)state {
  id s = [super state];

  if (s == nil) {
    NSString *sKey   = [self subKey];
    id       account = nil;
    account = [[self session] activeAccount];
    [self setState:
          [SkyPalmEntryListState listStateWithDefaults:
                                 [[self session] userDefaults]
                                 companyId:[account valueForKey:@"companyId"]
                                 subKey:sKey
                                 forPalmDb:[self palmDb]]];
  }
  return s;
}

// click key config
- (NSArray *)possibleClickKeys {
  NSLog(@"%s possibleClickKeys is NOT overwriten!", __PRETTY_FUNCTION__);
  return nil;
}
- (NSArray *)_possibleKeys {
  if (self->possibleKeys == nil) {
    NSMutableArray *all   = [NSMutableArray array];
    NSArray        *valid = [[self state] attributes];
    NSEnumerator   *e     = [[self possibleClickKeys] objectEnumerator];
    id             one    = nil;

    while ((one = [e nextObject])) {
      if ([valid containsObject:one])
        [all addObject:one];
    }

    self->possibleKeys = RETAIN(all);
  }
  return self->possibleKeys;
}
// overwrite if needed
- (id)documentKeyForRowKey:(id)_key {
  if ([_key hasPrefix:@"attribute_"])
    return [_key substringFromIndex:10];
  return _key;
}
- (id)clickKey {
  if (self->clickKey == nil) {
    NSEnumerator *e  = [[self _possibleKeys] objectEnumerator];
    id           one = nil;
    id           val = nil;
    while ((one = [e nextObject])) {
      val = [[self record] valueForKey:[self documentKeyForRowKey:one]];
      if ((val != nil) && ([val length] > 0)) {
        self->clickKey = RETAIN(one);
        if ([self->clickKey isEqualToString:@"attribute_description"])
          self->hasDescAttr = YES;
        break;
      }
    }
  }
  return self->clickKey;
}

- (void)setRecord:(id)_rec {
  [super setRecord:_rec];
  if (!self->hasDescAttr) {
    RELEASE(self->clickKey);  self->clickKey = nil;
  }
}

// accessors
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

- (void)setSelections:(NSArray *)_selections {
  ASSIGN(self->selections, selections);
}
- (NSArray *)selections {
  return self->selections;
}

- (NSArray *)selectedEntries {
  return [self selections];
}

// actions
- (BOOL)canHideDeleted {
  return ([[self state] hideDeleted])
    ? NO : YES;
}
- (id)hideDeleted {
  [[self state] setHideDeleted:YES];
  [[self dataSource] setFetchSpecification:[[self state] fetchSpecification]];
  return nil;
}
- (BOOL)canUnhideDeleted {
  return [[self state] hideDeleted];
}
- (id)unhideDeleted {
  [[self state] setHideDeleted:NO];
  [[self dataSource] setFetchSpecification:[[self state] fetchSpecification]];
  return nil;
}

- (id)updateSelection {
  [[self dataSource] setFetchSpecification:[[self state] fetchSpecification]];
  return nil;
}

// table components
- (id)hideTitle {
  return [self valueForBinding:@"hideTitle"];
}
- (id)hideButtons {
  return [self valueForBinding:@"hideButtons"];
}

// selection actions

- (id)selectionDelete {
  NSEnumerator *e  = [self->selections objectEnumerator];
  id           one = nil;

  while ((one = [e nextObject])) {
    if ([one isDeletable]) {
      [one delete];
    }
  }

  [self clearSelections];
  return nil;
}

- (id)selectionUndelete {
  NSEnumerator *e  = [self->selections objectEnumerator];
  id           one = nil;

  while ((one = [e nextObject])) {
    if ([one isUndeletable]) {
      [one undelete];
    }
  }

  [self clearSelections];
  return nil;
}

- (id)selectionMarkAsNew {
  NSEnumerator *e  = [self->selections objectEnumerator];
  id           one = nil;

  while ((one = [e nextObject])) {
    if ([one isDeleted]) [one setIsDeleted:NO];
    if ([one isArchived])  [one setIsArchived:NO];
    [one setPalmId:0];
    [one setIsNew:YES];
    [one saveWithoutReset];
  }

  [self clearSelections];
  return nil;
}

- (id)selectionDetachSkyrixEntry {
  NSEnumerator *e  = [self->selections objectEnumerator];
  id           one = nil;

  while ((one = [e nextObject])) {
    if ([one hasSkyrixRecord]) {
      [one setSkyrixId:nil];
      [one saveWithoutReset];
    }
  }

  [self clearSelections];
  return nil;
}

- (id)selectionSyncWithSkyrixEntry {
  NSEnumerator *e  = [self->selections objectEnumerator];
  id           one = nil;

  while ((one = [e nextObject])) {
    if ([one hasSkyrixRecord]) {
      [one syncWithSkyrixRecord];
    }
  }

  [self clearSelections];
  return nil;
}

- (id)_palmRecordSelection {
  NSString *classString    = nil;
  Class    selectionClass  = nil;
  
  SkyPalmDocumentSelection *recordSelection = nil;

  if ([self->selections count] == 0)
    return nil;
  
  classString = NSStringFromClass([[self->selections objectAtIndex:0] class]);
  classString = [NSString stringWithFormat:@"%@Selection", classString];
  selectionClass = NSClassFromString(classString);

  recordSelection = [[selectionClass alloc] init];
  return AUTORELEASE(recordSelection);
}
- (id)selectionCreateSkyrixRecord {
  SkyPalmDocumentSelection *sel   = [self _palmRecordSelection];
  id                       page   = nil;
  NSEnumerator             *e     = [self->selections objectEnumerator];
  id                       one    = nil;
  BOOL                     hasOne = NO;
  int                      max    = SKYPALM_MAX_IMPORT_ENTRIES;

  if (sel == nil)
    return nil;

  while ((one = [e nextObject])) {
    if (![one hasSkyrixRecord]) {
      if (max) {
        hasOne = YES;
        [sel addDoc:one];
        max--;
      }
      else break;
    }
  }
  [self clearSelections];

  if (!hasOne)
    return nil;
  
  page = [[[self session] navigation]
                 activateObject:sel
                 withVerb:@"create-skyrix-record"];
  return page;
}

// takeValuesFromRequest
- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  [super takeValuesFromRequest:_req inContext:_ctx];
  if ([self canSetValueForBinding:@"selections"]) 
    [self setValue:[self selectedEntries] forBinding:@"selections"];
}


#if 0
- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  NSLog(@"%s", __PRETTY_FUNCTION__);
  [NSAutoreleasePool enableDoubleReleaseCheck:YES];
  [super appendToResponse:_response inContext:_ctx];
  NSLog(@"%s done", __PRETTY_FUNCTION__);
}
#endif


@end /* SkyPalmEntryList */
