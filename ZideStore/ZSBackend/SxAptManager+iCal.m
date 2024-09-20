/*
  Copyright (C) 2002-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

#include "SxAptManager.h"
#include "common.h"
#include "SxAppointmentRenderer.h"
#include <NGObjWeb/NSException+HTTP.h>
#include <NGiCal/iCalEvent.h>

static BOOL catchExceptions = YES;

@interface SxAptManager(FetchOwner)
- (void)fetchOwnerForAppointment:(id)_apt;
@end /* SxAptManager(FetchOwner) */

@interface NSObject(iCalUID)
- (NSString *)uid;
@end /* NSObject(iCalUID) */

@implementation SxAptManager(iCal)

/* iCalendar / MIME */

- (id)renderAppointmentAsICal:(id)_eo timezone:(NSTimeZone *)_tz {
  id ical;
  
  if (![[_eo valueForKey:@"participants"] isNotNull])
    [self logWithFormat:@"date has no participant yet ..."];
  
  ical = [[self commandContext] runCommand:@"appointment::get-ical",
				@"gid", [_eo valueForKey:@"globalID"], nil];
  return [ical isKindOfClass:[NSArray class]]
    ? ([ical isNotEmpty] ? [ical objectAtIndex:0] : nil)
    : ical;
}
- (id)renderAppointmentAsMIME:(id)_eo timezone:(NSTimeZone *)_tz {
  SxAppointmentRenderer *renderer = [SxAppointmentRenderer renderer];
  
  return [renderer wrapICalStringInMIME:
                   [self renderAppointmentAsICal:_eo timezone:_tz]
                   appointment:_eo
                   timezone:_tz];
}
- (id)renderAppointmentAsICal:(id)_eo {
  return [self renderAppointmentAsICal:_eo timezone:nil];
}
- (id)renderAppointmentAsMIME:(id)_eo {
  return [self renderAppointmentAsMIME:_eo timezone:nil];
}

/* fetching */

- (void)fetchParticipantsForAppointments:(NSArray *)_apts {
  static NSArray *attributes = nil;
  NSDictionary   *participants;
  NSEnumerator   *aptEnum;
  id             apt;
  int            accountId;

  if (attributes == nil) {
    attributes =
      [[NSArray alloc] initWithObjects:
                       @"dateId",
                       @"companyId",
                       @"partStatus",
                       @"role",
                       @"rsvp",
                       @"person.companyId",
                       @"person.globalID",
                       @"person.extendedAttributes",
                       @"person.firstname",
                       @"person.name",
                       @"person.isPerson",
                       @"team.description",
                       @"team.isTeam",
                       @"team.companyId",
                       nil];
  }

  participants =
    [[self commandContext] runCommand:@"appointment::list-participants",
                           @"attributes",   attributes, 
                           @"appointments", _apts,
                           @"groupBy",      @"dateId",  
                           nil];

  accountId = [[[[self commandContext] valueForKey:LSAccountKey]
                       valueForKey:@"companyId"] intValue];
  
  aptEnum   = [_apts objectEnumerator];
  while ((apt = [aptEnum nextObject]) != nil) {
    NSNumber *dateId;
    NSArray  *dateParts;

    dateId    = [apt valueForKey:@"dateId"];
    dateParts = [participants objectForKey:dateId];
    if (dateParts != nil) {
      if ([dateParts count] == 1) {
        // only append the only participant if its not the current user
        if ([[[dateParts lastObject] valueForKey:@"companyId"] intValue]
            == accountId) {
          [apt takeValue:[NSArray array] forKey:@"participants"];
        }
        else {
          [apt takeValue:dateParts forKey:@"participants"];
        }
      }
      else {
        // more than one participant is a meeting
        [apt takeValue:dateParts forKey:@"participants"];
      }
    }
    else {
      [self warnWithFormat:@"%s: did not find participants for date %@",
              __PRETTY_FUNCTION__, apt];
      [apt takeValue:[NSArray array] forKey:@"participants"];
    }
  }
}

- (NSEnumerator *)pkeysAndModDatesAndICalsForGlobalIDs:(NSArray *)_gids
  timezone:(id)_tz
{
  // TODO: add a cache, query versions first
  /*
    Note: we need to take the timezone if we generate iCal for Evolution since
    it uses the iCal timezone for display in an appointment viewer.
    
    Returns:
      pkey     - the primary key
      iCalData - an iCal VEVENT fragment for the appointment
  */
  NSMutableArray *result;
  NSArray        *apts;
  unsigned       i, count;
  static NSArray *attributes = nil;
  
  if ([_tz isKindOfClass:[NSString class]])
    _tz = [NSTimeZone timeZoneWithAbbreviation:_tz];
  
  if (attributes == nil) {
    attributes = [[NSArray alloc] initWithObjects:
      @"ownerId", @"dateId", @"startDate", @"endDate", @"cycleEndDate",
      @"title", @"location", @"type", @"aptType", @"comment",
      @"globalID", @"objectVersion",
      @"sourceUrl",@"calendarName", @"fbtype",
      @"evoReminder", @"olReminder", @"onlineMeeting",
      @"keywords", @"associatedContacts",
      @"accessTeamId", @"sensitivity",
    nil];
  }
  
  if (![_gids isNotEmpty])
    return [[NSArray array] objectEnumerator];
  
  [self logWithFormat:@"process %i gids ...", [_gids count]];
  apts = [[self commandContext]
                runCommand:@"appointment::get-by-globalid",
                  @"gids", _gids,
                  @"attributes", attributes,
                nil];
  count = [apts count];
  [self logWithFormat:@"  fetched %i apts ...", count];
  
  // fetch participants
  [self fetchParticipantsForAppointments:apts];
  
  result = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSDictionary *values;
    id apt, pkey, version;
    id icaldata;
    NSString *keys[4];
    id       vals[4];
    int      p;
    
    apt = [apts objectAtIndex:i];
    
    /* first get key */
    
    pkey = [apt valueForKey:@"dateId"];

    version = [apt valueForKey:@"objectVersion"];
    if (version == nil)
      version = intObj(0);
    
    /* render iCalendar MIME message */
    // fetch owner of apt
    [self fetchOwnerForAppointment:apt];
    icaldata = [self renderAppointmentAsICal:apt timezone:_tz];
    
    /* create entry */
    
    p = 0;
    keys[p] = @"pkey";     vals[p] = pkey;     p++;
    keys[p] = @"iCalData"; vals[p] = icaldata; p++;
    keys[p] = @"version";  vals[p] = version;  p++;
    // TODO: last-modified
    
    values = [[NSDictionary alloc] initWithObjects:vals forKeys:keys count:p];
    [result addObject:values];
    [values release];
  }
  
  [[self commandContext] rollback];
  
  return [result objectEnumerator];
}

- (NSEnumerator *)pkeysAndModDatesAndICalsForGlobalIDs:(NSArray *)_gids {
  // TODO: do not call this method for Evolution, it doesn't return
  //       correct timezones
  return [self pkeysAndModDatesAndICalsForGlobalIDs:_gids timezone:nil];
}

/* put */

- (void)putOGoEvents:(NSMutableDictionary *)_map
  withOldGIDList:(NSMutableArray *)_oldGids  
{
  // these are ogo-gid's mapped to iCalEvents
  LSCommandContext *ctx;
  NSArray *gids;
  NSArray *apts;
  NSUInteger i, cnt;
  NSUInteger idx;
  id apt, gid, event;

  ctx  = [self commandContext];
  gids = [_map allKeys];
  apts = [ctx runCommand:@"appointment::get-by-globalid",
              @"gids", gids, nil];
  for (i = 0, cnt = [apts count]; i < cnt; i++) {
    apt   = [apts objectAtIndex:i];
    gid   = [apt valueForKey:@"globalID"];
    event = [_map objectForKey:gid];
    if (event == nil) {
      [self logWithFormat:@"%s did not find event for gid %@ in map %@",
              __PRETTY_FUNCTION__, gid, _map];
      continue;
    }
    [ctx runCommand:@"appointment::update-with-vevent",
         @"object", apt, @"vevent", event, nil];
    [_map removeObjectForKey:gid];
    if ((idx = [_oldGids indexOfObject:gid]) != NSNotFound)
      [_oldGids removeObjectAtIndex:idx];
  }
}

- (void)putOGoSourceEvents:(NSMutableDictionary *)_map
  withOldGIDList:(NSMutableArray *)_oldGids
{
  // these are ogo-gid's mapped to iCalEvents
  LSCommandContext *ctx;
  NSArray *sourceUrls;
  NSArray *apts;
  unsigned idx;
  unsigned i, cnt;
  id apt, url, event;

  ctx        = [self commandContext];
  sourceUrls = [_map allKeys];
  if ([sourceUrls isNotEmpty]) {
    [self debugWithFormat:@"%s: checking sourceUrls: %@",
          __PRETTY_FUNCTION__, [sourceUrls componentsJoinedByString:@", "]];
  }
  
  apts = [ctx runCommand:@"appointment::get-by-sourceurl",
	        @"sourceUrls", sourceUrls, nil];
  
  for (i = 0, cnt = [apts count]; i < cnt; i++) {
    apt   = [apts objectAtIndex:i];
    url   = [[[apt valueForKey:@"sourceUrl"] copy] autorelease];
    event = [_map objectForKey:url];
    if (event == nil) {
      [self logWithFormat:
	      @"%s: sourceUrl '%@' is linked more than once. ignoring.",
	      __PRETTY_FUNCTION__, url];
      continue;
    }
    [ctx runCommand:@"appointment::update-with-vevent",
         @"object", apt, @"vevent", event, nil];
    [_map removeObjectForKey:url];
    if ((idx = [_oldGids indexOfObject:[apt valueForKey:@"globalID"]])
        != NSNotFound)
      [_oldGids removeObjectAtIndex:idx];
  }
  if ([_map isNotEmpty]) {
    [self logWithFormat:@"got %d unknown sourceIds: %@",
          [[_map allKeys] count],
          [[_map allKeys] componentsJoinedByString:@","]];
  }
}

- (NSException *)_handleException:(NSException *)_exception 
  duringCreationOfEvent:(iCalEvent *)_event
{
  [self logWithFormat:
          @"failed creating appointment for iCal event:\n"
          @"  vevent: %@\n  exception: %@",
          _event, _exception];
  [self rollback];
  
  return catchExceptions ? (NSException *)nil : _exception;
}

- (void)putUnknownEvents:(NSArray *)_events {
  // these are vevents new/unknown to ogo
  LSCommandContext *ctx;
  unsigned i, cnt;
  
  ctx = [self commandContext];
  for (i = 0, cnt = [_events count]; i < cnt; i++) {
    iCalEvent *event;
    
    event = [_events objectAtIndex:i];    
    if (![[event startDate] isNotNull]) {
      [self logWithFormat:@"new iCal event has no startdate, ignore: %@",
              event];
      continue;
    }
    if (![[event endDate] isNotNull]) {
      [self logWithFormat:@"new iCal event has no enddate, ignore: %@",
              event];
      continue;
    }
    
    NS_DURING
      [ctx runCommand:@"appointment::new-with-vevent", @"vevent", event, nil];
    NS_HANDLER {
      [[self _handleException:localException duringCreationOfEvent:event] 
             raise];
    }
    NS_ENDHANDLER;
  }
}

- (id)putVEvents:(NSArray *)_events {
  return [self putVEvents:_events inAptSet:nil];
}
- (id)putVEvents:(NSArray *)_events inAptSet:(SxAptSetIdentifier *)_aptSet {
  /*
    what's todo:
     - check if uid is known (skyrix:// id or look for source id)
     - if known: check for changes PROBLEM: how to see what's new
     - if not knonw: create a new appointment, set source id
  */
  static NSString *skyrixId = nil;
  NSMutableDictionary *skyVEvents;     // events with a skyrix uid
  NSMutableDictionary *sourceVEvents;  // events with another uid
  NSMutableArray      *unknownVEvents; // events with no uid
  NSMutableArray      *oldGIDList;
  unsigned            i, cnt;

  if (skyrixId == nil) {
    skyrixId = [[NSUserDefaults standardUserDefaults]
                                valueForKey:@"skyrix_id"];
    skyrixId = [[NSString alloc] initWithFormat:@"skyrix://%@/%@/",
                                 [[NSHost currentHost] name],
                                 skyrixId];
  }

  oldGIDList = nil;
  if (_aptSet != nil) {
    NSArray *gids;
    gids = [self gidsOfAppointmentSet:_aptSet];
    oldGIDList = [[gids mutableCopy] autorelease];
  }
  
  [self commandContext]; // hh(2024-09-20): may have side effects
  cnt    = [_events count];
  [self logWithFormat:@"putting %d events", cnt];
  if (!cnt) return nil;

  // unused: neededEntityName = @"Date";
  skyVEvents     = [NSMutableDictionary dictionaryWithCapacity:cnt];
  sourceVEvents  = [NSMutableDictionary dictionaryWithCapacity:cnt];
  unknownVEvents = [NSMutableArray arrayWithCapacity:cnt];

  /*
    sort the vevents:
     - skyVEvents:    are those events with a skyrix_id as uid
     - sourceVEvents: are those that have a uid which is not a skyrix_id
     - unknownVEvent: are those events with no or an empty uid
  */
  for (i = 0; i < cnt; i ++) {
    NSString  *uid;
    id        event;
    
    event = [_events objectAtIndex:i];
    uid   = [event uid];
    if ([uid isNotEmpty]) {
      if ([uid hasPrefix:skyrixId]) {
        id gid;
        gid = [uid substringFromIndex:[skyrixId length]];
        gid = [NSNumber numberWithInt:[gid intValue]];
        gid = [EOKeyGlobalID globalIDWithEntityName:@"Date"
                             keys:&gid keyCount:1 zone:NULL];
        [skyVEvents setObject:event forKey:gid];
      }
      else {
        [sourceVEvents setObject:event forKey:uid];
      }
    }
    else
      [unknownVEvents addObject:event];
  }

  /*
    now save the events
  */

  /* put events with skyrix_id */
  [self putOGoEvents:skyVEvents withOldGIDList:oldGIDList];
  // if sky events left (unknown) -> they are deleted in skyrix
  // TODO: what todo with them ? 
  {
    NSArray *left = [skyVEvents allKeys];
    
    if ([left isNotEmpty])
      [self logWithFormat:@"%d vevents with unknown ogo-ids where not put! "
            @"maybe the ogo-records have been deleted.",
            [left count]];
  }

  /* put events with any other uid */
  [self putOGoSourceEvents:sourceVEvents withOldGIDList:oldGIDList];
  // if source events are left: -> unknown
  [unknownVEvents addObjectsFromArray:[sourceVEvents allValues]];

  /* put unknown events */
  [self putUnknownEvents:unknownVEvents];

  if (![self commit]) {
    [self logWithFormat:@"could not commit transaction !"];
    [self rollback];
    return [NSException exceptionWithHTTPStatus:409 /* Conflict */
                        reason:@"could not commit transaction !"];
  }
  
  /* check wether some gids of this set were not put
     -> this is interpreted as a delete-action
     -> those events which are in the set, but did not occure in this
        publish action, are assumed to be removed on client side
     -> delete matching entries in ogo

     this is done after the commit, to save all the other changes
     (which may not be so good. we'll see)

     TODO: we need a bulk delete
   */
  if ((cnt = [oldGIDList count]) > 0) {
    for (i = 0; i < cnt; i++) {
      EOKeyGlobalID *gid;
      id            error;
      id            pKey;
      
      gid  = (EOKeyGlobalID *)[oldGIDList objectAtIndex:i];
      pKey = [gid keyValues][0];
      
      if ((error = [self deleteRecordWithPrimaryKey:pKey]) != nil)
        return error;
    }
  }
  return nil;
}

@end /* SxAptManager(iCal) */
