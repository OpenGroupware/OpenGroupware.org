/*
  Copyright (C) 2005 SKYRIX Software AG

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

#include <OGoFoundation/OGoComponent.h>

/*
  OGoAptConflictsList

  A component to show the conflicts for a given appointment.

  Bindings:
    < appointment - appointment
*/

@class NSArray, NSDictionary;

@interface OGoAptConflictsList : OGoComponent
{
  id           appointment;
  NSDictionary *conflictInfos;
  NSArray      *conflictDates;

  /* transient */
  id currentDate;
  id currentConflict;
}

- (void)_resetCaches;

@end

#include "common.h"

@implementation OGoAptConflictsList

static NSNumber *yesNum        = nil;
static NSArray  *aptAttrs      = nil;
static NSArray  *conflictAttrs = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  yesNum   = [[NSNumber numberWithBool:YES] retain];
  aptAttrs = [[ud arrayForKey:@"schedulerconflicts_fetchkeys"] copy];
  conflictAttrs = [[ud arrayForKey:@"schedulerconflicts_conflictkeys"] copy];
}

- (void)dealloc {
  [self->currentConflict release];
  [self->currentDate     release];
  [self->appointment     release];
  [self->conflictDates   release];
  [self->conflictInfos   release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self->currentConflict release]; self->currentConflict = nil;
  [self->currentDate     release]; self->currentDate     = nil;
  [super sleep];
}

/* accessors */

- (void)setAppointment:(id)_appointment {
  if (self->appointment == _appointment)
    return;
  
  ASSIGN(self->appointment, _appointment);
  [self _resetCaches];
}
- (id)appointment {
  return self->appointment;
}

- (void)setCurrentDate:(id)_currentDate {
  ASSIGN(self->currentDate, _currentDate);
}
- (id)currentDate {
  return self->currentDate;
}

- (void)setCurrentConflict:(id)_rec {
  ASSIGN(self->currentConflict, _rec);
}
- (id)currentConflict {
  return self->currentConflict;
}

/* operations */

- (void)_resetCaches {
  [self->currentConflict release]; self->currentConflict = nil;
  [self->currentDate   release]; self->currentDate   = nil;
  [self->conflictDates release]; self->conflictDates = nil;
  [self->conflictInfos release]; self->conflictInfos = nil;
}

- (void)_fetchConflictInfos {
  [self _resetCaches];
  
  /* Note: need to be in GID mode to fetch infos */
  self->conflictInfos = 
    [[self runCommand:@"appointment::conflicts",
             @"appointment", [self appointment],
             @"fetchConflictInfo", yesNum,
             @"fetchGlobalIDs",    yesNum,
	     @"conflictInfoAttributes", conflictAttrs,
           nil] copy];
  
  self->conflictDates = 
    [[self runCommand:@"appointment::get-by-globalid",
             @"gids",       [self->conflictInfos allKeys],
             @"attributes", aptAttrs,
           nil] retain];
}

/* derived accessors */

- (NSArray *)conflictDates {
  if (self->conflictDates != nil)
    return [self->conflictDates isNotNull] ? self->conflictDates : nil;
  
  [self _fetchConflictInfos];
  if (self->conflictDates == nil) {
    self->conflictDates = [[NSNull null] retain];
    return nil;
  }
  
  return self->conflictDates;
}

- (NSArray *)currentDateConflicts {
  EOGlobalID *gid;
  
  gid = [[self currentDate] valueForKey:@"globalID"];
  return gid != nil ? [self->conflictInfos objectForKey:gid] : nil;
}

- (NSString *)conflictPartStatusLabel {
  NSString *s;
  
  s = [[self currentConflict] valueForKey:@"partStatus"];
  s = [s isNotNull] ? s : @"NEEDS-ACTION";
  s = [@"partStat_" stringByAppendingString:s];
  return [[self labels] valueForKey:s];
}
- (NSString *)conflictRoleLabel {
  NSString *s;
  
  s = [[self currentConflict] valueForKey:@"role"];
  s = [@"partRole_" stringByAppendingString:s];
  return [[self labels] valueForKey:s];
}

@end /* OGoAptConflictsList */
