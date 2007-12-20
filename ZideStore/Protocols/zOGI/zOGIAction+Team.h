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

#ifndef __zOGIAction_Team_H__
#define __zOGIAction_Team_H__

#include "zOGIAction.h"

@interface zOGIAction(Team)

-(NSArray *)_renderTeams:(NSArray *)_teams withDetail:(NSNumber *)_detail;
-(id)_getUnrenderedTeamsForKeys:(id)_arg;
-(id)_getTeamsForKeys:(id)_arg withDetail:(NSNumber *)_detail;
-(id)_getTeamForKey:(id)_arg withDetail:(NSNumber *)_detail;
-(void)_addContactsToTeam:(NSMutableDictionary *)_team;
-(NSArray *)_getTeamMembers:(id)_team;
-(NSArray *)_searchForTeams:(id)_arg 
                 withDetail:(NSNumber *)_detail
                 withFlags:(NSDictionary *)_flags;
-(id)_updateTeam:_dictionary
        objectId:_objectId
       withFlags:_flags;
@end

#endif /* __zOGIAction_Team_H__ */
