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

#include <OGoFoundation/LSWContentPage.h>

@interface SkyAppointmentList : LSWContentPage
{
@protected
  id             dataSource;
  unsigned       currentBatch;

  id             appointment;
  int            index;
  int            blockSize;
  NSString       *sortedKey;
  BOOL           isDescending;

  id             participantFormatter;
  id             person;
}

@end

#include <OGoFoundation/LSWNotifications.h>
#include <OGoFoundation/LSWSession.h>
#include <NGObjWeb/WOApplication.h>
#include <EOControl/EOControl.h>
#include <NGMime/NGMimeType.h>
#include "SkyAppointmentFormatter.h"
#include <OGoScheduler/SkyAptDataSource.h>
#include "common.h"

@interface NSObject(GID)
- (EOGlobalID *)globalID;
@end

@interface NSObject(AppointmentEditor)
- (void)addParticipant:(id)_participant;
@end

@implementation SkyAppointmentList

- (id)init {
  if ((self = [super init])) {    
    self->participantFormatter = nil;
    self->sortedKey = @"startDate";
  }
  return self;
}

- (void)dealloc {
  [self unregisterAsObserver];
  [self->dataSource           release];
  [self->appointment          release];
  [self->sortedKey            release];
  [self->participantFormatter release];
  [self->person               release];
  [super dealloc];
}

//accessors

- (void)setPerson:(id)_person {
  ASSIGN(self->person, _person);
}

- (void)setDataSource:(id)_ds {
  ASSIGN(self->dataSource,_ds);
}
- (id)dataSource {
  return self->dataSource;
}

- (void)setCurrentBatch:(unsigned)_cur {
  self->currentBatch = _cur;
}
- (unsigned)currentBatch {
  return self->currentBatch;    
}

- (void)setAppointment:(id)_appointment {
  ASSIGN(self->appointment, _appointment);
}
- (id)appointment {
  return self->appointment;    
}

- (void)setIndex:(int)_idx {
  self->index = _idx;
}
- (int)index {
  return self->index;
}

- (void)setBlockSize:(int)_val {
  self->blockSize = _val;
}
- (int)blockSize {
  return self->blockSize;
}

- (void)setSortedKey:(NSString *)_key {
  ASSIGN(self->sortedKey,_key);
}
- (NSString *)sortedKey {
  return self->sortedKey;
}

- (void)setIsDescending:(BOOL)_isDescending {
  self->isDescending = _isDescending;
}
- (BOOL)isDescending {
  return self->isDescending;    
}

- (id)participantFormatter {
  if (self->participantFormatter == nil) {
    self->participantFormatter =
      [(SkyAppointmentFormatter *)[SkyAppointmentFormatter alloc]
                                initWithFormat:@"%5P"];
    [self->participantFormatter setShowFullNames:
         [[[self session] userDefaults]
                 boolForKey:@"scheduler_overview_full_names"]];
  }
  return self->participantFormatter;
}

- (NSString *)detailAptsLabel {
  static NSString *calFmt = @"%Y-%m-%d"; // TODO: make configurable ?
  NSString *label = nil;
  NSString *from  = nil;
  NSString *to    = nil;
  
  from  = [[(SkyAptDataSource *)self->dataSource startDate]
                              descriptionWithCalendarFormat:calFmt];
  to    = [[(SkyAptDataSource *)self->dataSource endDate]
                              descriptionWithCalendarFormat:calFmt];

  label = [[self labels] valueForKey:@"appointments"];
  label = [NSString stringWithFormat:@"%@ (%@ - %@)",
                    label, from, to];
  return label;
}

- (id)appointmentOID {
  id oid = [self->appointment valueForKey:@"dateId"];
  if (oid == nil) {
    id gid = [self->appointment valueForKey:@"globalID"];
    if (gid) oid = [gid keyValues][0];
  }
  return oid;
}
- (id)appointmentEntity {
  static SEL gidSel = NULL;
  static SEL entSel = NULL;
  
  id gid;

  if (gidSel == NULL) gidSel = @selector(globalID);
  if (entSel == NULL) entSel = @selector(entityName);

  gid = [self->appointment valueForKey:@"globalID"];
  
  if (gid == nil) {
    if ([self->appointment respondsToSelector:gidSel])
      gid = [self->appointment globalID];
  }
  if (gid != nil) return [gid entityName];
  
  if ([self->appointment respondsToSelector:entSel])
    return [self->appointment entityName];
  return nil;
}

- (id)newAppointment {
  id ct;
  id obj = [self->person globalID];
  LSWSession *sn;

  obj = [self runCommand:@"object::get-by-globalid", @"gid", obj, nil];
  obj = [obj lastObject];
  sn  = (id)[self session];
  ct  = [sn instantiateComponentForCommand:@"new"
            type:[NGMimeType mimeType:@"eo/date"]];
  [(id)ct addParticipant:obj];
  [self enterPage:(id)ct];

  return nil;
}

@end /* SkyAppointmentList */
