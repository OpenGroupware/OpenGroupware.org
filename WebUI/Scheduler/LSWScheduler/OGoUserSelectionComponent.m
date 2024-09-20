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

#include "OGoUserSelectionComponent.h"
#include <OGoFoundation/OGoSession.h>
#include <LSFoundation/LSCommandContext.h>
#include "common.h"

static NSComparisonResult compareParticipants(id part1, id part2, void *context);

@interface NSObject(PRIVATE)
- (EOGlobalID *)globalID;
- (void)searchAndResetSearchText;
@end

@implementation OGoUserSelectionComponent

static BOOL     debugOn              = YES;
static NSNumber *yesNum              = nil;
static NSNumber *noNum               = nil;
static NSArray  *personNameAttrNames = nil;
static NSArray  *emptyArray          = nil;

+ (void)initialize {
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  yesNum = [[NSNumber numberWithBool:YES] retain];
  noNum  = [[NSNumber numberWithBool:NO]  retain];
  
  personNameAttrNames = 
    [[NSArray alloc] initWithObjects:@"name", @"firstname", @"login", nil];
  emptyArray = [[NSArray alloc] init];
}

- (id)init {
  if ((self = [super init]) != nil) {
    self->resultList   = [[NSMutableArray alloc] initWithCapacity:16];
    self->participants = [[NSMutableArray alloc] initWithCapacity:8];
  }
  return self;
}

- (void)dealloc {
  [self->newContactJSCB      release];
  [self->newCompanyId        release];
  [self->searchText          release];
  [self->searchTeam          release];
  [self->participants        release];
  [self->resultList          release];
  [self->selectedParticipantsCache  release];
  [super dealloc];
}

/* notifications */

- (void)syncSleep {
  // reset transient variables
  [self->selectedParticipantsCache release];
  self->selectedParticipantsCache = nil;
  [super syncSleep];
}

- (void)sleep {
  [self->item release]; self->item = nil;
  [super sleep];
}

/* handling requests */

- (void)_ensureEitherSearchTestOrPopUpTeam {
  /* If a search-text is set, use it and reset the search team */
  if ([self->searchText isNotEmpty]) {
    [self->searchTeam release]; 
    self->searchTeam = nil;
  }
  else if ([self->searchTeam isNotNull]) {
    /* this catches empty searchText setups */
    [self->searchText release]; 
    self->searchText = nil;
  }
}

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  /*
    This is overridden to ensure that the search is done (and all arrays are
    properly setup) _before_ any action runs (eg a 'save' action in the main
    editor).
  */
  [super takeValuesFromRequest:_req inContext:_ctx];
  [self _ensureEitherSearchTestOrPopUpTeam];
  [self searchAndResetSearchText];
}

/* implementation */

- (NSString *)participantLabel {
  // TODO: should be done by a formatter
  // Note: this is apparently also called indirectly by SkyListView using the
  //       'binding' key in the attributes dictionary
  NSString *result = nil, *fd;
  
  if ([[self->item valueForKey:@"isTeam"] boolValue]) {
    result = [self->item valueForKey:@"description"];
    return [@"Team: " stringByAppendingString:result];
  }
  
  if ((result = [self->item valueForKey:@"name"]) == nil)
    return [self->item valueForKey:@"login"];
  
  if ((fd = [self->item valueForKey:@"firstname"]) != nil)
    result = [NSString stringWithFormat:@"%@, %@", result, fd];
  
  return result;
}

- (void)removeDuplicateParticipantListEntries {
  /* remove participants from 'resultList' which are in 'participants' */
  unsigned i, count;
  
  for (i = 0, count = [self->participants count]; i < count; i++) {
    unsigned j, count2;
    NSNumber *pkey;
    
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
    self->uscFlags.isClicked = 1; // TODO: used for what?
  ASSIGN(self->searchTeam, _team);
}
- (id)searchTeam {
  return self->searchTeam;
}

- (void)setShowExtended:(BOOL)_flag {
  self->uscFlags.showExtended = _flag ? 1 :0;
}
- (BOOL)showExtended {
  return self->uscFlags.showExtended ? YES : NO;
}

- (void)setResolveTeams:(BOOL)_flag {
  self->uscFlags.resolveTeams = _flag ? 1 : 0;
}
- (BOOL)resolveTeams {
  return self->uscFlags.resolveTeams ? YES : NO;
}

- (NSString *)noSelectionString {
  return (self->uscFlags.onlyAccounts)
    ? [[self labels] valueForKey:@"accountSelection"]
    : [[self labels] valueForKey:@"personSelection"];
}

- (BOOL)hasParticipantSelection {
  return ([self->participants count] + [self->resultList count]) > 0 
    ? YES : NO;
}

- (void)setNewContactJSCB:(NSString *)_str {
  ASSIGNCOPY(self->newContactJSCB, _str);
}
- (NSString *)newContactJSCB {
  return self->newContactJSCB;
}

- (void)setNewCompanyId:(NSString *)_str {
  ASSIGNCOPY(self->newCompanyId, _str);
}
- (NSString *)newCompanyId {
  return self->newCompanyId;
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

- (NSArray *)getCompanyEOsForCompanyRecordList:(NSArray *)part
  doResolveTeams:(BOOL)_resolveTeams
{
  /*
    Note: this returns a *retained* array!
    
    Input elements can be:
    a) EOs => taken as is
    b) GIDs
    c) NSDictionary records
    
    The result is a set of EO objects (Person or Team entities).
  */
  // TODO: should be a command?
  NSMutableArray *pgids, *tgids;    
  NSEnumerator   *enumerator;
  id             obj;
  NSMutableArray *result;

  pgids  = [[NSMutableArray alloc] initWithCapacity:16];
  tgids  = [[NSMutableArray alloc] initWithCapacity:16];
  result = [[NSMutableArray alloc] initWithCapacity:16];
  
  /* filter out team and person gids */
  
  enumerator = [part objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil) {
    if ([obj isKindOfClass:[NSDictionary class]] || 
	[obj isKindOfClass:[EOGlobalID class]]) {
      EOGlobalID *gid = nil;
      
      if ([obj isKindOfClass:[NSDictionary class]]) {
	if ((gid = [(NSDictionary *)obj objectForKey:@"globalID"]) == nil) {
	  [self warnWithFormat:@"missing globalID for %@", obj];
	  continue;
	}
      }
      else
	gid = obj;
      
      if ([[gid entityName] isEqualToString:@"Person"])
	[pgids addObject:gid];
      else if ([[gid entityName] isEqualToString:@"Team"])
	[tgids addObject:gid];
      else
	[self warnWithFormat:@"unexpected gid: %@", gid];
    }
    else { /* treated as an EO */
      if (_resolveTeams && [[obj valueForKey:@"isTeam"] boolValue]) {
	[tgids addObject:[obj globalID]];
      }
      else
	[result addObject:obj];
    }
  }
  
  /* fetch pending persons */

  if ([pgids count] > 0)
    [result addObjectsFromArray:[self _fetchPersonEOsForGlobalIDs:pgids]];
  
  /* fetch pending teams */
    
  if ([tgids count] > 0) {
    NSArray *teams;
      
    if (_resolveTeams) {
      // TODO: fix variable naming ...
      teams = [self _fetchTeamMemberGlobalIDsForTeamGlobalIDs:tgids];
      teams = [self _fetchPersonEOsForGlobalIDs:teams];
    }
    else
      teams = [self _fetchTeamEOsForGlobalIDs:tgids];
    
    [result addObjectsFromArray:teams];
  }
  
  [tgids release]; tgids = nil;
  [pgids release]; pgids = nil;    
  return result;
}

- (void)setSelectedParticipants:(id)_part {
  // KVC support
}
- (NSArray *)selectedParticipants {
  /* Note: this is reset in -syncSleep */
  if (self->selectedParticipantsCache != nil)
    return self->selectedParticipantsCache;
  
  self->selectedParticipantsCache = 
    [self getCompanyEOsForCompanyRecordList:[self participants]
	  doResolveTeams:self->uscFlags.resolveTeams];
  return self->selectedParticipantsCache;
}

- (NSArray *)participants {
  return [self->participants sortedArrayUsingFunction:compareParticipants
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
  
  personGIDs = [self->resultList map:@selector(objectForKey:) 
		                 with:@"globalID"];
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
  while ((obj = [enumerator nextObject]) != nil) {
    NSEnumerator   *e;
    id             o;
    NSMutableArray *array;

    e = [[personEnterprises objectForKey:obj] objectEnumerator];
	
    array = [NSMutableArray arrayWithCapacity:16];
    while ((o = [e nextObject]) != nil) {
      id o1;
	  
      if ((o1 = [enterprises objectForKey:o]) == nil)
        continue;
          
      [array addObject:o1];
    }
    [persons setObject:array forKey:obj];
  }

  enumerator = [self->resultList objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil) {
    EOGlobalID *key;
    id ent;
        
    if ((key = [(NSDictionary *)obj objectForKey:@"globalID"]) == nil)
      continue;
    
    if ((ent = [persons objectForKey:key]) != nil)
      [(NSMutableDictionary *)obj setObject:ent forKey:@"enterprises"];
  }
  [persons release]; persons = nil;
}

- (void)addSearchResultsNotInParticipantsToResultList:(NSDictionary *)_results{
  NSEnumerator *enu;
  id obj;

  if (_results == nil)
    return;
  
  enu = [_results objectEnumerator];
  while ((obj = [enu nextObject]) != nil) {
    NSMutableDictionary *m;
    
    if ([self->participants containsObject:obj])
      continue;
    
    m = [obj mutableCopy]; // make it mutable (TODO: why is this necessary???)
    [self->resultList addObject:m];
    [m release];
  }
}

- (void)_doSearch:(NSString *)_txt {
  /*
    Note that the text can contain commas, eg: "donald,mickey".

    The method returns whether something was searched for.
  */
  NSMutableDictionary *result;
  NSString     *searchTextPart;
  NSEnumerator *enu;
  
  if (![_txt isNotEmpty])
    return;
  
  result = [NSMutableDictionary dictionaryWithCapacity:1];
  
  /* search for each component */
  enu = [[_txt componentsSeparatedByString:@","] objectEnumerator];
  while ((searchTextPart = [enu nextObject]) != nil) {
    NSDictionary *res;
    NSArray *gids;
    
    searchTextPart = [searchTextPart stringByTrimmingSpaces];
    if (![searchTextPart isNotEmpty])
      continue;
      
    gids = [self _fetchPersonGlobalIDsMatchingSubstring:searchTextPart
		 onlyAccounts:self->uscFlags.onlyAccounts];
    res = [self _fetchPersonNameAttributesGroupedByGlobalIDs:gids];
    if (res != nil) [result addEntriesFromDictionary:res];
  }
  
  [self addSearchResultsNotInParticipantsToResultList:result];
}

- (void)_setupTeamInResultList:(id)_selectedTeam {
  NSDictionary *res;
  NSArray      *gids;

  if (![_selectedTeam isNotNull])
    return;

  if (![_selectedTeam isKindOfClass:[EOGlobalID class]])
    _selectedTeam = [_selectedTeam globalID];
    
  gids = [self _fetchTeamMemberGlobalIDsForTeamGlobalID:_selectedTeam];
  
  // TODO: assigning an immutable to result
  res = [self _fetchPersonNameAttributesGroupedByGlobalIDs:gids];
  
  [self addSearchResultsNotInParticipantsToResultList:res];
}

- (id)search {
  if (debugOn)
    [self debugWithFormat:@"perform search: '%@' ...", self->searchText];
  
  [self->resultList removeAllObjects];

  /* search in persons */
  if ([self->searchText isNotEmpty])
    [self _doSearch:self->searchText];
  
  /* show selected teams */
  if ([self->searchTeam isNotNull])
    [self _setupTeamInResultList:self->searchTeam];
  
  [self removeDuplicateParticipantListEntries];
  
  if (self->uscFlags.showExtended)
    [self _fetchExtendedInformation];
  
  if ((self->searchTeam != nil) &&
      (![self->participants containsObject:self->searchTeam]))
    [self->resultList addObject:self->searchTeam];
  
  return nil;
}

- (void)searchAndResetSearchText {
  // called by -takeValuesFromRequest:inContext:!
  
  [self search];
  [self->searchText release]; self->searchText = nil;
}

- (id)searchAction {
  if (debugOn) [self debugWithFormat:@"0x%p did click search ...", self];
  self->uscFlags.isClicked = 1;
  return nil;
}

- (id)fetchNewContactEO {
  EOKeyGlobalID *gid;
  NSNumber     *pkey;
  NSDictionary *result;

  if (![(pkey = (id)[self newCompanyId]) isNotEmpty]) {
    [self errorWithFormat:@"called addNew action w/o a company-id?"];
    return nil;
  }
  
  /* make a global-id */
  
  pkey = [NSNumber numberWithUnsignedInt:[pkey unsignedIntValue]];
  gid = [EOKeyGlobalID globalIDWithEntityName:@"Person" keys:&pkey keyCount:1
		       zone:NULL];
  
  /* fetch person info */
  
  result = [self _fetchPersonNameAttributesGroupedByGlobalIDs:
		   [NSArray arrayWithObject:gid]];
  return [result objectForKey:gid];
}

- (id)addNew {
  NSDictionary *result;
  
  if ((result = [self fetchNewContactEO]) == nil)
    return nil;
  
  /* add to set of selected participants */
  
  [self->participants addObject:result];
  return nil;
}

/* accessors */

- (void)setOnlyAccounts:(BOOL)_bool {
  self->uscFlags.onlyAccounts = _bool ? 1 : 0;
}
- (BOOL)onlyAccounts {
  return self->uscFlags.onlyAccounts ? YES : NO;
}

- (BOOL)showExtendEnterprisesCheckBox {
  return self->uscFlags.onlyAccounts ? NO : YES;
}
- (BOOL)showResolveTeamsCheckBox {
  return [[[self session] userDefaults]
                 boolForKey:@"scheduler_editor_canResolveTeams"];
}
- (BOOL)showAnyCheckBox {
  return ([self showExtendEnterprisesCheckBox] ||
          [self showResolveTeamsCheckBox]);
}

- (void)setSearchLabel:(NSString *)_str {
  ASSIGNCOPY(self->searchLabel, _str);
}
- (NSString *)searchLabel {
  return self->searchLabel;
}

- (void)setIsClicked:(BOOL)_flag {
  self->uscFlags.isClicked = _flag ? 1 : 0;
}
- (BOOL)isClicked {
  return self->uscFlags.isClicked ? YES : NO;
}

@end /* OGoUserSelectionComponent */

static NSComparisonResult compareParticipants(id part1, id part2, void *context) {
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
