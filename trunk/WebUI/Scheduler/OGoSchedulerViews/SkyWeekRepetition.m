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

// does not support 'takeValuesFromRequest:inContext:'

#import <Foundation/Foundation.h>
#include <NGObjWeb/NGObjWeb.h>

#define SecondsPerWeek (7 * 24 * 60 * 60)
#define SecondsPerDay      (24 * 60 * 60)

static NSString *SkyWeekRep_TitleMode   = @"SkyWeekRep_TitleMode";
static NSString *SkyWeekRep_InfoMode    = @"SkyWeekRep_InfoMode";
static NSString *SkyWeekRep_ContentMode = @"SkyWeekRep_ContentMode";

static inline WOElement *WECreateElement(NSString *_className,
                                         NSString *_name,
                                         NSDictionary *_config,
                                         WOElement *_template)
{
  Class               c;
  WOElement           *result = nil;
  NSMutableDictionary *config = nil;
  
  if ((c = NSClassFromString(_className)) == Nil) {
    NSLog(@"%s: missing '%@' class", __PRETTY_FUNCTION__, _className);
    return nil;
  }
  config = [NSMutableDictionary dictionaryWithCapacity:4];
  {
    NSEnumerator *keyEnum;
    id           key;

    keyEnum = [_config keyEnumerator];

    while ((key = [keyEnum nextObject])) {
      WOAssociation *a;

      a = [WOAssociation associationWithValue:[_config objectForKey:key]];
      [config setObject:a forKey:key];
    }
  }
  result = [[c alloc] initWithName:_name
                      associations:config
                          template:_template];
  return result;
}

@interface SkyWeekRepetition : WODynamicElement
{
@protected
  WOAssociation *list;
  WOAssociation *item;
  WOAssociation *index;
  WOAssociation *identifier;
  
  WOAssociation *dayIndex;
  WOAssociation *weekStart;
  
  WOAssociation *startDateKey;
  WOAssociation *endDateKey;

  WOAssociation *weekdayTitleBgColor;
  WOAssociation *saturdayTitleBgColor;
  WOAssociation *sundayTitleBgColor;
  WOAssociation *selectedBgColor;
  WOAssociation *bgColor;

@private
  NSMutableDictionary *matrix[14];
  WOElement           *titles[7];
  
  WOElement      *template;
}
@end

@implementation SkyWeekRepetition

- (id)initWithName:(NSString *)_name
      associations:(NSDictionary *)_config
          template:(WOElement *)_tmp
{
  if ((self = [super initWithName:_name associations:_config template:_tmp])) {
    self->list         = OWGetProperty(_config, @"list");
    self->item         = OWGetProperty(_config, @"item");
    self->index        = OWGetProperty(_config, @"index");
    self->identifier   = OWGetProperty(_config, @"identifier");
    self->dayIndex     = OWGetProperty(_config, @"dayIndex");
    self->weekStart    = OWGetProperty(_config, @"weekStart");
    self->startDateKey = OWGetProperty(_config, @"startDateKey");
    self->endDateKey   = OWGetProperty(_config, @"endDateKey");

    self->weekdayTitleBgColor= OWGetProperty(_config, @"weekdayTitleBgColor");
    self->saturdayTitleBgColor=OWGetProperty(_config, @"saturdayTitleBgColor");
    self->sundayTitleBgColor = OWGetProperty(_config, @"sundayTitleBgColor");
    self->selectedBgColor    = OWGetProperty(_config, @"selectedBgColor");
    self->bgColor            = OWGetProperty(_config, @"bgColor");

    if (self->startDateKey == nil) {
      self->startDateKey = [WOAssociation associationWithValue:@"startDate"];
      RETAIN(self->startDateKey);
    }

    if (self->endDateKey == nil) {
      self->endDateKey = [WOAssociation associationWithValue:@"endDate"];
      RETAIN(self->endDateKey);
    }

    if (self->weekStart == nil) {
      self->weekStart =
        [WOAssociation associationWithValue:[NSCalendarDate calendarDate]];
      RETAIN(self->weekStart);
    }
    
    ASSIGN(self->template, _tmp);    
  }
  return self;
}

- (void)resetMatrix {
  int i;
  
  for (i=0; i<14; i++) {
    RELEASE(self->matrix[i]);
    self->matrix[i] = nil;
  }
}

- (void)resetTitles {
  int i;
  
  for (i = 0; i < 7; i++) {
    RELEASE(self->titles[i]);
    self->titles[i] = nil;
  }
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->list);
  RELEASE(self->item);
  RELEASE(self->index);
  RELEASE(self->identifier);

  RELEASE(self->dayIndex);
  RELEASE(self->weekStart);

  RELEASE(self->startDateKey);
  RELEASE(self->endDateKey);

  RELEASE(self->weekdayTitleBgColor);
  RELEASE(self->saturdayTitleBgColor);
  RELEASE(self->sundayTitleBgColor);
  RELEASE(self->selectedBgColor);
  RELEASE(self->bgColor);

  [self resetMatrix];
  [self resetTitles];

  RELEASE(self->template);
  
  [super dealloc];
}
#endif

static inline void
_applyIdentifier(SkyWeekRepetition *self, WOComponent *comp, NSString *_idx)
{
  NSArray *array;
  unsigned count;

  array = [self->list valueInComponent:comp];
  count = [array count];

  if (count > 0) {
    unsigned cnt;

    /* find subelement for unique id */
    
    for (cnt = 0; cnt < count; cnt++) {
      NSString *ident;
      
      if (self->index)
        [self->index setUnsignedIntValue:cnt inComponent:comp];

      if (self->item)
        [self->item setValue:[array objectAtIndex:cnt] inComponent:comp];

      ident = [self->identifier stringValueInComponent:comp];

      if ([ident isEqualToString:_idx]) {
        /* found subelement with unique id */
        return;
      }
    }
    
    [comp logWithFormat:
                  @"SkyWeekRepetition: array did change, "
                  @"unique-id isn't contained."];
    [self->item  setValue:nil          inComponent:comp];
    [self->index setUnsignedIntValue:0 inComponent:comp];
  }
}

static inline void
_applyIndex(SkyWeekRepetition *self, WOComponent *comp, unsigned _idx)
{
  NSArray *array;
  
  array = [self->list valueInComponent:comp];
  
  if (self->index)
    [self->index setUnsignedIntValue:_idx inComponent:comp];

  if (self->item) {
    int count = [array count];

    if (_idx < count) {
      [self->item setValue:[array objectAtIndex:_idx] inComponent:comp];
    }
    else {
      [comp logWithFormat:
            @"SkyWeekRepetition: array did change, index is invalid."];
      [self->item  setValue:nil          inComponent:comp];
      [self->index setUnsignedIntValue:0 inComponent:comp];
    }
  }
}


- (void)_calcMatrixInContext:(WOContext *)_ctx {
  WOComponent    *comp;
  NSCalendarDate *startWeek;
  NSCalendarDate *endWeek;
  NSArray        *array;
  NSString       *startKey;
  NSString       *endKey;
  int            i, idx, idx2, cnt;

  [self resetMatrix];
  
  comp      = [_ctx component];
  array     = [self->list valueInComponent:comp];
  startKey  = [self->startDateKey stringValueInComponent:comp];
  endKey    = [self->endDateKey   stringValueInComponent:comp];
  startWeek = [self->weekStart valueInComponent:comp];
  endWeek   = [startWeek addTimeInterval:SecondsPerWeek];

  for (i=0, cnt=[array count]; i<cnt; i++) {
    id             app;
    NSCalendarDate *sd, *ed;
    NSTimeInterval diff;

    app = [array objectAtIndex:i];
    sd  = [app valueForKey:startKey]; // startDate
    ed  = [app valueForKey:endKey];   // endDate

    if (sd == nil && ed == nil) continue;
    
    diff  = [sd timeIntervalSinceDate:startWeek];

    idx = floor((diff / SecondsPerWeek) * 14);

    if (0 <= idx && idx < 14) {
      if (self->matrix[idx] == nil)
        self->matrix[idx] = [[NSMutableDictionary alloc] initWithCapacity:8];
      
      [self->matrix[idx] setObject:[NSNumber numberWithInt:i] forKey:app];
    }
    idx = (idx < 0) ? (idx % 2) + 2 : idx + 2;
    diff = [ed timeIntervalSinceDate:startWeek];
    
    idx2 = floor((diff / SecondsPerWeek) * 14);
    idx2 = (idx2 > 14) ? 14 : idx2;
    
    while (idx < idx2) {
      if (self->matrix[idx] == nil)
        self->matrix[idx] = [[NSMutableDictionary alloc] initWithCapacity:8];

      [self->matrix[idx] setObject:[NSNumber numberWithInt:i] forKey:app];
      idx = idx + 2;
    }
  }
}
/*
- (void)appendDateTitleToResponse:(WOResponse *)_response
                        inContext:(WOContext *)_ctx
                              day:(int)_day
{
  NSMutableDictionary *config;
  NSCalendarDate      *date;

  config = [NSMutableDictionary dictionaryWithCapacity:8];
  date   = [self->weekStart valueInComponent:[_ctx component]];
  
  date = [date addTimeInterval:_day * SecondsPerDay];
  
  [config setObject:@"Monday"      forKey:@"title"];
  [config setObject:@"neu"         forKey:@"newLabel"];
  
  [config setObject:([date isToday]) ? @"YES" : @"NO" forKey:@"highlight"];
  
  [config setObject:@"NO"          forKey:@"disableNew"];
  [config setObject:date           forKey:@"date"];

  [_response appendContentString:@"<TD valign='TOP' width='15%'>"];
  self->titles[_day] =
    WECreateElement(@"LSWSchedulerDateTitle", @"Title", config, nil);
  [self->titles[_day] appendToResponse:_response inContext:_ctx];
  [_response appendContentString:@"</TD>"];
}
*/

- (void)appendDateTitleToResponse:(WOResponse *)_response
                        inContext:(WOContext *)_ctx
                              day:(int)_day
{
  WOComponent *comp;
  NSString    *bgcolor;

  comp = [_ctx component];
  
  if ([self->dayIndex isValueSettable])
    [self->dayIndex setIntValue:_day inComponent:comp];

  if (_day == 6)
    bgcolor = [self->sundayTitleBgColor stringValueInComponent:comp];
  else if (_day == 5)
    bgcolor = [self->saturdayTitleBgColor stringValueInComponent:comp];
  else
    bgcolor = [self->weekdayTitleBgColor stringValueInComponent:comp];

  [_response appendContentString:@"<TD valign=\"TOP\"width=\"15%\""];
  if (bgcolor) {
    [_response appendContentString:@" BGCOLOR=\""];
    [_response appendContentString:bgcolor];
    [_response appendContentCharacter:'"'];
  }
  [_response appendContentCharacter:'>'];

  
  [_ctx setObject:@"YES" forKey:SkyWeekRep_TitleMode];
  [_ctx appendElementIDComponent:@"t"];
  [_ctx appendElementIDComponent:[NSString stringWithFormat:@"%d", _day]];

  [self->template appendToResponse:_response inContext:_ctx];

  [_ctx deleteLastElementIDComponent]; // delete day index
  [_ctx deleteLastElementIDComponent]; // delete "t"
  [_ctx removeObjectForKey:SkyWeekRep_TitleMode];
  [_response appendContentString:@"</TD>"];
}

- (void)appendContentToResponse:(WOResponse *)_response
                      inContext:(WOContext *)_ctx
                          index:(int)_index
{
  WOComponent  *comp;
  NSArray      *apps;
  id           app;
  int          i, cnt, idx;

  comp    = [_ctx component];
  apps    = [self->matrix[_index] allKeys];

  // idx is the dayIndex (0=Mon ... 6=Sun)
  idx     = (int)(_index / 2);

  if ([self->dayIndex isValueSettable])
    [self->dayIndex setIntValue:idx inComponent:comp];

  // *** append day info
  if ((_index % 2) == 0) {
    // if AM-section...
    [_ctx setObject:@"YES" forKey:SkyWeekRep_InfoMode];
    [_ctx appendElementIDComponent:@"i"];
    [_ctx appendElementIDComponent:[NSString stringWithFormat:@"%d", idx]];
    [self->template appendToResponse:_response inContext:_ctx];
    [_ctx deleteLastElementIDComponent]; // delete dayIndex
    [_ctx deleteLastElementIDComponent]; // delete "i"
    [_ctx removeObjectForKey:SkyWeekRep_InfoMode];
  }

  // *** append day content
  [_ctx appendElementIDComponent:@"c"];
  // append section id (0 = Mon AM, 1 = Mon PM, 2 = Tue AM, ...)
  [_ctx appendElementIDComponent:[NSString stringWithFormat:@"%d", _index]];
  
  [_ctx setObject:@"YES" forKey:SkyWeekRep_ContentMode];

  for (i = 0, cnt = [apps count]; i < cnt; i++) {
    app = [apps objectAtIndex:i];

    // idx is the appointment index in self->list
    idx = [[self->matrix[_index] objectForKey:app] intValue];

    if ([self->item isValueSettable])
      [self->item  setValue:app inComponent:comp];
    if ([self->index isValueSettable])
      [self->index setIntValue:idx inComponent:comp];

    if (self->identifier == nil)
      [_ctx appendElementIDComponent:[NSString stringWithFormat:@"%d", idx]];
    else {
      NSString *s;

      s = [self->identifier stringValueInComponent:comp];
      [_ctx appendElementIDComponent:s];
    }
    [self->template appendToResponse:_response inContext:_ctx];
    [_ctx deleteLastElementIDComponent];
  }
  [_ctx removeObjectForKey:SkyWeekRep_ContentMode];

  [_ctx deleteLastElementIDComponent]; // delete section id
  [_ctx deleteLastElementIDComponent]; // delete "c"
}

- (NSString *)cellColorForDay:(int)_day inContext:(WOContext *)_ctx {
  NSCalendarDate *date;
  
  date = [self->weekStart valueInComponent:[_ctx component]];
  date = [date addTimeInterval:_day * SecondsPerDay];
  
  return ([date isToday])
    ? [self->selectedBgColor stringValueInComponent:[_ctx component]]
    : [self->bgColor         stringValueInComponent:[_ctx component]];
}

/***  responder ***/
- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {

}
- (id)invokeActionForRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  WOComponent *comp;
  id       result;
  NSString *cid;
  NSString *sectionId;

  cid = [_ctx currentElementID];       // get mode ("t" or "i" or "c")
  [_ctx consumeElementID];
  [_ctx appendElementIDComponent:cid];
  sectionId = [_ctx currentElementID];       // get section id
  [_ctx consumeElementID];
  [_ctx appendElementIDComponent:sectionId];

  comp = [_ctx component];
  
  if ([cid isEqualToString:@"t"]) {
    if ([self->dayIndex isValueSettable])
      [self->dayIndex setIntValue:[sectionId intValue] inComponent:comp];
    result = [self->template invokeActionForRequest:_req inContext:_ctx];
  }
  else if ([cid isEqualToString:@"i"]) {
    if ([self->dayIndex isValueSettable])
      [self->dayIndex setIntValue:([sectionId intValue] / 2) inComponent:comp];
    result = [self->template invokeActionForRequest:_req inContext:_ctx];
  }
  else if ([cid isEqualToString:@"c"]) {
    NSString *idxId;

    if ([self->dayIndex isValueSettable])
      [self->dayIndex setIntValue:([sectionId intValue] / 2) inComponent:comp];

    if ((idxId = [_ctx currentElementID])) {
      [_ctx consumeElementID];               // consume index-id
      [_ctx appendElementIDComponent:idxId];

      if (self->identifier)
        _applyIdentifier(self, comp, idxId);
      else
        _applyIndex(self, comp, [idxId intValue]);

      result = [self->template invokeActionForRequest:_req inContext:_ctx];

      [_ctx deleteLastElementIDComponent]; // delete index-id
    }
  }
  else
    NSLog(@"WARNING! SkyWeekRepetition: wrong section");

  [_ctx deleteLastElementIDComponent]; // delete section id
  [_ctx deleteLastElementIDComponent]; // delete mode
  
  return result;
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  NSString *bgcolor;
  int      i;
  
  [self _calcMatrixInContext:_ctx];

  /*** append title row (monday - saturday) ***/
  [_response appendContentString:@"<TR>"];
  for (i = 0; i < 6; i++) {
    [self appendDateTitleToResponse:_response inContext:_ctx day:i];
  }
  [_response appendContentString:@"</TR>"];

  /*** append AM content row + saturday ***/
  [_response appendContentString:@"<TR>"];

    /* AM weekdays content */
    for (i = 0; i < 10; i = i + 2) {
      [_response appendContentString:@"<TD VALIGN=\"TOP\""];
      if ((bgcolor = [self cellColorForDay:floor(i/2) inContext:_ctx])) {
        [_response appendContentString:@" BGCOLOR=\""];
        [_response appendContentString:bgcolor];
        [_response appendContentCharacter:'"'];
      }
      [_response appendContentCharacter:'>'];
      [self appendContentToResponse:_response inContext:_ctx index:i];
      [_response appendContentString:@"</TD>"];
    }
    /* saturday content */
    [_response appendContentString:@"<TD VALIGN=\"TOP\""];
    if ((bgcolor = [self cellColorForDay:5 inContext:_ctx])) {
      [_response appendContentString:@" BGCOLOR=\""];
      [_response appendContentString:bgcolor];
      [_response appendContentCharacter:'"'];
    }
    [_response appendContentCharacter:'>'];

    [self appendContentToResponse:_response inContext:_ctx index:10];
    [self appendContentToResponse:_response inContext:_ctx index:11];
    [_response appendContentString:@"</TD>"];
  
  [_response appendContentString:@"</TR>"];

  /*** append PM content row + sunday ***/
  [_response appendContentString:@"<TR>"];

    /* PM weekdays content */
    for (i = 1; i < 11; i = i + 2) {
      [_response appendContentString:
                 @"<TD VALIGN=\"TOP\" ROWSPAN=\"2\""];
      if ((bgcolor = [self cellColorForDay:floor(i/2) inContext:_ctx])) {
        [_response appendContentString:@" BGCOLOR=\""];
        [_response appendContentString:bgcolor];
        [_response appendContentCharacter:'"'];
      }
      [_response appendContentCharacter:'>'];


      
      [self appendContentToResponse:_response inContext:_ctx index:i];
      [_response appendContentString:@"</TD>"];
    }
    /* sunday title */
    [self appendDateTitleToResponse:_response inContext:_ctx day:6];
    [_response appendContentString:@"</TR>"];

    /*  sunday row */
    [_response appendContentString:@"<TR>"];
  
    [_response appendContentString:@"<TD VALIGN=\"TOP\""];
    if ((bgcolor = [self cellColorForDay:6 inContext:_ctx])) {
      [_response appendContentString:@" BGCOLOR=\""];
      [_response appendContentString:bgcolor];
      [_response appendContentCharacter:'"'];
    }
    [_response appendContentCharacter:'>'];

    [self appendContentToResponse:_response inContext:_ctx index:12];
    [self appendContentToResponse:_response inContext:_ctx index:13];
    [_response appendContentString:@"</TD"];
  
  [_response appendContentString:@"</TR>"];
  [self resetMatrix];
}
@end

/*
@interface SkyWeekRepetitionContentMode : WEContextConditional
@end

@implementation SkyWeekRepetitionContentMode
- (NSString *)_contextKey {
  return @"SkyWeekRepetitionContentMode";
}
@end
*/
