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

#include <LSFoundation/LSBaseCommand.h>

@class NSString, NSTimeZone;

@interface LSConvertTimeZoneCommand : LSBaseCommand
{
@private
  NSTimeZone *timeZone;
}

- (void)setTimeZoneWithAbbreviation:(NSString *)_abbrev;
- (void)setTimeZone:(NSTimeZone *)_timeZone;
- (NSTimeZone *)timeZone;

@end

#include "common.h"

@implementation LSConvertTimeZoneCommand

- (void)dealloc {
  [self->timeZone release];
  [super dealloc];
}

/* command methods */

- (void)_executeInContext:(id)_context {
  NSCalendarDate *myDate = nil;
  
  NSAssert([self object], @"object is nil");

  if ([[self object] isKindOfClass:[NSString class]]) {
    myDate = [NSCalendarDate dateWithString:[self object]
                             calendarFormat:@"%Y-%m-%d %H:%M:%S"];
    [self setReturnValue:myDate];
  }
  else
    myDate = [self returnValue];

  if ([myDate isKindOfClass:[NSCalendarDate class]])
    [myDate setTimeZone:timeZone];
}

// accessors

- (void)setTimeZoneWithAbbreviation:(NSString *)_abbrev {
  NSTimeZone *ts = [NSTimeZone timeZoneWithAbbreviation:_abbrev];

  NSAssert(ts, @"timezone is nil");

  [self setTimeZone:ts];
}
- (void)setTimeZone:(NSTimeZone *)_timeZone {
  ASSIGN(timeZone, _timeZone);
}
- (NSTimeZone *)timeZone {
  return timeZone;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"timeZoneAbbrev"])
    [self setTimeZoneWithAbbreviation:_value];
  else if ([_key isEqualToString:@"timeZone"])
    [self setTimeZone:_value];
  else if ([_key isEqualToString:@"object"])
    [self setObject:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"timeZone"])
    return [self timeZone];
  if ([_key isEqualToString:@"object"])
    return [self object];

  return [super valueForKey:_key];
}

@end /* LSConvertTimeZoneCommand */
