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

/*
  LSGetCompanyForMemberCommand
  
  Used to retrieve teams for an account and other company<->company
  relationships.
  
  Note: the members must not be immutable dictionaries! The commands sets some
        values in them.
*/

@class NSArray, NSString, NSNumber;

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
