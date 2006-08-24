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

#include "DirectAction.h"
#include "common.h"
#include "EOControl+XmlRpcDirectAction.h"
#include "NSObject+EKVC.h"
#include "Session.h"
#include <OGoScheduler/SkyAppointmentDocument.h>
#include <OGoScheduler/SkyAppointmentQualifier.h>
#include <EOControl/EOControl.h>

// TODO: this source needs serious cleanup ...

@interface SkyAppointmentQualifier(DirectAction_Appointment)
- (id)initWithBaseValue:(id)_arg;
@end /* SkyAppointmentQualifier(DirectAction_Appointment) */

@implementation DirectAction(Appointment)

- (void)_takeValuesDict:(NSDictionary *)_from
  toAppointment:(SkyAppointmentDocument **)_to
{
  // TODO: document. Apparently those are the keys which can be changed?
  [*_to takeValuesFromObject:_from
        keys:@"startDate", @"endDate", @"title", @"location", @"cycleEndDate",
	@"type", @"comment", @"aptType", @"accessTeamId", @"writeAccess", nil];
}

- (NSCalendarDate *)_calendarDateForValue:(id)_val {
  // TODO: clean up this mess!
  NSCalendarDate *date = nil;
  
  if (![_val isNotNull])
    return nil;
  if ([_val isKindOfClass:[NSCalendarDate class]])
    return _val;
  if ([_val isKindOfClass:[NSString class]]) {
    NSTimeZone     *tz = nil;
    NSUserDefaults *ud;
    id             tmp;
    // check formats
    // YYYY-MM-DD
    // YYYY-MM-DD HH:MM
    // YYYY-MM-DD HH:MM:SS

    ud = [[self commandContext] userDefaults];
    if ((tmp = [ud stringForKey:@"timezone"])) {
      tz = [NSTimeZone timeZoneWithAbbreviation:tmp];
    }

    if ([_val hasSuffix:@"Z"]) {
      _val = [_val substringToIndex:[_val length]-1];
      tz   = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    }
    if ([_val length] == 10) { // YYYY-MM-DD
      date = [NSCalendarDate dateWithString:_val calendarFormat:@"%Y-%m-%d"];
    }
    else if ([_val length] == 16) { // YYYY-MM-DD HH:MM
      date = [NSCalendarDate dateWithString:_val
                             calendarFormat:@"%Y-%m-%d %H:%M"];
    }
    else if ([_val length] == 19) { // YYYY-MM-DD HH:MM:SS
      date = [NSCalendarDate dateWithString:_val
                             calendarFormat:@"%Y-%m-%d %H:%M:%S"];
    }
    else {
      [self errorWithFormat:
	      @"%s: cannot deal with date format: %@", 
	      __PRETTY_FUNCTION__, _val];
    }

    if (tz != nil) 
      [date setTimeZone:tz];
  }

  if (date == nil) {
    [self errorWithFormat:@"%s: failed to make a date out of '%@'",
          __PRETTY_FUNCTION__, _val];
  }
  return date;
}

- (NSArray *)_gidsArrayForTeamNamed:(NSString *)_name
  inContext:(LSCommandContext *)_cmdctx
{
  NSArray *a;

  // TODO: use attributes
  a = [_cmdctx runCommand:@"team::get",
	         @"description", _name,
	         @"returnType", 
	         [NSNumber numberWithInt:LSDBReturnType_ManyObjects], 
	       nil];
  if (![a isKindOfClass:[NSArray class]])
    a = a != nil ? [NSArray arrayWithObject:a] : nil;
  
  return [a valueForKey:@"globalID"];
}
- (NSArray *)_gidsArrayForPersonWithLogin:(NSString *)_name
  inContext:(LSCommandContext *)_cmdctx
{
  NSArray *a;

  // TODO: use attributes
  a = [_cmdctx runCommand:@"person::get",
	         @"login", _name,
	         @"returnType", 
	         [NSNumber numberWithInt:LSDBReturnType_ManyObjects], 
	       nil];
  if (![a isKindOfClass:[NSArray class]])
    a = a != nil ? [NSArray arrayWithObject:a] : nil;
  
  return [a valueForKey:@"globalID"];
}

- (NSArray *)_validateCompanyValue:(id)_value {
  // TODO: explain what this does, seems to be a bit weird
  LSCommandContext   *cmdctx;
  id<SkyDocumentManager> dm;
  id activeUser;
  id tmp;
  
  cmdctx     = [self commandContext];
  activeUser = [[cmdctx valueForKey:LSAccountKey] valueForKey:@"globalID"];  
  
  if (![_value isNotNull])
    return [NSArray arrayWithObject:activeUser];

  if (!([_value isKindOfClass:[NSString class]] ||
        [_value isKindOfClass:[NSNumber class]])) {
    [self errorWithFormat:@"%s: class %@ not accept as company value",
          __PRETTY_FUNCTION__, NSStringFromClass([_value class])];
    return nil;
  }
  
  /* check whether it is a skyrix id */
  dm = [cmdctx documentManager];
  if ((tmp = [dm globalIDForURL:_value]) != nil) {
    // found a matching globalID
    return [NSArray arrayWithObject:tmp];
  }
  
  /* check wether it is a team name */
  if ((tmp = [self _gidsArrayForTeamNamed:_value inContext:cmdctx]) != nil) {
    if ([tmp isNotEmpty]) // found team(s) with that description
      return tmp;
    // else no team found
  }
  
  /* check wether it is a person */ 
  tmp = [self _gidsArrayForPersonWithLogin:_value inContext:cmdctx];
  if ([tmp isNotEmpty])
    return tmp;
  
  // nothing found
  return nil;
}

/*
  /brief Check whether the contents of the argument is/are teams
  /param _args An array of team ids or a team id as either a string or a number
  /note Used by appointment_setPermissionsAction
*/
- (NSException *)_validateTeams:(id)_arg {
  NSArray  *gids;
  unsigned i, cnt;

  /* If _args is a number convert it to a string */
  if ([_arg isKindOfClass:[NSNumber class]])
    _arg = [_arg stringValue];
  
  /* If _args is a string convert to a single element array */
  if ([_arg isKindOfClass:[NSString class]])
    _arg = [NSArray arrayWithObjects:&_arg count:1];

  /* If _arg is an array loop through the contents */
  if (![_arg isKindOfClass:[NSArray class]]) {
    /* We do not know how to handle the provided _arg */
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
		 reason:@"Invalid team identifier cannot be validated"];
  }

  gids = [[[self commandContext] documentManager] globalIDsForURLs:_arg];
  if ((cnt = [gids count]) == 0) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
		 reason:@"Team specification is empty"];
  }
  if ([gids containsObject:[NSNull null]]) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
		 reason:
                   @"Invalid team identifier specified "
		   @"parameter is not a valid URL/ID"];
  }
  
  for (i = 0; i < cnt; i++) {
    EOGlobalID *gid;
    
    gid = [gids objectAtIndex:i];
    if (![[gid entityName] isEqualToString:@"Team"]) {
      return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
		   reason:
		     @"Invalid team identifier specified "
		   @"URL/ID is not a team "];
    }
  }
  return nil;
}

- (NSException *)_validateAptStartDate:(id)_value {
  if (![_value isNotNull]) {
    return [self faultWithFaultCode:XMLRPC_FAULT_MISSING_PARAMETER
                 reason:@"Missing 'startDate' attribute in appointment"];
  }
  if (![_value isKindOfClass:[NSCalendarDate class]]) {
    [self debugWithFormat:@"WARNING: invalid start-date parameter: %@(%@)",
            _value, NSStringFromClass([_value class])];
    return [self faultWithFaultCode:XMLRPC_FAULT_MISSING_PARAMETER
                 reason:
                   @"'startDate' attribute in appointment is not a "
                   @"date-value!"];
  }
  return nil;
}
- (NSException *)_validateAptEndDate:(id)_value andDuration:(int)_duration {
  if (![_value isNotNull] && _duration == 0) {
    return [self faultWithFaultCode:XMLRPC_FAULT_MISSING_PARAMETER
                 reason:
                   @"Missing 'endDate' or 'duration' attribute in "
                   @"appointment"];
  }
  if (_duration > 0) 
    return nil;
  if (_duration < 0) {
    return [self faultWithFaultCode:XMLRPC_FAULT_MISSING_PARAMETER
                 reason:@"negative 'duration' value!"];
  }
  
  if (![_value isKindOfClass:[NSCalendarDate class]]) {
    return [self faultWithFaultCode:XMLRPC_FAULT_MISSING_PARAMETER
                 reason:
                   @"'endDate' attribute in appointment is not a date value!"];
  }
  return nil;
}

- (EOFetchSpecification *)appointmentFSpec:(id)_arg {
  /* 
     TODO: fix this method - this is completely weird, first creates and
           EOQualifier and then patches the value afterwards
     
     { qualifier = { startDate = ...; endDate = ...} };
  */  
  EOFetchSpecification *fSpec;
  
  fSpec = [[[EOFetchSpecification alloc] initWithBaseValue:_arg] autorelease];
  [fSpec setEntityName:@"Date"];
  
  if ([_arg respondsToSelector:@selector(objectForKey:)]) {
    SkyAppointmentQualifier *qual;
    id                      tmp;
    
    tmp  = [_arg valueForKey:@"qualifier"];
    qual = [[SkyAppointmentQualifier alloc] initWithBaseValue:tmp];
    [fSpec setQualifier:qual];
    [qual release]; qual = nil;
  }
  return fSpec;
}

- (NSArray *)appointment_fetchAction:(id)_arg {
  // TODO: broken for company queries, see OGo bug #220
  EODataSource *appointmentDS;
  
  appointmentDS = [self appointmentDataSource];
  [appointmentDS setFetchSpecification:[self appointmentFSpec:_arg]];
  return [appointmentDS fetchObjects];
}

- (id)appointment_fetchOverviewAction:(id)_startDate
                                     :(id)_endDate
                                     :(id)_company
{
  EODataSource   *appointmentDS;
  NSDictionary   *dict = nil;
  NSCalendarDate *startDate;
  NSCalendarDate *endDate;
  NSArray        *companies;
  id             company;
  id             error;
  /*
    participant_name may be:
    - a skyrix url, a company_id
    - a group name
    - a login name
  */
  startDate = [self _calendarDateForValue:_startDate];
  
  if ((error = [self _validateAptStartDate:startDate]))
    return error;
  
  endDate   = ([_endDate isNotNull])
    ? [self _calendarDateForValue:_endDate]
    : [startDate dateByAddingYears:0 months:0 days:1];
  if ((error = [self _validateAptEndDate:endDate andDuration:0]))
    return error;
  
  company   = _company;
  if ((companies = [self _validateCompanyValue:company]) == nil) {
    NSLog(@"%s: invalid company arguments: %@",
          __PRETTY_FUNCTION__, company);
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                 reason:@"invalid participant/group argument"];
  }
  
  dict = [NSDictionary dictionaryWithObjectsAndKeys:
                       startDate, @"startDate",
                       endDate,   @"endDate",
                       companies, @"companies",
                       nil];
  dict = [NSDictionary dictionaryWithObject:dict forKey:@"qualifier"];

  appointmentDS = [self appointmentDataSource];
  [appointmentDS setFetchSpecification:[self appointmentFSpec:dict]];
  return [appointmentDS fetchObjects];
}

- (id)appointment_getByIdAction:(id)_arg:(NSArray *)_attributes {
  id result;

  result = [self getDocumentById:_arg
		 dataSource:[self appointmentDataSource]
		 entityName:@"Date"
		 attributes:_attributes];
  if (result == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_NOT_FOUND
		 reason:@"did not find appointment with given id"];
  }
  return result;
}

- (NSArray *)appointment_fetchIdsAction:(id)_arg {
  EOFetchSpecification *fspec;
  NSMutableDictionary  *hints;
  EODataSource         *appointmentDS;
  
  appointmentDS = [self appointmentDataSource];
  fspec    = [self appointmentFSpec:_arg];
  hints    = [NSMutableDictionary dictionaryWithDictionary:[fspec hints]];
  [hints setObject:[NSNumber numberWithBool:YES] forKey:@"fetchGlobalIDs"];
  [fspec setHints:hints];
  [fspec setEntityName:@"Date"];
  
  [appointmentDS setFetchSpecification:fspec];
  
  return [[[self commandContext] documentManager]
                 urlsForGlobalIDs:[appointmentDS fetchObjects]];
}

- (NSException *)_validateAptTitle:(NSString *)_value {
  if (![_value isNotNull]) {
    return [self faultWithFaultCode:XMLRPC_FAULT_MISSING_PARAMETER
                 reason:@"Missing 'title' attribute in appointment"];
  }
  if ([_value length] == 0) {
    return [self faultWithFaultCode:XMLRPC_FAULT_MISSING_PARAMETER
                 reason:@"Empty 'title' attribute in appointment"];
  }
  return nil;
}

- (id)appointment_insertAction:(NSDictionary *)_arg {
  EODataSource           *appointmentDS = [self appointmentDataSource];
  SkyAppointmentDocument *appointment   = nil;
  NSException *error;
  int duration = 0;
  
  /* validate title */
  
  if ((error = [self _validateAptTitle:[_arg valueForKey:@"title"]]))
    return error;
  if ((error = [self _validateAptStartDate:[_arg valueForKey:@"startDate"]]))
    return error;
  
  duration = [[_arg valueForKey:@"duration"] intValue];

  error = [self _validateAptEndDate:[_arg valueForKey:@"endDate"]
                andDuration:duration];
  if (error) return error;
  
  if ((appointment = [appointmentDS createObject]) == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INTERNAL_ERROR
                 reason:@"Couldn't create appointment object"];
  }
  
  if (duration != 0) {
    NSMutableDictionary *mDict;
    NSCalendarDate *endDate;
    
    mDict = [_arg mutableCopy];
    endDate = [[_arg valueForKey:@"startDate"] addTimeInterval:duration*60];
    [mDict takeValue:endDate forKey:@"endDate"];
    [self _takeValuesDict:mDict toAppointment:&appointment];
    [mDict release]; mDict = nil;
  }
  else
    [self _takeValuesDict:_arg toAppointment:&appointment];
  
  [appointmentDS insertObject:appointment];
  return appointment;
}

- (id)appointment_updateAction:(id)_arg {
  SkyAppointmentDocument *appointment;
  
  appointment = (SkyAppointmentDocument *)[self getDocumentByArgument:_arg];
  
  if (appointment == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
                 reason:@"No appointment for argument found"];
  }
  
  // TODO: perform some input value validation ... (startDate, endDate, ..)
  
  [self _takeValuesDict:_arg toAppointment:&appointment];
  [[self appointmentDataSource] updateObject:appointment];

  return appointment;
}

- (id)appointment_deleteAction:(id)_arg {
  SkyAppointmentDocument *appointment = nil;

  appointment = (SkyAppointmentDocument *)[self getDocumentByArgument:_arg];

  if (appointment == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
                 reason:@"No appointment for argument found"];
  }
  
  [[self appointmentDataSource] deleteObject:appointment];
  return [NSNumber numberWithBool:YES];
}

- (id)urlStringsForNonEmptyParticipants:(id)_parts {
  if (![_parts isNotNull]) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                 reason:@"No participants supplied"];
  }

  /* Is _parts an array 
     If so there is no way to come out of this clause and proceed,
     we always return something. */
  if ([_parts isKindOfClass:[NSArray class]]) {
    id firstPart;
    
    if (![_parts isNotEmpty]) {
      return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
		   reason:@"No participants supplied"];
    }
    
    firstPart = [_parts objectAtIndex:0];
    
    if ([firstPart isKindOfClass:[NSString class]])
      return _parts;
    
    if ([firstPart isKindOfClass:[NSNumber class]]) {
      /* convert numbers to URLs */
      return [_parts valueForKey:@"stringValue"];
    }
    
    /* treat as dictionary's */
    return [_parts valueForKey:@"id"];
  }

  /* Is _parts a string?  If so then we turn it into a single
     element array and return that. */
  if ([_parts isKindOfClass:[NSString class]])
    return [NSArray arrayWithObjects:&_parts count:1];

  /* Is _parts a dictionary?  If so then we assume it is a
     team document and retrieve the id value from the
     dictionary and store it into a sungle element array. */
  if ([_parts isKindOfClass:[NSDictionary class]]) {
    if ([(_parts = [_parts valueForKey:@"id"]) isNotNull])
      _parts = [NSArray arrayWithObjects:&_parts count:1];
    return _parts;
  }
  
  /* Since nothing so far matches we don't have a bloody clue
     what to do with these parameters, so we throw an exception. */
  [self errorWithFormat:@"unexpected participant parameter type: '%@'",
	NSStringFromClass([_parts class])];
  return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
	       reason:@"Unexpected participants parameter type"];
}

/*
   /brief Set the participants of an appointment
   /param _app
   /param _parts
*/
- (id)appointment_setParticipantsAction:(id)_app:(id)_parts {
  SkyAppointmentDocument *app;
  NSArray                *gids;
  NSMutableArray         *parts;
  int                    i, cnt;
  
  app = (SkyAppointmentDocument *)[self getDocumentByArgument:_app];

  if (app == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
                 reason:@"No appointment for argument found"];
  }

  /* check participants argument */
  
  _parts = [self urlStringsForNonEmptyParticipants:_parts];
  if ([_parts isKindOfClass:[NSException class]])
    return _parts;
  
  /* process URLs */
  
  gids = [[[self commandContext] documentManager] globalIDsForURLs:_parts];
  if ([gids count] == 0) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                 reason:@"No participants supplied"];
  }
  if ([gids containsObject:[NSNull null]]) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                 reason:
		   @"Invalid participant IDs supplied or participant "
		   @"parameter is not a valid URL/ID"];
  }
  
  cnt   = [gids count];
  parts = [NSMutableArray arrayWithCapacity:cnt];
  
  for (i = 0; i < cnt; i++) {
    NSDictionary *part;
    NSString     *cid;
    
    cid  = [[[gids objectAtIndex:i] keyValuesArray] lastObject];
    if (![cid isNotNull]) continue;
    
    part = [[NSDictionary alloc] initWithObjectsAndKeys:cid,@"companyId", nil];
    [parts addObject:part];
    [part release]; part = nil;
  }
  [app setParticipants:parts];
  [app save];

  return app;
}

/*
  \brief Set the resources associated with an appointment
  \param _app An appointment id;  either a string or a number
  \param _resources A list of resources
  \note _resources can be an array of resource ids or a comma
    delimited list of resource ids.
*/
-(id)appointment_setResourcesAction:(id)_app:(id)_resources {
  SkyAppointmentDocument *app;
  NSArray                *resourceNames;
  
  /* If _args is a number convert it to a string */
  if ([_app isKindOfClass:[NSNumber class]])
    _app = [_app stringValue];
  
  /* Retrieve appointment object */
  app = (SkyAppointmentDocument *)[self getDocumentByArgument:_app];
  
  /* Was attempt to retrieve appointment successful */
  if (![app isNotNull]) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
                 reason:@"No appointment for argument found"];
  }
  
  /* Verify resource list */
  if([_resources isKindOfClass:[NSString class]]) {
    resourceNames = [_resources componentsSeparatedByString:@","];
  }
  else if ([_resources isKindOfClass:[NSArray class]]) {
    resourceNames = _resources;
  }
  else {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
		 reason:@"resource list invalid type"];
  }
  
  if ([resourceNames isKindOfClass:[NSArray class]]) {
    /* Verify resource ids */
    if ([resourceNames isNotEmpty]) {
#if 0
      /* Not implemented yet */
        if ((error = [self _validateResources:resourceNames]))
          return error;
#endif
	[app setResourceNames:[resourceNames componentsJoinedByString:@","]];
     } 
    else {
      [app setResourceNames:@""];
    }
    
    [app save];
    return [NSNumber numberWithBool:YES];
  }
  
  return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
               reason:@"cannot make heads or tails of parameter list"];
}

/*
  \brief Set access permissions on an appointment
  \param _reader number or string indicating read access team
  \param _writers number, string, or array indicating write access team(s)
*/
- (id)appointment_setPermissionsAction:(id)_app:(id)_reader:(id)_writers {
  SkyAppointmentDocument *app;
  id                     error;
  
  /* Retrieve appointment object */
  app = (SkyAppointmentDocument *)[self getDocumentByArgument:_app];
  /* Was attempt to retrieve appointment successful */
  if (app == nil) {
    /* NO! */
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
                 reason:@"No appointment for argument found"];
  }

  /* Check reader parameter */
  if ((error = [self _validateTeams:_reader]))
    return error;

  /* Check _writers parameter */
  if ((error = [self _validateTeams:_writers]))
    return error;

  /* If _reader is a number convert it to a string */
  if ([_reader isKindOfClass:[NSNumber class]])
    _reader = [_reader stringValue];

  /* If _writer is a number convert it to a string */
  if ([_writers isKindOfClass:[NSNumber class]])
    _writers = [_reader stringValue];
  /* If _writer is a string convert to a single element array */
  if ([_writers isKindOfClass:[NSString class]])
    _writers = [NSArray arrayWithObjects:&_writers count:1];

  [app setWriteAccess:_writers];
  [app setAccessTeamId:_reader];
  [app save];
  return [NSNumber numberWithBool:YES];
}

- (id)appointment_changeStatusAction:(id)_apt:
  (NSString *)_partstat:(NSString *)_role:
  (NSString *)_comment:(NSNumber *)_rsvp
{
  LSCommandContext    *cmdctx;
  NSMutableDictionary *args;
  
  cmdctx = [self commandContext];
  
  if (![_apt isNotEmpty]) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
		 reason:@"got no appointment to work upon"];
  }
  
  args = [NSMutableDictionary dictionaryWithCapacity:8];
  [args setObject:_apt forKey:@"appointment"];
  
  if (_partstat != nil) [args setObject:_partstat forKey:@"partstatus"];
  if (_role     != nil) [args setObject:_role     forKey:@"role"];
  if (_comment  != nil) [args setObject:_comment  forKey:@"comment"];
  if (_rsvp     != nil) [args setObject:_rsvp     forKey:@"rsvp"];
  
  return [cmdctx runCommand:@"appointment::change-attendee-status"
		 arguments:args];
}

- (id)appointment_acceptAction:(id)_apt {
  return [self appointment_changeStatusAction:_apt:@"ACCEPT":nil:nil:nil];
}
- (id)appointment_declineAction:(id)_apt {
  return [self appointment_changeStatusAction:_apt:@"DECLINED":nil:nil:nil];
}
- (id)appointment_acceptTentativelyAction:(id)_apt {
  return [self appointment_changeStatusAction:_apt:@"TENTATIVE":nil:nil:nil];
}
- (id)appointment_resetStatusAction:(id)_apt {
  return [self appointment_changeStatusAction:
		 _apt:@"NEEDS-ACTION":nil:nil:nil];
}

@end /* DirectAction(Appointment) */
