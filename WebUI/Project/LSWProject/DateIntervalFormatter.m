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

#import "common.h"
#import "DateIntervalFormatter.h"

#define HOUR_SECONDS   (3600)
#define DAY_SECONDS    (24*3600)

@implementation DateIntervalFormatter

- (NSString *)stringForObjectValue:(id)anObject {
  if (![anObject isKindOfClass:[NSNumber class]]) {
    return nil;
  }
  else {
    unsigned int interval = [anObject intValue];
    unsigned int days     = (interval / DAY_SECONDS);
    unsigned int hours    = (interval % DAY_SECONDS)  / HOUR_SECONDS;

    if (days && hours == 0)
      return [NSString stringWithFormat:@"%d", days];

    return [NSString stringWithFormat:@"%d", hours];
  }
}

- (BOOL)getObjectValue:(id *)obj
             forString:(NSString *)string
      errorDescription:(NSString **)error
{
  unsigned int intResult;
  NSScanner *scanner = [NSScanner scannerWithString:string];
  BOOL       result  = NO;
  
  if ([scanner scanInt:&intResult] && obj &&
      !([scanner scanLocation] == [string length])) {
    while ([scanner scanString:@" " intoString:NULL]) {
    }

    if ([scanner scanLocation] < [string length]) {
      unichar kind = [string characterAtIndex:[scanner scanLocation]];
    
      switch (kind) {
        case 'd':
        case 'D':
          intResult *= DAY_SECONDS;
          result = YES;
          break;
        case 'h':
        case 'H':
          intResult *= HOUR_SECONDS;
          result = YES;
          break;
      }
      *obj   = [NSNumber numberWithInt:intResult];
    }
    else
      *error  =  @"Choose '1d' = 1 day, '1h' = 1 hour";
  }
  else if (error)
    *error = @"Couldn't convert to int";
  
  return result;
}
   
@end
