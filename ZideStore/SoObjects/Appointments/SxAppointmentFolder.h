/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id: SxAppointmentFolder.h 1 2004-08-20 11:17:52Z znek $

#ifndef __Appointments_SxAppointmentFolder_H__
#define __Appointments_SxAppointmentFolder_H__

#include "SxFolder.h"

/*
  SxAppointmentFolder
  
  This class is a virtual folder on the appointment/meeting database. The
  selection is made based on the "read access group" in SKYRiX. That is,
  each group will have a virtual folder and each individual will have a
  private folder (if the read access group is not set [private meeting]).
*/

@class NSCalendarDate;
@class SxAptSetIdentifier;

@interface SxAppointmentFolder : SxFolder
{
  NSString *group;
  BOOL     overview;
}

/* accessors */

- (void)setGroup:(NSString *)_group;
- (NSString *)group;

- (void)setIsOverview:(BOOL)_flag;
- (BOOL)isOverview;

- (SxAptSetIdentifier *)aptSetID;

- (NSCalendarDate *)defaultStartDate;
- (NSCalendarDate *)defaultEndDate;

@end

#endif /* __Appointments_SxAppointmentFolder_H__ */
