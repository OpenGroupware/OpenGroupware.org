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

#include <OGoFoundation/LSWComponent.h>

@class NSString, NSArray, NSMutableArray;

@interface SkyParticipantsSelection : LSWComponent
{
  NSMutableArray *participants;
  NSMutableArray *resultList;
  NSMutableArray *removedParticipants;
  NSMutableArray *addedParticipants;

  NSArray  *selectedParticipantsCache;
  NSString *searchText;
  id       searchTeam;
  id       item;

  NSString *headLineLabel;
  NSString *searchLabel;
  NSString *selectionLabel;

  struct {
    int showExtended:1;
    int onlyAccounts:1;
    int viewHeadLine:1;
    int isClicked:1;
    int resolveTeams:1;
    int reserved:27;
  } spsFlags;
}
- (void)initializeParticipants;
- (id)participants;
@end

#include <OGoFoundation/LSWSession.h>
#include <LSFoundation/LSCommandContext.h>
#include "common.h"

static int compareParticipants(id part1, id part2, void *context);

@interface NSObject(PRIVATE)
- (id)globalID;
- (id)search;
@end

@implementation SkyParticipantsSelection

static BOOL     debugOn              = NO;
static BOOL     hasLSWEnterprises    = NO;
static NSNumber *yesNum              = nil;
static NSNumber *noNum               = nil;
static NSArray  *personNameAttrNames = nil;
static NSArray  *emptyArray          = nil;

+ (void)initialize {
  NGBundleManager *bm = [NGBundleManager defaultBundleManager];
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  yesNum = [[NSNumber numberWithBool:YES] retain];
  noNum  = [[NSNumber numberWithBool:NO]  retain];
  
  personNameAttrNames = 
    [[NSArray alloc] initWithObjects:@"name", @"firstname", @"login", nil];
  emptyArray = [[NSArray alloc] init];
  
  hasLSWEnterprises = [bm bundleProvidingResource:@"LSWEnterprises"
			  ofType:@"WOComponents"] ? YES : NO;
}

- (id)init {
  if ((self = [super init])) {
    self->resultList            = [[NSMutableArray alloc] initWithCapacity:16];
    self->removedParticipants   = [[NSMutableArray alloc] initWithCapacity:4];
    self->addedParticipants     = [[NSMutableArray alloc] initWithCapacity:4];
    self->participants          = [[NSMutableArray alloc] initWithCapacity:8];
    self->spsFlags.viewHeadLine = 1;
  }
  return self;
}

- (void)dealloc {
  [self->searchText          release];
  [self->searchTeam          release];
  [self->participants        release];
  [self->resultList          release];
  [self->removedParticipants release];
  [self->addedParticipants   release];
  [self->selectedParticipantsCache  release];
  [super dealloc];
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];
  // this must be run *before* -takeValuesFromRequest:inContext: is called
  [self->removedParticipants removeAllObjects];
  [self->addedParticipants   removeAllObjects];
}

- (void)syncSleep {
  // reset transient variables
  [self->removedParticipants removeAllObjects];
  [self->addedParticipants   removeAllObjects];
  [self->selectedParticipantsCache release];
  self->selectedParticipantsCache = nil;
  [super syncSleep];
}

/* handling requests */

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  if (debugOn) [self debugWithFormat:@"take values"];
  
  [super takeValuesFromRequest:_req inContext:_ctx];

  if (debugOn) [self debugWithFormat:@"  text: '%@'", self->searchText];
  
  // TODO: is this swap correct? If so, document!
  if (self->searchText != nil && ([self->searchText length] > 0)) {
    [self->searchTeam release]; 
    self->searchTeam = nil;
  }
  if (self->searchTeam != nil) {
    [self->searchText release]; 
    self->searchText = nil;
  }
  
  if (debugOn) [self debugWithFormat:@"  after: '%@'", self->searchText];
  
  [self search];
  [self->searchText release]; self->searchText = nil;
}

/* implementation */

- (NSString *)participantLabel {
  // TODO: should be done by a formatter
  NSString *result = nil, *fd;

  if ([[self->item valueForKey:@"isTeam"] boolValue]) {
    result = [self->item valueForKey:@"description"];
    return [@"Team: " stringByAppendingString:result];
  }
  
  if ((result = [self->item valueForKey:@"name"]) == nil)
    return [self->item valueForKey:@"login"];
  
  if ((fd = [self->item valueForKey:@"firstname"]))
    result = [NSString stringWithFormat:@"%@, %@", result, fd];
  
  return result;
}

- (void)removeDuplicateParticipantListEntries {
  int i, count;

  for (i = 0, count = [self->participants count]; i < count; i++) {
    int j, count2;
    id  pkey;
    
    pkey = [[self->participants objectAtIndex:i] valueForKey:@"companyId"];
    if (pkey == nil) continue;
    
    for (j = 0, count2 = [self->resultList count]; j < count2; j++) {
      id participant;
      
      participant = [self->resultList objectAtIndex:j];
      
      if ([[participant valueForKey:@"companyId"] isEqual:pkey]) {
        [self->resultList removeObjectAtIndex:j];
        break; // must break, otherwise 'count2' will be invalid
      }
    }
  }
}

/* clearing */

- (void)clear {
  if (debugOn) [self debugWithFormat:@"clear"];
  [self->searchTeam release]; self->searchTeam = nil;
  [self->searchText release]; self->searchText = nil;
}

/* accessors */

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (void)setSearchParticipantText:(NSString *)_txt {
  if (debugOn) [self debugWithFormat:@"SET SEARCH TEXT: '%@'", _txt];
  ASSIGNCOPY(self->searchText, _txt);
}
- (NSString *)searchParticipantText {
  return self->searchText;
}

- (void)setSearchTeam:(id)_team {
  if (_team != nil && ![self->searchTeam isEqual:_team])
     self->spsFlags.isClicked = 1;
  ASSIGN(self->searchTeam, _team);
}
- (id)searchTeam {
  return self->searchTeam;
}

- (void)setShowExtended:(BOOL)_flag {
  self->spsFlags.showExtended = _flag ? 1 :0;
}
- (BOOL)showExtended {
  return self->spsFlags.showExtended ? YES : NO;
}

- (void)setResolveTeams:(BOOL)_flag {
  self->spsFlags.resolveTeams = _flag ? 1 : 0;
}
- (BOOL)resolveTeams {
  return self->spsFlags.resolveTeams ? YES : NO;
}

- (NSString *)noSelectionString {
  return (self->spsFlags.onlyAccounts)
    ? [[self labels] valueForKey:@"accountSelection"]
    : [[self labels] valueForKey:@"personSelection"];
}

- (BOOL)hasParticipantSelection {
  return ([self->participants count] + [self->resultList count]) > 0 
    ? YES : NO;
}

/* commands */

- (NSArray *)_fetchPersonEOsForGlobalIDs:(NSArray *)_gids {
  if ([_gids count] == 0) return emptyArray;
  return [self runCommand:@"person::get-by-globalID", @"gids", _gids, nil];
}
- (NSArray *)_fetchTeamEOsForGlobalIDs:(NSArray *)_gids {
  if ([_gids count] == 0) return emptyArray;
  return [self runCommand:@"team::get-by-globalID", @"gids", _gids, nil];
}
- (NSArray *)_fetchTeamMemberGlobalIDsForTeamGlobalIDs:(NSArray *)_gids {
  return [self runCommand:@"team::members",
                 @"fetchGlobalIDs", yesNum, @"groups", _gids, nil];
}
- (NSArray *)_fetchTeamMemberGlobalIDsForTeamGlobalID:(EOGlobalID *)_gid {
  return [self runCommand:@"team::members",
                 @"fetchGlobalIDs", yesNum, @"team", _gid, nil];
}

- (NSDictionary *)_fetchPersonNameAttributesGroupedByGlobalIDs:(NSArray *)_gs {
  if ([_gs count] == 0) return nil;
  return [self runCommand:@"person::get-by-globalid",
                 @"gids",       _gs,
                 @"groupBy",    @"globalID",
                 @"attributes", personNameAttrNames,
               nil];
}

- (NSArray *)_fetchPersonGlobalIDsMatchingSubstring:(NSString *)_needle 
  onlyAccounts:(BOOL)_onlyAccounts
{
  NSArray  *res;
  NSString *cmdName;
  
  cmdName = _onlyAccounts
    ? @"account::extended-search"
    : @"person::extended-search";
  
  res = [self runCommand:cmdName,
                @"fetchGlobalIDs", yesNum,
                @"operator",       @"OR",
                @"name", _needle, @"firstname", _needle, 
                @"description", _needle, 
                @"login", _needle, @"keywords", _needle,
              nil];
  return res;
}

- (NSDictionary *)_fetchEnterpriseGlobalIDsForPersonGlobalIDs:(NSArray *)_gids{
  // TODO: does this really return a dictionary?
  NSDictionary *res;
  
  res = [self runCommand:@"person::enterprises",
                @"fetchGlobalIDs",    yesNum,
                @"persons",           _gids,
                @"relationKey",       @"enterprises",
                @"fetchForOneObject", noNum, 
              nil];
  return res;
}

- (NSDictionary *)_fetchEnterpriseDescriptionsGroupedByGlobalIDs:(NSArray *)_g{
  NSDictionary *d;
  
  if ([_g count] == 0) return nil;
  
  d = [self runCommand:@"enterprise::get-by-globalid",
              @"gids", _g,
              @"groupBy", @"globalID",
              @"attributes", [NSArray arrayWithObject:@"description"],
            nil];
  return d;
}

/* participants management */

- (void)initializeParticipants {
  int i, count;
  
  // participants selected in resultList
  for (i = 0, count = [self->addedParticipants count]; i < count; i++) {
    id  participant;
    id  pkey;
    int j, count2;

    participant = [self->addedParticipants objectAtIndex:i];
    pkey        = [participant valueForKey:@"companyId"];
    if (pkey == nil) {
      NSLog(@"ERROR(%@): invalid pkey of participant %@", self, participant);
      continue;
    }
    for (j = 0, count2 = [self->participants count]; j < count2; j++) {
      id opkey;

      opkey = [[self->participants objectAtIndex:j] valueForKey:@"companyId"];
      if ([opkey isEqual:pkey]) { // already in array
        pkey = nil;
        break;
      }
    }
    if (pkey) {
      [self->participants addObject:participant];
      [self->resultList removeObject:participant];
    }
  }
  [self->addedParticipants removeAllObjects];
    // participants not selected in participants list
  for (i = 0, count = [self->removedParticipants count]; i < count; i++) {
    id  participant;
    id  pkey;
    int j, count2, removeIdx = -1;

    participant = [self->removedParticipants objectAtIndex:i];
    pkey        = [participant valueForKey:@"companyId"];

    if (pkey == nil) {
      NSLog(@"ERROR(%@): invalid pkey of participant %@", self, participant);
      continue;
    }
    for (j = 0, count2 = [self->participants count]; j < count2; j++) {
      id opkey;
      opkey = [[self->participants objectAtIndex:j] valueForKey:@"companyId"];
      if ([opkey isEqual:pkey]) { // found in array
        removeIdx = j;
        break;
      }
    }
    if (removeIdx != -1) {
      [self->participants removeObjectAtIndex:removeIdx];
      [self->resultList addObject:participant];
    }
  }
  [self->removedParticipants removeAllObjects];
}

- (NSArray *)selectedParticipants {
  if (self->selectedParticipantsCache == nil) {
    NSMutableArray *pgids      = nil;
    NSMutableArray *tgids      = nil;    
    NSEnumerator   *enumerator = nil;
    id             obj         = nil;
    NSArray        *part       = nil;
    NSMutableArray *result     = nil;

    part       = [self participants];
    pgids      = [[NSMutableArray alloc] init];
    tgids      = [[NSMutableArray alloc] init];
    result     = [[NSMutableArray alloc] init];
    enumerator = [part objectEnumerator];
  
    while ((obj = [enumerator nextObject])) {
      if ([obj isKindOfClass:[NSDictionary class]]) {
        id gid = nil;

        gid = [obj objectForKey:@"globalID"];
        if (gid == nil) {
          NSLog(@"WARNING: missing globalID for %@", obj);
        }
        else {
          if ([[gid entityName] isEqualToString:@"Person"]) {
            [pgids addObject:gid];
          }
          else if ([[gid entityName] isEqualToString:@"Team"]) {
            [tgids addObject:gid];
          }
          else {
            NSLog(@"WARNING: unknown gid %@", gid);
          }
        }
      }
      else {
        if ((self->spsFlags.resolveTeams) &&
            ([[obj valueForKey:@"isTeam"] boolValue])) {
          [tgids addObject:[obj globalID]];
        }
        else {
          [result addObject:obj];
        }
      }
    }
    
    if ([pgids count] > 0)
      [result addObjectsFromArray:[self _fetchPersonEOsForGlobalIDs:pgids]];
    
    if ([tgids count] > 0) {
      NSArray *teams;
      
      if (self->spsFlags.resolveTeams) {
        // TODO: fix variable naming ...
        teams = [self _fetchTeamMemberGlobalIDsForTeamGlobalIDs:tgids];
        teams = [self _fetchPersonEOsForGlobalIDs:teams];
      }
      else {
        teams = [self _fetchTeamEOsForGlobalIDs:tgids];
      }
      [result addObjectsFromArray:teams];
    }
    
    [tgids release]; tgids = nil;
    [pgids release]; pgids = nil;    
    self->selectedParticipantsCache = result;
  }
  return self->selectedParticipantsCache;
}

- (void)setSelectedParticipants:(id)_part {
}

- (NSArray *)participants {
  return [self->participants sortedArrayUsingFunction:
              compareParticipants
              context:NULL];
}

- (void)setParticipants:(id)_part {
  if (_part == nil)
    return;
  
#if !LIB_FOUNDATION_LIBRARY
  // TODO: this breaks on Panther due to the mutable vs immutable issue,
  //       try to reuse the existing array, may or may not work (but seems
  //       to be just fine ;-)
  [self->participants removeAllObjects];
  [self->participants addObjectsFromArray:_part];
#else
  if (![_part isKindOfClass:[NSMutableArray class]]) {
    id tmp = self->participants;
    self->participants = [_part mutableCopy];
    [tmp release];
    return;
  }

  ASSIGN(self->participants, _part);
#endif
}

- (BOOL)addParticipant:(id)_participant {
  if (self->participants && 
      ![self->participants containsObject:_participant]) {
    [self->participants addObject:_participant];
    return YES;
  }
  return NO;
}

- (NSArray *)resultList {
  return [self->resultList sortedArrayUsingFunction:compareParticipants
                           context:NULL];
}

- (void)setAddedParticipants:(NSMutableArray *)_addedParticipants {
  ASSIGN(self->addedParticipants, _addedParticipants);
}
- (NSMutableArray *)addedParticipants {
  return self->addedParticipants;
}

- (void)setRemovedParticipants:(NSMutableArray *)_removedParticipants {
  ASSIGN(self->removedParticipants, _removedParticipants);
}
- (NSMutableArray *)removedParticipants {
  return self->removedParticipants;
}

- (NSArray *)attributesList {
  NSMutableArray      *myAttr;
  NSMutableDictionary *myDict1;
  NSMutableDictionary *myDict2;

  myAttr  = [NSMutableArray arrayWithCapacity:16];
  myDict1 = [[NSMutableDictionary alloc] initWithCapacity:8];
  myDict2 = [[NSMutableDictionary alloc] initWithCapacity:8];
  
  [myDict1 takeValue:@"participantLabel" forKey:@"binding"];
  [myAttr addObject: myDict1];
  
  if (self->spsFlags.showExtended) {
    [myDict2 takeValue:@"enterprises.description" forKey:@"key"];
    [myDict2 takeValue:@",  " forKey:@"separator"];
    [myAttr addObject: myDict2];
  }
  [myDict1 release]; myDict1 = nil;
  [myDict2 release]; myDict2 = nil;
  return myAttr;
}

- (int)noOfCols {
  id  d;
  int n;
  
  d = [[[self session] userDefaults] objectForKey:@"scheduler_no_of_cols"];
  n = [d intValue];
  return (n > 0) ? n : 2;
}

/* actions */

- (void)_fetchExtendedInformation {
  // TODO: split this big method
  NSDictionary        *personEnterprises;
  NSMutableDictionary *persons           = nil; 
  NSDictionary        *enterprises       = nil;
  NSMutableSet        *set               = nil;
  NSEnumerator        *enumerator        = nil;
  id                  obj                = nil;
  NSArray             *personGIDs;

  if ([self->resultList count] == 0) {
    [self logWithFormat:
            @"Note: empty result list, not fetching extended info"];
    return;
  }
  
  personGIDs = [self->resultList 
                    map:@selector(objectForKey:) with:@"globalID"];
  personEnterprises = [self _fetchEnterpriseGlobalIDsForPersonGlobalIDs:
                              personGIDs];
    
  if ([personEnterprises count] == 0) {
    [self debugWithFormat:
            @"Note: fetching no enterprises for person GIDs: %@ (%d)",
            personGIDs, [personGIDs count]];
    return;
  }
  
  // TODO: I guess using a set here is overkill, just use an array and
  //       check whether an ID is already in there
  enumerator = [personEnterprises objectEnumerator];
  set        = [NSMutableSet setWithCapacity:[personEnterprises count] * 3];
      
  while ((obj = [enumerator nextObject]) != nil)
    [set addObjectsFromArray:obj];
      
  enterprises = [self _fetchEnterpriseDescriptionsGroupedByGlobalIDs:
                        [set allObjects]];
  enumerator  = [personEnterprises keyEnumerator];
  persons     = [[NSMutableDictionary alloc] initWithCapacity:
                                               [personEnterprises count]];
  while ((obj = [enumerator nextObject])) {
    NSEnumerator   *e;
    id             o;
    NSMutableArray *array;

    e = [[personEnterprises objectForKey:obj] objectEnumerator];
	
    array = [NSMutableArray array];
    while ((o = [e nextObject])) {
      id o1;
	  
      if ((o1 = [enterprises objectForKey:o]) == nil)
        continue;
          
      [array addObject:o1];
    }
    [persons setObject:array forKey:obj];
  }

  enumerator = [self->resultList objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    EOGlobalID *key;
    id ent;
        
    if ((key = [obj objectForKey:@"globalID"]) == nil)
      continue;
    
    if ((ent = [persons objectForKey:key]) != nil)
      [obj setObject:ent forKey:@"enterprises"];
  }
  [persons release]; persons = nil;
}

- (id)search {
  // TODO: split up this huge method!
  BOOL didSearch = NO;

  if (debugOn)
    [self debugWithFormat:@"perform search: '%@' ...", self->searchText];
  
  [self initializeParticipants];
  [self->resultList removeAllObjects];

  // search in persons
  if ([self->searchText length] > 0) {
    NSMutableDictionary *result   = nil;
    NSString     *searchTextPart = nil;
    NSEnumerator *enu            = nil;
    NSDictionary *res            = nil;
    
    result = [NSMutableDictionary dictionaryWithCapacity:1];
    
    enu = [[self->searchText componentsSeparatedByString:@","]
                             objectEnumerator];
    while ((searchTextPart = [enu nextObject])) {
      NSArray *gids;
      
      if ([searchTextPart length] == 0)
        continue;

      searchTextPart = [searchTextPart stringByTrimmingSpaces];
      
      gids = [self _fetchPersonGlobalIDsMatchingSubstring:searchTextPart
                   onlyAccounts:self->spsFlags.onlyAccounts];
      res = [self _fetchPersonNameAttributesGroupedByGlobalIDs:gids];
      if (res) [result addEntriesFromDictionary:res];
    }
    
    if (result != nil) {
      NSEnumerator *enumerator;
      NSDictionary *obj;
      
      enumerator = [result objectEnumerator];
      while ((obj = [enumerator nextObject])) {
        NSMutableDictionary *m;
        
        if ([self->participants containsObject:obj])
          continue;
        
        m = [obj mutableCopy];
        [self->resultList addObject:m];
        [m release];
      }
    }
    didSearch = YES;
  }
  
  // show selected teams
  if (self->searchTeam) {
    NSDictionary *res;
    NSArray      *gids;
    
    gids = [self _fetchTeamMemberGlobalIDsForTeamGlobalID:
                   [self->searchTeam globalID]];
    
    // TODO: assigning an immutable to result
    res = [self _fetchPersonNameAttributesGroupedByGlobalIDs:gids];
    if (res != nil) {
      NSEnumerator *enumerator;
      NSDictionary *obj;
      
      enumerator = [res objectEnumerator];
      while ((obj = [enumerator nextObject])) { // TODO: looks like a DUP
        NSMutableDictionary *m;
        
        if ([self->participants containsObject:obj])
          continue;
        
        m = [obj mutableCopy];
        [self->resultList addObject:m];
        [m release];
      }
    }
    didSearch = YES;
  }
  [self removeDuplicateParticipantListEntries];
  
  if (self->spsFlags.showExtended)
    [self _fetchExtendedInformation];
  
  if ((self->searchTeam != nil) &&
      (![self->participants containsObject:self->searchTeam]))
    [self->resultList addObject:self->searchTeam];
  
  return nil;
}

- (id)searchAction {
  if (debugOn) [self debugWithFormat:@"0x%08X did click search ...", self];
  self->spsFlags.isClicked = 1;
  return nil;
}

/* notifications */

- (void)sleep {
  [self->removedParticipants removeAllObjects];
  [self->addedParticipants   removeAllObjects];
  [self->item release]; self->item = nil;
  [super sleep];
}

/* accessors */

- (void)setOnlyAccounts:(BOOL)_bool {
  self->spsFlags.onlyAccounts = _bool ? 1 : 0;
}
- (BOOL)onlyAccounts {
  return self->spsFlags.onlyAccounts ? YES : NO;
}

- (BOOL)showExtendEnterprisesCheckBox {
  return (!self->spsFlags.onlyAccounts && hasLSWEnterprises);
}
- (BOOL)showResolveTeamsCheckBox {
  return [[[self session] userDefaults]
                 boolForKey:@"scheduler_editor_canResolveTeams"];
}
- (BOOL)showAnyCheckBox {
  return ([self showExtendEnterprisesCheckBox] ||
          [self showResolveTeamsCheckBox]);
}

- (NSString *)headLineLabel {
  return self->headLineLabel;
}
- (void)setHeadLineLabel:(NSString *)_str {
  ASSIGN(self->headLineLabel, _str);
}

- (NSString *)searchLabel {
  return self->searchLabel;
}
- (void)setSearchLabel:(NSString *)_str {
  ASSIGN(self->searchLabel, _str);
}

- (NSString *)selectionLabel {
  return self->selectionLabel;
}
- (void)setSelectionLabel:(NSString *)_str {
  ASSIGN(self->selectionLabel, _str);
}

- (BOOL)viewHeadLine {
  return self->spsFlags.viewHeadLine ? YES : NO;
}
- (void)setViewHeadLine:(BOOL)_view {
  self->spsFlags.viewHeadLine = _view ? 1 : 0;
}

- (BOOL)isEnterpriseAvailable {
  return hasLSWEnterprises;
}

- (void)setIsClicked:(BOOL)_flag {
  self->spsFlags.isClicked = _flag ? 1 : 0;
}
- (BOOL)isClicked {
  return self->spsFlags.isClicked ? YES : NO;
}

@end /* SkyParticipantsSelection */

static int compareParticipants(id part1, id part2, void *context) {
  if ([[part1 valueForKey:@"isTeam"] boolValue]) {
    if (![[part2 valueForKey:@"isTeam"] boolValue])
      return NSOrderedAscending;
    
    {
      id d1 = [part1 valueForKey:@"description"];
      id d2 = [part2 valueForKey:@"description"];

      if (d1 == nil) d1 = @"";
      if (d2 == nil) d2 = @"";
        
      return ([d1 caseInsensitiveCompare:d2]);
    }
  }

  if ([[part2 valueForKey:@"isTeam"] boolValue])
    return NSOrderedDescending;

  {
    id n1 = [part1 valueForKey:@"name"];
    id n2 = [part2 valueForKey:@"name"];

    if (n1 == nil) n1 = @"";
    if (n2 == nil) n2 = @"";

    return ([n1 caseInsensitiveCompare:n2]);
  }
}
