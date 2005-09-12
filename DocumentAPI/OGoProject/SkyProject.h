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

#ifndef __SkyProjectDoc_H__
#define __SkyProjectDoc_H__

/*
  SkyProject
  
  A document object representing an OGo project.

  TODO: comment?

  Keys:
    type        project-type
    projectId   primary-key
    leaderName  (login of leader)
    accounts    (array of ???)
    url         string
    leader      SkyAccountDocument of "leader" account
    team        SkyDocument of team (what team?)
    status      string

  DataSources / FileManager:
    teamDataSource
    documentDataSource
    fileManager

  Methods:
    addAccount:withAccess:
    removeAccount:withAccess:
  
  This is really an SkyProjectDocument object, but the name was already given
  to documents *contained* in the SkyProject filesystem ...
*/

#include <OGoDocuments/SkyDocument.h>

@class NSCalendarDate, NSString, NSDictionary, NSArray, NSNumber;
@class NSMutableDictionary, NSMutableArray;
@class SkyProjectDataSource;
@class EODataSource;
@class LSCommandContext;

#ifndef XMLNS_PROJECT_DOCUMENT
#define XMLNS_PROJECT_DOCUMENT \
  @"http://www.skyrix.com/namespaces/project-document"
#endif

@interface SkyProject : SkyDocument
{
  SkyProjectDataSource *dataSource;
  NSString             *name;
  NSCalendarDate       *startDate;
  NSCalendarDate       *endDate;
  NSString             *number;
  SkyDocument          *leader;
  SkyDocument          *team;
  NSString             *kind;
  NSString             *type;
  NSString             *url;
  NSString             *projectStatus;         // status
  NSArray              *companyAssignmentsIds; // assigned companyIds
  EOGlobalID           *globalID;

  NSArray              *projectAccounts;
  
  NSMutableDictionary  *accounts;        // accounts/teams mapped to access
  NSMutableArray       *removedAccounts; // accounts/teams
                                         // removed from assignment

  NSMutableDictionary *properties;

  struct {
    BOOL isEdited;
    BOOL isValid;
    BOOL isComplete;
  } status;
}

- (id)initWithContext:(LSCommandContext *)_ctx;
- (id)initWithEO:(id)_eo dataSource:(SkyProjectDataSource *)_ds;

- (void)invalidate;
- (BOOL)isValid;

/* accessors */

- (void)setName:(NSString *)_name;
- (NSString *)name;

- (void)setStartDate:(NSCalendarDate *)_startDate;
- (NSCalendarDate *)startDate;

- (void)setEndDate:(NSCalendarDate *)_endDate;
- (NSCalendarDate *)endDate;

- (void)setNumber:(NSString *)_number;
- (NSString *)number;

- (void)setUrl:(NSString *)_url;
- (NSString *)url;

- (void)setKind:(NSString *)_kind;
- (NSString *)kind;

- (void)setLeader:(SkyDocument *)_leader;
- (SkyDocument *)leader;

- (void)setTeam:(SkyDocument *)_team;
- (SkyDocument *)team;

- (void)setStatus:(NSString *)_status;
- (NSString *)status;

- (void)setProperties:(NSDictionary *)_properties;
- (NSDictionary *)properties;

- (void)setProjectAccounts:(NSArray *)_accounts;

// used by SkyProjectTeamDataSource, etc.
- (NSArray *)companyAssignmentsIds;
- (EODataSource *)teamDataSource;

// rwid
// changes will take efect after save
- (void)addAccount:(SkyDocument *)_account withAccess:(NSString *)_access;
- (void)removeAccount:(SkyDocument *)_account;


- (id)fileManager;
- (id)documentDataSource;
- (NSNumber *)projectId;

- (NSDictionary *)asDict;

@end

#endif /* __SkyProjectDoc_H__ */
