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

#import <OGoFoundation/LSWEditorPage.h>

@interface LSWFolderEditor : LSWEditorPage
{
@private
  id parentFolder;
  id project;
}

- (void)setParentFolder:(id)_folder;
- (void)setProject:(id)_project;

@end

#import "common.h"

@implementation LSWFolderEditor

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->parentFolder);
  RELEASE(self->project);
  [super dealloc];
}
#endif

- (BOOL)prepareForEditCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id pj = [[self object] valueForKey:@"project"];

  if (pj != nil)
    ASSIGN(self->project, pj);

  return YES;
}

// accessors

- (NSMutableDictionary *)folder {
  return [self snapshot];
}

- (void)setParentFolder:(id)_folder { 
  ASSIGN(self->parentFolder, _folder);
}
- (id)parentFolder {
  return self->parentFolder;
}

- (void)setProject:(id)_project { 
  ASSIGN(self->project, _project);
}
- (id)project {
  return self->project;
}

- (BOOL)isContactAttrEnabled {
  return [[[self session] userDefaults]
                 boolForKey:@"SkyEnableContactAttrInDocuments"];
}

- (NSString *)insertNotificationName {
  return LSWNewFolderNotificationName;
}
- (NSString *)updateNotificationName {
  return LSWUpdatedFolderNotificationName;
}

//actions

- (BOOL)checkConstraints {
  NSMutableString *error  = [NSMutableString stringWithCapacity:128];
  NSString        *pTitle = [[self folder] valueForKey:@"title"];
  
  if (![pTitle isNotNull] || [pTitle length] == 0)
    [error appendString:@" No folder name set."];

  if ([error length] > 0) {
    [self setErrorString:error];
    return YES;
  }
  else {
    [self setErrorString:nil];
    return NO;
  }
}

- (BOOL)checkConstraintsForSave {
  return ![self checkConstraints];
}

- (id)insertObject {
  WOSession *sn       = [self session];
  id        accountId = [[sn activeAccount] valueForKey:@"companyId"];
  id        folder    = [self snapshot];
  
  [folder takeValue:accountId forKey:@"firstOwnerId"];
  [folder takeValue:accountId forKey:@"currentOwnerId"];
  [folder takeValue:[NSNumber numberWithBool:YES] forKey:@"isFolder"];
  [folder takeValue:self->parentFolder forKey:@"folder"];
  [folder takeValue:self->project forKey:@"project"];
  
  return [self runCommand:@"doc::new" arguments:folder];
}

- (id)updateObject {
  WOSession *sn       = [self session];
  id        accountId = [[sn activeAccount] valueForKey:@"companyId"];
  id        folder    = [self snapshot];

  [folder takeValue:accountId forKey:@"currentOwnerId"];

  if (self->project)
    [folder takeValue:self->project forKey:@"project"];

  return [self runCommand:@"doc::set-folder" arguments:folder];
}

- (id)deleteObject {
  id result = [[self object] run:@"doc::delete",
                               @"reallyDelete", [NSNumber numberWithBool:YES],
                               nil];
  if (result) {
    if (![self commit]) {
      [self rollback];
      [self setErrorString:@"Couldn't commit document deletion !"];
      return nil;
    }
  }
  return result;
}

@end

