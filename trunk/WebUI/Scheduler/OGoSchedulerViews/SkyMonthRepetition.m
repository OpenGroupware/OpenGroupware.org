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

#define NUMBER_OF_SECONDS_PER_DAY (24 * 60 * 60)

@interface SkyMonthRepetition : WODynamicElement
{
@protected
  WOAssociation *year;       // year
  WOAssociation *month;      // month
  WOAssociation *timeZone;   // timeZone
  WOAssociation *firstDay;   // 0 - Sunday .. 6 - Saturday (default:1)
  WOAssociation *tableTags;  // make table tags

  WOAssociation *startDate;  // current begin of day
  WOAssociation *endDate;    // current end of day
  WOAssociation *isInMonth;  // is day in wanted month

  WOElement     *template;

  // extra attributes forwarded to table data
}

@end /* SkyMonthRepetition */

@interface SkyMonthLabel : WODynamicElement
{
@protected
  WOAssociation *orientation;
  // left/top | top | right/top | right | right/bottom | bottom | left/bottom
  // left
  WOAssociation *dayOfWeek;
  // set if orientation is top or bottom
  WOAssociation *weekOfYear;
  // set if orientation is left or right
  WOAssociation *colspan;
  // set if orientation is header
  WOElement     *template;
}
@end /* SkyMonthLabel */

@interface SkyMonthCell : WODynamicElement
{
@protected
  WOElement *template;
}
@end /* SkyMonthCell */

#include "common.h"

@implementation SkyMonthRepetition

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary*)_config
  template:(WOElement *)_t
{
  if ((self = [super initWithName:_name associations:_config template:_t])) {
    self->year       = OWGetProperty(_config, @"year");
    self->month      = OWGetProperty(_config, @"month");
    self->timeZone   = OWGetProperty(_config, @"timeZone");
    self->firstDay   = OWGetProperty(_config, @"firstDay");
    self->tableTags  = OWGetProperty(_config, @"tableTags");
    
    self->startDate  = OWGetProperty(_config, @"startDate");
    self->endDate    = OWGetProperty(_config, @"endDate");
    self->isInMonth  = OWGetProperty(_config, @"isInMonth");

    self->template = RETAIN(_t);
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->year);
  RELEASE(self->month);
  RELEASE(self->timeZone);
  RELEASE(self->firstDay);
  RELEASE(self->tableTags);
  
  RELEASE(self->startDate);
  RELEASE(self->endDate);
  RELEASE(self->isInMonth);
  
  RELEASE(self->template);
  [super dealloc];
}
#endif

//accessors

- (WOElement *)template {
  return self->template;
}

// OWResponder

static inline void
_applyDate(SkyMonthRepetition *self, WOComponent *sComponent,
           NSCalendarDate *day)
{
  unsigned m;

  m = [self->month unsignedIntValueInComponent:sComponent];
  
  if (self->startDate)
    [self->startDate setValue:[day beginOfDay] inComponent:sComponent];
  if (self->endDate)
    [self->endDate setValue:[day endOfDay] inComponent:sComponent];
  
  if (self->isInMonth) {
    [self->isInMonth setBoolValue:([day monthOfYear] == m) ? YES : NO
         inComponent:sComponent];
  }
}

static inline void
_generateCell(SkyMonthRepetition *self, WOResponse *response,
              WOContext *ctx, NSString *key, NSString *value,
              NSCalendarDate *dateId)
{
  [ctx takeValue:
         [NSDictionary dictionaryWithObject:value forKey:key]
       forKey:@"SkyMonthRepetition"];
  
  [ctx appendElementIDComponent:key];
  if (dateId) {
    NSString *eid;
    eid = [NSString stringWithFormat:@"%d",
                      (unsigned)[dateId timeIntervalSince1970]];
    [ctx appendElementIDComponent:eid];
  }
  
  [self->template appendToResponse:response inContext:ctx];
  
  if (dateId)
    [ctx deleteLastElementIDComponent];
  [ctx deleteLastElementIDComponent];
}
static inline void
_takeValuesInCell(SkyMonthRepetition *self, WORequest *request,
                  WOContext *ctx, NSString *key, NSString *value,
                  NSCalendarDate *dateId)
{
  [ctx takeValue:
         [NSDictionary dictionaryWithObject:value forKey:key]
       forKey:@"SkyMonthRepetition"];
  
  [ctx appendElementIDComponent:key];
  if (dateId) {
    [ctx appendElementIDComponent:
           [NSString stringWithFormat:@"%d",
                       (unsigned)[dateId timeIntervalSince1970]]];
  }
  
  [self->template takeValuesFromRequest:request inContext:ctx];

  if (dateId)
    [ctx deleteLastElementIDComponent];
  [ctx deleteLastElementIDComponent];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  WOComponent    *sComponent;
  unsigned       y, m, first;
  unsigned       count = 0;
  NSTimeZone     *tz;
  BOOL           useTableTags;

  BOOL           hasHeader      = NO;
  BOOL           hasLeftTop     = NO;
  BOOL           hasLeft        = NO;
  BOOL           hasTop         = NO;
  BOOL           hasRightTop    = NO;
  BOOL           hasRight       = NO;
  BOOL           hasLeftBottom  = NO;
  BOOL           hasBottom      = NO;
  BOOL           hasRightBottom = NO;
  BOOL           hasCell        = NO;
  
  NSCalendarDate *day;

  sComponent = [_ctx component];
  y  = [self->year unsignedIntValueInComponent:sComponent];
  m  = [self->month unsignedIntValueInComponent:sComponent];
  tz = [self->timeZone valueInComponent:sComponent];

  first = (self->firstDay) 
    ? [self->firstDay unsignedIntValueInComponent:sComponent]
    : 1; // Monday

  useTableTags = (self->tableTags) 
    ? [self->tableTags boolValueInComponent:sComponent]
    : YES;

  day = [NSCalendarDate dateWithYear:y month:m day:1
                        hour:0 minute:0 second:0 timeZone:tz];

  { // computing last day and following days
    unsigned dow;
    int dif;

    count = [day numberOfDaysInMonth];

    dow = [[day lastDayOfMonth] dayOfWeek];
    dif = first - dow - 1; // overview stopps 1 day before the first weekday
                           // --> e.g.: repetition starts monday, ends sunday
    dif = (dif < 0) ? dif + 7 : dif;
    count += dif;
  }

  { // computing leading days
    unsigned dow; // dayOfWeek
    int dif;

    dow = [day dayOfWeek];

    dif = first - dow;
    dif = (dif > 0) ? dif - 7 : dif;

    day = [day dateByAddingYears:0 months:0 days:dif];
    count -= dif;
  }

  { // query mode ... testing orientations
    NSEnumerator *queryE;
    NSString     *orient;
    // only query mode .. no value setting
    [_ctx takeValue:
          [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSMutableArray array],
                        @"query", nil]
          forKey:@"SkyMonthRepetition"];
    [self->template appendToResponse:_response inContext:_ctx];

    queryE = [[[_ctx valueForKey:@"SkyMonthRepetition"] valueForKey:@"query"]
                     objectEnumerator];

    while ((orient = [queryE nextObject])) {
      if ((!hasHeader) && ([orient isEqualToString:@"header"]))
        hasHeader = YES;
      if ((!hasCell) && ([orient isEqualToString:@"cell"]))
        hasCell = YES;
      if ((!hasLeftTop) && ([orient isEqualToString:@"left/top"]))
        hasLeftTop = YES;
      if ((!hasLeftBottom) && ([orient isEqualToString:@"left/bottom"]))
        hasLeftBottom = YES;
      if ((!hasLeft) && ([orient isEqualToString:@"left"]))
        hasLeft = YES;
      if ((!hasTop) && ([orient isEqualToString:@"top"]))
        hasTop = YES;
      if ((!hasRightTop) && ([orient isEqualToString:@"right/top"]))
        hasRightTop = YES;
      if ((!hasRight) && ([orient isEqualToString:@"right"]))
        hasRight = YES;
      if ((!hasRightBottom) && ([orient isEqualToString:@"right/bottom"]))
        hasRightBottom = YES;
      if ((!hasBottom) && ([orient isEqualToString:@"bottom"]))
        hasBottom = YES;
    }

    [_ctx takeValue:nil forKey:@"SkyMonthRepetition"];
  }
  
  // open table
  if (useTableTags) {
    [_response appendContentString:@"<table"];
    [self appendExtraAttributesToResponse:_response inContext:_ctx];
    [_response appendContentString:@">\n"];
  }

  // generating head
  if (hasHeader) {
    int width = 7;
    if ((hasLeft) || (hasLeftTop) || (hasLeftBottom))
      width++;
    if ((hasRight) || (hasRightTop) || (hasRightBottom))
      width++;

    [_response appendContentString:@"<tr>"];
    
    _generateCell(self, _response, _ctx, @"header",
                  [NSString stringWithFormat:@"%d", width], nil);

    [_response appendContentString:@"</tr>"];
  }

  // generating top
  if ((hasTop) || (hasLeftTop) || (hasRightTop)) {
    [_response appendContentString:@"<tr>"];

    if (hasLeftTop)
      _generateCell(self, _response, _ctx, @"left/top", @"--", nil);
    else if ((hasLeft) || (hasLeftBottom))
      [_response appendContentString:@"<td></td>"];
    
    if (hasTop) {
      unsigned dOW = first; // dayOfWeek
      int cnt;
      
      for (cnt = 0; cnt < 7; cnt++) {
        NSString *k;
        k = [[NSString alloc] initWithFormat:@"%i", dOW];
        _generateCell(self, _response, _ctx, @"top", k, nil);
        [k release];
        
        dOW = (dOW == 6) ? 0 : (dOW + 1);
      }
    }
    else {
      [_response appendContentString:
                 @"<td></td><td></td><td></td><td></td>"
                 @"<td></td><td></td><td></td>"];
    }
    
    if (hasRightTop)
      _generateCell(self, _response, _ctx, @"right/top", @"--", nil);
    else if (hasRight)
      [_response appendContentString:@"<td></td>"]; 

    [_response appendContentString:@"</tr>"];
  }
  
  // generating content
  if (count > 0) {
    int      cnt;
    unsigned dow;
    
    dow = [day dayOfWeek];

    for (cnt = 0; cnt < count; cnt++) {
      // building HTML
      // append table row
      if (dow == first) {
        [_response appendContentString:@"<tr>"];
        // generate left border
        if (hasLeft) {
          NSCalendarDate *tmp;
          // jump to the middle of the week
          tmp = [day dateByAddingYears:0 months:0 days:3];
          
          _generateCell(self, _response, _ctx, @"left",
                        [NSString stringWithFormat:@"%i", [tmp weekOfYear]],
                        nil);
        }
        else if ((hasLeftTop) || (hasLeftBottom))
          [_response appendContentString:@"<td></td>"];
      }
      
      // set values
      _applyDate(self, sComponent, day);
      
      // append child elements
      if (hasCell)
        _generateCell(self, _response, _ctx, @"cell", @"--", day);
      else
        [_response appendContentString:@"<td></td>"];
      
      // next day
      day = [day tomorrow];
      dow = (dow == 6) ? 0 : (dow + 1);

      // close table row tag
      if (dow == first) {
        [_response appendContentString:@"</tr>\n"];
        // generate right border
        if (hasRight) {
          _generateCell(self, _response, _ctx, @"right",
                        [NSString stringWithFormat:@"%i", [day weekOfYear]],nil);
        }
        else if ((hasRightTop) || (hasRightBottom))
          [_response appendContentString:@"<td></td>"];
      }
    }
  }

  // generating footer
  if ((hasBottom) || (hasLeftBottom) || (hasRightBottom)) {
    unsigned dOW = first; // dayOfWeek
    int cnt;

    [_response appendContentString:@"<tr>"];

    if (hasLeftBottom)
      _generateCell(self, _response, _ctx, @"left/bottom", @"--", nil);
    else if ((hasLeft) || (hasLeftTop))
      [_response appendContentString:@"<td></td>"];

    if (hasBottom) {
      for (cnt = 0; cnt < 7; cnt++) {
        _generateCell(self, _response, _ctx, @"bottom",
                      [NSString stringWithFormat:@"%i", dOW], nil);
        dOW = (dOW == 6) ? 0 : (dOW + 1);
      }
    }
    else {
      [_response appendContentString:
                 @"<td></td><td></td><td></td><td></td>"
                 @"<td></td><td></td><td></td>"];
    }

    if (hasRightBottom)
      _generateCell(self, _response, _ctx, @"right/bottom", @"--", nil);
    else if ((hasRight) || (hasRightTop))
      [_response appendContentString:@"<td></td>"]; 

    [_response appendContentString:@"</tr>"];
  }

  // close table
  if (useTableTags)
    [_response appendContentString:@"</table>"];
      
}

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  WOComponent    *sComponent;
  unsigned       y, m, first;
  unsigned       count = 0;
  NSTimeZone     *tz = nil;
  NSCalendarDate *day;
  
  sComponent = [_ctx component];
  y  = [self->year unsignedIntValueInComponent:sComponent];
  m  = [self->month unsignedIntValueInComponent:sComponent];
  tz = [self->timeZone valueInComponent:sComponent];
  
  first = (self->firstDay) 
    ? [self->firstDay unsignedIntValueInComponent:sComponent]
    : 1; // Monday

  day = [NSCalendarDate dateWithYear:y month:m day:1
                        hour:0 minute:0 second:0 timeZone:tz];

  { // computing last day and following days
    unsigned dow;
    int dif;

    count = [day numberOfDaysInMonth];

    dow = [[day lastDayOfMonth] dayOfWeek];
    dif = first - dow - 1; // overview stopps 1 day before the first weekday
                           // --> e.g.: repetition starts monday, ends sunday
    dif = (dif < 0) ? dif + 7 : dif;
    count += dif;
  }

  { // computing leading days
    unsigned dow; // dayOfWeek
    int dif;

    dow = [day dayOfWeek];

    dif = first - dow;
    dif = (dif > 0) ? dif - 7 : dif;

    day   =  [day dateByAddingYears:0 months:0 days:dif];
    count -= dif;
  }
  
  /* take values */
  
  if (count > 0) {
    int      cnt;

    for (cnt = 0; cnt < count; cnt++) {
      // set values
      _applyDate(self, sComponent, day);
      
      // month cell
      _takeValuesInCell(self, _req, _ctx, @"cell", @"--", day);

      // next day
      day = [day tomorrow];
    }
  }
}

- (id)invokeActionForRequest:(WORequest *)_request inContext:(WOContext *)_ctx{
  WOComponent     *sComponent;
  id              result = nil;
  NSString        *ident;
  NSString        *orient;
  
  sComponent = [_ctx component];
  
  if ((orient = [_ctx currentElementID]) == nil) {
    [[_ctx session]
           logWithFormat:@"%@: MISSING ORIENTATION ID in URL !", self];
    return nil;
  }

  [_ctx consumeElementID];
  [_ctx appendElementIDComponent:orient];
    
  [_ctx takeValue:
          [NSDictionary dictionaryWithObjectsAndKeys:
          @"--", orient, nil]
	forKey:@"SkyMonthRepetition"];

  if (![orient isEqualToString:@"cell"]) {
    /* orientation is *not* 'cell' (some label) */
    result = [self->template invokeActionForRequest:_request inContext:_ctx];
  }
  else if ((ident = [_ctx currentElementID])) {
    /* orientation is 'cell' */
    NSCalendarDate *day;
    int ti;
    
    [_ctx consumeElementID]; // consume date-id
    [_ctx appendElementIDComponent:ident];
      
    ti = [ident intValue];

    // TODO: rewrite for MacOSX
    day = [[NSCalendarDate alloc] initWithTimeIntervalSince1970:ti];
    day = [day autorelease];
    [day setTimeZone:[self->timeZone valueInComponent:sComponent]];
    //NSLog(@"made date '%@' from ident '%@'", day, ident);
      
    // set values
    _applyDate(self, sComponent, day);
      
    result = [self->template invokeActionForRequest:_request inContext:_ctx];
      
    [_ctx deleteLastElementIDComponent];
  }
  else {
    /* orientation is 'cell' */
    [[_ctx session] logWithFormat:@"%@: MISSING DATE ID in 'cell' URL !",self];
  }
  [_ctx deleteLastElementIDComponent];
  
  return result;
}

@end /* SkyMonthRepetition */

@implementation SkyMonthLabel

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary*)_config
  template:(WOElement *)_t
{
  if ((self = [super initWithName:_name associations:_config template:_t])) {
    self->orientation  = OWGetProperty(_config, @"orientation");
    self->dayOfWeek    = OWGetProperty(_config, @"dayOfWeek");
    self->weekOfYear   = OWGetProperty(_config, @"weekOfYear");
    self->colspan      = OWGetProperty(_config, @"colspan");

    self->template = RETAIN(_t);
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->orientation);
  RELEASE(self->dayOfWeek);
  RELEASE(self->weekOfYear);
  RELEASE(self->colspan);
  
  RELEASE(self->template);
  [super dealloc];
}

/* processing requests */

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  id tmp;
  NSDictionary *op;
  NSString     *orient;
  BOOL         isEdge;
  
  orient = [self->orientation valueInComponent:[_ctx component]];
  isEdge = [orient rangeOfString:@"/"].length > 0;

  op  = [_ctx valueForKey:@"SkyMonthRepetition"];
  if ((tmp = [op objectForKey:orient]) == nil)
    return;
  
  if (!isEdge) {
      [_ctx appendElementIDComponent:orient];
      [self->template takeValuesFromRequest:_req inContext:_ctx];
      [_ctx deleteLastElementIDComponent];
  }
  else {
    [self->template takeValuesFromRequest:_req inContext:_ctx];
  }
}

- (id)invokeActionForRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  id tmp;
  NSDictionary *op;
  NSString     *orient;
  BOOL         isEdge;
  id           result;
  
  orient = [self->orientation valueInComponent:[_ctx component]];
  isEdge = [orient rangeOfString:@"/"].length > 0;

  op  = [_ctx valueForKey:@"SkyMonthRepetition"];
  if ((tmp = [op objectForKey:orient]) == nil)
    return nil;
  
  if (isEdge)
    return [self->template invokeActionForRequest:_req inContext:_ctx];
  
  tmp = [_ctx currentElementID];
  [_ctx consumeElementID];
  [_ctx appendElementIDComponent:tmp];
      
  if ([orient isEqualToString:@"top"] ||
      [orient isEqualToString:@"bottom"]) {
    [self->dayOfWeek setIntValue:[tmp intValue] inComponent:[_ctx component]];
  }
  else if ([orient isEqualToString:@"left"] ||
	   [orient isEqualToString:@"right"]) {
    [self->weekOfYear setIntValue:[tmp intValue] inComponent:[_ctx component]];
  }
  else if ([orient isEqualToString:@"header"]) {
    [self->colspan setIntValue:[tmp intValue] inComponent:[_ctx component]];
  }
      
  result = [self->template invokeActionForRequest:_req inContext:_ctx];

  [_ctx deleteLastElementIDComponent];
  return result;
}

/* response generation */

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  NSDictionary *op;
  id       tmp;
  NSString *orient;
  BOOL     isEdge;
  int      cols = -1;

  orient = [self->orientation valueInComponent:[_ctx component]];
  isEdge = [orient rangeOfString:@"/"].length > 0;
  
  op = [_ctx valueForKey:@"SkyMonthRepetition"];
  if ((tmp = [op objectForKey:@"query"])) {
    [tmp addObject:orient];
  }
  else if ((tmp = [op objectForKey:orient])) {
    if (!isEdge) {
      if ([orient isEqualToString:@"top"] ||
          [orient isEqualToString:@"bottom"]) {
        [self->dayOfWeek setIntValue:[tmp intValue]
             inComponent:[_ctx component]];
      }
      else if ([orient isEqualToString:@"left"] ||
               [orient isEqualToString:@"right"]) {
        [self->weekOfYear setIntValue:[tmp intValue]
             inComponent:[_ctx component]];
      } else if ([orient isEqualToString:@"header"]) {
        [self->colspan setIntValue:[tmp intValue]
             inComponent:[_ctx component]];
        cols = [tmp intValue];
      }
    }
    
    [_response appendContentString:@"<td"];

    if (cols != -1) {
      NSString *colStr =
        [NSString stringWithFormat:@" COLSPAN=\"%d\"", cols];
      
      [_response appendContentString:colStr];
    }
    
    [self appendExtraAttributesToResponse:_response inContext:_ctx];
    [_response appendContentString:@">"];
      
    if (!isEdge)
      [_ctx appendElementIDComponent:[tmp stringValue]];

    [self->template appendToResponse:_response inContext:_ctx];
    
    if (!isEdge)
      [_ctx deleteLastElementIDComponent];

      // close table data tag
    [_response appendContentString:@"</td>"];
  }
}

@end /* SkyMonthLabel */

@implementation SkyMonthCell

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary*)_config
  template:(WOElement *)_t
{
  if ((self = [super initWithName:_name associations:_config template:_t])) {
    self->template = RETAIN(_t);
  }
  return self;
}

- (void)dealloc {
  [self->template release];
  [super dealloc];
}

/* processing requests */

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  NSDictionary *op;
  id tmp;
  
  op  = [_ctx valueForKey:@"SkyMonthRepetition"];
  if ((tmp = [op objectForKey:@"cell"]))
    [self->template takeValuesFromRequest:_req inContext:_ctx];
}

- (id)invokeActionForRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  NSDictionary *op;
  id tmp;
  
  op  = [_ctx valueForKey:@"SkyMonthRepetition"];
  if ((tmp = [op objectForKey:@"cell"]) == nil)
    return nil;

  return [self->template invokeActionForRequest:_req inContext:_ctx];
}

/* generating response */

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  NSDictionary *op;
  id tmp;
  
  op = [_ctx valueForKey:@"SkyMonthRepetition"];
  if ((tmp = [op objectForKey:@"query"])) {
    [tmp addObject:@"cell"];
    return;
  }
  
  if ((tmp = [op objectForKey:@"cell"])) {
    // append table date, forwarding extra attributes
    [_response appendContentString:@"<td"];
    [self appendExtraAttributesToResponse:_response inContext:_ctx];
    [_response appendContentString:@">"];
    // append child
    [self->template appendToResponse:_response inContext:_ctx];
    // close table data tag
    [_response appendContentString:@"</td>"];
  }
}

@end /* SkyMonthCell */
