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

#include <NGObjWeb/WODynamicElement.h>

/*
  SkyDateField

  This generated a formatted representation of a NSDate object (doesn't
  need to be a NSCalendarDate).

  It uses session context information for formatting.

  You can use the 'spanId' binding to generate a <SPAN ID=$value> tag
  around the date (useful for JavaScript).

  Bindings:

    date       - NSDate
    dateformat - NSString
    formatter  - NSFormatter
    spanId     - NSString
    formatType - String: date/time/datetime (selects the default-formatter)
*/

@interface SkyDateField : WODynamicElement
{
  WOAssociation *date;
  WOAssociation *dateformat;
  WOAssociation *formatter;
  WOAssociation *spanId;
  WOAssociation *formatType;
}

@end

#include "common.h"

@interface WOSession(RequiredExtensions)
- (NSTimeZone *)timeZone;
- (NSFormatter *)formatDate;
- (NSFormatter *)formatTime;
- (NSFormatter *)formatDateTime;
@end

@implementation SkyDateField

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_t
{
  if ((self = [super initWithName:_name associations:_config template:_t])) {
    self->date       = [[_config objectForKey:@"date"]       copy];
    self->spanId     = [[_config objectForKey:@"spanId"]     copy];
    self->formatter  = [[_config objectForKey:@"formatter"]  copy];
    self->dateformat = [[_config objectForKey:@"dateformat"] copy];
    self->formatType = [[_config objectForKey:@"formatType"] copy];
  }
  return self;
}

- (void)dealloc {
  [self->formatType release];
  [self->spanId     release];
  [self->formatter  release];
  [self->dateformat release];
  [self->date       release];
  [super dealloc];
}

/* operations */

- (NSFormatter *)newFormatterInContext:(WOContext *)_ctx
  isToday:(BOOL)_isToday
{
  if (self->formatter != nil)
    return [[self->formatter valueInComponent:[_ctx component]] retain];

  if (self->dateformat != nil) {
    NSString *fmtstring;

    fmtstring = [self->dateformat stringValueInComponent:[_ctx component]];
    
    return [[NSDateFormatter alloc] initWithDateFormat:fmtstring
				    allowNaturalLanguage:NO];
  }
  
  if ([_ctx hasSession]) {
    NSFormatter *fmt;
    NSString *fmtType;

    if (self->formatType != nil) {
      fmtType = [self->formatType stringValueInComponent:[_ctx component]];
      if ([fmtType length] == 0)
        fmtType = nil;
    }
    else
      fmtType = nil;
    
    if ([fmtType isEqualToString:@"date"])
      fmt = [[_ctx session] formatDate];
    else if ([fmtType isEqualToString:@"time"])
      fmt = [[_ctx session] formatTime];
    else if ([fmtType isEqualToString:@"datetime"])
      fmt = [[_ctx session] formatDateTime];
    else {
      if (_isToday) {
        fmt = [[NSDateFormatter alloc] initWithDateFormat:@"%H:%M:%S"
                                       allowNaturalLanguage:NO];
        [fmt autorelease];
      }
      else
        fmt = [[_ctx session] formatDateTime];
    }
    
    return [fmt retain];
  }
  
  return nil;
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  NSDate         *d;
  NSCalendarDate *cdate;
  NSFormatter    *fmt;
  NSString       *string;
  NSString       *span;
  
  if ((d = [self->date valueInComponent:[_ctx component]]) != nil) {
    if (![d isNotNull])
      cdate = nil;
    else {
      cdate = [[NSCalendarDate alloc] initWithTimeIntervalSinceReferenceDate:
                                        [d timeIntervalSinceReferenceDate]];
    }
  }
  else
    cdate = nil;
  
  if ([_ctx hasSession])
    [cdate setTimeZone:[[_ctx session] timeZone]];
  
  span = [self->spanId stringValueInComponent:[_ctx component]];
  
  string = (fmt = [self newFormatterInContext:_ctx isToday:[cdate isToday]])
    ? [fmt stringForObjectValue:cdate]
    : [cdate description];
  
  /* generate HTML */

  if ([span length] > 0) {
    [_response appendContentString:@"<span id='"];
    [_response appendContentString:span];
    [_response appendContentString:@"'>"];
  }
  
  [_response appendContentHTMLString:string];

  if ([span length] > 0)
    [_response appendContentString:@"</span>"];

  /* release objects */
  
  [fmt   release]; fmt   = nil;
  [cdate release]; cdate = nil;
}

@end /* SkyDateField */
