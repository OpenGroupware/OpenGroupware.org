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

#include <OGoFoundation/OGoComponent.h>

/*
  a component to generate a PopUp for timezone-selection as used in the
  scheduler page.
  
  Output-Parameters:
    
    timeZone - the selected NSTimeZone object

  Input-Parameters:
    referenceDate - the date to determin the abbreviation (optional)
*/

@class NSTimeZone, NSDate;

@interface SkyTimeZonePopUp : OGoComponent
{
  NSArray    *timeZones;
  NSTimeZone *timeZone;
  NSDate     *referenceDate;
  
  /* temporary state */
  id item;
}

- (void)setTimeZone:(NSTimeZone *)_timeZone;
- (NSTimeZone *)timeZone;

- (void)setReferenceDate:(NSDate *)_date;
- (NSDate *)referenceDate;
@end

#include <OGoFoundation/OGoSession.h>
#include "common.h"

@implementation SkyTimeZonePopUp

+ (int)version {
  return 1;
}
- (BOOL)synchronizesVariablesWithBindings {
  return NO;
}

- (void)dealloc {
  [self->timeZones     release];
  [self->item          release];
  [self->timeZone      release];
  [self->referenceDate release];
  [super dealloc];
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];

  if (self->timeZones == nil)
    self->timeZones = [[(id)[self session] timeZones] copy];
}

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  [self setTimeZone:[self valueForBinding:@"timeZone"]];
  [self setReferenceDate:[self valueForBinding:@"referenceDate"]];
  [super takeValuesFromRequest:_req inContext:_ctx];
  [self setValue:[self timeZone] forBinding:@"timeZone"];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  [self setTimeZone:[self valueForBinding:@"timeZone"]];
  [self setReferenceDate:[self valueForBinding:@"referenceDate"]];
  [super appendToResponse:_response inContext:_ctx];
  [self setValue:[self timeZone] forBinding:@"timeZone"];
}

- (void)sleep {
  [self->item release];          self->item = nil;
  [self->timeZones release];     self->timeZones = nil;
  [self->referenceDate release]; self->referenceDate = nil;
  [super sleep];
}

/* accessors */

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (NSString *)itemAbbreviation {
  if ([self->referenceDate isNotNull])
    return [self->item abbreviationForDate:self->referenceDate];
  return [self->item abbreviation];
}

- (NSArray *)timeZones {
  return self->timeZones;
}

- (void)setTimeZone:(NSTimeZone *)_timeZone {
  if (_timeZone != nil)
    ASSIGN(self->timeZone, _timeZone);
}
- (NSTimeZone *)timeZone {
  return self->timeZone;
}

- (void)setReferenceDate:(NSDate *)_date {
  ASSIGN(self->referenceDate,_date);
}
- (NSDate *)referenceDate {
  return self->referenceDate;
}

@end /* SkyTimeZonePopUp */
