/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#import <Foundation/NSCalendarDate.h>

@interface dateTime : NSCalendarDate
@end

#include "common.h"

@implementation dateTime

/* '1970-01-01T00:00:00Z' */
static NSString *defTZFmt = @"%Y-%m-%dT%H:%M:%SZ";

/* 'Mon, 20 Jan 2003 14:01:47 GMT' */
static NSString *mailFmt = @"%a, %d %b %Y %H:%M:%S %Z";

- (id)initWithString:(NSString *)_s {
  NSCalendarDate *cd;

  if ([_s length] == 0) {
    [self release];
    return nil;
  }
  
  // TODO: wrong timezone ? (default-timezone instead of UTC ?)
  if ((cd = [NSCalendarDate dateWithString:_s calendarFormat:defTZFmt])) {
    [self release];
    return [cd retain];
  }
  if ((cd = [NSCalendarDate dateWithString:_s calendarFormat:mailFmt])) {
    [self release];
    return [cd retain];
  }
  return [super initWithString:_s];
}

@end /* dateTime */
