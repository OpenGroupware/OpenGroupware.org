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

#include <ZSFrontend/SxUserFolder.h>
#include "SoWCAPRenderer.h"
#include "WCAPResultSet.h"
#include <ZSFrontend/NSObject+ExValues.h>
#include <NGObjWeb/SoObjects.h>
#include "common.h"
#include <NGiCal/iCalPerson.h>
#include "WCAPEvent.h"
#include "WCAPToDo.h"
#include <ZSBackend/SxAptManager.h>
#include <ZSBackend/SxTaskManager.h>
#include <ZSBackend/SxBackendManager.h>
#include <LSFoundation/LSFoundation.h>

#define WCAP_COMPONENT_FREEBUSY 0x00
#define WCAP_COMPONENT_EVENT    0x01
#define WCAP_COMPONENT_TODO     0x02
#define WCAP_COMPONENT_ALL      0x03

@implementation SxUserFolder(WCAP)

- (id)iCalPersonForParticipant:(id)_participant {
  iCalPerson *person;
  NSString   *cn;
  NSString   *email;

  person = [[iCalPerson alloc] init];

  if ([[_participant valueForKey:@"isTeam"] boolValue]) {
    cn    = [_participant valueForKey:@"descriptions"];
    email = [_participant valueForKey:@"email"];
  }
  else {
    cn = [NSString stringWithFormat:@"%@, %@",
                   [_participant valueForKey:@"firstname"],
                   [_participant valueForKey:@"name"]];
    email = [_participant valueForKey:@"email1"];
  }

  [person setCn:cn];
  [person setEmail:email];
  [person setRole:[_participant valueForKey:@"role"]];
  [person setRsvp:[_participant valueForKey:@"rsvp"]];
  [person setXuid:[[_participant valueForKey:@"companyId"] stringValue]];
  [person setPartStat:[_participant valueForKey:@"partStatus"]];

  return [person autorelease];
}

- (id)wcapEventForRecord:(id)_record withLogin:(id)_account {
  NSEnumerator *participants;
  id           participant;
  id           ownerId;
  iCalPerson   *person;
  WCAPEvent    *event;
  int          accountId;
  BOOL         ownerFound = NO;

  accountId = [[_account valueForKey:@"companyId"] intValue];

  event = [[WCAPEvent alloc] init];

  [event setUid:[[_record valueForKey:@"dateId"] stringValue]];
  [event setSummary:[_record valueForKey:@"title"]];
  [event setLocation:[_record valueForKey:@"location"]];
  [event setComment:[_record valueForKey:@"comment"]];
  [event setStartDate:[_record valueForKey:@"startDate"]];
  [event setEndDate:[_record valueForKey:@"endDate"]];
  [event setPriority:[_record valueForKey:@"importance"]];
  [event setSequence:[NSNumber numberWithInt:0]];

  participants = [[_record valueForKey:@"participants"] objectEnumerator];
  ownerId      = [_record valueForKey:@"ownerId"];
  while ((participant = [participants nextObject])) {
    person = [self iCalPersonForParticipant:participant];
    [event addToAttendees:person];
    if ([ownerId isEqual:[participant valueForKey:@"companyId"]]) {
      [event setOrganizer:person];
      ownerFound = YES;
    }
  }

  if ((!ownerFound) && ([ownerId intValue] == accountId)) {
    [event setOrganizer:[self iCalPersonForParticipant:_account]];
  }

  return [event autorelease];
}

- (id)wcapToDoForRecord:(id)_record withLogin:(id)_account {
  WCAPToDo     *todo;

  todo = [[WCAPToDo alloc] init];

  [todo setUid:[[_record valueForKey:@"jobId"] stringValue]];
  [todo setSummary:  [_record valueForKey:@"name"]];
  [todo setComment:  [_record valueForKey:@"comment"]];
  [todo setStartDate:[_record valueForKey:@"startDate"]];
  [todo setDue:      [_record valueForKey:@"endDate"]];
  [todo setCompleted:[_record valueForKey:@"completionDate"]];
  [todo setPriority: [[_record valueForKey:@"priority"] stringValue]];
  [todo setSequence:[NSNumber numberWithInt:0]];
  [todo setPercentComplete:
        [[_record valueForKey:@"percentComplete"] stringValue]];

  [todo setOrganizer:[self iCalPersonForParticipant:_account]];
  return [todo autorelease];
}

- (id)wcapEventsForRecords:(NSArray *)_records withLogin:(id)_account {
  NSMutableArray *events;
  NSEnumerator   *e;
  id             record;

  events = [NSMutableArray arrayWithCapacity:[_records count]+1];
  e      = [_records objectEnumerator];
  while ((record = [e nextObject])) {
    [events addObject:[self wcapEventForRecord:record withLogin:_account]];
  }
  return events;
}

- (id)wcapToDosForRecords:(NSArray *)_records withLogin:(id)_account {
  NSMutableArray *todos;
  NSEnumerator   *e;
  id             record;

  todos = [NSMutableArray arrayWithCapacity:[_records count]+1];
  e     = [_records objectEnumerator];
  while ((record = [e nextObject])) {
    [todos addObject:[self wcapToDoForRecord:record withLogin:_account]];
  }
  return todos;
}

// TODO: SOPE should be able to map a request to such a method !
- (id)wcapFetchCalendar:(NSString *)_calendar
  from:(NSDate *)_startDate to:(NSDate *)_endDate
  type:(int)_componentType
  inContext:(WOContext *)_ctx 
{
  NSDictionary   *properties;
  NSArray        *result;
  NSCalendarDate *now;
  id             cmdctx;
  id             account;
  SxAptManager   *am;
  SxTaskManager  *tm;
  
  [self logWithFormat:@"shall fetch cal %@ from %@ to %@ type %i",
          _calendar, _startDate, _endDate, _componentType];

  now        = [NSCalendarDate date];
  properties =
    [NSDictionary dictionaryWithObjectsAndKeys:
                  now,              @"lastModified",
                  @"Europe/Berlin", @"tzid",
                  @"en",            @"language",
                  @"999",           @"read",
                  @"999",           @"write",
                  _calendar,        @"name",
                  [NSNumber numberWithInt:_componentType],
                  @"component-type",
                  nil];

  cmdctx = [self commandContextInContext:_ctx];
  account = [cmdctx valueForKey:LSAccountKey];
  am     = [SxAptManager  managerWithContext:cmdctx];
  tm     = [SxTaskManager managerWithContext:cmdctx];
  if (_componentType == WCAP_COMPONENT_FREEBUSY) {
    // free busy
    result = [am freeBusyDataForUser:[self nameInContainer]
                 from:_startDate to:_endDate];
  }
  else {
    result = [NSArray array];
    if (_componentType & WCAP_COMPONENT_EVENT) {
      result =
        [am coreInfoForAppointmentSet:[SxAptSetIdentifier privateOverviewSet]];
      [am fetchParticipantsForAppointments:result];
      result = [self wcapEventsForRecords:result withLogin:account];
      //NSLog(@"%s: fetched %d events", __PRETTY_FUNCTION__,
      //      [result count]);
    }
    if (_componentType & WCAP_COMPONENT_TODO) {
      NSArray *jobs;
      jobs = [tm fetchTasksOfGroup:nil type:@"todo"];
      jobs = [self wcapToDosForRecords:jobs withLogin:account];
      result = [result arrayByAddingObjectsFromArray:jobs];
    }
  }
  
  return [WCAPResultSet resultSetWithProperties:properties result:result];
}

- (id)wcapFetchByRangeInContext:(WOContext *)_ctx {
  NSCalendarDate *startDate, *endDate;
  WORequest   *r;
  NSString    *calid;
  NSException *error;
  NSString    *ctype;
  NSArray     *result;
  
  r = [_ctx request];
  calid  = [r formValueForKey:@"calid"];
  ctype  = [r formValueForKey:@"component-type"];
  
  startDate = [NSCalendarDate dateWithExDavString:
                                [r formValueForKey:@"dtstart"]];
  endDate   = [NSCalendarDate dateWithExDavString:
                                [r formValueForKey:@"dtend"]];
  
  result = [self wcapFetchCalendar:calid
                 from:startDate to:endDate
                 type:[ctype intValue]
                 inContext:_ctx];

  /* render */
  error = [[SoWCAPRenderer sharedRenderer] renderObject:result inContext:_ctx];
  if (error) return error;
  return [_ctx response];
}

- (id)wcapGetFreeBusyInContext:(WOContext *)_ctx {
  NSCalendarDate *startDate, *endDate;
  WORequest   *r;
  NSString    *calid;
  NSException *error;
  NSArray     *result;
  
  r = [_ctx request];
  calid  = [r formValueForKey:@"calid"];
  startDate = [NSCalendarDate dateWithExDavString:
                                [r formValueForKey:@"dtstart"]];
  endDate   = [NSCalendarDate dateWithExDavString:
                                [r formValueForKey:@"dtend"]];
  
  result = [self wcapFetchCalendar:calid
                 from:startDate to:endDate
                 type:0
                 inContext:_ctx];

  /* render */
  error = [[SoWCAPRenderer sharedRenderer] renderObject:result inContext:_ctx];
  if (error) return error;
  return [_ctx response];
}

- (id)wcapUserPrefsInContext:(WOContext *)_ctx {
  NSDictionary *prefs = nil, *sprefs = nil, *all;
  NSException *error;
  NSString *email, *cn, *gn, *sn, *user;
  
  [self logWithFormat:@"shall get WCAP user-prefs ..."];

  cn    = @"Helge Hess";
  gn    = @"Helge";
  sn    = @"Hess";
  email = [[self nameInContainer] stringByAppendingString:@"@skyrix.com"];
  user = [self nameInContainer];
  
  /* collect */
  
  prefs  = [NSDictionary dictionaryWithObjectsAndKeys:
                           cn, @"cn", gn, @"givenName", sn, @"sn",
                           email, @"mail",
                           @"",              @"preferredlanguage",
                           user,      @"nswcalCALID", 
                         
                         /* ICS */
                           user,            @"icsCalendar",
                           @"Europe/Berlin", @"icsTimezone",
                           @"",              @"icsDefaultSet",
                           @"",              @"icsFirstDay",
                           @"lucy$,jjones$,jsmith:jdoe", @"icsSubscribed", 
                           user, @"icsFreeBusy", 
                           @"dogbert", @"icsDWPHost", 
                           @"jdoe$John's Calendar,jdoe:personal$John's Personal Calendar",
                           @"icsCalendarOwned",
                         
                         /* CE (Calendar Express) */
                           @"PT0H30M", @"ceInterval", 
                           @"19",      @"ceDayTail", 
                           @"overview",    @"ceDefaultView", 
                           @"pref_group4", @"ceColorSet", 
                           @"1",       @"ceToolText", 
                           @"1",       @"ceToolImage", 
                           @"PrimSansBT,Verdana,sans-serif", @"ceFontFace",
                           @"0",       @"ceExcludeSatSun", 
                           @"1",       @"ceGroupInviteAll", 
                           @"0z",      @"ceSingleCalendarTZID", 
                           @"0",       @"ceAllCalendarTZIDs", 
                           @"0",       @"ceNotifyEnable", 
                           email,      @"ceNotifyEmail", 
                           @"P15M",    @"ceDefaultAlarmStart", 
                           email,      @"ceDefaultAlarmEmail", 
                           nil];
  
  sprefs = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"no",  @"allowchangepassword",
                           @"yes", @"allowcreatecalendars",
                           @"",    @"allowdeletecalendars",
                           @"yes", @"allowpublicwritablecalendars",
                           @"no",  @"validateowners",
                           nil];
  
  all = [NSDictionary dictionaryWithObjectsAndKeys:
                        prefs,  @"preferences",
                        sprefs, @"server-preferences",
                        nil];
  
  /* render */
  
  error = [[SoWCAPRenderer sharedRenderer] renderObject:all inContext:_ctx];
  if (error) return error;
  return [_ctx response];
}

- (id)wcapStoreEventsInContext:(WOContext *)_ctx {
  [self logWithFormat:@"WCAP store not implemented."];
  return nil;
}

@end /* SxUserFolder(WCAP) */
