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

@interface OGoCycleSelection : OGoComponent
{
  NSString *cycleType;
  NSString *cycleEndDate;
  NSString *day;          /* MO,TU,WE,TH,FR,SA,SO */
  NSString *dayOccurence; /* -31..-1 and 1..31    */
  
  id item; // transient
}

@end

#include <NGiCal/iCalRecurrenceRule.h>
#include "common.h"

@interface WOComponent(LSWAppointmentEditor) // HACK HACK
- (NSString *)calendarOnClickEventForFormElement:(NSString *)_name;
@end

@implementation OGoCycleSelection

- (void)dealloc {
  [self->day          release];
  [self->dayOccurence release];
  [self->cycleEndDate release];
  [self->cycleType    release];
  [self->item         release];
  [super dealloc];
}

/* defaults */

- (NSUserDefaults *)userDefaults {
  static NSUserDefaults *ud = nil;
  if (ud == nil) ud = [[NSUserDefaults standardUserDefaults] retain];
  return ud;
}

/* accessors */

- (void)setItem:(id)_value {
  ASSIGN(self->item, _value);
}
- (id)item {
  return self->item;
}

- (void)setCycleEndDate:(NSString *)_cDate {
  ASSIGNCOPY(self->cycleEndDate, _cDate);
}
- (NSString *)cycleEndDate {
  return self->cycleEndDate;
}

- (void)setDayOccurence:(NSString *)_cDate {
  ASSIGNCOPY(self->dayOccurence, _cDate);
}
- (NSString *)dayOccurence {
  return self->dayOccurence;
}
- (BOOL)hasDayOccurence {
  if (![self->dayOccurence isNotEmpty])
    return NO;
  return [self->dayOccurence isEqualToString:@"-"] ? NO : YES;
}

- (void)setDay:(NSString *)_cDate {
  ASSIGNCOPY(self->day, _cDate);
}
- (NSString *)day {
  return self->day;
}

/* type synchronisation */

- (void)_setupFromRRule:(iCalRecurrenceRule *)_rrule {
  NSString       *ct;
  NSCalendarDate *until;
  unsigned       dayMask;
  
  if (![_rrule isNotNull])
    return;

  /* determine 'primary OGo' cycle type */
  
  switch ([_rrule frequency]) { // TODO: fix this API in SOPE
  case iCalRecurrenceFrequenceDaily:   
    ct = @"daily"; 
    break;
  case iCalRecurrenceFrequenceWeekly:  
    // TODO: check interval=2 > 14_daily, interval=4 => 4_weekly
    // TODO: check BYDAY=MO,TU,WE,TH,FR; => weekday
    if ([_rrule repeatInterval] == 2)
      ct = @"14_daily";
    else if ([_rrule repeatInterval] == 4)
      ct = @"4_weekly";
    else 
      ct = @"weekly";
    break;
  case iCalRecurrenceFrequenceMonthly: 
    ct = @"monthly"; 
    break;
  case iCalRecurrenceFrequenceYearly:  
    ct = @"yearly"; 
    break;
  default:
    ct = nil;
    [self errorWithFormat:@"unsupported rrule frequency: %@", _rrule];
    break;
  }
  ASSIGNCOPY(self->cycleType, ct);
  
  /* fill enddate, Note: can also be set by parent, must be equal */
  
  if ((until = [_rrule untilDate]) != nil)
    [self setCycleEndDate:[until descriptionWithCalendarFormat:@"%Y-%m-%d"]];
  
  /* byday stuff */
  
  if ((dayMask = [_rrule byDayMask]) != 0) {
    if ([_rrule byDayOccurence1] != 0) {
      NSString *s;
      char buf[16];
      
      snprintf(buf, sizeof(buf), "%i", [_rrule byDayOccurence1]);
      s = [[NSString alloc] initWithCString:buf];
      ASSIGNCOPY(self->dayOccurence, s);
      [s release]; s= nil;
    }
    else {
      ASSIGNCOPY(self->dayOccurence, @"0");
    }
    
    /* setup day */

    if (dayMask & iCalWeekDayMonday)         [self setDay:@"MO"];
    else if (dayMask & iCalWeekDayTuesday)   [self setDay:@"TU"];
    else if (dayMask & iCalWeekDayWednesday) [self setDay:@"WE"];
    else if (dayMask & iCalWeekDayThursday)  [self setDay:@"TH"];
    else if (dayMask & iCalWeekDayFriday)    [self setDay:@"FR"];
    else if (dayMask & iCalWeekDaySaturday)  [self setDay:@"SA"];
    else if (dayMask & iCalWeekDaySunday)    [self setDay:@"SU"];
  }
  else {
    [self->day          release]; self->day          = nil;
    [self->dayOccurence release]; self->dayOccurence = nil;
  }
}

- (BOOL)needsRRuleRepresentation {
  if ([self->cycleType isEqualToString:@"monthly"])
    return [self hasDayOccurence];
  
  return NO;
}

- (NSString *)rruleType {
  NSMutableString *ms;
  
  if (![self->cycleType isNotEmpty])
    return nil;
  
  ms = [NSMutableString stringWithCapacity:50 /* size of type field! */];
  [ms appendString:@"RRULE:"];

  /* frequency */
  
  [ms appendString:@"FREQ="];
  if ([self->cycleType isEqualToString:@"14_daily"])
    [ms appendString:@"WEEKLY;INTERVAL=2"];
  else if ([self->cycleType isEqualToString:@"4_weekly"])
    [ms appendString:@"WEEKLY;INTERVAL=4"];
  else if ([self->cycleType isEqualToString:@"weekday"])
    [ms appendString:@"WEEKLY;BYDAY=MO,TU,WE,TH,FR"];
  else
    [ms appendString:[self->cycleType uppercaseString]];
  
  /* enddate */
  
  if ([self->cycleEndDate isNotEmpty]) {
    NSString *s;
    
    s = [self->cycleEndDate stringByReplacingString:@"-" withString:@""];
    if ([s length] == 8) {
      [ms appendString:@";UNTIL="];
      [ms appendString:s];
    }
    else if ([s isNotEmpty])
      [self logWithFormat:@"incomplete cycle enddate: %@", self->cycleEndDate];
  }
  
  /* byday things */
  
  if ([self->cycleType isEqualToString:@"monthly"]) {
    if ([self hasDayOccurence]) {
      [ms appendString:@";BYDAY="];
      if ([self->dayOccurence intValue] != 0)
        [ms appendString:self->dayOccurence];
      
      if ([self->day isNotEmpty])
        [ms appendString:self->day];
      else
        [ms appendString:@"MO"]; /* to keep the occurence selection */
    }
  }
  return ms;
}

- (void)setCycleType:(NSString *)_s {
  if (![_s isNotNull])
    _s = nil;
  if (self->cycleType == _s || [self->cycleType isEqual:_s])
    return;
  
  if ([_s hasPrefix:@"RRULE:"]) {
    iCalRecurrenceRule *rrule;
    NSString *pat;
    
    pat = [_s substringFromIndex:6];
    if ((rrule = [[iCalRecurrenceRule alloc] initWithString:pat]) == nil)
      [self errorWithFormat:@"invalid rrule: %@", pat];
    
    [self _setupFromRRule:rrule];
    [rrule release];
    return;
  }
  
  ASSIGNCOPY(self->cycleType, _s);
}
- (NSString *)cycleType {
  if ([self needsRRuleRepresentation])
    return [self rruleType];
  
  return self->cycleType;
}

/* popup selection */

- (void)setCycleTypePart:(NSString *)_p {
  ASSIGNCOPY(self->cycleType, _p);
}
- (NSString *)cycleTypePart {
  return self->cycleType;
}

/* JavaScript support */

- (NSString *)cycleEndDateOnClickEvent {
  // TODO: HACK HACK
  return [[self parent] calendarOnClickEventForFormElement:@"cycleEndDate"];
}

- (NSString *)defaultCycleSectionStyle {
  return [self->cycleType isNotEmpty] ? nil : @"display: none;";
}
- (NSString *)defaultMonthSectionStyle {
  return [self->cycleType isEqualToString:@"monthly"] 
    ? nil : @"display: none;";
}
- (NSString *)defaultMonthCycleStyle {
  return [self hasDayOccurence] ? nil : @"display: none;";
}

/* labels */

- (NSString *)itemOccurenceLabel {
  NSString *k;

  if (![(k = [self item]) isNotEmpty])
    return nil;
  
  k = [@"cycle_occurence_" stringByAppendingString:k];
  return [[self labels] valueForKey:k];
}

- (NSString *)itemDayLabel {
  NSString *k;

  if (![(k = [self item]) isNotEmpty])
    return nil;
  
  k = [@"cycle_day_" stringByAppendingString:k];
  return [[self labels] valueForKey:k];
}

/* notifications */

- (void)sleep {
  [self->item release]; self->item = nil;
  [super sleep];
}

@end /* OGoCycleSelection */
