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

#ifndef __LSScheduler_LSNewAppointmentCommand_H__
#define __LSScheduler_LSNewAppointmentCommand_H__

#include <LSFoundation/LSDBObjectNewCommand.h>

/*
  LSNewAppointmentCommand (appointment::new)

  Subclasses:
    LSNewAppointmentFromVEventCommand
*/

@class NSNumber;

@interface LSNewAppointmentCommand : LSDBObjectNewCommand
{
@private
  NSNumber *isWarningIgnored;
  NSString *comment;
  NSArray  *participants;
}

- (void)setComment:(NSString *)_comment;
- (NSString *)comment;
- (void)setIsWarningIgnored:(NSNumber *)_isWarningIgnored;
- (NSNumber *)isWarningIgnored;

- (void)setParticipants:(NSArray *)_participants;
- (NSArray *)participants;

- (void)setCycleEndDateFromString:(NSString *)_cycleEndDateString;

@end 

/* TODO: this shares a lot of copy/paste code with LSSetAppointmentCommand! */

#endif /* __LSScheduler_LSNewAppointmentCommand_H__ */
