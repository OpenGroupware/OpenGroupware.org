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
// $Id$

#ifndef __LSWScheduler_LSWAppointmentEditor_Fetches_H__
#define __LSWScheduler_LSWAppointmentEditor_Fetches_H__

#include "LSWAppointmentEditor.h"

@class NSArray;

@interface LSWAppointmentEditor(Fetches)

- (void)_fetchEnterprisesOfPersons:(NSArray *)_persons;
- (NSArray *)_fetchTeams;
- (NSArray *)_fetchPersonsForGIDs:(NSArray *)_gids;
- (NSArray *)_fetchTeamsForGIDs:(NSArray *)_gids;
- (NSArray *)_fetchParticipantsOfAppointment:(id)_apt force:(BOOL)_force;

- (NSString *)_getCommentOfAppointment:(id)_apt;

- (id)_fetchAccountForPrimaryKey:(id)_pkey;
- (id)_fetchAccountOrTeamForPrimaryKey:(id)_pkey;

- (id)_fetchAppointmentForPrimaryKey:(id)_pkey;
- (NSArray *)_fetchCyclicAppointmentsOfAppointment:(id)_apt;

@end

#endif /* __LSWScheduler_LSWAppointmentEditor_Fetches_H__ */
