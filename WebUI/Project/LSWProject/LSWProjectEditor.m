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
// $Id$

#include <OGoFoundation/LSWEditorPage.h>

@class NSString, NSMutableArray, NSMutableSet;

// TODO: split up this huge file/class

@interface LSWProjectEditor : LSWEditorPage
{
@private
  int      idx;
  id       team;  
  id       item;
  id       company;
  id       searchTeam;
  NSString *accountSearchText;
  NSString *companySearchText;
  NSString *searchOwnerText;
  id       teamSelection;
  id       ownerSelection;
  NSString *companyTypeSelection;
  NSString *companyTypeItem;

  NSMutableArray  *accounts;
  NSMutableSet    *accountsToRemove;
  NSMutableArray  *resultList;
  NSMutableArray  *removedAccounts;
  NSMutableArray  *addedAccounts;
  
  NSMutableArray  *ownerResultList;
  NSMutableArray  *addedOwners;

  NSMutableArray  *persons;
  NSMutableArray  *enterprises;
  NSMutableArray  *newPersons;
  NSMutableArray  *newEnterprises;

  NSArray         *personResultList;
  NSArray         *enterpriseResultList;
  NSArray         *oldEnterprises;
  NSArray         *oldPersons;

  NSArray         *allAccess;

  BOOL            showExtended;

  NSMutableDictionary *props;
  NSMutableDictionary *propMap;
  NSArray             *publicExtendedProjectAttributes;
  NSArray             *privateExtendedProjectAttributes;
  NSString            *projectBase;
}

@end

#include "NSString+Perm.h"
#include "common.h"
#include <GDLExtensions/GDLExtensions.h>

@interface NSObject(GlobalID)
- (id)globalID;
@end

static int compareAccounts(id e1, id e2, void* context) {
  return [[e1 valueForKey:@"fullNameLabel"]
          caseInsensitiveCompare:[e2 objectForKey:@"fullNameLabel"]];
}

@interface LSWProjectEditor(PrivatMethodes)
- (void)setOwnerSelection:(id)_leader;
- (NSArray *)_diff:(NSArray *)_list1 with:(NSArray *)_list2;
- (void)_merge:(NSMutableArray *)_resultList with:(NSArray *)_list;
- (void)_setLabelForAccount:(id)_part;
- (void)_updateAccountResultList:(NSArray *)_list;
- (void)_updateAssignmentsForObj:(id)_obj;
- (void)_ensureProps;
- (void)_setExtAttributes;
- (SkyObjectPropertyManager *)propertyManager;
- (BOOL)hasMoreThanOneProjectBases;
@end

@implementation LSWProjectEditor

static OGoFileManagerFactory *fmFactory = nil;
static NSNull   *null   = nil;
static NSNumber *yesNum = nil;
static NSNumber *noNum  = nil;
static NSArray  *personAttrSet = nil;
static NSArray  *projectBases  = nil;
static NSArray  *personAttrs   = nil;
static NSArray  *teamAttrs     = nil;
static int      OldProjectCompatiblity = -1;

+ (void)initialize {
  // TODO: should check superclass version!
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  // TODO: explain, what does that do?
  OldProjectCompatiblity =
    [ud boolForKey:@"SkyOldCommonProjectCompatibility"]?1:0;

  fmFactory = [[OGoFileManagerFactory sharedFileManagerFactory] retain];
  projectBases = [[fmFactory availableProjectBases] copy];
  
  yesNum = [[NSNumber numberWithBool:YES] retain];
  noNum  = [[NSNumber numberWithBool:NO]  retain];
  null   = [[NSNull null] retain];
  
  personAttrSet = 
    [[NSArray alloc] initWithObjects:@"name", @"firstname", @"login", nil];
  
  personAttrs = [[NSArray alloc] initWithObjects:@"name", @"firstname",
				   @"login", @"globalID", @"isTeam", nil];
  teamAttrs = [[NSArray alloc] initWithObjects:
				 @"description", @"globalID", nil];
}

- (id)init {
  if ((self = [super init])) {
    /* hh: do we really always need all those arrays? */
    self->resultList       = [[NSMutableArray alloc] initWithCapacity:4];
    self->removedAccounts  = [[NSMutableArray alloc] initWithCapacity:4];
    self->addedAccounts    = [[NSMutableArray alloc] initWithCapacity:4];
    self->accounts         = [[NSMutableArray alloc] initWithCapacity:4];
    self->accountsToRemove = [[NSMutableSet   alloc] initWithCapacity:4];
    self->ownerResultList  = [[NSMutableArray alloc] initWithCapacity:4];
    self->persons          = [[NSMutableArray alloc] initWithCapacity:4];
    self->newPersons       = [[NSMutableArray alloc] initWithCapacity:4];
    self->enterprises      = [[NSMutableArray alloc] initWithCapacity:4];
    self->newEnterprises   = [[NSMutableArray alloc] initWithCapacity:4];
    self->addedOwners      = [[NSMutableArray alloc] initWithCapacity:4];
    self->props            = [[NSMutableDictionary alloc] initWithCapacity:4];
    [self _setExtAttributes];
  }
  return self;
}

- (void)dealloc {
  [self->projectBase          release];
  [self->allAccess            release];
  [self->teamSelection        release];
  [self->ownerSelection       release];
  [self->ownerResultList      release];
  [self->companySearchText    release];
  [self->accountSearchText    release];
  [self->searchTeam           release];
  [self->resultList           release];
  [self->accounts             release];
  [self->accountsToRemove     release];
  [self->addedAccounts        release];
  [self->removedAccounts      release];
  [self->companyTypeItem      release];
  [self->companyTypeSelection release];
  [self->persons              release];
  [self->newPersons           release];
  [self->personResultList     release];
  [self->enterprises          release];
  [self->newEnterprises       release];
  [self->enterpriseResultList release];
  [self->oldEnterprises       release];
  [self->oldPersons           release];
  [self->addedOwners          release];
  [self->props                release];
  [self->publicExtendedProjectAttributes  release];
  [self->privateExtendedProjectAttributes release];
  [self->propMap release];
  [super dealloc];
}

- (void)clearEditor {
  [self->teamSelection     release]; self->teamSelection     = nil;
  [self->searchTeam        release]; self->searchTeam        = nil;
  [self->companySearchText release]; self->companySearchText = nil;
  [self->accountSearchText release]; self->accountSearchText = nil;
  [self->companySearchText release]; self->accountSearchText = nil;
  [self->searchOwnerText   release]; self->searchOwnerText   = nil;
  [super clearEditor];
}

/* activation */

- (BOOL)prepareForNewCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id             project;
  WOSession      *sn;
  NSCalendarDate *today, *silvester;
  
  project = [self snapshot];
  sn      = [self session];
  today   = [NSCalendarDate date];

  [today setTimeZone:[sn timeZone]];
  
  silvester = [NSCalendarDate dateWithYear:2028
                              month:12 day:31 
                              hour:0 minute:0 second:0
                              timeZone:[sn timeZone]];

  [project takeValue:today     forKey:@"startDate"];
  [project takeValue:silvester forKey:@"endDate"];
  
  [self->ownerSelection release]; self->ownerSelection = nil;
  self->ownerSelection = [[sn activeAccount] retain];
  [self->ownerResultList addObject:self->ownerSelection];
  [self->addedOwners addObject:self->ownerSelection];

  return YES;
}

/* defaults */

- (NSArray *)defaultPublicExtendedAttributes {
  return [[[self session] userDefaults]
                 arrayForKey:@"SkyPublicExtendedProjectAttributes"];
}
- (NSArray *)defaultPrivateExtendedAttributes {
  return [[[self session] userDefaults]
                 arrayForKey:@"SkyPrivateExtendedProjectAttributes"];
}

/* attributes */

- (void)_setExtAttributes {
  NSMutableArray *a        = nil;
  NSArray        *extAttrs = nil;
  NSString       *propKey;
  int i, cnt;
  
  propKey  = @"{http://www.skyrix.com/namespaces/project}";
  extAttrs = [self defaultPublicExtendedAttributes];
  a = [NSMutableArray array];
  
  for (i = 0, cnt = [extAttrs count]; i < cnt; i++) {
    NSMutableDictionary *ea, *e;
    NSString            *key;

    e   = [extAttrs objectAtIndex:i];
    key = [propKey stringByAppendingString:[e valueForKey:@"key"]];
    ea  = [[NSMutableDictionary alloc] init];
    [ea takeValuesFromDictionary:e];
    [ea takeValue:key forKey:@"key"];
    [self->propMap takeValue:ea forKey:key];
    [a addObject:ea];
    [ea release]; ea = nil;
  }
  [self->publicExtendedProjectAttributes release];
  self->publicExtendedProjectAttributes = nil;
  self->publicExtendedProjectAttributes = [a copy];

  extAttrs = [self defaultPrivateExtendedAttributes];
  [a removeAllObjects];

  for (i = 0, cnt = [extAttrs count]; i < cnt; i++) {
    NSMutableDictionary *ea, *e;
    NSString            *key;

    e   = [extAttrs objectAtIndex:i];
    key = [propKey stringByAppendingString:[e valueForKey:@"key"]];
    ea  = [[NSMutableDictionary alloc] init];
    [ea takeValuesFromDictionary:e];
    [ea takeValue:key    forKey:@"key"];
    [ea takeValue:yesNum forKey:@"isPrivate"];
    [self->propMap takeValue:ea forKey:key];
    [a addObject:ea];
    [ea release]; ea = nil;
  }
  ASSIGN(self->privateExtendedProjectAttributes, nil);
  self->privateExtendedProjectAttributes = [a copy];
}

- (void)_resetRightsInAccounts:(NSArray *)_accounts {
  int i, cnt;
  
  for (i = 0, cnt = [_accounts count]; i < cnt; i++ ) {
    [[_accounts objectAtIndex:i] takeValue:null 
                                 forKey:@"accessRight"];
  }
}

- (void)_setRightsInAccounts:(NSArray *)_accounts {
  // TODO: split up
  NSArray *assigns;
  id      obj;
  int     i, cnt;

  obj     = [self object];
  assigns = [obj valueForKey:@"companyAssignments"];

  for (i = 0, cnt = [_accounts count]; i < cnt; i++ ) {
    int j, cnt2;
    id  acc;

    acc = [_accounts objectAtIndex:i];

    for (j = 0, cnt2 = [assigns count]; j < cnt2; j++) {
      id as;

      as = [assigns objectAtIndex:j];

      if ([[acc valueForKey:@"companyId"]
                isEqual:[as valueForKey:@"companyId"]]) {
        NSMutableDictionary *dict;
        NSString *access;
        
        access = [as valueForKey:@"accessRight"];
        dict = [access splitAccessPermissionString];
        [acc takeValue:dict forKey:@"accessCheck"];
        break;
      }
    }
  }
}

- (id)_objectFromGlobalID:(EOKeyGlobalID *)gid {
  id obj;
  
  if (![[gid entityName] isEqualToString:@"Project"]) {
    [self logWithFormat:@"ERROR[%s]: invalid entity in gid: %@. "
            @"only Project accepted.",
            __PRETTY_FUNCTION__, gid];
    return nil;
  }
  
  obj = [self runCommand:@"project::get-by-globalID", @"gid", gid, nil];
  return [obj lastObject];
}

- (void)_makeSnapshot:(id)obj {
  NSMutableDictionary *sn;
  
  sn = [[obj valuesForKeys:[[obj entity] attributeNames]] mutableCopy];
  [self setSnapshot:sn];
  [sn release]; sn = nil;
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(id)_cfg
{
  // TODO: split up
  BOOL result;
  id   obj;

  result = NO;
  
  [self clearEditor];
  //self->activationCommand = [_command copy];
  
  [self setIsInWizardMode:[_command hasPrefix:@"wizard"]];
  [self setIsInNewMode:[_command hasPrefix:@"new"] || [self isInWizardMode]];

  if ([self isInNewMode]) {
    id sn;
    
    sn = [[NSMutableDictionary alloc] initWithCapacity:32];
    [self setSnapshot:sn];
    [sn release]; sn = nil;
    result = [self prepareForNewCommand:_command type:_type
                   configuration:nil];
    return result;
  }

  if ((obj = [[self session] getTransferObject]) == nil) {
    [self setErrorString:@"No object in transfer pasteboard !"];
    return  NO;
  }
  
  result = YES;
  if ([obj isKindOfClass:[EOKeyGlobalID class]]) {
    EOKeyGlobalID *gid = (EOKeyGlobalID *)obj;
    
    if ((obj = [self _objectFromGlobalID:gid]) == nil) {
      [self logWithFormat:@"ERROR[%s]: failed getting project for gid: %@",
            __PRETTY_FUNCTION__, gid];
      return NO;
    }
  }
  
  if (!result)
    return NO;
  
  [self setObject:obj];
  [self _makeSnapshot:obj];
  
  return [self prepareForEditCommand:_command type:_type
               configuration:nil];
}

- (BOOL)prepareForEditCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  /* TODO: split up this huge method */
  id obj, tmp;

  obj = [self object];
  {
    id             o;
    NSMutableArray *accs, *teams, *allAss;
    NSEnumerator   *enumerator;
    NSArray        *array, *oldAccounts;

    [self runCommand:@"project::get-accounts", @"object", obj, nil];
    oldAccounts = [obj valueForKey:@"accounts"];
    
    [self runCommand:@"project::get-company-assignments",
          @"object",     obj,
          @"relationKey", @"companyAssignments", nil];
  
    array = [obj valueForKey:@"companyAssignments"];
    
    {
      int          cnt;
      id           *objs;
      NSEnumerator *enumerator;

      cnt  = 0;
      objs = malloc(sizeof(id) * [array count]);
      enumerator = [array objectEnumerator];
      while ((o = [enumerator nextObject])) {
        if ([[o valueForKey:@"hasAccess"] boolValue]) {
          objs[cnt++] = o;
        }
      }
      array = [NSArray arrayWithObjects:objs count:cnt];
      
      free(objs); objs = NULL;
    }
    
    array = [array map:@selector(valueForKey:) with:@"companyId"];
    array = [[[(id)[self session] commandContext] typeManager]
                         globalIDsForPrimaryKeys:array];
    
    enumerator = [array objectEnumerator];
    accs       = [NSMutableArray array];
    teams      = [NSMutableArray array];

    while ((o = [enumerator nextObject])) {
      NSString *n;

      n = [o entityName];
      if ([n isEqualToString:@"Person"]) {
        [accs addObject:o];
      }
      else if ([n isEqualToString:@"Team"]) {
        [teams addObject:o];
      }
      else {
        NSLog(@"WARNING[%s]: got unknown company-assignment obj %@",
              __PRETTY_FUNCTION__, o);
      }
    }
    allAss = [NSMutableArray array];
    teams  = [self runCommand:@"team::get-by-globalID",
                   @"gids", teams, @"attributes", teamAttrs, nil];
    enumerator = [teams objectEnumerator];
    while ((o = [enumerator nextObject])) {
      id a;

      a = [o mutableCopy];
      [allAss addObject:a];
      [a release]; a = nil;
    }
    accs = [self runCommand:@"person::get-by-globalID",
                   @"gids", accs, @"attributes", personAttrs, nil];
    
    enumerator = [accs objectEnumerator];
    while ((o = [enumerator nextObject])) {
      id a;
      
      a = [o mutableCopy];
      [allAss addObject:a];
      [a release]; a = nil;
    }

    {
      // adding the filtered accounts because of no read - rights
      NSEnumerator *e;
      id           one;
      NSArray      *gids;
      
      e    = [oldAccounts objectEnumerator];
      one  = nil;
      gids = [allAss map:@selector(valueForKey:) with:@"globalID"];
      
      while ((one = [e nextObject])) {
        if (![gids containsObject:[one valueForKey:@"globalID"]]) {
          id       cid, gid, dict;
          NSString *name, *fname, *login;

          cid   = [one valueForKey:@"companyId"];
          name  = [one valueForKey:@"name"];
          fname = [one valueForKey:@"fname"];
          login = [one valueForKey:@"login"];
          gid   = [one valueForKey:@"globalID"];
          
          if ( name == nil) name  = @"";
          if (fname == nil) fname = @"";
          if (login == nil) login = @"";
          dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                          cid,   @"companyId",
                                          fname, @"firstname",
                                          gid,   @"globalID",
                                          login, @"login",
                                          name,  @"name",
                                          nil];
          dict = [dict mutableCopy];
          [allAss addObject:dict];
          [dict release]; dict = nil;
        }
      }
    }
    [obj takeValue:allAss forKey:@"accounts"];
  }
  [obj run:@"project::get-persons",     nil];
  [obj run:@"project::get-enterprises", nil];
  [obj run:@"project::get-status",      nil];
  [obj run:@"project::get-comment", @"relationKey", @"comment", nil];

  tmp = [[obj valueForKey:@"comment"] valueForKey:@"comment"];

  if (tmp != nil)
    [[self snapshot] setObject:[tmp copy] forKey:@"comment"];
  
  [self->accounts    addObjectsFromArray:[obj valueForKey:@"accounts"]];
  [self->persons     addObjectsFromArray:[obj valueForKey:@"persons"]];
  [self->enterprises addObjectsFromArray:[obj valueForKey:@"enterprises"]];

  [self _setRightsInAccounts:self->accounts];

  self->oldEnterprises = [self->enterprises copy];
  self->oldPersons     = [self->persons copy];
  
  [self runCommand:@"person::enterprises", @"persons", self->persons,
        @"relationKey", @"enterprises", nil];

  // get access team
  {
    [obj run:@"project::get-team",  @"relationKey", @"team", nil];
    [obj run:@"project::get-owner", @"relationKey", @"owner", nil];

    [self->teamSelection release]; self->teamSelection = nil;
    self->teamSelection = [[obj valueForKey:@"team"] retain];

    [self->ownerSelection release]; self->ownerSelection = nil;
    self->ownerSelection = [[obj valueForKey:@"owner"] retain];
    
    [self->ownerResultList addObject:self->ownerSelection];
    [self->addedOwners addObject:self->ownerSelection];
  }
  {
    NSDictionary *oprops;
    
    oprops = [[self propertyManager] propertiesForGlobalID:
                                     [[self object] globalID]];
    [[self snapshot] takeValuesFromDictionary:oprops];
  }

  if ([_command isEqualToString:@"delete"]) {
    if ([self isDeleteDisabled]) {
      OGoContentPage *page;
      NSString *s;
      
      page = [[[self session] navigation] activePage];
      s = [[self labels] valueForKey:@"error_projectContainsDataOrNoAccess"];
      [page setErrorString:s];
      return NO;
    }

    [self delete];
  }
  
  return YES;
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];
  [self->allAccess release]; self->allAccess = nil;
  [self->removedAccounts removeAllObjects];
  [self->addedAccounts   removeAllObjects];
}

- (void)syncSleep {
  self->team       = nil;
  self->item       = nil;
  [self->removedAccounts removeAllObjects];
  [self->addedAccounts   removeAllObjects];
  [super syncSleep];
}

/* selection management */

- (void)_removeUnselectedAccounts {
    int          i, cnt;

    ASSIGN(self->allAccess, nil);
    
    cnt = [self->accounts count];

    for (i = 0; i < cnt; i++) {
      NSEnumerator *access;
      id           obj, o;
      BOOL         hasAccess;

      obj       = [self->accounts objectAtIndex:i];
      hasAccess = NO;
      access    = [[obj valueForKey:@"accessCheck"] objectEnumerator];
      while ((o = [access nextObject])) {
        if ([o boolValue]) {
          hasAccess = YES;
          break;
        }
      }
      if (!hasAccess) {
        [self->accountsToRemove addObject:obj];
        [self->accounts removeObjectAtIndex:i];
        i--;
        cnt--;
      }
    }
    { /* add selected accounts */
      NSEnumerator *enumerator;
      id           obj;

      enumerator = [self->resultList objectEnumerator];

      while ((obj = [enumerator nextObject])) {
        NSEnumerator *access;
        id           o;
      

        access = [[obj valueForKey:@"accessCheck"] objectEnumerator];
        while ((o = [access nextObject])) {
          if ([o boolValue]) {
            [self->accounts addObject:obj];
            [self->accountsToRemove removeObject:obj];
          }
        }
      }
    }
    { /* make uniqe */
      id           *keys, *vals, obj;
      int          cnt;
      NSEnumerator *enumerator;
      NSDictionary *dict;

      cnt  = [self->accounts count];
      keys = malloc(sizeof(id) * cnt);
      vals = malloc(sizeof(id) * cnt);
      cnt  = 0;
      
      enumerator = [self->accounts objectEnumerator];
      while ((obj = [enumerator nextObject])) {
        keys[cnt] = [obj valueForKey:@"globalID"];
        vals[cnt] = obj;
        cnt++;
      }
      dict = [[NSDictionary alloc]
                            initWithObjects:vals forKeys:keys count:cnt];
      [self->accounts release]; self->accounts = nil;
      self->accounts = [[dict allValues] mutableCopy];
      [dict release]; dict = nil;
      if (keys) free(keys);
      if (vals) free(vals);
    }
}

- (void)_addSelectedAccounts {
  if ([self->addedOwners count] == 0)
    return;

  [self->ownerSelection release]; self->ownerSelection = nil;
  self->ownerSelection = [[self->addedOwners lastObject] retain];
  [self->ownerResultList removeAllObjects];
  [self->addedOwners     removeAllObjects];
  [self->ownerResultList addObject:self->ownerSelection];
  [self->addedOwners     addObject:self->ownerSelection];
}

/* handle requests */

- (id)invokeActionForRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  [self _ensureSyncAwake];
  
  [self _removeUnselectedAccounts];
  [self->resultList removeAllObjects];
  [self _addSelectedAccounts];
  
  return [super invokeActionForRequest:_rq inContext:_ctx];
}

/* accessors */

- (void)setOwnerSelection:(id)_leader {
  ASSIGN(self->ownerSelection, _leader);
}
- (id)ownerSelection {
  [self _setLabelForAccount:self->ownerSelection];
  return self->ownerSelection;
}

- (void)setAddedOwners:(NSArray *)_list {
  ASSIGN(self->addedOwners, _list);
}
- (NSArray *)addedOwners {
  return self->addedOwners;
}

- (void)setItem:(id)_item {
  self->item = _item;
}
- (id)item {
  return self->item;
}

- (NSMutableArray *)enterprises {
  return self->enterprises;
}
- (void)setEnterprises:(NSMutableArray *)_enterprises {
  ASSIGN(self->enterprises, _enterprises);
}

- (NSMutableArray *)persons {
  return self->persons;
}
- (void)setPersons:(NSMutableArray *)_persons {
  ASSIGN(self->persons, _persons);
}

- (NSArray *)newPersons {
  return self->newPersons;
}
- (void)setNewPersons:(NSMutableArray *)_newPersons {
  ASSIGN(self->newPersons, _newPersons);
}
- (NSArray *)newEnterprises {
  return self->newEnterprises;
}
- (void)setNewEnterprises:(NSMutableArray *)_newEnterprises {
  ASSIGN(self->newEnterprises, _newEnterprises);
}

- (NSArray *)personList {
  return self->persons;
}
- (NSArray *)enterpriseList {
  return self->enterprises;
}

- (NSArray *)personResultList {
  return self->personResultList;
}
- (void)setPersonResultList:(NSArray *)_personResultList {
  ASSIGN(self->personResultList, _personResultList);
}
- (NSArray *)enterpriseResultList {
  return self->enterpriseResultList;
}
- (void)setEnterpriseResultList:(NSArray *)_enterpriseResultList {
  ASSIGN(self->enterpriseResultList, _enterpriseResultList);
}

- (NSArray *)accounts {
  RELEASE(self->allAccess); self->allAccess = nil;
  [self _updateAccountResultList:self->accounts];
  return [self->accounts sortedArrayUsingFunction:compareAccounts context:NULL];
}
- (NSArray *)resultList {
  [self->allAccess release]; self->allAccess = nil;
  [self _updateAccountResultList:self->resultList];
  return [self->resultList sortedArrayUsingFunction:compareAccounts
              context:NULL];
}

- (void)setAddedAccounts:(NSMutableArray *)_addedAccounts {
  ASSIGN(self->addedAccounts, _addedAccounts);
}
- (NSMutableArray *)addedAccounts {
  return self->addedAccounts;
}

- (void)setRemovedAccounts:(NSMutableArray *)_removedAccounts {
  ASSIGN(self->removedAccounts, _removedAccounts);
  [self->accountsToRemove addObjectsFromArray:self->removedAccounts];
}
- (NSMutableArray *)removedAccounts {
  return self->removedAccounts;
}

- (NSArray *)ownerResultList {
  [self _updateAccountResultList:self->ownerResultList];
  return [self->ownerResultList sortedArrayUsingFunction:compareAccounts
              context:NULL];
}

- (BOOL)hasAccountSelection {
  return ([self->accounts count] + [self->resultList count]) > 0 ? YES : NO;
}

- (BOOL)isSaveDisabled {
  return NO;
}

- (BOOL)isTeam {
  id i, o, eN;

  i = [self item];

  if ((o = [i valueForKey:@"isTeam"]))
    return [o boolValue];
  
  eN = ([i isKindOfClass:[EOGenericRecord class]])
    ? [i entityName]
    : [[i valueForKey:@"globalID"] entityName];
  
  return [eN isEqualToString:@"Team"] ? YES : NO;
}

- (NSString *)teamLabel {
  NSString *d = nil;

  d = [self->searchTeam valueForKey:@"description"];
    
  if (d == nil) {
    d = [NSString stringWithFormat:@"pkey<%@>",
                  [self->searchTeam valueForKey:@"companyId"]];
  }
  d = [@"Team: " stringByAppendingString:d];
  return d;
}

- (BOOL)isTeamSet {
  return (self->searchTeam == nil) ? NO : YES;
}

- (NSMutableDictionary *)project {
  return [self snapshot];
}

- (NSArray *)teams {
  return [[[self session] activeAccount] valueForKey:@"groups"];
}

- (id)team {
  return self->team;
}
- (void)setTeam:(id)_team {
  self->team = _team;
}

- (void)setTeamSelection:(id)_team {
  id project = [self snapshot];
  id pkey    = [_team valueForKey:@"companyId"];

  if (pkey == nil) pkey = null;

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

- (void)setCompanySearchText:(NSString *)_text {
  ASSIGN(self->companySearchText, _text);
}
- (NSString *)companySearchText {
  return self->companySearchText;
}

- (void)setAccountSearchText:(NSString *)_text {
  ASSIGN(self->accountSearchText, _text);
}
- (NSString *)accountSearchText {
  return self->accountSearchText;
}


- (void)setSearchOwnerText:(NSString *)_text {
  if (self->searchOwnerText != _text) {
    [self->searchOwnerText release]; self->searchOwnerText = nil;
    self->searchOwnerText = [_text copyWithZone:[self zone]];
  }
}
- (NSString *)searchOwnerText {
  return self->searchOwnerText;
}

- (int)noOfCols {
  id  d = [[[self session] userDefaults] objectForKey:@"projects_no_of_cols"];
  int n = [d intValue];
  
  return (n > 0) ? n : 2;
}

- (NSString *)companyTypeItem {
  return self->companyTypeItem;
}
- (void)setCompanyTypeItem:(NSString *)_companyTypeItem {
  ASSIGN(self->companyTypeItem, _companyTypeItem);
}

- (NSString *)companyTypeSelection {
  return self->companyTypeSelection;
}
- (void)setCompanyTypeSelection:(NSString *)_companyTypeSelection {
  ASSIGN(self->companyTypeSelection, _companyTypeSelection);
}

- (void)setShowExtended:(BOOL)_flag {
  self->showExtended = _flag;
}
- (BOOL)showExtended {
  return self->showExtended;
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

- (NSString *)privateLabel {
  NSString *l;

  l = [[self labels] valueForKey:@"private"];

  return (l != nil) ? l : @"private";
}

// --------------------------------------------------------------------

- (NSArray *)attributesList {
  NSMutableArray      *result;
  NSMutableDictionary *myDict1, *myDict2;

  result  = [NSMutableArray array];
  myDict1 = [[NSMutableDictionary alloc] initWithCapacity:4];
  myDict2 = [[NSMutableDictionary alloc] initWithCapacity:4];

  [myDict1 takeValue:@"name"      forKey:@"key"];
  [myDict1 takeValue:@", "        forKey:@"suffix"];

  [myDict2 takeValue:@"firstname" forKey:@"key"];
  
  [result addObject:myDict1]; [myDict1 release]; myDict1 = nil;
  [result addObject:myDict2]; [myDict2 release]; myDict2 = nil;
  
  return result;
}

- (NSArray *)publicExtendedProjectAttributes {
  return self->publicExtendedProjectAttributes;
}

- (NSArray *)privateExtendedProjectAttributes {
  return self->privateExtendedProjectAttributes;
}

- (BOOL)hasExtendedAttributes {
  return ([self->publicExtendedProjectAttributes count]
          + [self->privateExtendedProjectAttributes count]) > 0 ? YES : NO;
}

- (NSDictionary *)propMap {
  return self->propMap;
}

- (NSArray *)personAttributeList {
  NSMutableArray *r;

  r = [NSMutableArray arrayWithArray:[self attributesList]];
  
  if (self->showExtended) {
    NSMutableDictionary *myDict = [NSMutableDictionary dictionary];
    
    [myDict takeValue:@"enterprises.description" forKey:@"key"];
    [myDict takeValue:@", "                      forKey:@"separator"];
    [r      addObject:myDict];
  }
  return r;
}

- (NSArray *)accountAttributesList {
  return [self attributesList];
}

- (NSString *)companyTypeLabel {
  return [[self labels] valueForKey:self->companyTypeItem];
}

- (BOOL)isShowPersonList {
  return (([self->persons count] + [self->personResultList count]) > 0);
}

- (BOOL)isShowEnterpriseList {
  return (([self->enterprises count]+[self->enterpriseResultList count]) > 0);
}

- (BOOL)isRootOrNew {
  return ([self isInNewMode] || [[self session] activeAccountIsRoot])
    ? YES : NO;
}


// --------------------------------------------------------------------

- (void)removeDuplicateAccountListEntries {
  int i, count;

  for (i = 0, count = [self->accounts count]; i < count; i++) {
    int j, count2;
    id  pkey;

    pkey = [[self->accounts objectAtIndex:i] valueForKey:@"companyId"];
    if (pkey == nil) continue;

    for (j = 0, count2 = [self->resultList count]; j < count2; j++) {
      id account = [self->resultList objectAtIndex:j];

      if ([[account valueForKey:@"companyId"] isEqual:pkey]) {
        [self->resultList removeObjectAtIndex:j];
        break; // must break, otherwise 'count2' will be invalid
      }
    }
  }
  [self->allAccess release]; self->allAccess = nil;
}

// notifications

- (NSString *)insertNotificationName {
  return LSWNewProjectNotificationName;
}
- (NSString *)updateNotificationName {
  return LSWUpdatedProjectNotificationName;
}
- (NSString *)deleteNotificationName {
  return LSWDeletedProjectNotificationName;
}

// --- actions ----------------------------------------------------------

- (id)_primarySearchAccounts:(NSString *)_text {
  NSEnumerator *enumerator = nil;
  id obj;
  id result;
  
  result = [self runCommand:
                   @"account::extended-search",
                   @"fetchGlobalIDs", yesNum,
                   @"operator",       @"OR",
                   @"name",           _text,
                   @"firstname",      _text,
                   @"description",    _text,
                   @"login",          _text,
                   @"keywords",       _text,
                  nil];
  result = [self runCommand:@"person::get-by-globalid",
                   @"gids",       result,
                   @"groupBy",    @"globalID",
                   @"attributes", personAttrSet,
                   nil];
  if (result == nil)
    return nil;

  enumerator = [result objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    NSMutableDictionary *o;
    
    if ([self->accounts containsObject:obj])
      continue;
    
    o = [obj mutableCopy];
    [o setObject:[NSMutableDictionary dictionary] forKey:@"accessCheck"];
    [self->resultList addObject:o];
    [o release];
  }
  return result;
}

- (id)_primarySearchTeam:(id)_team {
  id result;

  result = [self runCommand:
                   @"team::members",
                   @"fetchGlobalIDs", yesNum,
                   @"team", [_team globalID], nil];

  result = [self runCommand:@"person::get-by-globalid",
                   @"gids", result,
                   @"groupBy", @"globalID",                   
                   @"attributes", personAttrSet,
                   nil];
  if (result != nil) {
    NSEnumerator *enumerator;
    id           obj;

    enumerator = [result objectEnumerator];
    while ((obj = [enumerator nextObject])) {
      NSMutableDictionary *o;
      
      if ([self->accounts containsObject:obj])
        continue;

      o = [obj mutableCopy];
      [o setObject:[NSMutableDictionary dictionary]
         forKey:@"accessCheck"];
          
      [self->resultList addObject:o];
      [o release];
    }
  }
  {
    NSMutableDictionary *t;
      
    t = [[NSMutableDictionary alloc] initWithCapacity:8];
    [t setObject:[NSMutableDictionary dictionary] forKey:@"accessCheck"];
    [t setObject:[_team valueForKey:@"description"]
       forKey:@"description"];
    [t setObject:yesNum           forKey:@"isTeam"];
    [t setObject:[_team globalID] forKey:@"globalID"];
    [t setObject:[_team valueForKey:@"companyId"]
       forKey:@"companyId"];
    
    [self->resultList insertObject:t atIndex:0];
    [t release];
  }
  return result;
}

- (id)search {
  id result = nil;
  [self->allAccess release]; self->allAccess = nil;
  [self->resultList removeAllObjects];
  
  if (self->accountSearchText!=nil && [self->accountSearchText length] > 0)
    result = [self _primarySearchAccounts:self->accountSearchText];
  else if (self->searchTeam != nil)
    result = [self _primarySearchTeam:self->searchTeam];
  
  [self removeDuplicateAccountListEntries];

  if (self->accountSearchText && [self->accountSearchText length] > 0) {
    [self->searchTeam release]; 
    self->searchTeam = nil;
  }
  [self->accountSearchText release]; self->accountSearchText = nil;
  
  return nil;
}

- (id)searchLeader {
  NSArray *result = nil;

  [self->ownerResultList removeAllObjects];

  result = [self runCommand:
                 @"account::extended-search",
                 @"operator",    @"OR",
                 @"name",        self->searchOwnerText,
                 @"firstname",   self->searchOwnerText,
                 @"description", self->searchOwnerText,
                 @"login",       self->searchOwnerText,
                 @"keywords",    self->searchOwnerText,
                 nil];

  if (result != nil) {
    [self->ownerResultList addObjectsFromArray:result];
  }
  return nil;
}
- (id)companySearch {
  [self _merge:self->persons with:self->newPersons];
  [self->newPersons removeAllObjects];
  
  [self _merge:self->enterprises with:self->newEnterprises];
  [self->newEnterprises removeAllObjects];

  if ([self->companyTypeSelection isEqualToString:@"personType"]) {
    NSArray *result;

    result = [self runCommand:
                   @"person::extended-search",
                   @"operator",    @"OR",
                   @"name",        self->companySearchText,
                   @"firstname",   self->companySearchText,
                   @"description", self->companySearchText,
                   @"login",       self->companySearchText,
                   @"keywords",    self->companySearchText,
                   nil];
    if (result) {
      result = [self _diff:result with:self->accounts];
      [self setPersonResultList:[self _diff:result with:self->persons]];
      [self runCommand:@"person::enterprises",
            @"persons",     self->personResultList,
            @"relationKey", @"enterprises", nil];
    }
  }
  else {
    NSArray *result;

    result = [self runCommand:
                   @"enterprise::extended-search",
                   @"operator",    @"OR",
                   @"number",      self->companySearchText,
                   @"description", self->companySearchText,
                   @"login",       self->companySearchText,
                   nil];
    if (result)
      [self setEnterpriseResultList:[self _diff:result with:self->enterprises]];
  }
  return nil;
}

- (BOOL)isOwnerAssigned {
  return (self->ownerSelection != nil) ? YES : NO;
}

- (BOOL)hasAssociatedTasks {
  NSArray *jobRel;
  
  jobRel = [[self object] valueForKey:@"toJob"];
  return [jobRel count] == 0 ? NO : YES;
}
- (BOOL)hasOneAssociatedDocument { /* TODO: explain */
  NSArray *docRel;
  
  docRel = [[self object] valueForKey:@"toDocument"];
  return [docRel count] == 1 ? YES : NO;
}
- (BOOL)hasAssociatedCompanies {
  NSArray *companyRel;
  
  companyRel = [[self object] valueForKey:@"toProjectCompanyAssignment"];
  return [companyRel count] == 0 ? NO : YES;
}

- (BOOL)isActiveAccountOwnerOrRoot {
  OGoSession *sn;
  NSNumber   *accountId;
  
  sn = [self session];
  if ([sn activeAccountIsRoot])
    return YES;
  
  accountId = [[sn activeAccount] valueForKey:@"companyId"];
  return [accountId isEqual:[[self object] valueForKey:@"ownerId"]];
}

- (BOOL)hasAssociatedTeam {
  // TODO: explain, I actually don't know what 'teamId' does
  return [[[self object] valueForKey:@"teamId"] isNotNull];
}

- (BOOL)isDeleteDisabled {
  if ([self isInNewMode])
    return YES;
  
  /* delete is disabled as long as other objects are connected */
  if (![self isActiveAccountOwnerOrRoot]) return YES;
  if ([self hasAssociatedTeam])           return YES;
  if ([self hasAssociatedTasks])          return YES;
  if (![self hasOneAssociatedDocument])   return YES;
  if ([self hasAssociatedCompanies])      return YES;
  return NO; /* enabled */
}

/* datasource */

- (EODataSource *)projectDataSource {
  SkyProjectDataSource *ds;
  LSCommandContext *ctx;
  
  ctx = [(OGoSession *)[self session] commandContext];
  ds  = [SkyProjectDataSource alloc]; /* to keep gcc 3 happy */
  return [[ds initWithContext:ctx] autorelease];
}
- (EOFetchSpecification *)fetchSpecificationForProjectNumber:(NSString *)_pn {
  EOFetchSpecification *fs;
  EOQualifier          *qual;
  NSDictionary         *hints;
  
  qual = [EOQualifier qualifierWithQualifierFormat:@"number=%@", _pn];
  
  hints = [NSDictionary dictionaryWithObject:yesNum
			forKey:@"SearchAllProjects"];
  fs = [[EOFetchSpecification alloc] initWithEntityName:nil
				     qualifier:qual sortOrderings:nil
				     usesDistinct:YES isDeep:NO hints:hints];
  return [fs autorelease];
}

/* actions */

- (BOOL)isProjectNumberAvailable:(id)_pNumber {
  EODataSource *pds;
  unsigned int count;
  
  if (![_pNumber isNotNull]) /* auto-assign number */
    return YES;
  if ([_pNumber length] == 0) /* auto-assign number */
    return YES;
  
  pds = [self projectDataSource];
  [pds setFetchSpecification:
	 [self fetchSpecificationForProjectNumber:_pNumber]];
  count = [[pds fetchObjects] count];
  return (count == 0) ? YES : NO;
}

- (NSArray *)_fetchMemberEOsForTeamEOs:(NSArray *)_teams {
  NSArray *members;
  
  if (![_teams isNotNull])
    return nil;
  
  if ((members = [_teams valueForKey:@"members"]) != nil)
    return members;
  
  return [self runCommand:@"team::members", @"object", _teams, nil];
}

- (BOOL)checkConstraints {
  // TODO: split up method!
  id              project;
  NSCalendarDate  *begin, *end;
  NSString        *pName;
  NSArray         *members;
  NSString        *pNumber;
  NSMutableString *error = nil;
  id              labels;

  project = [self snapshot];
  begin   = [project valueForKey:@"startDate"];
  end     = [project valueForKey:@"endDate"];
  pName   = [project valueForKey:@"name"];
  pNumber = [project valueForKey:@"number"];
  labels  = [self labels];
  error   = [NSMutableString stringWithCapacity:128];
  
  if (begin == nil) 
    [error appendString:[labels valueForKey:@"error_no_start_date"]];
  if (end == nil) 
    [error appendString:[labels valueForKey:@"error_no_end_date"]];
  if (pName == nil || [pName length] == 0) 
    [error appendString:[labels valueForKey:@"error_no_project_name"]];
  
  if ([self isInNewMode]) {
    if (![self isProjectNumberAvailable:pNumber])
      [error appendString:[labels valueForKey:@"error_pcode_not_unique"]];
  }

  members = [self _fetchMemberEOsForTeamEOs:self->teamSelection];
  
  if ([self->teamSelection isNotNull] &&
      ![members containsObject:self->ownerSelection] &&
      ![self->ownerSelection isEqual:[[self session] activeAccount]]) {
    NSString *e;
    
    e = [NSString stringWithFormat:
                  [labels valueForKey:@"error_leader_not_in_team"],
                  [self->ownerSelection valueForKey:@"fullNameLabel"],
                  [self->teamSelection valueForKey:@"description"]];
    [error appendString:e];
  }

  if ([error length] > 0) {
    [self setErrorString:error];
    return YES;
  }
  [self setErrorString:nil];

  return NO;
}

- (BOOL)checkConstraintsForSave {
  return ![self checkConstraints];
}

- (void)_prepareAccountForInsert:(id)a {
    unsigned char *str;
    int           strCnt;
    id            k;
    NSDictionary  *dic;
    NSEnumerator  *keyEnum;
    NSString      *ar;
    
    dic    = [a valueForKey:@"accessCheck"];
    str    = calloc([dic count] + 2, sizeof(char));
    strCnt = 0;
    
    keyEnum = [dic keyEnumerator];
    while ((k = [keyEnum nextObject])) {
      if (![[dic objectForKey:k] boolValue])
	continue;
      
      str[strCnt] = [k cString][0];
      strCnt++;
    }
    ar = [[NSString alloc] initWithCString:str length:strCnt];
    [a setObject:ar forKey:@"accessRight"];
    [ar release];
}
- (NSArray *)_prepareAccountsForInsert:(NSArray *)_accounts {
  NSEnumerator *enumerator;
  id           a;
  
  enumerator = [_accounts objectEnumerator];
  while ((a = [enumerator nextObject]))
    [self _prepareAccountForInsert:a];
  return _accounts;
}

- (BOOL)_ensureProjectBase {
  if ([self->projectBase length] == 0) {
    if (![self hasMoreThanOneProjectBases]) {
      [self logWithFormat:
	      @"Note: autoselecting FileSystem storage for new project"];
      self->projectBase = @"FileSystem";
    }
    else {
      // TODO: labels!
      [self setErrorString:@"Please specify your project storage!"];
      return NO;
    }
  }
  return YES;
}

- (id)insertObject {
  // TODO: make pluggable! split up!
  LSCommandContext *cmdctx;
  NSURL *url;
  id project;
  id newProject = nil;
  
  if (![self _ensureProjectBase])
    return nil;
  
  project = [self snapshot];

  cmdctx = [[self session] commandContext];
  url    = [fmFactory newURLForProjectBase:self->projectBase
		      stringValue:[project valueForKey:@"url"]
		      commandContext:cmdctx];
  [project takeValue:[url stringValue] forKey:@"url"];
  
  [project takeValue:[self _prepareAccountsForInsert:self->accounts]
           forKey:@"accounts"];
  [project takeValue:self->accountsToRemove forKey:@"removedAccounts"];

  [project takeValue:noNum forKey:@"isFake"];

  if (self->ownerSelection != nil) {
    [project takeValue:[self->ownerSelection
                            valueForKey:@"companyId"] forKey:@"ownerId"];
  }

  if ([project valueForKey:@"team"] == nil &&
      self->ownerSelection == nil) {
    [project takeValue:[[[self session] activeAccount]
                               valueForKey:@"companyId"] forKey:@"ownerId"];
    [project takeValue:null forKey:@"teamId"];
  }
  newProject = [self runCommand:@"project::new" arguments:project];

  if (newProject)
    [self _updateAssignmentsForObj:newProject];  

  return newProject;
}

- (id)updateObject {
  id project;

  project = [self snapshot];

  [project takeValue:[self _prepareAccountsForInsert:self->accounts]
           forKey:@"accounts"];
  [project takeValue:self->accountsToRemove forKey:@"removedAccounts"];

  [self _updateAssignmentsForObj:[self object]];

  if (self->ownerSelection != nil) {
    [project setObject:[self->ownerSelection valueForKey:@"companyId"]
                forKey:@"ownerId"];
  }
  project = [self runCommand:@"project::set" arguments:project];
  [self runCommand:@"project::get-company-assignments",
                @"object",     project,
                @"relationKey", @"companyAssignments", nil];
  return project;
}

- (id)deleteObject {
  return [[self object] run:@"project::delete", @"reallyDelete", yesNum, nil];
}

- (void)__clear {
  NSEnumerator *enumerator;
  id           o;

  enumerator = [self->accounts objectEnumerator];
  while ((o = [enumerator nextObject]))
    [o setObject:null forKey:@"accessCheck"];
  
  enumerator = [self->resultList objectEnumerator];
  while ((o = [enumerator nextObject]))
    [o setObject:null forKey:@"accessCheck"];

  [self clearEditor];
  [self->accounts removeAllObjects];
  [self->resultList removeAllObjects];

  [self->allAccess release]; self->allAccess = nil;
}

- (void)_setProperties {
  NSArray *keys = nil;
  int i, cnt;

  keys = [self publicExtendedProjectAttributes];
  keys = [keys valueForKey:@"key"];

  for (i = 0, cnt = [keys count]; i < cnt; i++) {
    id key = [keys objectAtIndex:i];

    [self->props takeValue:[[self project] valueForKey:key] forKey:key];
  }

  keys = [self privateExtendedProjectAttributes];
  keys = [keys valueForKey:@"key"];

  for (i = 0, cnt = [keys count]; i < cnt; i++) {
    id key = [keys objectAtIndex:i];

    [self->props takeValue:[[self project] valueForKey:key] forKey:key];
  }
}

- (id)save {
  NSException *exc;
  NSString    *cmd;

  [self _setProperties];
  if (![self saveAndGoBackWithCount:1])
    return nil;

  exc = [[self propertyManager]
          takeProperties:self->props globalID:[[self object] globalID]];
  if (exc) {
    [self setErrorString:[exc description]];
    return nil;
  }
  
  if (self->company == nil)
    return nil;
  
  if ([[self navigation] activePage] == self)
    return nil;
  
  cmd = [[[self->company entity] name] lowercaseString];
  cmd = [cmd stringByAppendingString:@"::assign-projects"];

  [self->company run:cmd, @"projects",
       [NSArray arrayWithObject:[self object]], nil];

  if ([self commit])
    return nil;
  
  [self rollback];
  [self enterPage:self];
  return nil;
}

- (id)cancel {
  [self _resetRightsInAccounts:self->accounts];
  [self __clear];
  return [super cancel];
}

- (id)archive {
  [self runCommand:@"project::archive", @"object", [self object], nil];

  if (![self commit]) {
    [self rollback];
    [self setErrorString:@"Couldn't commit project::archive !"];
    return nil;
  }
  [self postChange:LSWUpdatedProjectNotificationName onObject:[self object]];
  [self leavePage];
  return nil;
}
  
- (BOOL)hasResult {
  if ([self->accounts count] > 0) {
    if ([self->resultList count] > 0)
      return YES;
  }
  return NO;
}

/* LSWProjectEditor(PrivatMethodes) */

- (void)_updateAssignmentsForObj:(id)_obj {
  [self _merge:self->persons     with:self->newPersons];
  [self _merge:self->enterprises with:self->newEnterprises];

  [self runCommand:@"project::assign-accounts",
    @"project",         _obj,
    @"hasAccess",       noNum,
    @"companies",       
	[self _diff:self->enterprises with:self->oldEnterprises],
    @"removedCompanies",
	[self _diff:self->oldEnterprises with:self->enterprises],
    nil];
  
  [self runCommand:@"project::assign-accounts",
        @"project",         _obj,
        @"hasAccess",       noNum,
        @"companies",       [self _diff:self->persons with:self->oldPersons],
        @"removedCompanies",[self _diff:self->oldPersons with:self->persons],
        nil];
}

- (NSArray *)_diff:(NSArray *)_list1 with:(NSArray *)_list2 {
  int             i, count;
  NSMutableArray *result;

  count  = [_list1 count];
  result = [NSMutableArray array];

  for (i = 0; i < count; i++) {
    int  j,count2;
    id   pkey;
    BOOL isInList;
                                                                               
    count2   = [_list2 count];
    pkey     = [[_list1 objectAtIndex:i] valueForKey:@"companyId"];
    isInList = NO;
                                                                               
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
  unsigned i, count;
  
  for (i = 0, count = [_list count]; i < count; i++) {
    int      j, count2;
    NSNumber *pkey;
    BOOL     isInList = NO;
    
    count2 = [_resultList count];
    pkey   = [[_list objectAtIndex:i] valueForKey:@"companyId"];
    if (pkey == nil) continue;
    
    for (j = 0; j < count2; j++) {
      NSNumber *pkey2;
      
      pkey2 = [[_resultList objectAtIndex:j] valueForKey:@"companyId"];
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

- (void)_setLabelForAccount:(id)_part {
  // TODO: should be a formatter!
  // TODO: this code seems to be a copy from LSWScheduler
  id        p;
  NSString *d;
  
  p = _part;
  
  if ((d = [p valueForKey:@"name"]) == nil) {
    if ((d = [p valueForKey:@"login"]) == nil) {
      if ((d = [p valueForKey:@"description"]) == nil) {
	d = [NSString stringWithFormat:@"pkey<%@>",
		        [p valueForKey:@"companyId"]];
      }
    }
  }
  else {
    NSString *fd;
    
    if ((fd = [p valueForKey:@"firstname"]) != nil)
      d = [NSString stringWithFormat:@"%@, %@", d, fd];
  }
  [p takeValue:d forKey:@"fullNameLabel"];
}

- (void)_updateAccountResultList:(NSArray *)_list {
  NSEnumerator *partEnum;
  id           part;

  partEnum = [_list objectEnumerator];

  while ((part = [partEnum nextObject])) {
    [self _setLabelForAccount:part];
  }
}

- (BOOL)hasAccounts {
  return ([self->accounts count] == 0) ? NO : YES;
}

- (NSArray *)allAccess {
  NSEnumerator   *enumerator;
  NSMutableArray *array;
  id             o;
  int            cnt;
  
  if (self->allAccess)
    return self->allAccess;

  array      = [NSMutableArray array];
  cnt        = 0;
  enumerator = [self->resultList objectEnumerator];
  while ((o = [enumerator nextObject])) {
    if ([[[o valueForKey:@"globalID"] entityName] isEqualToString:@"Team"]) {
      [array insertObject:o atIndex:0];
      cnt++;
    }
    else
      [array addObject:o];
  }
  enumerator = [self->accounts objectEnumerator];
  while ((o = [enumerator nextObject])) {
    if ([[[o valueForKey:@"globalID"] entityName] isEqualToString:@"Team"]) {
      [array insertObject:o atIndex:0];
      cnt++;
    }
    else
      [array insertObject:o atIndex:cnt];
  }
  self->allAccess = [array copy];
  return self->allAccess;
}

- (SkyObjectPropertyManager *)propertyManager {
  LSCommandContext *cmdctx;
  
  cmdctx = [(OGoSession *)[self existingSession] commandContext];
  return [cmdctx propertyManager];
}

- (BOOL)hasMoreThanOneProjectBases {
  return [projectBases count] != 1 ? YES : NO;
}

- (NSArray *)projectBases {
  return projectBases;
}
- (NSArray *)licensedBases {
  // DEPRECATED!
  [self debugWithFormat:@"Note: Deprecated -licensedBases method was called."];
  return projectBases;
}

- (NSString *)projectBaseLabel {
  return [[self labels] valueForKey:[self item]];
}

- (NSString *)projectBase {
  return self->projectBase;
}
- (void)setProjectBase:(NSString *)_base {
  ASSIGN(self->projectBase, _base);
}

- (BOOL)showProjectURL {
  NSString *url;

  /* only allow root to edit URLs! */
  if (![[self session] activeAccountIsRoot])
    return NO;
  
  // TODO: the check is really for the "FileSystem" project base
  if ([(url = [[self object] valueForKey:@"url"]) isNotNull])
    return [url hasPrefix:@"file:"];
  
  /* no URL is set so far, so allow editing (for root!) */
  return YES;
}

- (BOOL)oldProjectCompatiblity {
  return OldProjectCompatiblity ? YES : NO;
}

@end /* LSWProjectEditor */
