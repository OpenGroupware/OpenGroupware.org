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

#include "IcalEvents.h"
#include "IcalResponse.h"
#include "SkyAptAction.h"

#import <Foundation/Foundation.h>
#include <NGObjWeb/NGObjWeb.h>
#include <LSFoundation/LSFoundation.h>
#include <NGExtensions/NGExtensions.h>

@interface IcalEvents(PrivateMethods)
- (NSArray *)appointments;
@end /* IcalEvents(PrivateMethods) */


@implementation IcalEvents

- (id)initWithRequest:(WORequest *)_req commandContext:(id)_cmdctx {
  if ((self = [super init])) {
    ASSIGN(self->ctx,_cmdctx);
    ASSIGN(self->request,_req);
    self->appointments = nil;
    self->now          = nil;
    self->content      = nil;
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->ctx);
  RELEASE(self->request);
  RELEASE(self->appointments);
  RELEASE(self->content);
  [super dealloc];
}

- (LSCommandContext *)commandContext {
  return self->ctx;
}

// accessors
- (NSCalendarDate *)now {
  if (self->now == nil) {
    self->now = [NSCalendarDate date];
    RETAIN(self->now);
  }
  return self->now;
}

// content

- (NSString *)formattedDate:(NSCalendarDate *)_date {
  NSString *result;
  static NSTimeZone *gmt = nil;
  static NSString   *fmt = nil;
  if (gmt == nil) gmt = [[NSTimeZone timeZoneWithAbbreviation:@"GMT"] copy];
  if (fmt == nil) fmt = [(NSString *)@"%Y%m%dT%H%M00Z" copy];
  _date = [_date copy];
  [_date setTimeZone:gmt];
  result = [_date descriptionWithCalendarFormat:fmt];
  RELEASE(_date);
  return result;
}
- (NSString *)timestampString { return [self formattedDate:[self now]]; }


- (BOOL)_appendEvent:(id)_apt toResponse:(IcalResponse *)_response {
  id tmp;
  [_response appendLine:@"BEGIN:VEVENT"];

  [_response appendLine:[[_apt valueForKey:@"id"] stringValue]
             forAttribute:@"UID"];
  [_response appendLine:[self timestampString]   forAttribute:@"DTSTAMP"];
  [_response appendLine:[self formattedDate:[_apt valueForKey:@"startDate"]]
             forAttribute:@"DTSTART"];
  [_response appendLine:[self formattedDate:[_apt valueForKey:@"endDate"]]
             forAttribute:@"DTEND"];
  tmp = [_apt valueForKey:@"title"];
  if (![tmp length]) tmp = @"";
  [_response appendLine:tmp forAttribute:@"SUMMARY"];

  // access
  tmp = [_apt valueForKey:@"accessTeamId"];
  if ([tmp isNotNull]) tmp = @"PUBLIC";
  else tmp = @"PRIVATE";
  [_response appendLine:tmp forAttribute:@"CLASS"];

  // location
  tmp = [_apt valueForKey:@"location"];
  if ([tmp length]) [_response appendLine:tmp forAttribute:@"LOCATION"];
  // comment
  tmp = [_apt valueForKey:@"comment"];
  if ([tmp length]) {
    if ([tmp indexOfString:@"\r"] != NSNotFound)
      tmp = [[tmp componentsSeparatedByString:@"\r"]
                  componentsJoinedByString:@""];
    if ([tmp indexOfString:@"\n"] != NSNotFound)
      tmp = [[tmp componentsSeparatedByString:@"\n"]
                  componentsJoinedByString:@"\\n"];
    [_response appendLine:tmp forAttribute:@"DESCRIPTION"];
  }
  tmp = [_apt valueForKey:@"resourceNames"];
  if ([tmp length]) [_response appendLine:tmp forAttribute:@"RESOURCES"];

  tmp = [_apt valueForKey:@"aptType"];
  if ([tmp length]) [_response appendLine:tmp forAttribute:@"CATEGORIES"];

#if 0
  {
    NSEnumerator *e = [[_apt valueForKey:@"participants"] objectEnumerator];
    while ((tmp = [e nextObject])) {
      tmp = [tmp valueForKey:@"email1"];
    }
  }
#endif

  [_response appendLine:@"END:VEVENT"];
  return YES;
}

- (BOOL)_appendEvents:(IcalResponse *)_response {
  NSArray         *apts;
  NSEnumerator    *e;
  id              one;

  apts = [self appointments];
  e    = [apts objectEnumerator];
  while ((one = [e nextObject])) {
    [self _appendEvent:one toResponse:_response];
  }
  
  return YES;
}

- (NSString *)contentAsString {
  if (self->content == nil) {
    IcalResponse *response;

    response = [[IcalResponse alloc] init];
    [self _appendEvents:response];
    self->content = [response asString];
    RETAIN(self->content);
    RELEASE(response);
  }
  return self->content;
}

- (NSData *)contentUsingEncoding:(NSStringEncoding)_se {
  return [[self contentAsString] dataUsingEncoding:_se];
}

/* methods */

- (int)fetchPast {
  id fetchPast = [self->request formValueForKey:@"past"];
  return ([fetchPast length]) ? [fetchPast intValue] : 10; // days
}
- (int)fetchFuture {
  id fetchFuture = [self->request formValueForKey:@"future"];
  return ([fetchFuture length]) ? [fetchFuture intValue] : 10; // days
}

- (NSArray *)_fetchAppointments {
  NSCalendarDate *start, *end;
  id action;
  NSArray *result;
  NSArray *parts     = nil;
  NSArray *resources = nil;
  NSArray *aptTypes  = nil;
  id      tmp;
  NSDictionary *hints = nil;

  start = [[self now] dateByAddingYears:0 months:0 days:-[self fetchPast]
                      hours:0 minutes:0 seconds:0];
  start = [start beginOfDay];
  end   = [[self now] dateByAddingYears:0 months:0 days:[self fetchFuture]
                      hours:0 minutes:0 seconds:0];
  end = [end endOfDay];
  
  action =
    [[NSClassFromString(@"SkyAptAction") alloc]
                                         initWithContext:
                   [WOContext contextWithRequest:self->request]];

  // look for participant queries
  tmp = [self->request formValueForKey:@"group"];
  if ([tmp length]) {
    parts = (parts == nil)
      ? [NSArray arrayWithObject:tmp] : [parts arrayByAddingObject:tmp];
  }
  tmp = [self->request formValueForKey:@"groups"];
  if ([tmp length]) {
    if ([tmp indexOfString:@", "] != NSNotFound)
      tmp = [tmp componentsSeparatedByString:@", "];
    else if ([tmp indexOfString:@","] != NSNotFound)
      tmp = [tmp componentsSeparatedByString:@","];
    
    parts = (parts == nil)
      ? tmp : [parts arrayByAddingObjectsFromArray:tmp];
  }
  tmp = [self->request formValueForKey:@"user"];
  if ([tmp length]) {
    parts = (parts == nil)
      ? [NSArray arrayWithObject:tmp] : [parts arrayByAddingObject:tmp];
  }
  tmp = [self->request formValueForKey:@"users"];
  if ([tmp length]) {
    if ([tmp indexOfString:@", "] != NSNotFound)
      tmp = [tmp componentsSeparatedByString:@", "];
    else if ([tmp indexOfString:@","] != NSNotFound)
      tmp = [tmp componentsSeparatedByString:@","];
    
    parts = (parts == nil)
      ? tmp : [parts arrayByAddingObjectsFromArray:tmp];
  }

  // resources
  tmp = [self->request formValueForKey:@"resource"];
  if ([tmp length]) {
    resources = (resources == nil)
      ? [NSArray arrayWithObject:tmp] : [resources arrayByAddingObject:tmp];
  }
  tmp = [self->request formValueForKey:@"resources"];
  if ([tmp length]) {
    if ([tmp indexOfString:@", "] != NSNotFound)
      tmp = [tmp componentsSeparatedByString:@", "];
    else if ([tmp indexOfString:@","] != NSNotFound)
      tmp = [tmp componentsSeparatedByString:@","];
    
    resources = (resources == nil)
      ? tmp : [resources arrayByAddingObjectsFromArray:tmp];
  }
  
  // resources
  tmp = [self->request formValueForKey:@"aptType"];
  if ([tmp length]) {
    aptTypes = (aptTypes == nil)
      ? [NSArray arrayWithObject:tmp] : [aptTypes arrayByAddingObject:tmp];
  }
  tmp = [self->request formValueForKey:@"aptTypes"];
  if ([tmp length]) {
    if ([tmp indexOfString:@", "] != NSNotFound)
      tmp = [tmp componentsSeparatedByString:@", "];
    else if ([tmp indexOfString:@","] != NSNotFound)
      tmp = [tmp componentsSeparatedByString:@","];
    
    aptTypes = (aptTypes == nil)
      ? tmp : [aptTypes arrayByAddingObjectsFromArray:tmp];
  }

  // tz
  if ((tmp = [self->request formValueForKey:@"timezone"]) == nil) {
    if ((tmp = [self->request formValueForKey:@"tz"]) == nil) {
      if ((tmp = [self->request formValueForKey:@"timeZone"]) == nil) {
        // tja.. no extra timezone
      }
    }
  }
  if (tmp != nil) {
    tmp = [NSTimeZone timeZoneWithAbbreviation:tmp];
    if (tmp != nil) {
      hints = [NSDictionary dictionaryWithObjectsAndKeys:
                            tmp, @"timeZone", nil];
    }
  }
  
  result = [action listAppointmentsAction:start :end :parts :resources
                   :aptTypes :hints];

  return result;
}

/* accessors */

- (NSArray *)appointments {
  if (self->appointments == nil) {
    self->appointments = [[self _fetchAppointments] retain];
  }
  return self->appointments;
}

@end /* IcalEvents */
