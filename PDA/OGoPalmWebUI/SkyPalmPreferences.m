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

#include <OGoFoundation/LSWContentPage.h>
#include <OGoPalmUI/SkyPalmEntryListState.h>

@class NSUserDefaults, NSArray, NSMutableDictionary;
@class SkyPalmEntryListState;
@class NSMutableArray;

@interface SkyPalmPreferences : LSWContentPage
{
  id             account;
  NSUserDefaults *defaults;
  // address settings
  SkyPalmEntryListState *addressListState;

  // date settings
  SkyPalmEntryListState *dateListState;

  // memo settings
  SkyPalmEntryListState *memoListState;

  // job settings
  SkyPalmEntryListState *jobListState;

  // helper
  id             item;

  // palm address skyrix sync
  NSArray               *palmAddressAttributes;
  NSArray               *skyrixPersonAttributes;
  NSArray               *skyrixEnterpriseAttributes;
  NSMutableDictionary   *palm2SkyrixMappingAddressPerson;
  NSMutableDictionary   *palm2SkyrixMappingAddressEnterprise;
  // mapping for skyrix address values
  NSMutableDictionary   *skyrix2PalmMappingPersonAddress;
  NSMutableDictionary   *skyrix2PalmMappingEnterpriseAddress;
  id                    attribute;

  NSArray *availableConduits;

  /* ogo scheduler default access settings */
  // available teams
  NSArray *ogoDateAccessTeams;
  // selected team;
  id selectedOgoDateAccessTeam;
  // mutable array for the skyaptselection
  NSMutableArray *ogoDateWriteAccess;
  // selected write access teams / accounts
  NSArray        *selectedOgoDateWriteAccess;
}

- (id)defaults;
- (NSArray *)_fetchTeams;

static NSMutableArray *_getGIDSforIds(SkyPalmPreferences *self,
                                      NSArray *_ids, NSString *_entityName); 
@end /* SkyPalmPreferences */

#include "common.h"
#include <OGoPalm/SkyPalmAddressDocument.h>
#include <NGExtensions/NGBundleManager.h>
#include <LSFoundation/LSFoundation.h>
#include <GDLAccess/GDLAccess.h>

@interface OGoSession(SkyPalmEntryListMethods)
- (NSNotificationCenter *)notificationCenter;
@end

@implementation SkyPalmPreferences

+ (void)initialize {
  // make sure that SkyPalmDocument is loaded
  [[[SkyPalmAddressDocument alloc] init] release];
}

- (void)_clearVars {
  ASSIGN(self->account,                             nil);
  ASSIGN(self->defaults,                            nil);
  ASSIGN(self->addressListState,                    nil);
  ASSIGN(self->dateListState,                       nil);
  ASSIGN(self->memoListState,                       nil);
  ASSIGN(self->jobListState,                        nil);
  ASSIGN(self->item,                                nil);
  ASSIGN(self->palmAddressAttributes,               nil);
  ASSIGN(self->skyrixPersonAttributes,              nil);
  ASSIGN(self->skyrixEnterpriseAttributes,          nil);  
  ASSIGN(self->palm2SkyrixMappingAddressPerson,     nil);
  ASSIGN(self->palm2SkyrixMappingAddressEnterprise, nil);
  ASSIGN(self->skyrix2PalmMappingPersonAddress,     nil);
  ASSIGN(self->skyrix2PalmMappingEnterpriseAddress, nil);
  ASSIGN(self->attribute,                           nil);
  ASSIGN(self->availableConduits,                   nil);
  // scheduler default access
  ASSIGN(self->ogoDateAccessTeams, nil);
  ASSIGN(self->selectedOgoDateAccessTeam, nil);
  ASSIGN(self->ogoDateWriteAccess, nil);
  ASSIGN(self->selectedOgoDateWriteAccess, nil);
}

- (void)dealloc {
  [self _clearVars];
  [super dealloc];
}

// accessors

- (BOOL)isEditorPage {
  return YES;
}

- (void)setAccount:(id)_account {
  id companyId;
  id tmp;
  
  [self _clearVars];

  ASSIGN(self->account,_account);

  tmp = (_account != nil)
    ? [self runCommand:@"userdefaults::get",
            @"user", _account, nil]
    : [self runCommand:@"userdefaults::get", nil];
  ASSIGN(self->defaults, tmp);

  companyId = [_account valueForKey:@"companyId"];

  tmp = [SkyPalmEntryListState listStateWithDefaults:self->defaults
                               companyId:companyId
                               subKey:@""
                               forPalmDb:@"AddressDB"];
  ASSIGN(self->addressListState,tmp);
  
  tmp = [SkyPalmEntryListState listStateWithDefaults:self->defaults
                               companyId:companyId
                               subKey:@""
                               forPalmDb:@"DatebookDB"];
  ASSIGN(self->dateListState,tmp);
  
  tmp = [SkyPalmEntryListState listStateWithDefaults:self->defaults
                               companyId:companyId
                               subKey:@""
                               forPalmDb:@"MemoDB"];
  ASSIGN(self->memoListState,tmp);
  
  tmp = [SkyPalmEntryListState listStateWithDefaults:self->defaults
                               companyId:companyId
                               subKey:@""
                               forPalmDb:@"ToDoDB"];
  ASSIGN(self->jobListState,tmp);


  /* write access defaults */
  self->ogoDateWriteAccess =
    [_getGIDSforIds(self,
                    [self->defaults arrayForKey:
                         @"ogopalm_default_scheduler_write_access_accounts"],
                    @"Person") mutableCopy];
  [self->ogoDateWriteAccess addObjectsFromArray:
       _getGIDSforIds(self,
                      [self->defaults arrayForKey:
                           @"ogopalm_default_scheduler_write_access_teams"],
                      @"Team")];
  self->selectedOgoDateWriteAccess =
    [[NSArray alloc] initWithArray:self->ogoDateWriteAccess];

  /* read access defaults */
  self->ogoDateAccessTeams = [[self _fetchTeams] retain];
  {
    NSString *accessTeamId;
    accessTeamId =
      [self->defaults stringForKey:
           @"ogopalm_default_scheduler_read_access_team"];
    if ([accessTeamId length]) {
      NSEnumerator *e = [self->ogoDateAccessTeams objectEnumerator];
      id team;
      while ((team = [e nextObject])) {
        if ([[[team valueForKey:@"companyId"] stringValue]
                    isEqualToString:accessTeamId]) {
          ASSIGN(self->selectedOgoDateAccessTeam, team);
          break;
        }
      }
    }
    else {
      ASSIGN(self->selectedOgoDateAccessTeam, nil);
    }
  }
} /* setAccount */

- (id)account {
  return self->account;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item,_item);
}
- (id)item {
  return self->item;
}

- (NSString *)conflictHandlingLabelKey {
  return [NSString stringWithFormat:@"conflict_handling_%@", self->item];
}
- (NSString *)conflictNotificationLabelKey {
  return [NSString stringWithFormat:@"conflict_notification_%@", self->item];
}

- (NSString *)importOGoContactsLabelKey {
  return [NSString stringWithFormat:@"import_ogo_contacts_%@", self->item];
}
- (NSString *)importPalmDatesLabelKey {
  return [NSString stringWithFormat:@"import_palm_dates_%@", self->item];
}
- (NSString *)importPalmContactsLabelKey {
  return [NSString stringWithFormat:@"import_palm_contacts_%@", self->item];
}

// list states
- (void)setAddressListState:(SkyPalmEntryListState *)_state {
  ASSIGN(self->addressListState,_state);
}
- (SkyPalmEntryListState *)addressListState {
  return self->addressListState;
}
- (void)setDateListState:(SkyPalmEntryListState *)_state {
  ASSIGN(self->dateListState,_state);
}
- (SkyPalmEntryListState *)dateListState {
  return self->dateListState;
}
- (void)setMemoListState:(SkyPalmEntryListState *)_state {
  ASSIGN(self->memoListState,_state);
}
- (SkyPalmEntryListState *)memoListState {
  return self->memoListState;
}
- (void)setJobListState:(SkyPalmEntryListState *)_state {
  ASSIGN(self->jobListState,_state);
}
- (SkyPalmEntryListState *)jobListState {
  return self->jobListState;
}

/* date access defaults */
- (NSArray *)ogoDateWriteAccess {
  return self->ogoDateWriteAccess;
}
- (void)setOgoDateWriteAccess:(NSArray *)_access {
  ASSIGN(self->ogoDateWriteAccess,_access);
}

- (NSArray *)selectedOgoDateWriteAccess {
  return self->selectedOgoDateWriteAccess;
}
- (void)setSelectedOgoDateWriteAccess:(NSArray *)_access {
  ASSIGN(self->selectedOgoDateWriteAccess,_access);
}

- (NSArray *)ogoDateAccessTeams {
  return self->ogoDateAccessTeams;
}
- (void)setOgoDateAccessTeams:(NSArray *)_teams {
  ASSIGN(self->ogoDateAccessTeams,_teams);
}
- (id)selectedOgoDateAccessTeam {
  return self->selectedOgoDateAccessTeam;
}
- (void)setSelectedOgoDateAccessTeam:(id)_team {
  ASSIGN(self->selectedOgoDateAccessTeam,_team);
}

// palm address skyrix synchronisation

// palmAttributes
- (NSArray *)palmAddressAttributes {
  if (self->palmAddressAttributes == nil) {
    id tmp;

    tmp = [[self defaults] dictionaryForKey:@"OGoPalmAddress_Palm_Attributes"];
    tmp = [tmp allKeys];
    tmp = [tmp sortedArrayUsingSelector:@selector(compare:)];
    ASSIGN(self->palmAddressAttributes,tmp);
  }
  return self->palmAddressAttributes;
}

- (NSArray *)_validExtendedAttributesForEntity:(NSString *)_entity
                                          type:(NSString *)_type
{
  id             tmp;
  NSEnumerator   *e;
  NSMutableArray *valid;

  valid = [NSMutableArray array];
  tmp   = [NSString stringWithFormat:@"Sky%@Extended%@Attributes",
                    _type, _entity];
  tmp   = [[self defaults] arrayForKey:tmp];
  e     = [tmp objectEnumerator];
  
  while ((tmp = [e nextObject])) {
    // no bool values
    if ([[tmp valueForKey:@"type"] intValue] == 2)
      continue;
    [valid addObject:[tmp valueForKey:@"key"]];
  }
  return valid;
}
- (NSArray *)skyrixPersonAttributes {
  if (self->skyrixPersonAttributes == nil) {
    NSMutableArray *allAttr;
    id             tmp;

    allAttr = [NSMutableArray array];    
    tmp     = [self _validExtendedAttributesForEntity:@"Person" type:@"Public"];
    [allAttr addObjectsFromArray:tmp];
    tmp = [self _validExtendedAttributesForEntity:@"Person" type:@"Private"];
    [allAttr addObjectsFromArray:tmp];
    tmp =
      [[self defaults] dictionaryForKey:@"OGoPalmAddress_Person_Attributes"];
    [allAttr addObjectsFromArray:[tmp allKeys]];
    [allAttr addObject:@"00nothing"];
    tmp = [allAttr sortedArrayUsingSelector:@selector(compare:)];
    ASSIGN(self->skyrixPersonAttributes,tmp);
  }
  return self->skyrixPersonAttributes;
}
- (NSArray *)skyrixEnterpriseAttributes {
  if (self->skyrixEnterpriseAttributes == nil) {
    NSMutableArray *allAttr;
    id             tmp;

    allAttr = [NSMutableArray array];
    tmp = [self _validExtendedAttributesForEntity:@"Enterprise"
                type:@"Public"];
    [allAttr addObjectsFromArray:tmp];
    tmp = [self _validExtendedAttributesForEntity:@"Enterprise"
                type:@"Private"];
    [allAttr addObjectsFromArray:tmp];
    tmp =
      [[self defaults] dictionaryForKey:
           @"OGoPalmAddress_Enterprise_Attributes"];
    [allAttr addObjectsFromArray:[tmp allKeys]];
    [allAttr addObject:@"00nothing"];
    tmp = [allAttr sortedArrayUsingSelector:@selector(compare:)];
    ASSIGN(self->skyrixEnterpriseAttributes,tmp);
  }
  return self->skyrixEnterpriseAttributes;
}

// selected attributes for person
- (NSMutableDictionary *)palm2SkyrixMappingAddressPerson {
  if (self->palm2SkyrixMappingAddressPerson == nil) {
    self->palm2SkyrixMappingAddressPerson =
      [[[self defaults] dictionaryForKey:
            @"OGoPalmAddress_Person_AttributeMapping"] mutableCopy];
  }
  return self->palm2SkyrixMappingAddressPerson;
}
- (void)setSkyrixAddressPersonAttributeOfItem:(NSString *)_val {
  if ((![_val length]) || ([_val isEqualToString:@"00nothing"]))
    [[self palm2SkyrixMappingAddressPerson] removeObjectForKey:self->item];
  else
    [[self palm2SkyrixMappingAddressPerson] setObject:_val forKey:self->item];
}
- (NSString *)skyrixAddressPersonAttributeOfItem {
  NSString *sAttr;
  
  sAttr = [[self palm2SkyrixMappingAddressPerson] valueForKey:self->item];
  return (sAttr == nil)
    ? (NSString *)@"00nothing"
    : sAttr;
}
- (NSArray *)palmKeysWithoutPhoneKeys {
  static NSArray *_palmKeysWithoutPhoneKeys = nil;
  if (_palmKeysWithoutPhoneKeys == nil) {
    id             tmp, one, cfg;
    NSEnumerator   *e;
    NSMutableArray *ma;

    ma  = [NSMutableArray array];
    tmp = [[self defaults] dictionaryForKey:@"OGoPalmAddress_Palm_Attributes"];
    e   = [tmp keyEnumerator];

    [ma addObject:@"00nothing"];

    // going to all palm attributes
    while ((one = [e nextObject])) {
      cfg = [tmp valueForKey:one];
      // checking config for palm attribute
      if ([cfg valueForKey:@"labelId"] == nil) {
        // no phone label id set  --> not a phone key
        [ma addObject:one];
      }
    }
    _palmKeysWithoutPhoneKeys =
      [[ma sortedArrayUsingSelector:@selector(compare:)] retain];
  }
  return _palmKeysWithoutPhoneKeys;
}
- (NSMutableDictionary *)skyrix2PalmMappingPersonAddress {
  if (self->skyrix2PalmMappingPersonAddress == nil) {
    self->skyrix2PalmMappingPersonAddress =
      [[[self defaults] dictionaryForKey:
            @"OGoPalmAddress_Person_AddressMapping"] mutableCopy];
  }
  return self->skyrix2PalmMappingPersonAddress;
}
- (void)setPalmAttributeForSkyrixPersonAddressAttribute:(NSString *)_palmAttr {
  if ((![_palmAttr length]) || ([_palmAttr isEqualToString:@"00nothing"]))
    [[self skyrix2PalmMappingPersonAddress]
           removeObjectForKey:self->attribute];
  else
    [[self skyrix2PalmMappingPersonAddress]
           setObject:_palmAttr forKey:self->attribute];
}
- (NSString *)palmAttributeForSkyrixPersonAddressAttribute {
  NSString *pAttr;
  
  pAttr = [[self skyrix2PalmMappingPersonAddress] valueForKey:self->attribute];
  return (pAttr == nil)
    ? (NSString *)@"00nothing"
    : pAttr;  
}

// selected attributes for enterprise
- (NSMutableDictionary *)palm2SkyrixMappingAddressEnterprise {
  if (self->palm2SkyrixMappingAddressEnterprise == nil) {
    self->palm2SkyrixMappingAddressEnterprise =
      [[[self defaults] dictionaryForKey:
            @"OGoPalmAddress_Enterprise_AttributeMapping"] mutableCopy];
  }
  return self->palm2SkyrixMappingAddressEnterprise;
}
- (void)setSkyrixAddressEnterpriseAttributeOfItem:(NSString *)_val {
  if ((![_val length]) || ([_val isEqualToString:@"00nothing"]))
    [[self palm2SkyrixMappingAddressEnterprise]
           removeObjectForKey:self->item];
  else
    [[self palm2SkyrixMappingAddressEnterprise]
           setObject:_val forKey:self->item];
}
- (NSString *)skyrixAddressEnterpriseAttributeOfItem {
  NSString *sAttr;
  
  sAttr = [[self palm2SkyrixMappingAddressEnterprise] valueForKey:self->item];
  return (sAttr == nil)
    ? (NSString *)@"00nothing"
    : sAttr;
}
- (NSMutableDictionary *)skyrix2PalmMappingEnterpriseAddress {
  if (self->skyrix2PalmMappingEnterpriseAddress == nil) {
    self->skyrix2PalmMappingEnterpriseAddress =
      [[[self defaults] dictionaryForKey:
            @"OGoPalmAddress_Enterprise_AddressMapping"] mutableCopy];
  }
  return self->skyrix2PalmMappingEnterpriseAddress;
}
- (void)setPalmAttributeForSkyrixEnterpriseAddressAttribute:(NSString *)_palmAttr
{
  if ((![_palmAttr length]) || ([_palmAttr isEqualToString:@"00nothing"]))
    [[self skyrix2PalmMappingEnterpriseAddress]
           removeObjectForKey:self->attribute];
  else
    [[self skyrix2PalmMappingEnterpriseAddress]
           setObject:_palmAttr forKey:self->attribute];
}
- (NSString *)palmAttributeForSkyrixEnterpriseAddressAttribute {
  NSString *pAttr;
  pAttr = [[self skyrix2PalmMappingEnterpriseAddress]
                 valueForKey:self->attribute];
  return (pAttr == nil)
    ? (NSString *)@"00nothing"
    : pAttr;
}

// addresstypes
- (NSArray *)personAddressTypes {
  NSMutableArray *types;

  types = [NSMutableArray array];
  [types addObjectsFromArray:
         [[[self defaults] dictionaryForKey:@"LSAddressType"]
                          valueForKey:@"Person"]];
  [types addObject:@""];
  return [types sortedArrayUsingSelector:@selector(compare:)];
}
- (NSArray *)enterpriseAddressTypes {
  NSMutableArray *types;

  types = [NSMutableArray array];
  [types addObjectsFromArray:
         [[[self defaults] dictionaryForKey:@"LSAddressType"]
                          valueForKey:@"Enterprise"]];
  [types addObject:@""];
  return [types sortedArrayUsingSelector:@selector(compare:)];
}

// accessors
- (void)setAttribute:(NSString *)_attribute {
  ASSIGN(self->attribute,_attribute);
}
- (NSString *)attribute {
  return self->attribute;
}
- (NSString *)palmAttributeKey {
  return [NSString stringWithFormat:@"attribute_%@", self->item];
}
- (NSString *)skyrixAttributeKey {
  return [NSString stringWithFormat:@"skyrixAttribute_%@", self->attribute];
}
- (NSString *)skyrixAddressTypeKey {
  return [NSString stringWithFormat:@"skyrixAddressType_%@", self->item];
}

- (NSString *)autoScrollItemLabelKey {
  return [NSString stringWithFormat:@"autoScrollSize_%@", self->item];
}

- (NSArray *)availableConduits {
  static NSArray *defaultConduits = nil;
  
  if (defaultConduits == nil)
    defaultConduits = 
      [[NSArray alloc] initWithObjects:@"AddressDB", @"DatebookDB",
                       @"MemoDB", @"ToDoDB", nil];
  
  if (self->availableConduits == nil) {
    NGBundleManager *bm;
    NSArray         *conduits;
    
    bm       = [NGBundleManager defaultBundleManager];
    conduits = [bm providedResourcesOfType:@"SkyPalmDataSources"];
    conduits = [conduits valueForKey:@"palmDb"];
    self->availableConduits =
      [[defaultConduits arrayByAddingObjectsFromArray:conduits] retain];
  }
  return self->availableConduits;
}

// import dates
- (NSString *)importOGoDatesFrom {
  NSString *from;
  int i;
  from = [[self defaults] valueForKey:@"SkyPalm_DatePreSync_daysPast"];
  i = [from intValue];
  return i > 0 ? from : (NSString *)@"10";
}
- (void)setImportOGoDatesFrom:(NSString *)_val {
  int i;
  i = [_val intValue];
  if (i <= 0) i = 10;
  [[self defaults] takeValue:[NSString stringWithFormat:@"%i", i]
                   forKey:@"SkyPalm_DatePreSync_daysPast"];
}
- (NSString *)importOGoDatesTo {
  NSString *to;
  int i;
  to = [[self defaults] valueForKey:@"SkyPalm_DatePreSync_daysFuture"];
  i = [to intValue];
  return i > 0 ? to : (NSString *)@"10";
}
- (void)setImportOGoDatesTo:(NSString *)_val {
  int i;
  i = [_val intValue];
  if (i <= 0) i = 10;
  [[self defaults] takeValue:[NSString stringWithFormat:@"%i", i]
                   forKey:@"SkyPalm_DatePreSync_daysFuture"];
}

- (void)setOGoPalmConflictHandling:(int)_val {
  NSLog(@"%s %i", __PRETTY_FUNCTION__, _val);
  [self->defaults takeValue:[NSString stringWithFormat:@"%i", _val]
       forKey:@"ogopalm_ogo_conflict_handling"];
}
- (int)oGoPalmConflictHandling {
  NSLog(@"%s: %@", __PRETTY_FUNCTION__,
        [self->defaults valueForKey:@"ogopalm_ogo_conflict_handling"]);
  return [[self->defaults valueForKey:@"ogopalm_ogo_conflict_handling"]
                          intValue];
}
- (void)setOGoPalmConflictNotification:(int)_val {
  NSLog(@"%s %i", __PRETTY_FUNCTION__, _val);
  [self->defaults takeValue:[NSString stringWithFormat:@"%i", _val]
       forKey:@"ogopalm_ogo_conflict_notification"];
}
- (int)oGoPalmConflictNotification {
  NSLog(@"%s: %@", __PRETTY_FUNCTION__,
        [self->defaults valueForKey:@"ogopalm_ogo_conflict_notification"]);
  return [[self->defaults valueForKey:@"ogopalm_ogo_conflict_notification"]
                          intValue];
}

// actions
- (id)cancel {
  [self leavePage];
  return nil;
}

- (id)defaults {
  if (self->defaults == nil)
    return [[self session] userDefaults];
  return self->defaults;
}

- (id)save {
  NSNotificationCenter *nc;
  id ud;
  id uid;

  uid = [[self account] valueForKey:@"companyId"];

  ud = [self defaults];

  [ud setObject:[self palm2SkyrixMappingAddressEnterprise]
      forKey:@"OGoPalmAddress_Enterprise_AttributeMapping"];

  [ud setObject:[self palm2SkyrixMappingAddressPerson]
      forKey:@"OGoPalmAddress_Person_AttributeMapping"];

  [ud setObject:[self skyrix2PalmMappingEnterpriseAddress]
      forKey:@"OGoPalmAddress_Enterprise_AddressMapping"];

  [ud setObject:[self skyrix2PalmMappingPersonAddress]
      forKey:@"OGoPalmAddress_Person_AddressMapping"];

  /* write ids for write access*/
  {
    NSMutableArray *pIds       = nil;
    NSMutableArray *tIds       = nil;
    NSEnumerator   *enumerator = nil;
    id             obj         = nil;

    enumerator = [self->selectedOgoDateWriteAccess objectEnumerator];
    pIds = [[NSMutableArray alloc] init];
    tIds = [[NSMutableArray alloc] init];

    while ((obj = [enumerator nextObject])) {
      if ([[[obj valueForKey:@"globalID"] entityName] isEqualToString:@"Person"])
        {
          [pIds addObject:[obj valueForKey:@"companyId"]];
        }
      else if ([[[obj valueForKey:@"globalID"] entityName]
                      isEqualToString:@"Team"]) {
          [tIds addObject:[obj valueForKey:@"companyId"]];        
      }
      else {
        NSLog(@"got unexpected obj %@", obj);
      }
    }
    [self runCommand:@"userdefaults::write",
          @"key",          @"ogopalm_default_scheduler_write_access_accounts",
          @"value",        pIds,
          @"userdefaults", ud,
          @"userId",       uid, nil];
    [self runCommand:@"userdefaults::write",
          @"key",          @"ogopalm_default_scheduler_write_access_teams",
          @"value",        tIds,
          @"userdefaults", ud,
          @"userId",       uid, nil];
    RELEASE(pIds); pIds = nil;
    RELEASE(tIds); tIds = nil;
  }

  [ud setObject:[[[self selectedOgoDateAccessTeam]
                        valueForKey:@"companyId"]
                        stringValue]
      forKey:@"ogopalm_default_scheduler_read_access_team"];

  [(NSUserDefaults *)ud synchronize];
  nc = [(id)[self session] notificationCenter];
  [nc postNotificationName:@"NSUserDefaultsChanged" object:ud];
  return [self leavePage];
}

static NSMutableArray *_getGIDSforIds(SkyPalmPreferences *self,
                                      NSArray *_ids, NSString *_entityName)
{
  NSEnumerator *enumerator = nil;
  id           obj         = nil;
  NSArray      *tmp        = nil;
  EOEntity     *entity     = nil;
  id           *objs       = NULL;
  int          cnt         = 0;
  NSArray      *gids       = nil;
  NSString     *command    = nil;
  NSArray      *args       = nil;

  command = [NSString stringWithFormat:@"%@::get-by-globalid", _entityName];

  if ([_entityName isEqualToString:@"Team"] == YES)
    args = [NSArray arrayWithObjects:@"description", @"isTeam", nil];
  else if ([_entityName isEqualToString:@"Person"] == YES)
    args = [NSArray arrayWithObjects:@"name", @"firstname", @"isAccount",
                    @"login", nil];
  else
    NSLog(@"WARNING: unknown entityName %@", _entityName);


  if ((_ids != nil) && ([_ids count] > 0)) {
    entity     = [[[(id)[self session] commandContext]
                              valueForKey:LSDatabaseKey]
                              entityNamed:_entityName];
    enumerator = [_ids objectEnumerator];
    objs       = malloc(sizeof(id) * [_ids count]);
    while ((obj = [enumerator nextObject])) {
      objs[cnt++] = [entity globalIDForRow:
                            [NSDictionary dictionaryWithObject:obj
                                          forKey:@"companyId"]];
    }
    gids = [[NSArray alloc] initWithObjects:objs count:cnt];
    tmp  = [[self runCommand:command,
                  @"gids", gids,
                  @"attributes", args,
                  @"groupBy", @"globalID", nil] allValues];
    RELEASE(gids);
    free(objs);
    return AUTORELEASE([tmp mutableCopy]);
  }
  else
    return [NSMutableArray array];
}

- (NSArray *)_fetchTeams {
  return [self runCommand:@"account::teams",
                 @"object", [[self session] activeAccount],
                 nil];
}

@end /* SkyPalmPreferences */
