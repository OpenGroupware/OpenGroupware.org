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

#include "IcaliCalPublish.h"
#include "SkyAptAction.h"

#import <Foundation/Foundation.h>
#include <NGObjWeb/NGObjWeb.h>
#include <LSFoundation/LSFoundation.h>
#include <NGExtensions/NGExtensions.h>

#include "ICalVEvent.h"
#include "ICalParser.h"

@implementation IcaliCalPublish

- (id)initWithRequest:(WORequest *)_req commandContext:(id)_cmdctx {
  if ((self = [super init])) {
    ASSIGN(self->ctx,_cmdctx);
    ASSIGN(self->request,_req);
    self->content = nil;
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->ctx);
  RELEASE(self->request);
  RELEASE(self->content);
  [super dealloc];
}

- (LSCommandContext *)commandContext {
  return self->ctx;
}

- (void)_lookForVEvents:(ICalComponent *)_comp
                 events:(NSMutableArray *)_events
{
  if ([[_comp externalName] isEqualToString:@"VEVENT"])
    [_events addObject:_comp];
  else {
    NSEnumerator *e = [[_comp subComponents] objectEnumerator];
    id           one;
    while ((one = [e nextObject]))
      [self _lookForVEvents:one events:_events];
  }
}
- (NSArray *)_vevents {
  NSMutableArray *events;
  NSString       *cont;
  ICalParser     *parser;
  ICalComponent  *comp;
  id             cp;

  cont = [[NSString alloc] initWithData:[self->request content]
                           encoding:[self->request contentEncoding]];
  if (cont == nil) {
    NSLog(@"WARNING[%s]: Got no content in publish request",
          __PRETTY_FUNCTION__);
    return nil;
  }
  if (![cont length]) {
    NSLog(@"WARNING[%s]: Got empty content in publish request",
          __PRETTY_FUNCTION__);
    RELEASE(cont);
    return [NSArray array];
  }
  
  parser = [ICalParser iCalParser];
  comp   = [parser parseString:cont];
  if (comp == nil) {
    NSLog(@"WARNING[%s]: unable to parse content: %@",
          __PRETTY_FUNCTION__, cont);
    RELEASE(cont);
    return nil;
  }

  events = [NSMutableArray array];
  [self _lookForVEvents:comp events:events];

  RELEASE(cont);
  cp = [events copy];
  return AUTORELEASE(cp);
}

- (void)_insertEvents:(NSArray *)_events
            aptAction:(SkyAptAction *)_action
             calendar:(NSString *)_calName
{
  NSEnumerator *e = [_events objectEnumerator];
  ICalVEvent   *one = nil;

  while ((one = [e nextObject])) {
    [_action createAppointmentFromICalEvent:one aptType:_calName];
  }
}

- (void)_deleteOldiCalEventsForCalendar:(NSString *)_calName
                                 action:(SkyAptAction *)_action
{
  NSDictionary *hints;
  NSArray      *apts;
  NSEnumerator *e;
  id           one;

  hints = [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSNumber numberWithBool:YES], @"noFromDate",
                        [NSNumber numberWithBool:YES], @"noToDate",
                        [NSNumber numberWithBool:YES], @"fetchUrls",
                        nil];
  apts = [_action listAppointmentsAction:nil :nil :nil :nil
                  :[NSArray arrayWithObject:_calName] :hints];
  e = [apts objectEnumerator];
  while ((one = [e nextObject]))
    [_action deleteAppointmentAction:one :nil :nil];
}

- (BOOL)compute {
  NSArray      *events;
  SkyAptAction *action;
  NSString     *calName;

  calName = [[[self->request uri] lastPathComponent]
                             stringByDeletingPathExtension];
  if ([calName length])
    calName = [(NSString *)@"iCal:" stringByAppendingString:calName];
  else calName = @"iCal:Default";

  action = 
    [[NSClassFromString(@"SkyAptAction") alloc]
                       initWithContext:
                       [WOContext contextWithRequest:self->request]];

  events = [self _vevents];
  [self _deleteOldiCalEventsForCalendar:calName action:action];
  [self _insertEvents:events aptAction:action calendar:calName];

  return YES;
}

- (NSString *)contentAsString {
  if (self->content == nil) {
    if ([self compute])
      self->content = @"Ok.";
    else
      self->content = @"Failed.";
    RETAIN(self->content);
  }
  return self->content;
}
- (NSData *)contentUsingEncoding:(NSStringEncoding)_se {
  return [[self contentAsString] dataUsingEncoding:_se];
}

@end /* IcaliCalPublish */
