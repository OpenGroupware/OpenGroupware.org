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
// $Id: SxContactManager.h 1 2004-08-20 11:17:52Z znek $

#ifndef __Backend_SxContactManager_H__
#define __Backend_SxContactManager_H__

#include <Backend/SxBackendManager.h>

/*
  SxContactManager, SxContactSetIdentifier
  
*/

@class NSEnumerator, NSDictionary, NSArray, NSNumber;
@class EOGlobalID;
@class WOResponse;

/* in the moment it's intended that this doesn't deal with groups ! */
@interface SxContactSetIdentifier : NSObject
{
  BOOL public;
  BOOL enterprises;
  BOOL accounts;
  BOOL groups;
}

+ (id)publicPersons;
+ (id)privatePersons;
+ (id)accounts;
+ (id)groups;
+ (id)publicEnterprises;
+ (id)privateEnterprises;

/* accessors */

- (BOOL)isGroupSet;
- (BOOL)isPublicSet;
- (BOOL)isEnterpriseSet;
- (BOOL)isAccountSet;

- (NSString *)cachePrefixInContext:(id)_ctx;

@end /* SxContactSetIdentifier */

@interface SxContactManager : SxBackendManager
{
}

/* list queries, returns: pkey, sn, givenname */

- (NSEnumerator *)listContactSet:(SxContactSetIdentifier *)_sid;

- (NSEnumerator *)listAccountsForGroup:(id)_group;
- (NSEnumerator *)listAccountsWithEmail:(NSString *)_eml;
- (NSEnumerator *)listAccountsWithEmails:(NSArray *)_emls;
- (NSEnumerator *)listGroupsWithEmails:(NSArray *)_emls;
- (NSEnumerator *)listPublicPersonsWithEmails:(NSArray *)_emls;
- (NSEnumerator *)listPrivatePersonsWithEmails:(NSArray *)_emls;

- (NSEnumerator *)listGroups;

/* evo searches, returns: [lookup in query class header] */

// prefix of "cn", "sn", "fileas"

- (NSDictionary *)fullPersonInfoForPrimaryKey:(NSNumber *)_pkey;
- (NSDictionary *)fullEnterpriseInfoForPrimaryKey:(NSNumber *)_pkey;
- (NSDictionary *)fullGroupInfoForPrimaryKey:(NSNumber *)_pkeys;
- (NSArray *)fullPersonInfosForPrimaryKeys:(NSArray *)_pkeys;
- (NSArray *)fullEnterpriseInfosForPrimaryKeys:(NSArray *)_pkeys;

// Returns a string in the format: (id:version\n)*
- (NSString *)idsAndVersionsCSVForContactSet:(SxContactSetIdentifier *)_set;
- (int)generationOfContactSet:(SxContactSetIdentifier *)_set;
- (int)countOfContactSet:(SxContactSetIdentifier *)_set;

- (NSArray *)fullObjectInfosForPrimaryKeys:(NSArray *)_pkeys
  withSetIdentifier:(SxContactSetIdentifier *)_ident;

@end /* SxContactManager */

@interface SxContactManager(vCard)

- (NSEnumerator *)idsAndVersionsAndVCardsForGlobalIDs:(NSArray *)_gids;
- (NSEnumerator *)idsAndVersionsAndVCardsForContactSet:
  (SxContactSetIdentifier *)_set;

@end /* SxContactManager(vCard) */

@interface SxContactManager(Evo)

- (NSEnumerator *)evoContactsWithPrefix:(NSString *)_prefix 
  inContactSet:(SxContactSetIdentifier *)_sid;
- (NSEnumerator *)evoAccountsForGroup:(NSString *)_grp prefix:(NSString *)_pre;
- (NSEnumerator *)evoGroupsWithPrefix:(NSString *)_prefix;

@end /* SxContactManager(Evo) */

@interface SxContactManager(Zl)

- (NSEnumerator *)zlContactsWithPrefix:(NSString *)_prefix 
  inContactSet:(SxContactSetIdentifier *)_sid;
- (NSEnumerator *)zlAccountsForGroup:(NSString *)_grp prefix:(NSString *)_pre;
- (NSEnumerator *)zlGroupsWithPrefix:(NSString *)_prefix;

@end /* SxContactManager(Evo) */
#endif /* __Backend_SxContactManager_H__ */
