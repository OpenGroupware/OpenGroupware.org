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

#include <OGoFoundation/LSWContentPage.h>

@class NSUserDefaults, NSString, NSNumber, NSArray;

@interface LSWProjectPreferences : LSWContentPage
{
  id             account;
  NSUserDefaults *defaults;
  NSString       *projectSubview;
  NSString       *projectsSubview;
  NSNumber       *blockSize;
  NSString       *noOfCols;
  NSArray        *dockedProjects;
  BOOL           isProjectSubviewEditable;
  BOOL           isProjectsSubviewEditable;
  BOOL           isBlockSizeEditable;
  BOOL           isNoOfColsEditable;
  BOOL           isDockedProjectsEditable;
  BOOL           isRoot;
}

@end

#include "common.h"

@implementation LSWProjectPreferences

- (void)dealloc {
  [self->account         release];
  [self->defaults        release];
  [self->projectSubview  release];
  [self->projectsSubview release];
  [self->noOfCols        release];
  [self->blockSize       release];
  [self->dockedProjects  release];
  [super dealloc];
}

/* notifications */

- (void)awake {
  [super awake];
  self->isRoot = [[self session] activeAccountIsRoot];
}

/* accessors */

- (BOOL)isEditorPage {
  return YES;
}

- (BOOL)_isEditable:(NSString *)_defName {
  id obj;

  _defName = [@"rootAccess" stringByAppendingString:_defName];
  obj = [self->defaults objectForKey:_defName];

  return obj ? [obj boolValue] : YES;
}

- (void)_getDockedProjectsOfAccount:(id)_account {
  NSString       *entityName;
  NSArray        *projectIds;
  NSArray        *projects = nil;
  NSMutableArray *gIDs;
  int            i, cnt;

  entityName = @"Project";
  projectIds = [self->defaults arrayForKey:@"docked_projects"];
  cnt        = [projectIds count];
  gIDs       = [[NSMutableArray alloc] initWithCapacity:cnt];

  for (i=0; i<cnt; i++) {
    EOKeyGlobalID *gID;
    NSString      *projectId;

    projectId = [projectIds objectAtIndex:i];

    gID = [EOKeyGlobalID globalIDWithEntityName:entityName
                         keys: &projectId
                         keyCount:1
                         zone:[self zone]];
    [gIDs addObject:gID];
  }

  projects = [self runCommand:@"project::get-by-globalid",
                   @"gids", gIDs, nil];

  ASSIGN(self->dockedProjects, projects);
  RELEASE(gIDs);
}

- (void)setAccount:(id)_account {
  NSUserDefaults *ud;
  
  RELEASE(self->defaults);        self->defaults        = nil;
  RELEASE(self->projectSubview);  self->projectSubview  = nil;
  RELEASE(self->projectsSubview); self->projectsSubview = nil;
  RELEASE(self->noOfCols);        self->noOfCols        = nil;
  RELEASE(self->blockSize);       self->blockSize       = nil;
  
  ASSIGN(self->account, _account);
  
  ud = _account
    ? [self runCommand:@"userdefaults::get",
              @"user", _account, nil]
    : [self runCommand:@"userdefaults::get", nil];

  self->defaults = RETAIN(ud);

  self->projectSubview =
      [[self->defaults stringForKey:@"skyp4_projectviewer_tab"] copy];
  self->projectsSubview =
      [[self->defaults stringForKey:@"skyp4_desktop_tab"] copy];
  self->blockSize = [self->defaults objectForKey:@"projects_blocksize"];
  self->noOfCols  = [self->defaults stringForKey:@"projects_no_of_cols"];
  [self _getDockedProjectsOfAccount:_account];
  RETAIN(self->blockSize);
  RETAIN(self->noOfCols);

  self->isBlockSizeEditable = [self _isEditable:@"projects_blocksize"];
  self->isNoOfColsEditable = [self _isEditable:@"projects_no_of_cols"];
  self->isProjectSubviewEditable = [self _isEditable:@"project_sub_view"];
  self->isProjectsSubviewEditable = [self _isEditable:@"projects_sub_view"];
  self->isDockedProjectsEditable  = [self _isEditable:@"docked_projects"];
}
- (id)account {
  return self->account;
}

- (NSString *)accountLabel {
  return [[self session] labelForObject:[self account]];
}

- (void)setNoOfCols:(NSString *)_number {
  ASSIGN(self->noOfCols, _number);
}
- (NSString *)noOfCols {
  return self->noOfCols;
}

- (void)setIsNoOfColsEditableRoot:(BOOL)_flag {
  if (self->isRoot) {
    self->isNoOfColsEditable = _flag;
  }
}
- (BOOL)isNoOfColsEditable {
  return self->isNoOfColsEditable || self->isRoot;
}

- (void)setBlockSize:(NSNumber *)_number {
  ASSIGN(self->blockSize, _number);
}
- (NSNumber *)blockSize {
  return self->blockSize;
}

- (void)setIsBlockSizeEditableRoot:(BOOL)_flag {
  if (self->isRoot) {
    self->isBlockSizeEditable = _flag;
  }
}
- (BOOL)isBlockSizeEditable {
  return self->isBlockSizeEditable || self->isRoot;
}

- (void)setIsDockedProjectsEditableRoot:(BOOL)_flag {
  if (self->isRoot) {
    self->isDockedProjectsEditable = _flag;
  }
}
- (BOOL)isDockedProjectsEditable {
  return self->isDockedProjectsEditable || self->isRoot;
}


- (BOOL)isRoot {
  return self->isRoot;
}

- (BOOL)isProjectsSubviewEditable {
  return self->isProjectsSubviewEditable || self->isRoot;
}
- (BOOL)isProjectsSubviewEditableRoot {
  return self->isProjectsSubviewEditable;
}
- (void)setIsProjectsSubiewEditableRoot:(BOOL)_flag {
  if (self->isRoot)
    self->isProjectsSubviewEditable = _flag;
}

- (BOOL)isProjectSubviewEditable {
  return self->isProjectSubviewEditable || self->isRoot;
}

- (void)setIsProjectSubiewEditableRoot:(BOOL)_flag {
  if (self->isRoot)
    self->isProjectSubviewEditable = _flag;
}

- (NSString *)projectSubview {
  return self->projectSubview;
}
- (void)setProjectSubview:(NSString *)_subview {
  ASSIGN(self->projectSubview, _subview);
}

- (NSString *)projectsSubview {
  return self->projectsSubview;
}
- (void)setProjectsSubview:(NSString *)_subview {
  ASSIGN(self->projectsSubview, _subview);
}

- (void)setDockedProjects:(NSArray *)_dockedProjects {
  ASSIGN(self->dockedProjects, _dockedProjects);
}
- (NSArray *)dockedProjects {
  return self->dockedProjects;
}

/* actions */

- (id)cancel {
  [self leavePage];
  return nil;
}

- (id)save {
  id uid;

  uid = [[self account] valueForKey:@"companyId"];

  if ([self isProjectSubviewEditable]) {
    [self runCommand:@"userdefaults::write",
            @"key",      @"project_sub_view",
            @"value",    [self projectSubview],
            @"defaults", self->defaults,
            @"userId",   uid,
            nil];
  }
  if ([self isBlockSizeEditable]) {
    id tmp;

    tmp = [self blockSize];

    if ([tmp isNotNull]) {
      [self runCommand:@"userdefaults::write",
            @"key",      @"projects_blocksize",
            @"value",    tmp,
            @"defaults", self->defaults,
            @"userId",   uid,
            nil];
    }
  }
  if ([self isNoOfColsEditable]) {
    [self runCommand:@"userdefaults::write",
            @"key",      @"projects_no_of_cols",
            @"value",    [self noOfCols],
            @"defaults", self->defaults,
            @"userId",   uid,
            nil];
  }
  if ([self isProjectsSubviewEditable]) {
    [self runCommand:@"userdefaults::write",
            @"key",      @"projects_sub_view",
            @"value",    [self projectsSubview],
            @"defaults", self->defaults,
            @"userId",   uid,
            nil];
  }
  if ([self isDockedProjectsEditable]) {
    [self runCommand:@"userdefaults::write",
            @"key",      @"docked_projects",
            @"value",    [self->dockedProjects valueForKey:@"projectId"],
            @"defaults", self->defaults,
            @"userId",   uid,
            nil];
    [(LSWSession *)[self session] fetchDockedProjectInfos];
  }

  [self postChange:LSWUpdatedAccountNotificationName onObject:[self account]];
  
  return [self leavePage];
}

@end
