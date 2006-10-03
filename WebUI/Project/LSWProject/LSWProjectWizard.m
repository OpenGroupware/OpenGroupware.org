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

#include "LSWProjectWizard.h"
#include "common.h"

#define MainAttributesMode          @"mode_0"
#define AccessListMode              @"mode_1"
#define ProjectLeaderAssignmentMode @"mode_2"
#define CompanyAssignmentMode       @"mode_3"
#define ProjectPlanMode             @"mode_4"

int _compareAccounts(id e1, id e2, void* context) {
  return [[e1 valueForKey:@"fullNameLabel"]
          caseInsensitiveCompare:[e2 objectForKey:@"fullNameLabel"]];
}

@interface LSWProjectWizard(PrivatMethodes)
- (void)_merge:(NSMutableArray *)_resultList with:(NSArray *)_list;
- (NSArray *)_diff:(NSArray *)_resultList with:(NSArray *)_list;
- (void)_action;
- (void)_updateAccountResultList:(NSArray *)_list;
- (void)_setLabelForAccount:(id)_part;
- (void)setEnterprises:(NSMutableArray *)_enterprises;
- (void)setPersons:(NSMutableArray *)_persons;
@end

@implementation LSWProjectWizard

- (id)init {
  if ((self = [super init])) {
    self->accounts             = [[NSMutableArray alloc] init];
    self->newAccounts          = [[NSMutableArray alloc] init];
    self->persons              = [[NSMutableArray alloc] init];
    self->newPersons           = [[NSMutableArray alloc] init];
    self->enterprises          = [[NSMutableArray alloc] init];
    self->newEnterprises       = [[NSMutableArray alloc] init];
    
    self->mode                 = MainAttributesMode;
    self->showExtended         = NO;
  }
  return self;
}

- (void)dealloc {
  [self unregisterAsObserver];
  RELEASE(self->mode);
  RELEASE(self->item);
  RELEASE(self->accounts);
  RELEASE(self->ownerSelection);
  RELEASE(self->teamSelection);
  RELEASE(self->searchTeam);
  RELEASE(self->searchText);
  RELEASE(self->accountResultList);
  RELEASE(self->enterprises);
  RELEASE(self->persons);
  RELEASE(self->enterpriseResultList);
  RELEASE(self->personResultList);
  RELEASE(self->companyTypeSelection);
  RELEASE(self->oldAccounts);
  RELEASE(self->oldEnterprises);
  RELEASE(self->oldPersons);

  [super dealloc];
}

/* clear editor */

- (void)clearEditor {
  RELEASE(self->teamSelection);      self->teamSelection  = nil;
  RELEASE(self->searchTeam);         self->searchTeam     = nil;
  RELEASE(self->searchText);         self->searchText     = nil;
  [super clearEditor];
}

/* activation */

- (BOOL)prepareForNewCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id             project;
  WOSession      *sn;
  NSCalendarDate *today;
  NSCalendarDate *silvester;

  project   = [self snapshot];
  sn        = [self session];
  today     = [NSCalendarDate date];
  self->isFinishDisabled = YES;
  
  [today setTimeZone:[(OGoSession *)sn timeZone]];
  
  silvester = [NSCalendarDate dateWithYear:2028  month:12    day:31 
                              hour:0    minute:0  second:0
                              timeZone:[today timeZone]];
  
  [project takeValue:today     forKey:@"startDate"];
  //  [project takeValue:silvester forKey:@"endDate"];

  [self->ownerSelection release]; self->ownerSelection = nil;
  self->ownerSelection = [[sn activeAccount] retain];
  return YES;
}


- (BOOL)prepareForEditCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id obj = [self object];

  self->isFinishDisabled = NO;

  [obj run:@"project::get-persons", nil];
  [obj run:@"project::get-accounts", nil];
  [obj run:@"project::get-enterprises", nil];

  [self->accounts    addObjectsFromArray:[obj valueForKey:@"accounts"]];
  [self->persons     addObjectsFromArray:[obj valueForKey:@"persons"]];
  [self->enterprises addObjectsFromArray:[obj valueForKey:@"enterprises"]];
  
  [self->oldAccounts release]; self->oldAccounts = nil;
  self->oldAccounts = [self->accounts copy];

  [self->oldEnterprises release]; self->oldEnterprises = nil;
  self->oldEnterprises = [self->enterprises copy];

  [self->oldPersons release]; self->oldPersons = nil;
  self->oldPersons = [self->persons copy];
  
  [obj run:@"project::get-status", nil];

  [self runCommandInTransaction:@"person::enterprises",
        @"persons",     self->accounts,
        @"relationKey", @"enterprises", nil];

  // get access team
  {
    id accessTeam = nil;
    id _owner     = nil;
    
    [obj run:@"project::get-team",  @"relationKey", @"team", nil];
    [obj run:@"project::get-owner", @"relationKey", @"owner", nil];

    accessTeam = [obj valueForKey:@"team"];
    ASSIGN(self->teamSelection, accessTeam);

    _owner = [obj valueForKey:@"owner"];
    ASSIGN(self->ownerSelection, _owner);
  }
  return YES;
}

/* accessors */

- (void)setMode:(NSString *)_mode {
  ASSIGN(self->mode, _mode);
}
- (NSString *)mode {
  return self->mode;
}

- (void)setItem:(id)_item {
  self->item = _item;
}
- (id)item {
  return self->item;
}

- (void)setTeamSelection:(id)_team {
  id project = [self snapshot];
  id pkey    = [_team valueForKey:@"companyId"];

  if (pkey == nil) pkey = [EONull null];

  ASSIGN(self->teamSelection, _team);
  [project takeValue:pkey forKey:@"teamId"];

  if ([_team isNotNull]) {
    [project takeValue:_team forKey:@"team"];
  }
  else {
    [project removeObjectForKey:@"team"];
    [[self object] removeObjectForKey:@"team"];
  }
}

- (id)teamSelection {
  return self->teamSelection;
}

- (void)setSearchTeam:(id)_team {
  ASSIGN(self->searchTeam, _team);
}
- (id)searchTeam {
  return self->searchTeam;
}

- (void)setSearchText:(NSString *)_text {
  if (self->searchText != _text) {
    RELEASE(self->searchText); self->searchText = nil;
    self->searchText = [_text copyWithZone:[self zone]];
  }
}
- (NSString *)searchText {
  return self->searchText;
}

- (void)setSelectedOwner:(NSMutableArray *)_selectedOwner {
  if ([_selectedOwner count] > 0) {
    id tmp = [_selectedOwner lastObject];
    ASSIGN(self->ownerSelection, tmp);
  }
}
- (NSMutableArray *)selectedOwner {
  return (self->ownerSelection == nil)
    ? [NSMutableArray array]
    : [NSMutableArray arrayWithObject:self->ownerSelection];
}

- (void)setNewAccounts:(NSMutableArray *)_newAccounts {
  ASSIGN(self->newAccounts, _newAccounts);
}
- (NSMutableArray *)newAccounts {
  return self->newAccounts;
}

- (void)setAccounts:(NSMutableArray *)_accounts {
  ASSIGN(self->accounts, _accounts);
}
- (NSMutableArray *)accounts {
  return self->accounts;
}

- (NSArray *)accountResultList {
  return self->accountResultList;
}
- (void)setAccountResultList:(NSArray *)_accountResultList {
  ASSIGN(self->accountResultList, _accountResultList);
}

- (void)setPersons:(NSMutableArray *)_persons {
  ASSIGN(self->persons, _persons);
}
- (NSMutableArray *)persons {
  return self->persons;
}


- (void)setNewEnterprises:(NSMutableArray *)_newEnterprises {
  ASSIGN(self->newEnterprises, _newEnterprises);
}
- (NSMutableArray *)newEnterprises {
  return self->newEnterprises;
}

- (void)setEnterprises:(NSMutableArray *)_enterprises {
  ASSIGN(self->enterprises, _enterprises);
}
- (NSMutableArray *)enterprises {
  return self->enterprises;
}

- (NSArray *)enterpriseList {
  return [NSArray arrayWithArray:self->enterprises];
}

- (NSArray *)personList {
  return [NSArray arrayWithArray:self->persons];
}

- (void)setNewPersons:(NSMutableArray *)_newPersons {
  ASSIGN(self->newPersons, _newPersons);
}
- (NSMutableArray *)newPersons {
  return self->newPersons;
}

- (void)setPersonResultList:(NSArray *)_personResultList {
  ASSIGN(self->personResultList, _personResultList);
}
- (NSArray *)personResultList {
  return self->personResultList;
}

- (void)setEnterpriseResultList:(NSArray *)_enterpriseResultList {
  ASSIGN(self->enterpriseResultList, _enterpriseResultList);
}
- (NSArray *)enterpriseResultList {
  return self->enterpriseResultList;
}

- (void)setCompanyTypeSelection:(NSString *)_companyTypeSelection {
  ASSIGN(self->companyTypeSelection, _companyTypeSelection);
}
- (NSString *)companyTypeSelection {
  return self->companyTypeSelection;
}

- (void)setShowExtended:(BOOL)_flag {
  self->showExtended = _flag;
}
- (BOOL)showExtended {
  return self->showExtended;
}

- (NSMutableDictionary *)project {
  return [self snapshot];
}

- (void)setCompany:(id)_company {
  if ([[_company entityName] isEqualToString:@"Person"]) {
    [self->newPersons addObject:_company];
    [self _merge:self->persons with:self->newPersons];
    [self->newPersons removeAllObjects];
  }
  else {
    [self->newEnterprises addObject:_company];
    [self _merge:self->enterprises with:self->newEnterprises];
    [self->newEnterprises removeAllObjects];
  }
}

// ---------------------------------------------------------------------

- (NSArray*)attributesList {
  NSMutableArray      *myAttrs;
  NSMutableDictionary *myDict1, *myDict2;
  
  myAttrs = [NSMutableArray arrayWithCapacity:4];
  myDict1 = [[NSMutableDictionary alloc] initWithCapacity:4];
  myDict2 = [[NSMutableDictionary alloc] initWithCapacity:4];
  [myDict1 takeValue:@"name"      forKey:@"key"];
  [myDict1 takeValue:@", "        forKey:@"suffix"];

  [myDict2 takeValue:@"firstname" forKey:@"key"];
  
  [myAttrs addObject:myDict1];
  [myAttrs addObject:myDict2];
  [myDict1 release];
  [myDict2 release];
  
  if (self->showExtended) {
    NSMutableDictionary *myDict3;
    
    myDict3 = [[NSMutableDictionary alloc] initWithCapacity:2];
    [myDict3 setObject:@"enterprises.description" forKey:@"key"];
    [myDict3 setObject:@",  "                     forKey:@"separator"];
    [myAttrs addObject:myDict3];
    [myDict3 release];
  }
  return myAttrs;
}

- (NSString *)companyTypeLabel {
  return [[self labels] valueForKey:self->item];
}

- (NSArray *)accountList {
  return [NSArray arrayWithArray:self->accounts];
}

- (NSArray *)accessList {
  NSArray        *members;
  NSMutableArray *result;
  
  members = [self->teamSelection valueForKey:@"members"];
  result  = [NSMutableArray arrayWithArray:self->accounts];
  
  if ([members isNotNull])
    [self _merge:result with:members];

  if ([result count] == 0) {
    id owner;
    
    owner = [[self session] activeAccount];
    [result addObject:owner];
    ASSIGN(self->ownerSelection, owner);
  }
  else if (![result containsObject:self->ownerSelection])
    [result addObject:self->ownerSelection];

  return result;
}

/* wizard title */

- (NSString *)wizardWindowTitle {
  NSString *result;
  
  result = [NSString stringWithFormat:@"%@ (%@)",
                     [[self labels] valueForKey:@"projectWizardTitle"],
                     [[self labels] valueForKey:self->mode]];
  return result;
}

/* notifications */

- (NSString *)insertNotificationName {
  return LSWNewProjectNotificationName;
}
- (NSString *)updateNotificationName {
  return LSWUpdatedProjectNotificationName;
}
- (NSString *)deleteNotificationName {
  return LSWDeletedProjectNotificationName;
}

/* constraints */

- (BOOL)checkConstraintsForMainAttributes {
  id        project;
  NSString *pName;
  
  project = [self snapshot];
  pName   = [project valueForKey:@"name"];

  if (![pName isNotNull] || [pName length] == 0) {
    [self setErrorString:@" No project name set."];
    return YES;
  }
  return NO;
}

- (BOOL)checkConstraintsForAccessList {
  return NO;
}

- (BOOL)checkConstraintsForProjectLeader {
  if (![self->ownerSelection isNotNull]) {
    [self setErrorString:@"No Project Leader set!"];
    return YES;
  }
  return NO;
}

- (BOOL)checkConstraintsForDate {
  id             project;
  NSCalendarDate  *begin, *end;
  
  project = [self snapshot];
  begin = [project valueForKey:@"startDate"];
  end   = [project valueForKey:@"endDate"];

   if (begin == nil) {
    [self setErrorString:@" No start date set."];
    return YES;
  }
  if (end == nil) {
    [self setErrorString:@" No end date set."];
    return YES;
  }
  return NO;
}

- (BOOL)checkConstraints {
  id             project;
  NSCalendarDate *begin, *end;
  NSString       *pName;

  project = [self snapshot];
  begin   = [project valueForKey:@"startDate"];
  end     = [project valueForKey:@"endDate"];
  pName   = [project valueForKey:@"name"];
  
  if (begin == nil) {
    [self setErrorString:@" No start date set."];
    return YES;
  }
  if (end == nil) {
    [self setErrorString:@" No end date set."];
    return YES;
  }
  if (![pName isNotNull] || [pName length] == 0) {
    [self setErrorString:@" No project name set."];
    return YES;
  }
  
  if ([self->teamSelection isNotNull] &&
      ![[self->teamSelection valueForKey:@"members"]
                             containsObject:self->ownerSelection] &&
      ![self->ownerSelection isEqual:[[self session] activeAccount]]) {
    [self setErrorString:@"Project Leader is not a member of selected Team!"];
    return YES;
  }
  return NO;
}

- (BOOL)checkConstraintsForSave {
  return [self checkConstraints] ? NO : YES;
}

- (BOOL)isShowAccountList {
  return (([self->accountResultList count] > 0) ||
          ([self->accounts count] > 0)) ? YES : NO;
}

- (BOOL)isShowPersonList {
  return (([self->persons count] + [self->personResultList count]) > 0);
}

- (BOOL)isShowEnterpriseList {
  return (([self->enterprises count]+[self->enterpriseResultList count]) > 0);
}

- (BOOL)isFinishDisabled {
  return self->isFinishDisabled;
}

- (BOOL)isNextDisabled {
  return [self->mode isEqualToString:ProjectPlanMode];
}

- (BOOL)isBackDisabled {
  return [self->mode isEqualToString:MainAttributesMode];
}

- (BOOL)isRoot {
  return [[self session] activeAccountIsRoot];
}

/* actions */

- (id)accountSearch {
  NSArray *result   = nil;
  BOOL    didSearch = NO;
  
  if (self->searchText != nil && [self->searchText length] > 0 &&
      self->searchTeam == nil) {
    result = [self runCommand:
                   @"account::extended-search",
                   @"operator",    @"OR",
                   @"name",        self->searchText,
                   @"firstname",   self->searchText,
                   @"description", self->searchText,
                   @"login",       self->searchText,
                   nil];
    didSearch = YES;
  }
  else if (self->searchTeam != nil) {
    result = [self runCommand:@"team::resolveaccounts", @"staff",
                   self->searchTeam, nil];
    didSearch = YES;
  }
  
  if (didSearch) {
    [self _merge:self->accounts with:self->newAccounts];
    [self->newAccounts removeAllObjects];
    
    if (result)
      [self setAccountResultList:[self _diff:result with:self->accounts]];
    else
      [self setAccountResultList:[NSArray array]];

    [self runCommandInTransaction:@"person::enterprises",
          @"persons",     self->accountResultList,
          @"relationKey", @"enterprises", nil];
  }
  else 
    [self setErrorString:@"specify search criteria !"];

  return nil;
}

- (id)companySearch {
  NSArray *result;
  
  [self _merge:self->persons with:self->newPersons];
  [self setEnterpriseResultList:[NSArray array]];
  [self->newPersons removeAllObjects];
  
  [self _merge:self->enterprises with:self->newEnterprises];
  [self setPersonResultList:[NSArray array]];
  [self->newEnterprises removeAllObjects];

  if ([self->companyTypeSelection isEqualToString:@"personType"]) {
    result = [self runCommand:
                   @"person::extended-search",
                   @"operator",    @"OR",
                   @"name",        self->searchText,
                   @"firstname",   self->searchText,
                   @"description", self->searchText,
                   @"login",       self->searchText,
                   nil];
    if (result) {
      result = [self _diff:result with:self->accounts];
      [self setPersonResultList:[self _diff:result with:self->persons]];

      [self runCommandInTransaction:@"person::enterprises",
            @"persons",     self->personResultList,
            @"relationKey", @"enterprises", nil];
    }
  }
  else {
    result = [self runCommand:
                   @"enterprise::extended-search",
                   @"operator",    @"OR",
                   @"number",      self->searchText,
                   @"description", self->searchText,
                   @"login",       self->searchText,
                   nil];
    if (result) {
      [self setEnterpriseResultList:
	      [self _diff:result with:self->enterprises]];
    }
  }
  return nil;
}

- (id)next {
  [self _action];
  if ([self->mode isEqualToString:MainAttributesMode]) {
    if ([self checkConstraintsForMainAttributes]) return nil;
    [self setMode:AccessListMode];
  }
  else if ([self->mode isEqualToString:AccessListMode]) {
    if ([self checkConstraintsForAccessList]) return nil;
    [self setMode:ProjectLeaderAssignmentMode];
  }
  else if ([self->mode isEqualToString:ProjectLeaderAssignmentMode]) {
    if ([self checkConstraintsForProjectLeader]) return nil;
    [self setMode:CompanyAssignmentMode];
  }
  else if ([self->mode isEqualToString:CompanyAssignmentMode]) {
    [self setMode:ProjectPlanMode];
    self->isFinishDisabled = NO;
  }
  return nil;
}

- (id)previous {
  [self _action];
  if ([self->mode isEqualToString:ProjectPlanMode]) {
    if ([self checkConstraintsForDate]) return nil;
    [self setMode:CompanyAssignmentMode];
  }
  else if ([self->mode isEqualToString:CompanyAssignmentMode]) {
    [self setMode:ProjectLeaderAssignmentMode];
  }
  else if ([self->mode isEqualToString:ProjectLeaderAssignmentMode]) {
    if ([self checkConstraintsForProjectLeader]) return nil;
    [self setMode:AccessListMode];
  } 
  else if ([self->mode isEqualToString:AccessListMode]) {
    if ([self checkConstraintsForAccessList]) return nil;
    [self setMode:MainAttributesMode];
  }
  return nil;
}

- (id)insertObject {
  id project;
  
  project = [self snapshot];
  
  [self _action];
  [project takeValue:self->accounts forKey:@"accounts"];
  
  [project takeValue:[NSNumber numberWithBool:NO] forKey:@"isFake"];

  if ([self isRoot] && self->ownerSelection == nil)
    [project takeValue:[[[self session] activeAccount]
                               valueForKey:@"companyId"] forKey:@"ownerId"];
  else {
    [project takeValue:[self->ownerSelection
                            valueForKey:@"companyId"] forKey:@"ownerId"];
  }

  if (![self isRoot])
    [project takeValue:[EONull null] forKey:@"teamId"];
  
  return [self runCommand:@"project::new" arguments:project];
}

- (id)updateObject {
  id project = [self snapshot];

  [self _action];

  [project takeValue:[self _diff:self->accounts with:self->oldAccounts]
              forKey:@"accounts"];
  [project takeValue:[self _diff:self->oldAccounts with:self->accounts]
              forKey:@"removedAccounts"];

  if (self->ownerSelection != nil) {
    [project takeValue:[self->ownerSelection valueForKey:@"companyId"]
                forKey:@"ownerId"];
  }
  return [self runCommand:@"project::set" arguments:project];
}

- (id)save {
  [self saveAndGoBackWithCount:1];

  if ([[self navigation] activePage] != self) {
    id obj = [self object];
    
    if ([self isInNewMode]) {
      [obj run:@"project::assign-accounts",
                  @"companies", self->enterprises,
                  @"hasAccess", [NSNumber numberWithBool:NO], nil];

      [obj run:@"project::assign-accounts",
                  @"companies", self->persons,
                  @"hasAccess", [NSNumber numberWithBool:NO], nil];
    }
    else {
      [obj run:@"project::assign-accounts",
        @"companies", [self _diff:self->enterprises with:self->oldEnterprises],
        @"removedCompanies",
                     [self _diff:self->oldEnterprises with:self->enterprises],
        @"hasAccess", [NSNumber numberWithBool:NO], nil];

      [obj run:@"project::assign-accounts",
        @"companies",       [self _diff:self->persons with:self->oldPersons],
        @"removedCompanies",[self _diff:self->oldPersons with:self->persons],
        @"hasAccess",       [NSNumber numberWithBool:NO], nil];
    }
  }
  return nil;
}

- (id)deleteObject {
  id result = [[self object] run:@"project::delete", 
                               @"reallyDelete", [NSNumber numberWithBool:YES],
                               nil];
  return result;
}

/* LSWProjectWizard(PrivatMethodes) */

- (void)_action {
  [self  setSearchText:@""];
  [self setErrorString:@""];
  
  [self _merge:self->accounts with:self->newAccounts];
  [self->newAccounts removeAllObjects];
  [self setAccountResultList:[NSArray array]];
  
  [self _merge:self->persons with:self->newPersons];
  [self->newPersons removeAllObjects];
  [self setPersonResultList:[NSArray array]];

  [self _merge:self->enterprises with:self->newEnterprises];
  [self setEnterpriseResultList:[NSArray array]];
}

- (NSArray *)_diff:(NSArray *)_list1 with:(NSArray *)_list2 {
  int             i, count = [_list1 count];
  NSMutableArray *result   = [NSMutableArray array];

  for (i = 0; i < count; i++) {
    int  j,count2 = [_list2 count];
    id   pkey     = [[_list1 objectAtIndex:i] valueForKey:@"companyId"];
    BOOL isInList = NO;
                                                                               
    if (pkey == nil) continue;

    for (j = 0; j < count2; j++) {
      id pkey2 = [[_list2 objectAtIndex:j] valueForKey:@"companyId"];

      if ([pkey2 isEqual:pkey]) {
        isInList = YES;
        break;
      }
    }
    if (!isInList)
      [result addObject:[_list1 objectAtIndex:i]];
  }

  [self _updateAccountResultList:result];
  return result;
}

- (void)_merge:(NSMutableArray *)_resultList with:(NSArray *)_list {
  int i, count = [_list count];

  for (i = 0; i < count; i++) {
    int  j,count2 = [_resultList count];
    id   pkey     = [[_list objectAtIndex:i] valueForKey:@"companyId"];
    BOOL isInList = NO;
                                                                               
    if (pkey == nil) continue;

    for (j = 0; j < count2; j++) {
      id pkey2 = [[_resultList objectAtIndex:j] valueForKey:@"companyId"];

      if ([pkey2 isEqual:pkey]) {
        isInList = YES;
        break;
      }
    }
    if (!isInList)
      [_resultList addObject:[_list objectAtIndex:i]];
  }

  [self _updateAccountResultList:_resultList];
}

- (void)_updateAccountResultList:(NSArray *)_list {
  NSEnumerator *partEnum =  [_list objectEnumerator];
  id           part;
  
  while ((part = [partEnum nextObject])) {
    [self _setLabelForAccount:part];
  }
}

- (void)_setLabelForAccount:(id)_part {
  id        p = _part;
  NSString *d = nil;
  
  if (![(d = [p valueForKey:@"name"]) isNotNull]) {
    if (![(d = [p valueForKey:@"login"]) isNotNull]) {
      if (![(d = [p valueForKey:@"description"]) isNotNull]) {
        d = [NSString stringWithFormat:@"pkey<%@>",
                      [p valueForKey:@"companyId"]];
      }
    }
  }
  else {
    NSString *fd = [p valueForKey:@"firstname"];

    if (fd != nil)
      d = [NSString stringWithFormat:@"%@, %@", d, fd];
  }
  [p takeValue:d forKey:@"fullNameLabel"];
}

@end /* LSWProjectWizard */
