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

#ifndef __LSLogic_LSAddress_LSGetCompanyForMemberCommand_H__
#define __LSLogic_LSAddress_LSGetCompanyForMemberCommand_H__

#include <LSFoundation/LSDBObjectBaseCommand.h>

@class NSArray, NSString, NSNumber;

/**
 * @class LSGetCompanyForMemberCommand
 *
 * Retrieves the group/parent companies for a set of member
 * companies. Primarily used to look up team memberships for
 * accounts and enterprise-to-person relationships.
 *
 * Concrete subclasses:
 *   - LSGetTeamForAccountCommand (team membership)
 *   - LSGetEnterpriseForPersonCommand
 *
 * Accepts one or more member objects via @c setMember: or
 * @c setMembers: and returns the associated groups sorted
 * by description. Supports batched SQL queries and can
 * optionally return global IDs instead of full objects when
 * @c fetchGlobalIDs is set.
 *
 * @note The member objects must be mutable, as the command
 *       sets relationship values on them.
 */
@interface LSGetCompanyForMemberCommand : LSDBObjectBaseCommand
{
@private
  NSArray  *members;
  NSString *relationKey;
  BOOL     fetchGlobalIDs;
  NSNumber *fetchForOneObject;
}

// accessors

- (void)setMember:(id)_member;
- (id)member;

- (void)setMembers:(NSArray *)_members;
- (NSArray *)members;

- (NSString *)groupEntityName;

- (NSString *)relationKey;

@end

#endif /* __LSLogic_LSAddress_LSGetCompanyForMemberCommand_H__ */
