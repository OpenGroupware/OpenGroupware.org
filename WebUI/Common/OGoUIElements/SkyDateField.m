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

#include <NGObjWeb/WODynamicElement.h>

/*
  this generated a formatted representation of a NSDate object (doesn't
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
  template:(WOElement *)_templ
{
  if ((self = [super initWithName:_name associations:_config template:_templ])) {
    self->date       = [[_config objectForKey:@"date"] copy];
    self->spanId     = [[_config objectForKey:@"spanId"] copy];
    self->formatter  = [[_config objectForKey:@"formatter"] copy];
    self->dateformat = [[_config objectForKey:@"dateformat"] copy];
    self->formatType = [[_config objectForKey:@"formatType"] copy];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->formatType);
  RELEASE(self->spanId);
  RELEASE(self->formatter);
  RELEASE(self->dateformat);
  RELEASE(self->date);
  [super dealloc];
}

/* operations */

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  NSDate         *d;
  NSCalendarDate *cdate;
  NSFormatter    *fmt;
  NSString       *string;
  NSString       *span;
  
  if ((d = [self->date valueInComponent:[_ctx component]])) {
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
  
  if (self->formatter) {
    fmt = [[self->formatter valueInComponent:[_ctx component]] retain];
  }
  else if (self->dateformat) {
    NSString *fmtstring;

    fmtstring = [self->dateformat stringValueInComponent:[_ctx component]];
    
    fmt = [[NSDateFormatter alloc]
                            initWithDateFormat:fmtstring
                            allowNaturalLanguage:NO];
  }
  else if ([_ctx hasSession]) {
    NSString *fmtType;

    if (self->formatType) {
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
      if ([cdate isToday]) {
        fmt = [[NSDateFormatter alloc] initWithDateFormat:@"%H:%M:%S"
                                       allowNaturalLanguage:NO];
        AUTORELEASE(fmt);
      }
      else
        fmt = [[_ctx session] formatDateTime];
    }
    
    RETAIN(fmt);
  }
  else
    fmt = nil;
  
  string = fmt
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
  
  RELEASE(fmt);   fmt   = nil;
  RELEASE(cdate); cdate = nil;
}

@end /* SkyDateField */
