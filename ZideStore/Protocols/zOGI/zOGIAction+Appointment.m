/*
  Copyright (C) 2006-2007 Whitemice Consulting

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

#include "zOGIAction.h"
#include "zOGIAction+Object.h"
#include "zOGIAction+Appointment.h"
#include "zOGIAction+AppointmentConflicts.h"
#include "zOGIAction+Contact.h"
#include "zOGIAction+Resource.h"
#include "zOGIAction+Team.h"
#include "zOGIAction+Note.h"

@implementation zOGIAction(Appointment)

/*
  Construct a ZOGI Appointment dictionary from an EOGenericRecord of an
  appointment with the specified detail 
*/
-(NSDictionary *)_renderAppointment:(NSDictionary *)eoAppointment
                         withDetail:(NSNumber *)_detail {
  NSMutableDictionary  *appointment;
  NSMutableArray       *flags;
  NSCalendarDate       *startDate;
  NSCalendarDate       *endDate;
  id                    tmp;
  id                    resources;
  NSString             *permissions;

  if (eoAppointment == nil) return [[NSDictionary alloc] init];
  flags = [[NSMutableArray alloc] initWithCapacity:6];
  permissions = [[self getCTX] runCommand:@"appointment::access", 
                               @"gid", 
                                 [eoAppointment valueForKey:@"globalID"],
                               nil];

  /* Render core appointment attributes */
  startDate = [eoAppointment valueForKey:@"startDate"];
  [startDate setTimeZone:[self _getTimeZone]];
  endDate = [eoAppointment valueForKey:@"endDate"];
  [endDate setTimeZone:[self _getTimeZone]];
  if ([permissions rangeOfString:@"v"].length > 0) {
    /* render appointment in visible mode */
    [flags addObject:@"VISIBLE"];
    appointment = [NSMutableDictionary dictionaryWithObjectsAndKeys:
      [eoAppointment valueForKey:@"dateId"], @"objectId",
      @"Appointment", @"entityName",
      [self ZERO:[eoAppointment valueForKey:@"objectVersion"]], @"version",
      [eoAppointment valueForKey:@"ownerId"], @"ownerObjectId",
      endDate, @"end", startDate, @"start",
      [self NIL:[eoAppointment valueForKey:@"title"]], @"title",
      [self NIL:[eoAppointment valueForKey:@"notificationTime"]], 
         @"notification",
      [self NIL:[eoAppointment valueForKey:@"location"]], @"location",
      [self NIL:[eoAppointment valueForKey:@"keywords"]], @"keywords",
      [self NIL:[eoAppointment valueForKey:@"aptType"]], @"appointmentType",
      [self NIL:[eoAppointment valueForKey:@"comment"]], @"comment",
      [self NIL:[eoAppointment valueForKey:@"accessTeamId"]], 
         @"readAccessTeamObjectId",
      nil];
    /* Add object details */
    [appointment setObject:eoAppointment forKey:@"*eoObject"];
    if([_detail intValue] & zOGI_INCLUDE_NOTATIONS)
      [self _addNotesToDate:appointment];
    if([_detail intValue] & zOGI_INCLUDE_PARTICIPANTS)
      [self _addParticipantsToDate:appointment];
    if([_detail intValue] & zOGI_INCLUDE_CONFLICTS)
      [self _addConflictsToDate:appointment];
    [self _addObjectDetails:appointment withDetail:_detail];
   } else {
       /* render appointment in non-visible mode */
       [flags addObject:@"NONVISIBLE"];
       appointment = [NSMutableDictionary dictionaryWithObjectsAndKeys:
         [eoAppointment valueForKey:@"dateId"], @"objectId",
         @"Appointment", @"entityName",
         [eoAppointment valueForKey:@"objectVersion"], @"version",
         [eoAppointment valueForKey:@"ownerId"], @"ownerObjectId",
         [self NIL:[eoAppointment valueForKey:@"accessTeamId"]], 
            @"readAccessTeamObjectId",
         endDate, @"end", startDate, @"start",
         nil];
      }
  /* Add cyclical attributes if appointment has a type */
  if([eoAppointment valueForKey:@"type"] != nil) {
    [flags addObject:@"CYCLIC"];
    [appointment setObject:[self NIL:[eoAppointment valueForKey:@"parentDateId"]]
                 forKey:@"parentObjectId"];
    [appointment setObject:[eoAppointment valueForKey:@"cycleEndDate"]
                 forKey:@"cycleEndDate"];
    [appointment setObject:[eoAppointment valueForKey:@"type"]
                 forKey:@"cycleType"];
   }
  /* Add resources */
  if([eoAppointment valueForKey:@"resourceNames"] != nil) {
    if ([self isDebug])
      [self logWithFormat:@"appointment resources: %@",
         [eoAppointment valueForKey:@"resourceNames"]];    
    tmp = [[eoAppointment valueForKey:@"resourceNames"] 
              componentsSeparatedByString:@", "];
    resources = [self _renderNamedResources:tmp];  
  } else resources = [NSConcreteEmptyArray new];
  [appointment setObject:resources forKey:@"_RESOURCES"];
  /* Add writers */
  if ([(tmp = [eoAppointment valueForKey:@"writeAccessList"]) isNotEmpty]) {
    if([tmp length] == 0)
      [appointment setObject:[[NSArray alloc] init]
                      forKey:@"writeAccessObjectIds"];
    else [appointment setObject:[tmp componentsSeparatedByString:@","]
                         forKey:@"writeAccessObjectIds"];
   } else [appointment setObject:[[NSArray alloc] init] 
                         forKey:@"writeAccessObjectIds"];
  /* Add access hint for the client */
  if ([permissions rangeOfString:@"d"].length > 0) 
    [flags addObject:@"DELETE"];
  if ([permissions rangeOfString:@"e"].length > 0)
    [flags addObject:@"WRITE"];
   else 
     [flags addObject:@"READONLY"];
  if ([[eoAppointment objectForKey:@"ownerId"] isEqualTo:[self _getCompanyId]])
    [flags addObject:@"SELF"];
  [appointment setObject:flags forKey:@"FLAGS"];
  /* Return Rendered Appointment */
  return appointment;
} /* end _renderAppointment */

/*
	Construct an array of ZOGI appointments from an array of EOGenericRecords
    with the specified detail.  This iteratively calls the singular
    _renderAppointment method;  it would be way more efficient to bulk load
    all the required detail in one pass,  that would require rewriting each
    of the 'add detail' methods to return dictionaries of arrays.
 */
-(NSArray *)_renderAppointments:(NSArray *)_appointments 
                     withDetail:(NSNumber *)_detail {
  NSMutableArray      *result;
  NSDictionary        *appointment;
  int                 count;

  if (_appointments == nil) return [[NSArray alloc] init];
  if ([_appointments count] == 0) return [[NSArray alloc] init];

  result = [NSMutableArray arrayWithCapacity:[_appointments count]];
  for (count = 0; count < [_appointments count]; count++) {
    appointment = [_appointments objectAtIndex:count];
    [result addObject:[self _renderAppointment:appointment
                                    withDetail:_detail]];
   }
  return result;
} /* end _renderAppointments */

/*
  Return an array of EOGenericRecords for appointment objects.  _arg is
  expected to be an array of objects that can be turned into EOGlobalIDs via
  the _getEOsForPKeys method.
 */
-(NSMutableArray *)_getUnrenderedDatesForKeys:(id)_arg {
  return [[[self getCTX] runCommand:@"appointment::get-by-globalid",
                                    @"gids", [self _getEOsForPKeys:_arg],
                                    @"timeZone", [self _getTimeZone],
                                    nil] mutableCopy];
} /* end _getUnrenderedDatesForKeys */

/*
  Singular instance of _getUnrenderedDatesForKeys;  still returns an array
  however so that it can be used with methods that also handle bulk actions.
  This array is guaranteed to be single-valued.
 */
-(NSMutableDictionary *)_getUnrenderedDateForKey:(id)_arg {
  id               result;

  result = [self _getUnrenderedDatesForKeys:_arg];
  if ([result isKindOfClass:[NSException class]])
    return result;
  if ([result isKindOfClass:[NSMutableArray class]])
    if([result count] == 1)
      return [result objectAtIndex:0];
  return nil;
} /* end _getUnrenderedDateForKey */

/*
  Get an array of ZOGI Appointment dictionaries at the specified detail.
 */
-(id)_getDatesForKeys:(id)_arg withDetail:(NSNumber *)_detail {
  return [self _renderAppointments:[self _getUnrenderedDatesForKeys:_arg]
                        withDetail:_detail];
} /* end _getDatesForKeys */

/* Get an array of ZOGI Appointment dictionaries with no detail. */
-(id)_getDatesForKeys:(id)_pk {
  return [self _getDatesForKeys:_pk withDetail:[NSNumber numberWithInt:0]];
} /* end _getDatesForKeys */

/* Get a ZOGI Appointment dictionary with specified detail. */
-(id)_getDateForKey:(id)_pk withDetail:(NSNumber *)_detail 
{
  id               result;

  result = [self _getDatesForKeys:_pk withDetail:_detail];
  if ([result isKindOfClass:[NSException class]])
    return result;
  if ([result isKindOfClass:[NSMutableArray class]])
    if([result count] == 1)
      return [result objectAtIndex:0];
  return nil;
} /* End of _getDateForKey */

/* Get a ZOGI Appointment dictionary with no detail. */
-(id)_getDateForKey:(id)_pk {
  return [self _getDateForKey:_pk withDetail:[NSNumber numberWithInt:0]];
} /* End of _getDateForKey */

/*
  Loads the notes and their contents for an appointment and attaches them
  to the dictionary as the _NOTES key.
  TODO: This is a poorly (confusingly) named method
 */
-(void)_addNotesToDate:(NSMutableDictionary *)_appointment {
  NSArray        *notes;

  notes = [self _getNotesForKey:[_appointment valueForKey:@"objectId"]];
  [_appointment setObject:notes forKey:@"_NOTES"];
}

/*
  Adds the _PARTICIPANTS key to the provided appointment dictionary
  TODO: This is a poorly (confusingly) named method
 */
-(void)_addParticipantsToDate:(NSMutableDictionary *)_appointment {
  NSMutableArray *participantList;
  NSArray        *participants;
  NSDictionary   *participant;
  NSEnumerator   *enumerator;
  NSString       *status;

  participantList = [NSMutableArray new];
  participants = 
    [[self getCTX] runCommand:@"appointment::list-participants",
       @"gid", [self _getEOForPKey:[_appointment valueForKey:@"objectId"]],
       @"attributes", [NSArray arrayWithObjects:@"dateCompanyAssignmentId",
                         @"role", @"companyId", @"partStatus", @"comment",
                         @"rsvp", @"team.isTeam", @"team.description",
                         @"team.companyId", @"person.companyId",
                         @"person.firstname", @"person.name", 
                         @"person.isPrivate", @"dateId", nil],
       nil];
  enumerator = [participants objectEnumerator];
  while ((participant = [enumerator nextObject]) != nil) {
    if([participant valueForKey:@"isTeam"] == nil) {
      /* Participant is a contact */
      if ([participant valueForKey:@"partStatus"] == nil)
        status = [NSString stringWithString:@"NEEDS-ACTION"];
      else
        status = [participant valueForKey:@"partStatus"];
      [participantList addObject:
         [NSDictionary dictionaryWithObjectsAndKeys:
            @"participant", @"entityName",
            @"Contact", @"participantEntityName",
           [participant valueForKey:@"companyId"], @"participantObjectId",
           [participant valueForKey:@"dateCompanyAssignmentId"], @"objectId",
           [self NIL:[participant valueForKey:@"firstname"]], @"firstName",
           [self NIL:[participant valueForKey:@"name"]], @"lastName",
           [self NIL:[participant valueForKey:@"role"]], @"role",
           [self ZERO:[participant valueForKey:@"isPrivate"]], @"private",
           status, @"status",
           [self NIL:[participant valueForKey:@"comment"]], @"comment",
           [self ZERO:[participant valueForKey:@"rsvp"]], @"rsvp",
           [_appointment valueForKey:@"objectId"], @"appointmentObjectId",
           nil]];
     } else {
         /* Participant is a team */
         [participantList addObject:
            [NSDictionary dictionaryWithObjectsAndKeys:
               @"participant", @"entityName",
               @"Team", @"participantEntityName",
              [participant valueForKey:@"companyId"], @"participantObjectId",
              [participant valueForKey:@"dateCompanyAssignmentId"], @"objectId",
              [self NIL:[participant valueForKey:@"description"]], @"name",
              [self NIL:[participant valueForKey:@"role"]], @"role",
              [self NIL:[participant valueForKey:@"comment"]], @"comment",
              [self ZERO:[participant valueForKey:@"rsvp"]], @"rsvp",
              [_appointment valueForKey:@"objectId"], @"appointmentObjectId",
              nil]];
        }
   }
  [_appointment setObject:participantList forKey:@"_PARTICIPANTS"];
} /* end _addParticipantsToDate */

/*
  Adds the _CONFLICTS key to the provided appointment dictionary. This
  uses the method _renderConflictsForDateKey from the 
  zOGIAction+AppointmentConflicts.m file.
  TODO: This is a poorly (confusingly) named method
 */
-(void)_addConflictsToDate:(id)_appointment {
  [_appointment 
    setObject:
      [self _renderConflictsForDate:[_appointment valueForKey:@"*eoObject"]]
    forKey:@"_CONFLICTS"];
} /* end _addConflictsToDate */

/* 
  This provides a method to set all the status information for a participant
  of an appointment.  This isn't currently used anywhere and is really
  just a cut-n-paste of code from the XML-RPCd action;  we put it here as
  a place horder so as not to loose the logic and command setup.
 */
-(id)_setParticipantStatus:(id)_pk 
  withStatus:(NSString *)_partstat withRole:(NSString *)_role
  withComment:(NSString *)_comment withRSVP:(NSNumber *)_rsvp {
  NSMutableDictionary *args;

  args = [NSMutableDictionary dictionaryWithCapacity:8];
  [args setObject:_pk forKey:@"appointment"];
  if (_partstat != nil) [args setObject:_partstat forKey:@"partstatus"];
  if (_role     != nil) [args setObject:_role     forKey:@"role"];
  if (_comment  != nil) [args setObject:_comment  forKey:@"comment"];
  if (_rsvp     != nil) [args setObject:_rsvp     forKey:@"rsvp"];
  return [[self getCTX] runCommand:@"appointment::change-attendee-status"
                                    arguments:args];
} /* end _setParticipantStatus */

/*
  Search For Appointments
  Runs the appointment::query logic command
  In the query specification the following keys are supported:
    endDate, startDate, and participants
  "startDate" is required.  If no "endDate" is specified then the query is
  automatically done for a span of 8 days.  If no participants are specified
  then the current user is assumed to be relevent participant.
  The aptType and resources keys should be supported by currently is not.
  TODO: Implement appointment types and resources as qualifiers.
  TODO: Handle the participants sanely.  Should be a ZOGI key.
 */
-(id)_searchForAppointments:(NSDictionary *)_query 
                 withDetail:(NSNumber *)_detail
                  withFlags:(NSDictionary *)_flags {
  NSCalendarDate        *startDate, *endDate;
  NSMutableDictionary   *args;
  NSArray               *participants, *gids;
  id                     tmp;

  /* Setup & Validate Start Date */
  startDate = [self _makeCalendarDate:[_query objectForKey:@"startDate"]];
  if (startDate == nil) {
    // \todo Throw exception for unhandle startDate data type
    return [NSException exceptionWithHTTPStatus:500
                        reason:@"No start date specified in query"];
  }
  [startDate setTimeZone:[self _getTimeZone]];

  /* Setup & Validate End Date */
  endDate = nil;
  if ([_query objectForKey:@"endDate"] == nil)
    endDate = [startDate dateByAddingYears:0 months:0 days:8];
  else
    endDate = [self _makeCalendarDate:[_query objectForKey:@"endDate"]];
  if (endDate == nil) {
    // \todo Throw exception for unhandle startDate data type
  }
  [endDate setTimeZone:[self _getTimeZone]];

  /* setup participant restraint */
  if([_query objectForKey:@"participants"] == nil) {
    /* no participants provided - assume self */
    if ([self isDebug])
      [self logWithFormat:@"no participants specified, assuming self"];
    tmp = [NSArray arrayWithObject:[self _getCompanyId]];
  } else {
      /* participants were specified */
      tmp = [_query objectForKey:@"participants"];
      if ([tmp isKindOfClass:[NSString class]]) {
        /* blow up string into an array */
        tmp = [tmp componentsSeparatedByString:@","];
      } else if ([tmp isKindOfClass:[NSNumber class]]) {
          tmp = [NSArray arrayWithObject:tmp];
        }
    } /* end process participants */

  /* participant setup complete, get EOs if we have an array */
  if ([tmp isKindOfClass:[NSArray class]]) {
    /* generate participants from array */
    participants = [self _getEOsForPKeys:tmp];
    if ([self isDebug])
      [self logWithFormat:@"participants for appointments query = %@",
         participants];
  } else {
      [self warnWithFormat:@"appointment query with participants of type %@",
         [tmp class]];
      return [NSException exceptionWithHTTPStatus:500
                reason:@"Participant specified using unsupported type"];
    }
  tmp = nil;

  /* Do Query */
  args = [NSMutableDictionary dictionaryWithCapacity:5];
  [args takeValue:startDate forKey:@"fromDate"];
  [args takeValue:endDate forKey:@"toDate"];
  [args takeValue:participants forKey:@"companies"];
  /*
  if (resources != nil)
    [dict takeValue:resources    forKey:@"resourceNames"];
   */
  if ([_query objectForKey:@"appointmentType"] != nil) {
    tmp = [_query objectForKey:@"appointmentType"];
    if ([tmp isKindOfClass:[NSString class]])
      tmp = [tmp componentsSeparatedByString:@","];
    [args takeValue:tmp forKey:@"aptTypes"];
  }
  gids = [[self getCTX] runCommand:@"appointment::query" arguments:args];
  args = nil;

  /* process quert results */
  if ([gids count] == 0)
    return [[NSArray alloc] init];
  return [self _getDatesForKeys:gids withDetail:_detail];
} /* end _searchForAppointments */

/*
  _createAppointment creates a new appointment from the provided dictionary.
  The
 */
-(id)_createAppointment:(NSDictionary *)_appointment
              withFlags:(NSArray *)_flags {
  return [self _writeAppointment:_appointment
                     withCommand:@"appointment::new"
                       withFlags:_flags];
} /* end _createAppointment */

/*
  Update appointment
 */
-(id)_updateAppointment:(NSDictionary *)_appointment
               objectId:(NSString *)_objectId 
              withFlags:(NSArray *)_flags {
  return [self _writeAppointment:_appointment
                     withCommand:@"appointment::set"
                       withFlags:_flags];
} /* end _updateAppointment */

/* 
  Delete an appointment or a set of related appointments
  If the "deleteCycle" flag is supplied then all appointments with the
  same parentDateObjectId as the specified appointment are deleted.
  TODO: Do we need to unlink notes manually?
*/
-(id)_deleteAppointment:(NSString *)_objectId
              withFlags:(NSArray *)_flags {
  if ([_flags containsObject:[NSString stringWithString:@"deleteCycle"]]) {
    [[self getCTX] runCommand:@"appointment::delete",
                     @"object", [self _getUnrenderedDateForKey:_objectId],
                     @"deleteAllCyclic", [NSNumber numberWithBool:YES],
                     @"reallyDelete", [NSNumber numberWithBool:YES],
                     nil];
   } else {
       [[self getCTX] runCommand:@"appointment::delete",
                        @"object", [self _getUnrenderedDateForKey:_objectId],
                        @"reallyDelete", [NSNumber numberWithBool:YES],
                        nil];
      }
  [[self getCTX] commit];
  return [NSNumber numberWithBool:YES];
} /* end _deleteAppointment */

/* Write an appointment to the database
   TODO: Check for version conflicts */
-(id)_writeAppointment:(NSDictionary *)_appointment
           withCommand:(NSString *)_command
             withFlags:(NSArray *)_flags {
  id                     appointment, exception; 
  NSDictionary          *resource, *eoResource;
  NSEnumerator	        *enumerator;
  NSMutableString       *resourceNames;

  exception = nil;
 
  /* translate zogi appointment to ogo logic date */ 
  appointment = [self _translateAppointment:(id)_appointment
                                  withFlags:_flags];
  if ([appointment isKindOfClass:[NSException class]])
    return appointment;
  [appointment setObject:[self _getTimeZone] forKey:@"timeZone"];
  /* translate resources */
  if ([_appointment valueForKey:@"_RESOURCES"] != nil) {
    resourceNames = [NSMutableString new];
    enumerator = [[_appointment objectForKey:@"_RESOURCES"] objectEnumerator];
    while((resource = [enumerator nextObject]) != nil) {
      eoResource = [self _getUnrenderedResourceForKey:[resource objectForKey:@"objectId"]]; 
      if (eoResource != nil) {
        if ([self isDebug])
          [self logWithFormat:@"retrieved resource %@ for objectId %@",
             eoResource,
             [resource objectForKey:@"objectId"]];
        if ([resourceNames length] > 0)
          [resourceNames appendString:@", "];
        [resourceNames appendString:[eoResource objectForKey:@"name"]];
        [eoResource release];
      }
    }
    [appointment setObject:resourceNames forKey:@"resourceNames"];
  }

  /* perform logic command */
  appointment = [[self getCTX] runCommand:_command
                                arguments:appointment];
  if ([appointment valueForKey:@"dateId"] == nil) {
    exception = [NSException exceptionWithHTTPStatus:500
                             reason:@"Failure to write appointment"];
  }
 
  /* save object links */
  if (exception == nil)
    exception = [self _saveObjectLinks:[_appointment objectForKey:@"_OBJECTLINKS"] 
                             forObject:[appointment objectForKey:@"dateId"]];

  /* save object properties */
  if (exception == nil)
    exception = [self _saveProperties:[_appointment objectForKey:@"_PROPERTIES"] 
                            forObject:[appointment objectForKey:@"dateId"]];

  /* save notes */

  if (exception == nil)
    exception = [self _saveNotes:[_appointment objectForKey:@"_NOTES"] 
                       forObject:[appointment objectForKey:@"dateId"]];
  if (exception != nil) {
    if ([self isDebug])
      [self logWithFormat:@"exception occured, rolling back appointment"];
    [[self getCTX] rollback];
    return exception;
  }

  /* Save complete */
  if ([self isDebug])
    [self logWithFormat:@"saving date %@ complete", [appointment objectForKey:@"dateId"]];
  if ([_flags containsObject:[NSString stringWithString:@"noCommit"]]) {
    /* database commit has been disabled by the noCommit flag */
    if ([self isDebug])
      [self logWithFormat:@"commit disabled via flag!"];
  } else {
      /* committing database transaction */
      [[self getCTX] commit];
    }

  /* render appointment and return */
  return [self _getDateForKey:[appointment objectForKey:@"dateId"]
                   withDetail:[NSNumber numberWithInt:65535]];
} /* end _writeAppointment */

/*
  Translate participants from a ZOGI dictionary to what the OpenGroupware
  logic expects.  Currently it will extract the comment and role keys in 
  addition to the participantObjectId (which is translated to a companyId).
  TODO: Verify that the provided participants are teams or contacts
  TODO: Verify the provided role string is a valid role.
 */
-(id)_translateParticipants:(NSArray *)_participants {
  NSMutableArray      *participants;
  NSMutableDictionary *participant;
  id                  _participant, objectId;
  int                 count;

  if (_participants == nil) {
    participant = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                     [self _getCompanyId], @"companyId",
                     nil];
    if ([self isDebug])
      [self logWithFormat:@"_translateParticipants; called with nil list"];
    return [NSArray arrayWithObject:participant];
   }
  participants = [[NSMutableArray alloc] initWithCapacity:[_participants count]];
  for (count = 0; count < [_participants count]; count++) {
    _participant = [_participants objectAtIndex:count];
    // Make dictionary to contain the new translated participant
    participant = [[NSMutableDictionary alloc] initWithCapacity:8];
    if (![_participant isKindOfClass:[NSDictionary class]])
      return [NSException exceptionWithHTTPStatus:500
                          reason:@"Non-dictionary in participant list"];
    // Extract and if need be translate participant object id to a string
    objectId = [_participant objectForKey:@"participantObjectId"];
    if (objectId == nil)
      return [NSException exceptionWithHTTPStatus:500
                          reason:@"Participant specified with no id"];
     else if ([objectId isKindOfClass:[NSNumber class]])
       objectId = [objectId stringValue];
    // TODO: Verify that objectId points to a contact or a team
    [participant setObject:objectId forKey:@"companyId"];
    // Retrieve record object id and translate to a string if need be
    objectId = [_participant objectForKey:@"objectId"];
    if (objectId != nil) {
      if ([objectId isKindOfClass:[NSNumber class]])
        objectId = [objectId stringValue];
      if (![objectId isEqualToString:@"0"])
        [participant setObject:objectId forKey:@"dateCompanyAssignmentId"];
     } // End objectId (record object id) != nil
    if ([_participant objectForKey:@"role"] != nil)
      [participant setObject:[_participant objectForKey:@"role"]
                      forKey:@"role"];
    if ([_participant objectForKey:@"comment"] != nil)
      [participant setObject:[_participant objectForKey:@"comment"]
                      forKey:@"comment"];      
    [participants addObject:participant];
   } // End for count < [_participants count]
  return participants;
} /* End _translateParticipants */

/*
  Translate a ZOGI dictionary into a dictionary that corresponds to an
  OpenGroupware date record.  If the dictionary cannot be translated to
  a valid appointment an NSException is returned.  This translation takes
  care of the ignoreConlicts/respectConflicts flags.
 */
-(id)_translateAppointment:(NSDictionary *)_appointment 
                 withFlags:(NSArray *)_flags {
  NSMutableDictionary   *appointment;
  NSArray               *keys;
  NSString              *key;
  id                    objectId, value, participants, tmp;
  int                   count;

  objectId = [_appointment objectForKey:@"objectId"];
  if (objectId == nil)
    objectId = [NSString stringWithString:@"0"];
  else if ([objectId isKindOfClass:[NSNumber class]])
    objectId = [objectId stringValue];

  appointment = [[NSMutableDictionary alloc] initWithCapacity:32];
  keys = [_appointment allKeys];
  for (count = 0; count < [keys count]; count++) {
    key = [keys objectAtIndex:count];
    value = [_appointment objectForKey:key];
    if ([self isDebug])
      [self logWithFormat:@"translating key %@ of type %@", key, [value class]];
    if ([key isEqualToString:@"end"]) {
      [appointment setObject:[self _makeCalendarDate:value] forKey:@"endDate"];
    } else if ([key isEqualToString:@"start"]) {
      [appointment setObject:[self _makeCalendarDate:value] forKey:@"startDate"];
    } else if ([key isEqualToString:@"cycleEndDate"]) {
      [appointment setObject:[self _makeCalendarDate:value] forKey:@"cycleEndDate"];
    } else if ([key isEqualToString:@"appointmentType"]) {
      [appointment setObject:value forKey:@"aptType"];
    } else if ([key isEqualToString:@"notification"]) {
      /* notification -> notificationTime */
      [appointment setObject:value forKey:@"notificationTime"];
    } else if ([key isEqualToString:@"readAccessTeamObjectId"]) {
      /* readAccessTeamObjectId -> accessTeamId 
         A blank string or a value of zero nulls the attribute. */
      tmp = nil;
      if (([value isKindOfClass:[NSString class]]) ||
          ([value isKindOfClass:[NSShortInline8BitString class]])) {
        if ([value length] == 0)
          tmp = intObj(0);
        else tmp = intObj([value intValue]);
      } else tmp = value; /* Assuming value is an number */
      if ([tmp intValue] == 0)
        [appointment setObject:[EONull null] forKey:@"accessTeamId"];
      else [appointment setObject:tmp forKey:@"accessTeamId"];
    } else if ([key isEqualToString:@"writeAccessObjectIds"]) {
      /* writeAccessObjectIds -> writeAccessList 
         May be an array or a CSV string 
         TODO: Verify contained values */
        tmp = nil;
        if (([value isKindOfClass:[NSString class]]) ||
            ([value isKindOfClass:[NSShortInline8BitString class]])) {
          if (([tmp length] == 0) || ([tmp isEqualToString:@"0"]))
            tmp = [NSString stringWithString:@""];
          else tmp = value;
        } else if (([value isKindOfClass:[NSArray class]]) ||
                   ([value isKindOfClass:[NSConcreteEmptyArray class]]) ||
                   ([value isKindOfClass:[NSConcreteArray class]])) {
            if ([value count] == 0)
              tmp = [NSString stringWithString:@""];
            else tmp = [value componentsJoinedByString:@","];
          }
        [appointment setObject:tmp forKey:@"writeAccessList"];
    } else if ([key isEqualToString:@"cycleType"]) {
      [appointment setObject:value forKey:@"type"];
    } else if ([key isEqualToString:@"parentObjectId"]) {
      [appointment setObject:[self NIL:value] forKey:@"parentDateId"];
    } else if ([key isEqualToString:@"objectId"]) {
      // Only translate this attribute if it has a non-zero value
      if ([objectId isEqualToString:@"0"]) {
        if ([self isDebug])
          [self logWithFormat:@"_translateAppointment(); dropping objectId"];
       } else { 
           [appointment setObject:value forKey:@"dateId"];
          }
    } else if ([key isEqualToString:@"entityName"] || 
               [key isEqualToString:@"version"]) {
      // These atttributes are deliberately dropped
      if ([self isDebug])
        [self logWithFormat:@"key %@ dropped", key];
    } else if ([[key substringToIndex:1] isEqualToString:@"_"]) {
        if ([self isDebug])
          [self logWithFormat:@"subkey %@ dropped", key];
    } else {
        [appointment setObject:value forKey:key];
       }
   } // End for loop through keys
  // Translate participants
  participants = [self _translateParticipants:[_appointment objectForKey:@"_PARTICIPANTS"]];
  if ([participants isKindOfClass:[NSException class]]) {
    [appointment release];
    return participants;
   }
  [appointment setObject:participants forKey:@"participants"];
  // Deal with the "ignoreConflicts" flag if presented
  if ([_flags containsObject:[NSString stringWithString:@"ignoreConflicts"]])
    [appointment setObject:[NSNumber numberWithInt:1] 
                    forKey:@"isWarningIgnored"];
  if ([_flags containsObject:[NSString stringWithString:@"respectConflicts"]])
    [appointment setObject:[NSNumber numberWithInt:0] 
                    forKey:@"isWarningIgnored"];
  return appointment;
} /* end _translateAppointment */

-(id)_setParticipantStatus:(NSDictionary *)_status
                  objectId:(NSString *)_objectId
                 withFlags:(NSArray *)_flags {
  NSMutableDictionary *args;
  id                   appointment;
  id                   result;

  args = [NSMutableDictionary dictionaryWithCapacity:8];

  /* Get appointment */
  appointment = [self _getUnrenderedDateForKey:_objectId];
  if (appointment == nil)
    return [self _makeUnknownObject:_objectId];
  /* Participant status */
  if ([_status objectForKey:@"status"] != nil)
    [args setObject:[[_status objectForKey:@"status"] uppercaseString]
             forKey:@"partstatus"];
   else
     [args setObject:@"NEEDS-ACTION" forKey:@"partstatus"];
  /* Participant role */
  if ([_status objectForKey:@"role"] != nil)
    [args setObject:[_status objectForKey:@"role"] 
             forKey:@"role"];
  /* Participant comment */
  if ([_status objectForKey:@"comment"] != nil)
    [args setObject:[_status objectForKey:@"comment"] 
             forKey:@"comment"];
  /* Participant RSVP */
  if ([_status objectForKey:@"rsvp"] != nil)
    [args setObject:[_status objectForKey:@"rsvp"] 
             forKey:@"rsvp"];
  [args setObject:appointment forKey:@"appointment"];

  result = [[self getCTX] runCommand:@"appointment::change-attendee-status"
                           arguments:args];
  if ([result intValue] == 1) {
    [[self getCTX] commit];
  }

  return [self _getDateForKey:_objectId 
                   withDetail:[NSNumber numberWithInt:65535]];
} /* end _setParticipantStatus */

@end /* End zOGIAction(Appointment) */
