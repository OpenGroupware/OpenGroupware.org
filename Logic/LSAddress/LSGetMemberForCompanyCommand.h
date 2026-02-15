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

#ifndef __LSLogic_LSAddress_LSGetMemberForCompanyCommand_H__
#define __LSLogic_LSAddress_LSGetMemberForCompanyCommand_H__

#include <LSFoundation/LSDBObjectBaseCommand.h>

@class NSArray, NSString;

/**
 * @class LSGetMemberForCompanyCommand
 *
 * Retrieves the member companies (sub-companies) belonging
 * to one or more group/parent companies. This is the
 * inverse of LSGetCompanyForMemberCommand.
 *
 * Concrete subclasses:
 *   - LSGetMemberForTeamCommand (team::members)
 *   - LSGetMemberForEnterpriseCommand
 *
 * Accepts one or more group objects via @c setGroup: or
 * @c setGroups: and returns their member records. Excludes
 * archived members (dbStatus). Supports batched SQL queries
 * and optional global-ID-only fetching.
 */
@interface LSGetMemberForCompanyCommand : LSDBObjectBaseCommand
{
@private
  NSArray *groups;
  BOOL    fetchGlobalIDs;
}

// accessors

- (void)setGroup:(id)_group;
- (id)group;

- (void)setGroups:(NSArray *)_groups;
- (NSArray *)groups;

- (NSString *)memberEntityName;
@end

#endif /* __LSLogic_LSAddress_LSGetMemberForCompanyCommand_H__ */
