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
//$Id: SkyAccountApplication.h 5 2004-08-20 23:20:26Z helge $

#include <OGoDaemon/SDApplication.h>

@class NSMutableDictionary;

@interface SkyAccountApplication : SDApplication
{
  NSMutableDictionary *login2AccountCache;
  NSMutableDictionary *uid2AccountCache;
  NSMutableDictionary *name2GroupCache;
  NSMutableDictionary *gid2GroupCache;
  NSMutableDictionary *gid2AccountCache;
  NSMutableDictionary *uid2GroupCache;
}
- (void)initCache;

- (NSArray *)allGroups;
- (NSDictionary *)groupById:(NSString *)_id;
- (NSDictionary *)groupByName:(NSString *)_name;

- (NSArray *)accountsForGroup:(NSString *)_id;
- (NSArray *)groupsForAccount:(NSString *)_id;
  
- (NSDictionary *)accountById:(NSString *)_id;
- (NSDictionary *)accountByLogin:(NSString *)_i;

- (void)insertAccount:(NSMutableDictionary *)_account;
- (void)flushCachesForLogin:(NSString *)_login;

- (void)insertGroup:(NSMutableDictionary *)_group;
- (void)flushCachesForGroupName:(NSString *)_name;

- (void)flushCachesForUid:(NSString *)_uid;
- (void)flushCachesForGid:(NSString *)_gid;
- (void)removeAccountFromGroupCache:(NSString *)_uid;
- (void)removeGroupFromAccountsCache:(NSString *)_gid;

- (void)addAccounts:(NSArray *)_accounts toGroup:(NSString *)_id;
- (void)removeAccounts:(NSArray *)_accounts fromGroup:(NSString *)_id;
@end
