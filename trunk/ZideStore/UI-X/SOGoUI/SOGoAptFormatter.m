/*
  Copyright (C) 2004 SKYRIX Software AG

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
// $Id$

#include "SOGoAptFormatter.h"
#include "common.h"

@interface SOGoAptFormatter(PrivateAPI)
- (NSString *)titleForApt:(id)_apt;
- (NSString *)shortTitleForApt:(id)_apt;
- (NSTimeZone *)displayTZ;
- (void)appendTimeInfoFromApt:(id)_apt toBuffer:(NSMutableString *)_buf;
@end

@implementation SOGoAptFormatter

- (id)initWithDisplayTimeZone:(NSTimeZone *)_tz {
  if ((self = [super init])) {
    self->tz = [_tz retain];
    [self setFullDetails];
  }
  return self;
}

- (void)dealloc {
  [self->tz           release];
  [self->privateTitle release];
  [super dealloc];
}

/* accessors */

- (void)setTooltip {
  self->formatAction = @selector(tooltipForApt:);
}

- (void)setFullDetails {
  self->formatAction = @selector(fullDetailsForApt:);
}

- (void)setPrivateTooltip {
  self->formatAction = @selector(tooltipForPrivateApt:);
}

- (void)setPrivateDetails {
  self->formatAction = @selector(detailsForPrivateApt:);
}

- (void)setTitleOnly {
  self->formatAction = @selector(titleForApt:);
}

- (void)setShortTitleOnly {
  self->formatAction = @selector(shortTitleForApt:);
}

- (void)setPrivateSuppressAll {
  self->formatAction = @selector(suppressApt:);
}

- (void)setPrivateTitleOnly {
  self->formatAction = @selector(titleOnlyForPrivateApt:);
}

- (void)setPrivateTitle:(NSString *)_privateTitle {
  ASSIGN(self->privateTitle, _privateTitle);
}
- (NSString *)privateTitle {
  return self->privateTitle;
}

- (NSString *)stringForObjectValue:(id)_obj {
  return [self performSelector:self->formatAction withObject:_obj];
}

/* Private */

- (NSTimeZone *)displayTZ {
  return self->tz;
}

- (void)appendTimeInfoFromApt:(id)_apt toBuffer:(NSMutableString *)_buf {
  NSCalendarDate *startDate, *endDate;
  BOOL           spansRange;

  spansRange = NO;
  startDate  = [_apt valueForKey:@"startDate"];
  [startDate setTimeZone:[self displayTZ]];
  endDate    = [_apt valueForKey:@"endDate"];
  if(endDate != nil) {
    [endDate setTimeZone:[self displayTZ]];
    spansRange = ![endDate isEqualToDate:startDate];
  }
  [_buf appendFormat:@"%02i:%02i",
                       [startDate hourOfDay],
                       [startDate minuteOfHour]];
  if(spansRange) {
    [_buf appendFormat:@", %02i:%02i",
                         [endDate hourOfDay],
                         [endDate minuteOfHour]];
  }
}

- (NSString *)titleForApt:(id)_apt {
  return [_apt valueForKey:@"title"];
}

- (NSString *)shortTitleForApt:(id)_apt {
  NSString *title;
  
  title = [self titleForApt:_apt];
  if ([title length] > 12)
    title = [[title substringToIndex:11] stringByAppendingString:@"..."];
  
  return title;
}

- (NSString *)fullDetailsForApt:(id)_apt {
  NSMutableString *aptDescr;
  NSString *s;
    
  aptDescr = [NSMutableString stringWithCapacity:60];
  [self appendTimeInfoFromApt:_apt toBuffer:aptDescr];
  if ((s = [_apt valueForKey:@"location"]) != nil) {
    if([s length] > 12)
      s = [[s substringToIndex:11] stringByAppendingString:@"..."];
    [aptDescr appendFormat:@" (%@)", s];
  }
  if ((s = [_apt valueForKey:@"title"]) != nil)
    [aptDescr appendFormat:@"<br />%@", [self shortTitleForApt:_apt]];
  
  return aptDescr;
}

- (NSString *)detailsForPrivateApt:(id)_apt {
  NSMutableString *aptDescr;
  NSString        *s;

  aptDescr = [NSMutableString stringWithCapacity:40];
  [self appendTimeInfoFromApt:_apt toBuffer:aptDescr];
  if ((s = [self privateTitle]) != nil)
    [aptDescr appendFormat:@"<br />%@", s];
  return aptDescr;
}

- (NSString *)titleOnlyForPrivateApt:(id)_apt {
  NSString *s;
  
  s = [self privateTitle];
  if(!s)
    return @"";
  return s;
}

- (NSString *)tooltipForApt:(id)_apt {
  NSCalendarDate  *startDate, *endDate;
  NSMutableString *aptDescr;
  NSString        *s;
  BOOL            spansRange;
    
  spansRange = NO;
  startDate = [_apt valueForKey:@"startDate"];
  [startDate setTimeZone:[self displayTZ]];
  endDate = [_apt valueForKey:@"endDate"];
  if(endDate != nil) {
    [endDate setTimeZone:[self displayTZ]];
    spansRange = ![endDate isEqualToDate:startDate];
  }
  aptDescr = [NSMutableString stringWithCapacity:60];
  [aptDescr appendFormat:@"%02i:%02i",
	    [startDate hourOfDay],
	    [startDate minuteOfHour]];
  if (spansRange) {
    [aptDescr appendFormat:@" - %02i:%02i",
	      [endDate hourOfDay],
	      [endDate minuteOfHour]];
  }
    
  if ((s = [_apt valueForKey:@"title"]) != nil)
    [aptDescr appendFormat:@"\n%@", s];
  if ((s = [_apt valueForKey:@"location"]) != nil)
    [aptDescr appendFormat:@"\n%@", s];
    
  return aptDescr;
}

- (NSString *)tooltipForPrivateApt:(id)_apt {
  NSCalendarDate  *startDate, *endDate;
  NSMutableString *aptDescr;
  NSString        *s;
  BOOL            spansRange;
  
  spansRange = NO;
  startDate  = [_apt valueForKey:@"startDate"];
  [startDate setTimeZone:[self displayTZ]];
  endDate = [_apt valueForKey:@"endDate"];
  if(endDate != nil) {
    [endDate setTimeZone:[self displayTZ]];
    spansRange = ![endDate isEqualToDate:startDate];
  }
  aptDescr = [NSMutableString stringWithCapacity:25];
  [aptDescr appendFormat:@"%02i:%02i",
    [startDate hourOfDay],
    [startDate minuteOfHour]];
  if (spansRange) {
    [aptDescr appendFormat:@" - %02i:%02i",
      [endDate hourOfDay],
      [endDate minuteOfHour]];
  }

  if ((s = [self privateTitle]) != nil)
    [aptDescr appendFormat:@"\n%@", s];

  return aptDescr;
}

- (NSString *)suppressApt:(id)_apt {
  return @"";
}

@end /* SOGoAptFormatter */
