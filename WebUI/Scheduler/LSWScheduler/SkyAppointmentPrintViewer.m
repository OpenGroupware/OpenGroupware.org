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

#include <OGoFoundation/LSWViewerPage.h>

/* most code copied from 'LSWAppointmentViewer.m' */
// TODO: hh asks: ^^^ says who? WTF???

@class NSTimeZone, NSArray, NSString, NSMutableString;

@interface SkyAppointmentPrintViewer : LSWViewerPage
{
@private
  NSMutableString *writeAccessList;
  NSTimeZone      *timeZone;
  BOOL            fetchComment;
  NSArray         *aptTypes;
  id              aptType;
}

/* accessors */

- (id)appointment;
- (BOOL)isCyclic;
- (NSString *)startDate;
- (NSString *)accessTeamLabel;

@end /* SkyAppointmentPrintViewer */

#include <OGoFoundation/LSWMailEditorComponent.h>
#include "common.h"
#include <EOControl/EOKeyGlobalID.h>

@interface SkyAppointmentPrintViewer(PrivateMethodes)
- (id)_getOwnerOf:(id)_app;
- (id)_getAccessTeamOf:(id)_app;
- (id)_getAppointmentByGlobalID:(id)_gid;
@end /* SkyAppointmentPrintViewer(PrivateMethodes) */


@interface NSObject(GID)
- (EOGlobalID *)globalID;
- (BOOL)hasLogTab;
@end

@implementation SkyAppointmentPrintViewer

+ (int)version {
  return [super version] + 4;
}

- (id)init {
  if ((self = [super init])) {
    self->writeAccessList = [[NSMutableString alloc] initWithCapacity:128];
  }
  return self;
}

- (void)dealloc {
  [self unregisterAsObserver];
  [self->timeZone        release];
  [self->writeAccessList release];
  [self->aptTypes        release];
  [self->aptType         release];
  [super dealloc];
}

/* operations */

- (void)_fetchComment {
  id tmp;
  id obj;
  
  obj = [self object];
  if ([obj isKindOfClass:[NSDictionary class]]) return;

  [obj run:@"appointment::get-comment", @"relationKey", @"dateInfo", nil];
  tmp = [[obj valueForKey:@"dateInfo"] valueForKey:@"comment"];
  if (tmp) [obj takeValue:tmp forKey:@"comment"];
}

- (void)_fetchWriteAccessList {
  // TODO: split up
  NSEnumerator   *enumerator = nil;
  id             objId = nil;
  NSString       *list = nil;
  EOGlobalID     *oid  = nil;
  NSNumber       *pkey = nil;
  NSMutableArray *personIds;
  NSMutableArray *teamIds;
  NSMutableArray *result;

  personIds = [[NSMutableArray alloc] init];
  teamIds   = [[NSMutableArray alloc] init];
  result    = [[NSMutableArray alloc] init];

  pkey = [[self object] valueForKey:@"ownerId"];
  oid  = [EOKeyGlobalID globalIDWithEntityName:@"Person" 
                          keys:&pkey keyCount:1 zone:NULL];
  [personIds addObject:oid];

  list = [[self object] valueForKey:@"writeAccessList"];

  if (list != nil && ![list isEqualToString:@" "]) {
    enumerator = [[list componentsSeparatedByString:@","] objectEnumerator];

    while ((objId = [enumerator nextObject])) {
      pkey = [NSNumber numberWithInt:[objId intValue]];
      oid  = [EOKeyGlobalID globalIDWithEntityName:@"Person" 
                            keys:&pkey keyCount:1 zone:NULL];
      [personIds addObject:oid];

      oid  = [EOKeyGlobalID globalIDWithEntityName:@"Team" 
                            keys:&pkey keyCount:1 zone:NULL];
      [teamIds addObject:oid];
    }
  }
  if ([personIds count] > 0) {
    NSArray *tmp;

    tmp = [self runCommand:@"person::get-by-globalid",
                @"gids", personIds,
                @"attributes", [NSArray arrayWithObjects:
                                        @"globalID",  @"name",    
                                        @"firstname", @"login", nil],
                nil];
    [result addObjectsFromArray:tmp];
  }
  if ([teamIds count] > 0) {
    NSArray *tmp;

    tmp = [self runCommand:@"team::get-by-globalid",
                @"gids", teamIds,
                @"attributes", [NSArray arrayWithObjects:
                                        @"globalID",
                                        @"description", nil],
                nil];
    [result addObjectsFromArray:tmp];
  }
  {
    int i, cnt;

    [self->writeAccessList setString:@""];

    for (i = 0, cnt = [result count]; i< cnt; i++) {
      id       o      = [result objectAtIndex:i];
      NSString *eName = [[o valueForKey:@"globalID"] entityName];

      if (i > 0)
        [self->writeAccessList appendString:@", "];

      if ([eName isEqualToString:@"Person"])
        [self->writeAccessList appendString:[o valueForKey:@"login"]];
      else
        [self->writeAccessList appendString:[o valueForKey:@"description"]];
    }
  }
  RELEASE(personIds); personIds = nil;
  RELEASE(teamIds);   teamIds   = nil;
  RELEASE(result);    result    = nil;
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  if ([super prepareForActivationCommand:_command
             type:_type configuration:_cmdCfg]){
    id appointment;
    NSTimeZone *tz;

    if ((tz = [[self context] valueForKey:@"SkySchedulerTimeZone"]) == nil)
      tz = [[self session] timeZone];

    self->timeZone = [tz retain];
    
    appointment = [self object];

    if ([[_type type] isEqualToString:@"eo-gid"]) {
      if (![[_type subType] isEqualToString:@"date"])
        return NO;

      appointment = [self _getAppointmentByGlobalID:appointment];
      
      [self setObject:appointment];
    }
    else if (![[appointment valueForKey:@"comment"] isNotNull]) {
      id tmp;

      [appointment run:@"appointment::get-comment",
                   @"relationKey", @"dateInfo",
                   nil];
      tmp = [[appointment valueForKey:@"dateInfo"] valueForKey:@"comment"];
      if (tmp) [appointment takeValue:tmp forKey:@"comment"];
    }

    if (appointment == nil) {
      NSLog(@"WARNING: %s No appointment can be set!!!", __PRETTY_FUNCTION__);
      return NO;
    }
    
    //NSAssert(appointment, @"no appointment is set !");
    
    /* refetch comment */
    
    
    if ([appointment valueForKey:@"owner"] == nil) {
      id owner;

      owner = [self _getOwnerOf:appointment];
      if (owner)
        [appointment takeValue:owner forKey:@"owner"];
    }
    [self _fetchWriteAccessList];
    
    return YES;
  }
  return NO;
}

// notifications

- (void)syncAwake {
  [super syncAwake];

  if (self->fetchComment) {
    [self _fetchComment];
    [self _fetchWriteAccessList];
    self->fetchComment = NO;
  }
  
  [[[self object] valueForKey:@"startDate"] setTimeZone:self->timeZone];
  [[[self object] valueForKey:@"endDate"]   setTimeZone:self->timeZone];
}

// accessors

- (void)sleep {
  [super sleep];
  RELEASE(self->aptTypes); self->aptTypes = nil;
  RELEASE(self->aptType);  self->aptType  = nil;
}
 
- (id)appointment {
  return [self object];
}

- (BOOL)isLogTabEnabled {
  return [[self application] hasLogTab];
}

- (NSString *)startDate {
  id date, day;
  
  date = [[self appointment] valueForKey:@"startDate"];
  day  = [date descriptionWithCalendarFormat:@"%A"];

  return [NSString stringWithFormat:@"%@, %@",
                   [[self labels] valueForKey:day],
                   [date descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M %Z"]];
}

- (NSString *)aptTitle {
  return [NSString stringWithFormat:@"%@; %@",
                   [[self appointment] valueForKey:@"title"],
                   [self startDate]];
}

- (NSString *)endDate {
  id date, day;
  
  date = [[self appointment] valueForKey:@"endDate"];
  day  = [date descriptionWithCalendarFormat:@"%A"];
  
  return [NSString stringWithFormat:@"%@, %@",
                   [[self labels] valueForKey:day],
                   [date descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M %Z"]];
}

- (NSString *)cycleEndDateString {
  NSCalendarDate *d = [[self object] valueForKey:@"cycleEndDate"];
  if (d == nil) return nil;
  return [d descriptionWithCalendarFormat:@"%Y-%m-%d %Z"];
}

/* appointment types */

- (NSArray *)configuredAptTypes {
  // TODO: duplicate code with viewer
  NSUserDefaults *ud;
  NSArray *configured = nil;
  NSArray *custom     = nil;

  ud = [[self session] userDefaults];
  configured = [ud objectForKey:@"SkyScheduler_defaultAppointmentTypes"];
  if (configured == nil) configured = [NSArray array];
  custom = [ud objectForKey:@"SkyScheduler_customAppointmentTypes"];
  if (custom != nil)
    configured = [configured arrayByAddingObjectsFromArray:custom];
  return configured;
}
- (NSArray *)aptTypes {
  if (self->aptTypes == nil)
    self->aptTypes = [[self configuredAptTypes] copy];
  return self->aptTypes;
}

- (id)_appointmentType {
  // TODO: document the return type
  NSEnumerator *e;
  id           one     = nil;
  NSString     *wanted;
  
  if (self->aptType != nil)
    return self->aptType;

  e      = [[self aptTypes] objectEnumerator];
  wanted = [[self appointment] valueForKey:@"aptType"];
  
  while ((one = [e nextObject]) != nil) {
    NSString *key;
    
    key = [one valueForKey:@"type"];
    
    if ((![wanted isNotEmpty]) && [key isEqualToString:@"none"])
      self->aptType = [one retain];
    else if ([wanted isEqualToString:key])
      self->aptType = [one retain];
    
    if (self->aptType != nil)
      break;
  }
  return self->aptType;
}

- (NSString *)aptTypeLabel {
  id       type; // TODO: use proper type?
  NSString *label;
  
  type = [self _appointmentType];
  if ((label = [type valueForKey:@"label"]) != nil)
    return label;
  
  label = [@"aptType_" stringByAppendingString:[type valueForKey:@"type"]];
  return [[self labels] valueForKey:label];
}

- (NSString *)accessTeamLabel {
  id accessTeam;

  accessTeam = [self _getAccessTeamOf:[self appointment]];
  
  return ([accessTeam isNotNull])
    ? [accessTeam valueForKey:@"description"]
    : nil;
}

- (NSString *)ignoreConflicts {
  return ([[[self object] valueForKey:@"isConflictDisabled"] boolValue])
    ? [[self labels] valueForKey:@"yes"]
    : [[self labels] valueForKey:@"no"];
}

- (NSString *)notificationTime {
  NSString *timeNumber = nil;

  timeNumber = [[[self object] valueForKey:@"notificationTime"] stringValue];
  
  if ([timeNumber isEqualToString:@"10"]) timeNumber = @"10m";
  
  if (timeNumber != nil) {
    return [NSString stringWithFormat:@"%@ %@",
                     [[self labels] valueForKey:timeNumber],
                     [[self labels] valueForKey:@"before"]];
  }
  else
    return [[self labels] valueForKey:@"notSet"];
}

- (BOOL)isCyclic {
  return ([[[self object] valueForKey:@"type"] isNotNull]) ? YES : NO; 
}

- (NSString *)cycleType {
  return [[self labels] valueForKey:[[self object] valueForKey:@"type"]];
}

- (NSString *)writeAccessList {
  return self->writeAccessList;
}

- (BOOL)isOwnerArchived {
  return [[[self->object valueForKey:@"owner"]
                         valueForKey:@"dbStatus"]
                         isEqualToString:@"archived"];
}

/* actions */

@end /* SkyAppointmentPrintViewer */

@implementation SkyAppointmentPrintViewer(PrivateMethodes)

- (id)_getOwnerOf:(id)_app {
  NSString *ownerId;

  ownerId = [_app valueForKey:@"ownerId"];
  if (![ownerId isNotNull])
    return nil;
  
  return  [[self runCommand:@"person::get", @"companyId", ownerId, nil]
	    lastObject];
}

- (id)_getAccessTeamOf:(id)_app {
  id theAccessTeam;
  
  theAccessTeam = [_app valueForKey:@"toAccessTeam"];
  if (theAccessTeam == nil) {
    NSString *accessTeamId;

    accessTeamId = [_app valueForKey:@"accessTeamId"];

    theAccessTeam = ([accessTeamId isNotNull])
      ? [[self runCommand:@"team::get", @"companyId", accessTeamId, nil]
               lastObject]
      : nil;
    if (theAccessTeam != nil)
      [_app takeValue:theAccessTeam forKey:@"toAccessTeam"];
  }
  return theAccessTeam;
}

- (id)_getAppointmentByGlobalID:(id)_gid {
  id result = nil;

  if (_gid == nil) return nil;

  // TODO: move attrs to Defaults.plist
  result = [self run:@"appointment::get-by-globalid",
                 @"gids",       [NSArray arrayWithObject:_gid],
                 @"timeZone",   self->timeZone,
#if 1
                 @"attributes", [NSArray arrayWithObjects:
                                         @"globalID",
                                         @"startDate",
                                         @"endDate",
                                         @"title",
                                         @"aptType",
                                         @"location",
                                         @"resourceNames",
                                         @"comment",
                                         @"ownerId",
                                         @"accessTeamId",
                                         @"comment",
                                         @"objectVersion",
                                         @"isConflictDisabled",
                                         @"cycleEndDate",
                                         @"isAttendance",
                                         @"isAbsence",
                                         @"isViewAllowed",
                                         @"type",
                                         @"writeAccessList",
                                         @"notificationTime",
                                         @"dbStatus",
                                         nil],
#endif              
                 nil];
  
  return [result lastObject];
}

@end /* SkyAppointmentPrintViewer(PrivateMethodes) */
