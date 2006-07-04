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

#include <OGoFoundation/OGoContentPage.h>

@class NSArray, NSDictionary, NSCalendarDate;
@class EOArrayDataSource;

@interface SkyNewsAppointmentList : OGoContentPage
{
@protected
  EOArrayDataSource *dataSource;
  NSDictionary      *selectedAttribute;
  NSCalendarDate    *today;
  NSCalendarDate    *future;
  unsigned          startIndex;
  id                appointment;
  BOOL              fetchAppointments;
  BOOL              isDescending; 
  NSString          *sortedKey;
  NSString          *title;
}

- (void)_setParticipantsLabelForAppointment:(id)_appointment;

@end

#include <LSFoundation/LSFoundation.h>
#include "common.h"

@interface NSObject(Gid)
- (EOGlobalID *)globalID;
@end

@implementation SkyNewsAppointmentList

static NSArray      *fetchKeys     = nil;
static NSString     *dateformat    = nil;
static NSDictionary *emptyDict     = nil;
static int          maxLabelLength = 28;  // TODO: make a default!

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  if (fetchKeys == nil)
    fetchKeys = [[ud arrayForKey:@"OGoScheduler_NewsFetchKeys"] copy];
  
  if (dateformat == nil)
    dateformat = [[ud stringForKey:@"OGoScheduler_NewsPageDateFormat"] copy];
  
  if (emptyDict == nil)
    emptyDict = [[NSDictionary alloc] init];
}

- (id)init {
  if ((self = [super init])) {
    NSCalendarDate *now;
    NSUserDefaults *d;
    unsigned int   seconds;
    
    // TODO: not too good to use a session in -init, better place in awake?
    d       = [(id)[self session] userDefaults];
    seconds = [[d objectForKey:@"news_filterDays"] intValue];
    seconds = (seconds == 0) ? 86400 : (seconds * 86400);
    
    now = [NSCalendarDate date];
    [now setTimeZone:[[self session] timeZone]];

    self->today = [now hour:1 minute:0 second:0];
    [self->today setCalendarFormat:dateformat];
    self->today = [self->today retain];
    
    self->future = [[now addTimeInterval:seconds] endOfDay]; //latest date
    [self->future setCalendarFormat:dateformat];
    self->future = [self->future retain];
    
    [self registerForNotificationNamed:LSWNewAppointmentNotificationName];
    [self registerForNotificationNamed:LSWUpdatedAppointmentNotificationName];
    [self registerForNotificationNamed:LSWDeletedAppointmentNotificationName];
    
    self->fetchAppointments = YES;
    self->dataSource = [[EOArrayDataSource alloc] init];
    self->sortedKey = @"startDate";
  }
  return self;
}

- (void)dealloc {
  [self unregisterAsObserver];

  [self->appointment       release];
  [self->selectedAttribute release];
  [self->today             release];
  [self->future            release];
  [self->dataSource        release];
  [self->sortedKey         release];
  [self->title             release];
  
  [super dealloc];
}

/* processing */

- (NSDictionary *)_argsWithGids:(NSArray *)_gids {
  NSDictionary *result;
  static NSString *keys[4] = { @"timeZone", @"gids", @"attributes", nil };
  id values[3];
  
  if (_gids == nil)
    return emptyDict;
  
  if ((values[0] = [[self session] timeZone]) == nil) {
    [self logWithFormat:@"ERROR: missing timezone in session: %@", 
	    [self session]];
    return emptyDict;
  }
  if ((values[2] = fetchKeys) == nil) {
    [self logWithFormat:@"ERROR: missing fetchkeys!"];
    return emptyDict;
  }
  values[1] = _gids;
  result = [[[NSDictionary alloc] 
	    initWithObjects:values forKeys:keys count:3] autorelease];
  return result;
}

- (void)_fetchAppointments {
  NSArray      *gids = nil, *apts = nil;
  id           gid;
  int          i, cnt;
  NSDictionary *args = nil;
  
  gid  = [[[self session] activeAccount] globalID];
  gids = [self runCommand:@"appointment::query",
               @"companies", [NSArray arrayWithObject:gid],
               @"fromDate",  self->today,
               @"toDate",    self->future,
               nil];
  
  args = [self _argsWithGids:gids];
  apts = [self runCommand:@"appointment::get-by-globalid" arguments:args];
  
  for (i = 0, cnt = [apts count]; i < cnt; i++) {
    id apmt = [apts objectAtIndex:i];
    [self _setParticipantsLabelForAppointment:apmt];
  }
  
  [self->dataSource setArray:apts];
  self->fetchAppointments = NO;
}

- (void)syncAwake {
  [super syncAwake];
  
  if (self->fetchAppointments)
    [self _fetchAppointments];
}

- (void)syncSleep {
  self->fetchAppointments = YES;
  [self->appointment release]; self->appointment = nil;
  [super syncSleep];
}
- (void)sleep {
  [super sleep];
  [self->title release]; self->title = nil;
}

/* accessors   */

- (void)setSortedKey:(NSString *)_key {
  ASSIGNCOPY(self->sortedKey, _key);
}
- (NSString *)sortedKey {
  return self->sortedKey;
}

- (void)setStart:(unsigned)_startIndex {
  self->startIndex = _startIndex;
}
- (unsigned)start {
  return self->startIndex;
}

- (void)setIsDescending:(BOOL)_isDescending {
  self->isDescending = _isDescending;
}
- (BOOL)isDescending {
  return self->isDescending;    
}

- (void)setSelectedAttribute:(NSDictionary *)_selectedAttribute {
  ASSIGN(self->selectedAttribute, _selectedAttribute);
}
- (NSDictionary *)selectedAttribute {
  return self->selectedAttribute;    
}

- (void)setAppointment:(id)_appointment {
  ASSIGN(self->appointment, _appointment);
}
- (id)appointment {
  return self->appointment;    
}

- (NSString *)title {
  if (self->title)
    return self->title;
  
  self->title = [[NSString alloc] initWithFormat:@"%@ (%@ - %@)",
                   [[self labels] valueForKey:@"appointments"],
                   [self->today description],
                   [self->future description]];
  return self->title;
}

- (id)dataSource {
  return self->dataSource;
}

/* actions */

- (id)refresh {
  [self _fetchAppointments];
  
  return nil;
}

- (id)viewAppointment {
  return [[[self session] navigation]
                 activateObject:[self->appointment valueForKey:@"globalID"]
                 withVerb:@"view"];
}

/* notifications */

- (void)noteChange:(NSString *)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];

  if ([_cn isEqualToString:LSWNewAppointmentNotificationName] ||
      [_cn isEqualToString:LSWUpdatedAppointmentNotificationName] ||
      [_cn isEqualToString:LSWDeletedAppointmentNotificationName])
    self->fetchAppointments = YES;
}

- (NSArray *)_participantsOfAppointment:(id)_appointment {
  NSAutoreleasePool *pool  = nil;
  NSArray        *parts    = nil;
  NSEnumerator   *partEnum = nil;
  NSMutableArray *result   = nil;
  id             part      = nil;
  id             accountId = nil;

  pool = [[NSAutoreleasePool alloc] init];
  {
    parts  = [_appointment valueForKey:@"participants"];
    result = [[NSMutableArray alloc] initWithCapacity:([parts count] + 1)];
								  
    partEnum  = [parts objectEnumerator];
    accountId = [[[self session] activeAccount] valueForKey:@"companyId"];

    while ((part = [partEnum nextObject])) {
      if ([[part valueForKey:@"companyId"] isEqual:accountId])
	[result insertObject:part atIndex:0];
      else
	[result addObject:part];
    }
  }
  [pool release];
  return [result autorelease];
}

- (NSString *)_stringValueForParticipant:(id)part {
  NSString *str;
  
  if ([[part valueForKey:@"isAccount"] boolValue])
    str = [part valueForKey:@"login"];
  else if ([[part valueForKey:@"isTeam"] boolValue])
    str = [part valueForKey:@"description"];
  else {
    if ((str = [part valueForKey:@"name"]) == nil)
      str = [part valueForKey:@"description"];
  }
  return [str isNotNull] ? str : (NSString *)nil;
}

- (int)maxLabelLength {
  return maxLabelLength;
}

- (void)_setParticipantsLabelForAppointment:(id)_appointment {
  NSAutoreleasePool *pool;
  NSMutableString *result = nil;
  NSArray         *parts;
  NSEnumerator    *partEnum;
  id              part;
  BOOL            isFirst;
  
  pool   = [[NSAutoreleasePool alloc] init];
  
  result   = [NSMutableString stringWithCapacity:32];
  parts    = [self _participantsOfAppointment:_appointment];
  partEnum = [parts objectEnumerator];
  
  isFirst = YES;
  while ((part = [partEnum nextObject])) {
    if ([result length] > [self maxLabelLength])
      /* limit label length ... */
      break;
    
    if (isFirst) isFirst = NO;
    else         [result appendString:@", "];
    
    [result appendString:[self _stringValueForParticipant:part]];
    
  }
  if ([result length] > maxLabelLength) {
    result = (id)[result substringToIndex:maxLabelLength];
    result = (id)[result stringByAppendingString:@".."];
  }
  [_appointment takeValue:result forKey:@"participantsLabel"];
  
  [pool release];
}

@end /* SkyNewsAppointmentList */
