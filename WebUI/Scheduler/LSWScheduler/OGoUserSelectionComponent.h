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

#ifndef __OGoUserSelectionComponent_H__
#define __OGoUserSelectionComponent_H__

#include <OGoFoundation/OGoComponent.h>

/*
  OGoUserSelectionComponent

  NOTE: this was introduced to refactor SkyParticipantsSelection and make the
        functionality available to other components.

  TODO: document

  Subclasses:
    SkyParticipantsSelection
    OGoAttendeeSelection

  Bindings
    participants         [in/out] array
    selectedParticipants [out]    array
    onlyAccounts         [in/out] bool
    searchLabel          [in/out] string
    isClicked            [in/out] bool
    TODO: incomplete?
  
  TODO: why are there two bindings for the participants?
        'selectedParticipants' is an out parameter and returns
        EOs based on the 'participants' (potentially resolving
        teams if configured so).
*/

@class NSString, NSArray, NSMutableArray;

@interface OGoUserSelectionComponent : OGoComponent
{
  NSMutableArray *participants;
  NSMutableArray *resultList;

  NSArray  *selectedParticipantsCache;
  NSString *searchText;
  id       searchTeam;
  id       item;

  NSString *searchLabel;

  struct {
    int showExtended:1;
    int onlyAccounts:1;
    int isClicked:1;
    int resolveTeams:1;
    int reserved:28;
  } uscFlags;
}

/* accessors */

- (NSArray *)participants;

/* actions */

- (id)search;

@end

#endif /* __OGoUserSelectionComponent_H__ */
