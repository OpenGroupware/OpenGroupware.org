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

#include "OGoAppointmentDateFormatter.h"
#include "common.h"

// TODO: to be extended for other formats, currently used for cycle end date
// TODO: add ability to generate "null" objects instead of nil

// TODO: document those formats
static NSString *DateParseFmt = @"%Y-%m-%d %H:%M:%S %Z";
static NSString *DateFmt      = @"%Y-%m-%d";

@implementation OGoAppointmentDateFormatter

- (void)dealloc {
  [self->timeZone release];
  [super dealloc];
}

/* accessors */

- (void)setTimeZone:(NSTimeZone *)_tz {
  ASSIGN(self->timeZone, _tz);
}
- (NSTimeZone *)timeZone {
  return self->timeZone;
}
- (NSString *)timeZoneAbbreviation {
  return [[self timeZone] abbreviation];
}

/* date => string */

- (NSString *)stringForObjectValue:(id)_object {
  if (![_object isNotNull])
    return nil;

  if ([_object isKindOfClass:[NSString class]])
    return _object;
  
  if ([_object isKindOfClass:[NSDate class]])
    return [_object descriptionWithCalendarFormat:DateFmt];
  
  return [_object stringValue];
}

/* string => date */

- (NSString *)_parseStringForString:(NSString *)_string {
  // Note: returns retained instance
  NSString *s;
  
  s = [[NSString alloc] initWithFormat:@"%@ 23:59:00 %@", _string,
                          [self timeZoneAbbreviation]];
  return s;
}

- (NSCalendarDate *)_parseString:(NSString *)_string {
  /* first format 'style', used for cycle end date */
  
  return [NSCalendarDate dateWithString:_string calendarFormat:DateParseFmt];
}

- (BOOL)getObjectValue:(id *)_object
  forString:(NSString *)_string
  errorDescription:(NSString **)_error
{
  NSCalendarDate *d;
  NSString *s;
  int      year;
  BOOL     ok;
  
  if (_error) *_error = nil;
  
  if (![_string isNotNull]) { /* no string => nil object */
    if (_object) *_object = nil;
    return YES;
  }
  if ([_string isKindOfClass:[NSCalendarDate class]]) { /* be tolerant */
    if (_object) *_object = _string;
    return YES;
  }
  if ([_string length] == 0) { /* empty string => nil object */
    if (_object) *_object = nil;
    return YES;
  }
  
  s = [self _parseStringForString:_string];
  d = [self _parseString:s];
  [d setTimeZone:[self timeZone]];
  year = [d yearOfCommonEra];
  [s release];
  
  ok = NO;
  if (d == nil) {
    if (_error) *_error = @"error_couldNotParseDate";
  }
  else if ((year >= 2037) || ((year < 1700) && (year != 0))) {
    if (_error) *_error = @"error_invalidDateYearRange";
  }
  else {
    ok = YES;
  }
  
  if (!ok && _object != NULL) 
    *_object = nil;
  else if (ok && _object != NULL)
    *_object = d;
  
  if (ok && _error != NULL)
    *_error = nil;
  
  return ok;
}

@end /* OGoAppointmentDateFormatter */
