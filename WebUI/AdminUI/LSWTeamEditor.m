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

#include <OGoFoundation/LSWEditorPage.h>

@class NSString, NSMutableArray;

@interface LSWTeamEditor : LSWEditorPage
{
@protected
  NSMutableArray *assignedAccounts;
  NSMutableArray *resultList;
  NSMutableArray *addedAccounts;
  NSMutableArray *removedAccounts;
  NSString       *searchText;
  id             item;
  id             defaults;
}

@end

#include "common.h"
#include <OGoFoundation/LSWNotifications.h>

@implementation LSWTeamEditor

- (id)init {
  if ((self = [super init])) {
    self->assignedAccounts = [[NSMutableArray alloc] init];
    self->addedAccounts    = [[NSMutableArray alloc] init];
    self->removedAccounts  = [[NSMutableArray alloc] init];
    self->resultList       = [[NSMutableArray alloc] init];
    self->searchText       = [[NSString       alloc] init];
  }
  return self;
}

- (void)dealloc {
  [self->assignedAccounts release];
  [self->addedAccounts    release];
  [self->removedAccounts  release];
  [self->resultList       release];
  [self->searchText       release];
  [self->item             release];
  [self->defaults         release];
  [super dealloc];
}

/* activation */

- (BOOL)prepareForEditCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id obj;

  obj = [self object]; 

  [self runCommand:
        @"team::members",
        @"object",     obj,
        @"returnType", intObj(LSDBReturnType_ManyObjects), 
        nil];
  [self->assignedAccounts addObjectsFromArray:[obj valueForKey:@"members"]];

  [self->defaults release]; self->defaults = nil;
  self->defaults = [[self runCommand:@"userdefaults::get", @"user", obj, nil]
                          retain];
  return YES;
}

/* setup */

- (void)_setLabelForAccount:(id)_part {
  id        p = _part;
  NSString *d = nil;
  
  if ((d = [p valueForKey:@"name"]) == nil) {
    if ((d = [p valueForKey:@"login"]) == nil) {
      if ((d = [p valueForKey:@"description"]) == nil) {
        d = [NSString stringWithFormat:@"pkey<%@>",
                      [p valueForKey:@"companyId"]];
      }
    }
  }
  else {
    NSString *fd = [p valueForKey:@"firstname"];
    
    if (fd)
      d = [NSString stringWithFormat:@"%@, %@", d, fd];
  }
  [p takeValue:d forKey:@"fullNameLabel"];
}

- (void)_updateAccountList:(NSArray *)_list {
  NSEnumerator *partEnum;
  id           part;
  
  partEnum =  [_list objectEnumerator];
  while ((part = [partEnum nextObject]))
    [self _setLabelForAccount:part];
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];
  // this must be run *before* -takeValuesFromRequest:inContext: is called
  self->item       = nil;
  [self->removedAccounts removeAllObjects];
  [self->addedAccounts   removeAllObjects];
}

- (void)syncSleep {
  // reset transient variables
  self->item       = nil;
  [self->removedAccounts removeAllObjects];
  [self->addedAccounts   removeAllObjects];
  [super syncSleep];
}

- (void)_processSelectedAccounts {
  int i, count;
  
  for (i = 0, count = [self->addedAccounts count]; i < count; i++) {
    id  account;
    id  pkey;
    int j, count2;

    account = [self->addedAccounts objectAtIndex:i];
    pkey        = [account valueForKey:@"companyId"];

    if (pkey == nil) {
      NSLog(@"ERROR(%@): invalid pkey of account %@", self, account);
      continue;
    }

    for (j = 0, count2 = [self->assignedAccounts count]; j < count2; j++) {
      id opkey;

      opkey = [[self->assignedAccounts objectAtIndex:j]
                                       valueForKey:@"companyId"];
      if ([opkey isEqual:pkey]) { // already in array
        pkey = nil;
        break;
      }
    }

    if (pkey) {
      [self->assignedAccounts addObject:account];
      [self->resultList removeObject:account];
    }
  }
}
- (void)_processUnselectedAccounts {
  int i, count;

  for (i = 0, count = [self->removedAccounts count]; i < count; i++) {
    id  account;
    id  pkey;
    int j, count2, removeIdx = -1;

    account = [self->removedAccounts objectAtIndex:i];
    pkey        = [account valueForKey:@"companyId"];

    if (pkey == nil) {
      NSLog(@"ERROR(%@): invalid pkey of account %@", self, account);
      continue;
    }

    for (j = 0, count2 = [self->assignedAccounts count]; j < count2; j++) {
      id opkey;

      opkey = [[self->assignedAccounts objectAtIndex:j]
                                       valueForKey:@"companyId"];
      if ([opkey isEqual:pkey]) { // found in array
        removeIdx = j;
        break;
      }
    }

    if (removeIdx != -1) {
      [self->assignedAccounts removeObjectAtIndex:removeIdx];
      [self->resultList addObject:account];
    }
  }
}

- (id)invokeActionForRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  [self _ensureSyncAwake];

  // accounts selected in resultList
  [self _processSelectedAccounts];
  
  // accounts not selected in accounts list
  [self _processUnselectedAccounts];
  
  // then continue request processing
  return [super invokeActionForRequest:_rq inContext:_ctx];
}

/* accessors */

- (void)setItem:(id)_item { 
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (id)team {
  return [self snapshot];
}
- (void)setIsLocationTeam:(BOOL)_isLocationTeam {
  [[self snapshot] takeValue:[NSNumber numberWithBool:_isLocationTeam]
                   forKey:@"isLocationTeam"];
}

- (BOOL)isAllIntranetTeam {
  NSString *l = [[self snapshot] valueForKey:@"login"];
  
  return ([l isEqualToString:@"all intranet"]) ? YES : NO;
}

- (BOOL)isLocationTeam {
  id value = [[self snapshot] valueForKey:@"isLocationTeam"];

  return (value == nil) ? NO : [value boolValue];
}

- (BOOL)isDeleteEnabled {
  return (![self isInNewMode] && ![self isAllIntranetTeam]) ? YES : NO;
}

- (BOOL)hasAccountSelection {
  return ([self->assignedAccounts count] + [self->resultList count]) > 0
    ? YES : NO;
}

- (NSString*)searchText {
  return self->searchText;
}
- (void)setSearchText: (NSString*) _text {
  ASSIGN(self->searchText, _text);
}

- (NSArray *)resultList {
  [self _updateAccountList:self->resultList];
  return self->resultList;
}

- (NSArray *)assignedAccounts {
  [self _updateAccountList:self->assignedAccounts];
  return self->assignedAccounts;
}

- (void)setAddedAccounts:(NSMutableArray *)_addedAccounts {
  ASSIGN(self->addedAccounts, _addedAccounts);
}
- (NSMutableArray *)addedAccounts {
  return self->addedAccounts;
}

- (void)setRemovedAccounts:(NSMutableArray *)_removedAccounts {
  ASSIGN(self->removedAccounts, _removedAccounts);
}
- (NSMutableArray *)removedAccounts {
  return self->removedAccounts;
}

// notifications

- (NSString *)insertNotificationName {
  return LSWNewTeamNotificationName;
}
- (NSString *)updateNotificationName {
  return LSWUpdatedTeamNotificationName;
}
- (NSString *)deleteNotificationName {
  return LSWDeletedTeamNotificationName;
}

/* misc */

- (void)_removeDuplicateAccountListEntries {
  int i, count;

  for (i = 0, count = [self->assignedAccounts count]; i < count; i++) {
    int j, count2;
    id  pkey;

    pkey = [[self->assignedAccounts objectAtIndex:i] valueForKey:@"companyId"];
    if (pkey == nil) continue;

    for (j = 0, count2 = [self->resultList count]; j < count2; j++) {
      id anAccount = [self->resultList objectAtIndex:j];

      if ([[anAccount valueForKey:@"companyId"] isEqual:pkey]) {
        [self->resultList removeObjectAtIndex:j];
        break; // must break, otherwise 'count2' will be invalid
      }
      if ([[anAccount valueForKey:@"isTemplateUser"] boolValue]) {
        [self->resultList removeObjectAtIndex:j];
        break;
      }
    }
  }
}

/* actions */

- (id)search {
  NSArray *result = nil;

  [self->resultList removeAllObjects];

  result = [self runCommand:
                 @"account::extended-search",
                 @"operator",    @"OR",
                 @"name",        self->searchText,
                 @"firstname",   self->searchText,
                 @"description", self->searchText,
                 @"login",       self->searchText,
                 nil];

  if (result != nil) {
    [self->resultList addObjectsFromArray:result];
  }
  [self _removeDuplicateAccountListEntries];

  return nil;
}

- (BOOL)checkConstraints {
  NSMutableString *error = [NSMutableString stringWithCapacity:128];
  NSString        *desc  = [[self snapshot] valueForKey:@"description"];
  
  if (![desc isNotNull] || [desc length] == 0)
    [error appendString:@" No name set."];

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
  id team = [self snapshot];

  [team takeValue:self->assignedAccounts forKey:@"accounts"];
  return [self runCommand:@"team::new" arguments:team];
}

- (id)updateObject {
  id team;

  team = [self snapshot];

  [self->defaults synchronize];
  
  [team takeValue:self->assignedAccounts forKey:@"accounts"];
  return [self runCommand:@"team::set" arguments:team];
}

- (id)deleteObject {
  id result;

  result = [[self object] run:@"team::delete", 
                            @"reallyDelete", [NSNumber numberWithBool:YES],
                            nil];
  return result;
}

- (id)defaults {
  return self->defaults;
}

- (BOOL)isMailConfigEnabled {
  static int IsMailConfigEnabled = -1;

  if (IsMailConfigEnabled == -1) {
    IsMailConfigEnabled =
      [[NSUserDefaults standardUserDefaults]
                       boolForKey:@"MailConfigEnabled"] ? 1 : 0;
  }
  return (IsMailConfigEnabled == 1) ? YES : NO;
}

@end /* LSWTeamEditor */
