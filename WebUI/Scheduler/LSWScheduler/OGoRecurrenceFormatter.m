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

#include "OGoRecurrenceFormatter.h"
#include <NGiCal/iCalRecurrenceRule.h>
#include "common.h"

@implementation OGoRecurrenceFormatter

static NSString *CycleDateStringFmt= @"%Y-%m-%d %Z";

- (id)initWithLabels:(id)_labels {
  if ((self = [super init]) != nil) {
    self->labels = [_labels retain];
  }
  return self;
}
- (id)init {
  return [self initWithLabels:nil];
}

+ (id)formatterWithLabels:(id)_labels {
  return [[[self alloc] initWithLabels:_labels] autorelease];
}

- (void)dealloc {
  [self->labels release];
  [super dealloc];
}

/* labels */

- (NSString *)invalidRRuleLabel {
  return [self->labels valueForKey:@"rrule_couldnotparse"];
}
- (NSString *)infiniteLabel {
  /* cycles w/o enddate */
  return [self->labels valueForKey:@"rrule_infinite"];
}

/* typed formatters */

- (NSString *)stringForICalRecurrence:(iCalRecurrenceRule *)_rrule {
  // TODO: this is far from complete
  NSMutableString *ms;
  id tmp;
  
  if (_rrule == nil)
    return [self invalidRRuleLabel];
  
  ms = [NSMutableString stringWithCapacity:128];
  
  [ms appendString:[_rrule iCalRepresentation]];
  
  /* "until" */

  if ([_rrule isInfinite])
    [ms appendString:[self infiniteLabel]];
  else if ((tmp = [_rrule untilDate]) != nil) {
    [ms appendString:@" "];
    [ms appendString:[self->labels valueForKey:@"until"]];
    [ms appendString:@" "];
    [ms appendString:[tmp descriptionWithCalendarFormat:CycleDateStringFmt]];
  }
  else {
    [ms appendString:[self->labels valueForKey:@"times_pre"]]; // TODO: label
    [ms appendFormat:@" %d ", [_rrule repeatCount]];
    [ms appendString:[self->labels valueForKey:@"times_post"]]; // TODO: label
  }
  
  // TODO: render iCalRecurrenceRule's
  return ms;
}

- (NSString *)stringForRuleString:(NSString *)_str {
  NSString *s;
  
  if ([_str hasPrefix:@"RRULE:"]) {
    iCalRecurrenceRule *rrule;
    NSString *pat;
    
    pat = [_str substringFromIndex:6];
    if ((rrule = [[iCalRecurrenceRule alloc] initWithString:pat]) != nil) {
      s = [self stringForICalRecurrence:rrule];
      [rrule release];
    }
    else
      s = [self invalidRRuleLabel];
  }
  else if ([_str isNotEmpty])
    s = [self->labels valueForKey:_str];
  else
    s = nil;
  
  return s;
}

- (NSString *)stringForAppointment:(id)_apt {
  NSMutableString *ms;
  NSString        *cycleType;
  NSCalendarDate  *cycleEndDate;
  NSString        *typeLabel;
  
  if (_apt == nil)
    return nil;
  
  cycleType    = [_apt valueForKey:@"type"];
  cycleEndDate = [_apt valueForKey:@"cycleEndDate"];
  
  if (![cycleType isNotEmpty]) /* is not a cyclic appointment */
    return nil;
  
  if ((typeLabel = [self stringForRuleString:cycleType]) == nil)
    return nil;

  ms = [[NSMutableString alloc] initWithCapacity:[typeLabel length] + 16];
  [ms appendString:typeLabel];
  
  if ([cycleType hasPrefix:@"RRULE:"])
    /* 'UNTIL' MUST be set in RRULE and is already rendered */;
  else if ([cycleEndDate isNotNull]) {
    [ms appendString:@" "];
    [ms appendString:[self->labels valueForKey:@"until"]];
    [ms appendString:@" "];
    [ms appendString:
          [cycleEndDate descriptionWithCalendarFormat:CycleDateStringFmt]];
  }
  else
    [ms appendString:[self infiniteLabel]];
  
  typeLabel = [[ms copy] autorelease];
  [ms release];
  return typeLabel;
}

/* main entry */

- (NSString *)stringForObjectValue:(id)_object {
  if (![_object isNotNull])
    return nil;
  
  if ([_object isKindOfClass:[iCalRecurrenceRule class]])
    return [self stringForICalRecurrence:_object];

  if ([_object isKindOfClass:[NSString class]])
    return [self stringForRuleString:_object];

  return [self stringForAppointment:_object];
  
#if 0
  if ((t = [[self snapshot] valueForKey:@"type"]) == nil)
    return nil;
  
  if ([t hasPrefix:@"RRULE:"]) {
    // TODO: add a rrule formatter
    return [t substringFromIndex:6];
  }
  
  return [[self labels] valueForKey:t];
  
    [ms appendString:[self cycleType]];
    
#endif
    return nil;
}

@end /* OGoRecurrenceFormatter */


/* attach to component */

#include <OGoFoundation/OGoComponent.h>

@implementation OGoComponent(RecurrenceFormatter)

- (NSFormatter *)recurrenceFormatter {
  return [OGoRecurrenceFormatter formatterWithLabels:[self labels]];
}

@end /* OGoComponent(RecurrenceFormatter) */

