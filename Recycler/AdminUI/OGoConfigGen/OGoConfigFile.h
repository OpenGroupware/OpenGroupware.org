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

#ifndef __OGoConfigFile_H__
#define __OGoConfigFile_H__

#import <Foundation/NSObject.h>

@class NSString, NSUserDefaults, NSArray;
@class EOGlobalID;
@class OGoConfigDatabase;
@class LSCommandContext;

@interface OGoConfigFile : NSObject
{
  OGoConfigDatabase *database;
  NSString          *path;
}

/* accessors */

- (NSString *)name;
- (NSString *)configType;
- (EOGlobalID *)globalID;

/* some common operations */

- (NSUserDefaults *)defaultsForAccount:(id)_account
  inContext:(LSCommandContext *)_ctx;
- (NSUserDefaults *)defaultsForTeam:(id)_team
  inContext:(LSCommandContext *)_ctx;

- (BOOL)shouldExportAccount:(id)_account inContext:(LSCommandContext *)_ctx;
- (BOOL)shouldExportTeam:(id)_team inContext:(LSCommandContext *)_ctx;

/* common fetch operations */

- (NSArray *)fetchTeamGlobalIDsInContext:(LSCommandContext *)_ctx;
- (NSArray *)fetchTeamEmailsForGlobalIDs:(NSArray *)_gids 
  inContext:(LSCommandContext *)_ctx;
- (NSArray *)fetchAllTeamEOsInContext:(LSCommandContext *)_ctx;

- (NSArray *)fetchAllAccountEOsInContext:(LSCommandContext *)_ctx;
- (NSArray *)fetchAccountGlobalIDsInContext:(LSCommandContext *)_ctx;
- (NSArray *)fetchAccountLoginsForGlobalIDs:(NSArray *)_gids 
  inContext:(LSCommandContext *)_ctx;
- (NSArray *)fetchAccountGlobalIDsForTeamGlobalID:(EOGlobalID *)_gid 
  inContext:(LSCommandContext *)_ctx;

/* factory */

+ (id)loadEntryFromPath:(NSString *)_p configDatabase:(OGoConfigDatabase *)_db;

@end

#endif /* __OGoConfigFile_H__ */
