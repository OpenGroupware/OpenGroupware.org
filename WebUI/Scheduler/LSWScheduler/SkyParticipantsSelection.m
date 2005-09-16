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

#include "OGoUserSelectionComponent.h"

/*
  SkyParticipantsSelection

  TODO: document
  
  This component is used in various parts of OGo, not just in the appointment
  editor.
*/

@interface SkyParticipantsSelection : OGoUserSelectionComponent
{
  NSMutableArray *removedParticipants;
  NSMutableArray *addedParticipants;
  NSString *headLineLabel;
  NSString *selectionLabel;
  struct {
    int viewHeadLine:1;
    int plainMode:1;
    int reserved:30;
  } spsFlags;
}
@end

#include <OGoFoundation/OGoSession.h>
#include <LSFoundation/LSCommandContext.h>
#include "common.h"

@implementation SkyParticipantsSelection

static BOOL hasLSWEnterprises = NO;

+ (void)initialize {
  NGBundleManager *bm = [NGBundleManager defaultBundleManager];
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  hasLSWEnterprises = [bm bundleProvidingResource:@"LSWEnterprises"
			  ofType:@"WOComponents"] ? YES : NO;
}

- (id)init {
  if ((self = [super init]) != nil) {
    self->removedParticipants   = [[NSMutableArray alloc] initWithCapacity:4];
    self->addedParticipants     = [[NSMutableArray alloc] initWithCapacity:4];
    self->spsFlags.viewHeadLine = 1;
  }
  return self;
}

- (void)dealloc {
  [self->removedParticipants release];
  [self->addedParticipants   release];
  [self->headLineLabel  release];
  [self->selectionLabel release];
  [super dealloc];
}

/* accessors */

- (void)setViewHeadLine:(BOOL)_view {
  self->spsFlags.viewHeadLine = _view ? 1 : 0;
}
- (BOOL)viewHeadLine {
  return self->spsFlags.viewHeadLine ? YES : NO;
}

- (void)setSelectionLabel:(NSString *)_str {
  ASSIGNCOPY(self->selectionLabel, _str);
}
- (NSString *)selectionLabel {
  return self->selectionLabel;
}

- (void)setPlainMode:(BOOL)_view {
  self->spsFlags.plainMode = _view ? 1 : 0;
}
- (BOOL)plainMode {
  return self->spsFlags.plainMode ? YES : NO;
}

- (void)setHeadLineLabel:(NSString *)_str {
  ASSIGNCOPY(self->headLineLabel, _str);
}
- (NSString *)headLineLabel {
  return self->headLineLabel;
}

- (BOOL)isEnterpriseAvailable {
  return hasLSWEnterprises;
}

- (BOOL)showExtendEnterprisesCheckBox {
  return (!self->uscFlags.onlyAccounts && hasLSWEnterprises);
}

- (void)setAddedParticipants:(NSMutableArray *)_addedParticipants {
  ASSIGN(self->addedParticipants, _addedParticipants);
}
- (NSMutableArray *)addedParticipants {
  return self->addedParticipants;
}

- (void)setRemovedParticipants:(NSMutableArray *)_removedParticipants {
  ASSIGN(self->removedParticipants, _removedParticipants);
}
- (NSMutableArray *)removedParticipants {
  return self->removedParticipants;
}

- (NSArray *)attributesList {
  // move to SkyParticipantsSelection once we removed the listview in the
  // attendee selection
  NSMutableArray      *myAttr;
  NSMutableDictionary *myDict1;
  NSMutableDictionary *myDict2;

  myAttr  = [NSMutableArray arrayWithCapacity:16];
  myDict1 = [[NSMutableDictionary alloc] initWithCapacity:8];
  myDict2 = [[NSMutableDictionary alloc] initWithCapacity:8];
  
  [myDict1 takeValue:@"participantLabel" forKey:@"binding"];
  [myAttr addObject: myDict1];
  
  if (self->uscFlags.showExtended) {
    [myDict2 takeValue:@"enterprises.description" forKey:@"key"];
    [myDict2 takeValue:@",  " forKey:@"separator"];
    [myAttr addObject: myDict2];
  }
  [myDict1 release]; myDict1 = nil;
  [myDict2 release]; myDict2 = nil;
  return myAttr;
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];
  // this must be run *before* -takeValuesFromRequest:inContext: is called
  [self->removedParticipants removeAllObjects];
  [self->addedParticipants   removeAllObjects];
}

- (void)syncSleep {
  // reset transient variables
  [self->removedParticipants removeAllObjects];
  [self->addedParticipants   removeAllObjects];
  [super syncSleep];
}

- (void)sleep {
  [self->removedParticipants removeAllObjects];
  [self->addedParticipants   removeAllObjects];
  [super sleep];
}

/* participants management */

- (void)initializeParticipants {
  unsigned i, count;
  
  /* process participants selected in resultList */
  for (i = 0, count = [self->addedParticipants count]; i < count; i++) {
    NSNumber *pkey;
    id  participant;
    int j, count2;

    participant = [self->addedParticipants objectAtIndex:i];
    pkey        = [participant valueForKey:@"companyId"];
    if (![pkey isNotNull]) {
      [self errorWithFormat:@"invalid pkey of participant: %@", participant];
      continue;
    }
    for (j = 0, count2 = [self->participants count]; j < count2; j++) {
      NSNumber *opkey;

      opkey = [[self->participants objectAtIndex:j] valueForKey:@"companyId"];
      if ([opkey isEqual:pkey]) { // already in array
        pkey = nil;
        break;
      }
    }
    if (pkey) {
      [self->participants addObject:participant];
      [self->resultList removeObject:participant];
    }
  }
  [self->addedParticipants removeAllObjects];
  
  /* process participants not selected in participants list */
  for (i = 0, count = [self->removedParticipants count]; i < count; i++) {
    NSNumber *pkey;
    id  participant;
    int j, count2, removeIdx = -1;

    participant = [self->removedParticipants objectAtIndex:i];
    pkey        = [participant valueForKey:@"companyId"];

    if (![pkey isNotNull]) {
      [self errorWithFormat:@"invalid pkey of participant %@", participant];
      continue;
    }
    for (j = 0, count2 = [self->participants count]; j < count2; j++) {
      NSNumber *opkey;
      
      opkey = [[self->participants objectAtIndex:j] valueForKey:@"companyId"];
      if ([opkey isEqual:pkey]) { // found in array
        removeIdx = j;
        break;
      }
    }
    if (removeIdx != -1) {
      [self->participants removeObjectAtIndex:removeIdx];
      [self->resultList addObject:participant];
    }
  }
  [self->removedParticipants removeAllObjects];
}

/* actions */

- (id)search {
  [self initializeParticipants];
  return [super search];
}

@end /* SkyParticipantsSelection */
