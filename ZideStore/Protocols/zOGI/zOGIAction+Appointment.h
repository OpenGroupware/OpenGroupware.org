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

#ifndef __zOGIAction_Appointment_H__
#define __zOGIAction_Appointment_H__

#include "zOGIAction.h"

@interface zOGIAction(Appointment)

-(NSDictionary *)_renderAppointment:(NSDictionary *)eoAppointment
                         withDetail:(NSNumber *)_detail;
-(NSArray *)_renderAppointments:(NSArray *)_appointments 
                     withDetail:(NSNumber *)_detail;
-(NSMutableArray *)_getUnrenderedDatesForKeys:(id)_arg;
-(NSMutableDictionary *)_getUnrenderedDateForKey:(id)_arg;
-(id)_getDatesForKeys:(id)_arg 
           withDetail:(NSNumber* )_detail;
-(id)_getDatesForKeys:(id)_arg;
-(id)_getDateForKey:(id)_arg 
         withDetail:(NSNumber* )_detail;
-(id)_getDateForKey:(id)_arg;
-(void)_addNotesToDate:(NSMutableDictionary *)_appointment;
-(void)_addParticipantsToDate:(NSMutableDictionary *)_appointment;
-(void)_addConflictsToDate:(id)_appointment;
-(id)_setParticipantStatus:(id)_pk 
                withStatus:(NSString *)_partstat 
                  withRole:(NSString *)_role
               withComment:(NSString *)_comment 
                  withRSVP:(NSNumber *)_rsvp;
-(id)_searchForAppointments:(NSDictionary *)_query 
                 withDetail:(NSNumber *)_detail
                  withFlags:(NSDictionary *)_flags;
-(id)_createAppointment:(NSDictionary *)_app 
              withFlags:(NSArray *)_flags;
-(id)_updateAppointment:(NSDictionary *)_app 
               objectId:(NSString *)_objectId
              withFlags:(NSArray *)_flags;
-(id)_deleteAppointment:(NSString *)_objectId
              withFlags:(NSArray *)_flags;
-(id)_writeAppointment:(NSDictionary *)_appointment
           withCommand:(NSString *)_command
             withFlags:(NSArray *)_flags;
-(id)_translateParticipants:(NSArray *)_participants;
-(id)_translateAppointment:(NSDictionary *)_appointment
                 withFlags:(NSArray *)_flags;
-(id)_setParticipantStatus:(NSDictionary *)_status
                  objectId:(NSString *)_objectId
                 withFlags:(NSArray *)_flags;

@end

#endif /* __zOGIAction_Appointment_H__ */
