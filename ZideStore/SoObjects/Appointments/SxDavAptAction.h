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
// $Id: SxDavAptAction.h 1 2004-08-20 11:17:52Z znek $

#ifndef __Appointments_SxDavAptAction_H__
#define __Appointments_SxDavAptAction_H__

#include "SxDavAction.h"

@class NSString, NSException, NSDictionary;
@class SxAppointment;

@interface SxDavAptAction : SxDavAction
{
}

- (id)initWithName:(NSString *)_name properties:(NSDictionary *)_props
  forAppointment:(SxAppointment *)_apt;

/* accessors */

- (SxAppointment *)appointment;
- (NSString *)expectedMessageClass;

/* mapping */

- (NSString *)accessClassForDavProp:(id)_sens;

/* common attribute processors */

- (NSException *)addParticipantsInContext:(id)_ctx;
- (NSException *)processTitleInContext:(id)_ctx;
- (NSException *)processAppointmentRangeInContext:(id)_ctx;
- (NSException *)processReminderInContext:(id)_ctx;
- (NSException *)processOnlineMeetingInContext:(id)_ctx;
- (NSException *)processAssociatedContactsInContext:(id)_ctx;
- (NSException *)processKeywordsInContext:(id)_ctx;
- (NSException *)processFBTypeInContext:(id)_ctx;


@end /* SxDavAptAction */

#endif /* __Appointments_SxDavAptAction_H__ */
