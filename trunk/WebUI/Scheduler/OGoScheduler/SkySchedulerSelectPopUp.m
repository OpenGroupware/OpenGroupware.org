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

#include <OGoFoundation/OGoComponent.h>

/*
  This component generates a PopUp containing groups and accounts. It should
  be extended to allow any kind of person.

    Input parameters:

      showAccount     - should include the login account in the list
      showTeams       - should include the teams in the list
      showSearchField - add ability to search for persons
      fetchGlobalIDs  - work with EOGlobalIDs
      onChange        - JavaScript to execute in the PopUp's onChange attribute

    In/Output parameters:
      
      selectedCompany  - the company which was selected by the user
    
    Output parameters:
      
      selectedGlobalID - the gid of the company which was selected by the user
*/

@interface NSObject(Private)
- (id)commandContext;
@end;

@class NSArray, NSString, NSMutableArray;

@interface SkySchedulerSelectPopUp : OGoComponent
{
  BOOL     fetchGlobalIDs;
  
  /* temporary state */
  NSMutableArray  *possibleItems;
  id              item;
  id              selectedItem;
  id              onChange;
  NSArray         *preSelectedItems;  
  
  BOOL      meToo;
  int       meTooCond;
  NSString *searchText;
  int       maxLabelLength;

  NSArray  *idsForPerson;
  NSArray  *idsForTeams;
  NSArray  *resources;
}

- (void)_initializePreSelectedItems;
- (NSArray *)_getGIDsForIds:(NSArray *)_ids entityName:(NSString *)_entityName;

@end


#include <GDLAccess/GDLAccess.h>
#include <OGoFoundation/OGoFoundation.h>
#include <LSFoundation/LSFoundation.h>
#include "common.h"

static int compareItems(id part1, id part2, void *context);

@implementation SkySchedulerSelectPopUp

static NSArray  *personCoreAttrNames = nil;
static NSArray  *teamCoreAttrNames   = nil;
static NSArray  *nameAttrArray       = nil;
static NSArray  *categoryAttrArray   = nil;
static NSNumber *yesNum              = nil;
static Class    StrClass             = Nil;
static Class    DictClass            = Nil;

+ (void)initialize {
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;

  StrClass  = [NSString     class];
  DictClass = [NSDictionary class];
  yesNum    = [[NSNumber numberWithBool:YES] retain];
  
  personCoreAttrNames = 
    [[NSArray alloc] initWithObjects:
		       @"name", @"firstname", @"isAccount", @"login", nil];
  teamCoreAttrNames = [[NSArray alloc] initWithObjects:@"description", nil];
  nameAttrArray     = [[NSArray alloc] initWithObjects:@"name", nil];
  categoryAttrArray = [[NSArray alloc] initWithObjects:@"category", nil];
}

- (id)init {
  if ((self = [super init])) {
    self->meToo          = YES;
    self->meTooCond      = -1;
    self->maxLabelLength = -1;
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->item);
  RELEASE(self->preSelectedItems);
  RELEASE(self->possibleItems);
  RELEASE(self->idsForTeams);
  RELEASE(self->idsForPerson); 
  RELEASE(self->resources);
  [super dealloc];
}

/* defaults */

- (NSUserDefaults *)userDefaults {
  return [[self session] userDefaults];
}
- (int)defaultPopUpMaxLength {
  return [[self userDefaults] integerForKey:@"scheduler_popup_maxlength"];
}
- (int)defaultAdditionalPopUpEntries {
  return [[self userDefaults] 
	        integerForKey:@"scheduler_additional_popup_entries"];
}

/* commands */

- (NSDictionary *)_fetchGroupedCoreAttrsOfTeamsWithGIDs:(NSArray *)_gids {
  return [self runCommand:@"team::get-by-globalID",
	       @"gids",       _gids,
	       @"groupBy",    @"globalID",
	       @"attributes", teamCoreAttrNames, nil];
}
- (NSDictionary *)_fetchGroupedCoreAttrsOfPersonsWithGIDs:(NSArray *)_gids {
  return [self runCommand:@"person::get-by-globalID",
		 @"gids",       _gids,
		 @"groupBy",    @"globalID",
		 @"attributes", personCoreAttrNames, 
	       nil];
}

- (NSArray *)_fetchTeamsOfAccountEO:(id)_account {
  return [self runCommand:@"account::teams", @"account", _account, nil];
}

- (NSArray *)_fetchAllTeamGlobalIDs {
  return [self runCommand:@"team::extended-search",
	         @"fetchGlobalIDs", yesNum,
	         @"description", @"%%", nil];
}

- (NSArray *)_fetchTeamGlobalIDsMatching:(NSString *)_text max:(int)_max {
  return [self runCommand:@"team::extended-search",
	         @"fetchGlobalIDs", yesNum,
	         @"operator", @"OR",
	         @"description", _text,
                 @"maxSearchCount", [NSNumber numberWithInt:_max],
	       nil];
}

- (NSArray *)_fetchAccountGlobalIDsMatching:(NSString *)_text max:(int)_max {
  return [self runCommand:@"account::extended-search",
                  @"fetchGlobalIDs", yesNum,
                  @"operator", @"OR",
                  @"name",           _text,
                  @"firstname",      _text,
                  @"description",    _text,
                  @"login",          _text,
                  @"maxSearchCount", [NSNumber numberWithInt:_max],
	       nil];
}
- (NSArray *)_fetchPersonGlobalIDsMatching:(NSString *)_text max:(int)_max {
  return [self runCommand:@"person::extended-search",
	         @"fetchGlobalIDs",  yesNum,
                 @"operator",        @"OR",
                 @"name",            _text,
                 @"firstname",       _text,
                 @"description",     _text,
                 @"login",           _text,
                 @"withoutAccounts", yesNum,
                 @"maxSearchCount",  [NSNumber numberWithInt:_max],
	       nil];
}

- (NSArray *)_fetchResourceGIDsCategoryMatching:(NSString *)_tx max:(int)_max {
  return [self runCommand:@"appointmentresource::extended-search",
	         @"fetchGlobalIDs", yesNum,
                 @"operator",       @"OR",
                 @"category",       _tx,
	         @"maxSearchCount", [NSNumber numberWithInt:_max],
	       nil];
}
- (NSArray *)_fetchResourceGIDsNameMatching:(NSString *)_tx max:(int)_max {
  return [self runCommand:@"appointmentresource::extended-search",
	         @"fetchGlobalIDs", yesNum,
                 @"operator",       @"OR",
                 @"name",           _tx,
	         @"maxSearchCount", [NSNumber numberWithInt:_max],
	       nil];
}
- (NSArray *)_fetchCategoriesOfResourcesWithGlobalIDs:(NSArray *)_gids {
  return [self runCommand:@"appointmentresource::get-by-globalID",
	         @"gids", _gids, @"attributes", categoryAttrArray, nil];
}
- (NSArray *)_fetchNamesOfResourcesWithGlobalIDs:(NSArray *)_gids {
  return [self runCommand:@"appointmentresource::get-by-globalID",
	         @"gids", _gids, @"attributes", nameAttrArray, nil];
}

/* accessors */

- (id)possibleItems {
  return self->possibleItems;
}

- (void)setOnChange:(id)_id {
  ASSIGN(self->onChange, _id);
}
- (id)onChange {
  return self->onChange;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}
- (EOGlobalID *)itemGlobalID {
  return [self->item valueForKey:@"globalID"];
}

- (void)setMeToo:(BOOL)_bool {
  self->meToo = _bool;
}
- (BOOL)meToo {
  return self->meToo;
}

- (void)setSearchText:(id)_txt {
  ASSIGN(self->searchText, _txt);
}
- (id)searchText {
  return self->searchText;
}
  
- (void)setSelectedItem:(id)_item {
  if (![_item isNotNull])
    return;

  ASSIGN(self->selectedItem, _item);
  
  if (![self->possibleItems containsObject:_item])
    [self->possibleItems addObject:_item];
}
- (id)selectedItem {
  return self->selectedItem;
}
- (EOGlobalID *)selectedItemGlobalID {
  return [self->selectedItem valueForKey:@"globalID"];
}

- (BOOL)isSelectedItemTeam {
  return [[[self selectedItemGlobalID] entityName] isEqualToString:@"Team"];
}
- (BOOL)isSelectedItemPerson {
  return [[[self selectedItemGlobalID] entityName] isEqualToString:@"Person"];
}

- (BOOL)meTooCond {
  id ac = nil;

  if (self->meTooCond != -1)
    return (self->meTooCond == 1) ? YES : NO;

  self->meTooCond = 1;
  ac = [self->session activeAccount];

  if ([self->selectedItem isKindOfClass:StrClass])
    self->meTooCond = 1;

  else if (![self->selectedItem isKindOfClass:DictClass])
    self->meTooCond = 0;
  
  else if ([self isSelectedItemTeam]) {
    NSEnumerator *enumerator = nil;
    id           obj         = nil;
    
    enumerator = [[self _fetchTeamsOfAccountEO:ac] objectEnumerator];
    while ((obj = [enumerator nextObject])) {
      NSNumber *objPKey, *selPKey;
      
      objPKey = [obj valueForKey:@"companyId"];
      selPKey = [self->selectedItem valueForKey:@"companyId"];
      if ([objPKey isEqual:selPKey]) {
	self->meTooCond = 0;
	break;
      }
    }
  }
  else if ([self isSelectedItemPerson]) {
    NSNumber *accPKey;
    
    accPKey = [ac valueForKey:@"companyId"];
    if ([accPKey isEqual:[self->selectedItem valueForKey:@"companyId"]])
      self->meTooCond = 0;
  }
  else {
    NSLog(@"WARNING: unknown selected item %@", self->selectedItem);
  }
  return (self->meTooCond == 1) ? YES : NO;
}

- (int)maxLabelLength {
  if (self->maxLabelLength != -1)
    return self->maxLabelLength;

  self->maxLabelLength = [self defaultPopUpMaxLength];
  if (self->maxLabelLength < 20) self->maxLabelLength = 20;
  return self->maxLabelLength;
}

- (NSString *)_labelForStringItem:(NSString *)_item {
  NSString *d;
  id l;
  
  l = [self labels];
  if ([self->item isEqualToString:@""])
    return [l valueForKey:@"emptyEntry"];

  d = [l valueForKey:@"resCategory"];
  if (d == nil) d = @"resCategory";
  d = [StrClass stringWithFormat:@" (%@)", d];
      
  if ([self->item hasSuffix:d]) {
    /* is a resource category */
    d = [StrClass stringWithFormat:@"%@: %@",
                      [l valueForKey:@"ResourceCategory"],
                      [[self->item componentsSeparatedByString:@" ("]
                                   objectAtIndex:0]];
  }
  else {
    /* is a resource */      
    d = [StrClass stringWithFormat:@"%@: %@",
                      [l valueForKey:@"Resource"], self->item];
  }
  return d;
}
- (NSString *)itemLabel {
  // TODO: clean up this method, might use a formatter?
  NSString *d = nil;
  int maxLen;
  
  if ([self->item isKindOfClass:StrClass]) {
    d = [self _labelForStringItem:self->item];
  }
  else {
    id entityName = nil;
    id l = nil;
    
    l = [self labels];
    if ([self->item isKindOfClass:DictClass])
      entityName = [[self->item valueForKey:@"globalID"] entityName];
    else
      entityName = [[self->item entity] name];

    if ([entityName isEqualToString:@"Team"]) {
      /* found team */
      d = [StrClass stringWithFormat:@"%@: %@",
                    [l valueForKey:@"Team"],
                    [self->item valueForKey:@"description"]];
    }
    else if ([entityName isEqualToString:@"Person"]) {
      NSString *kind;
      NSString *n    = nil;
      NSString *fn   = nil;
      NSString *ln   = nil;
      
      if ([[self->item valueForKey:@"isAccount"] boolValue])
        kind = @"Account";
      else
        kind = @"Person";

      fn = [self->item valueForKey:@"firstname"];
      ln = [self->item valueForKey:@"name"];

      kind = [l valueForKey:kind];
      
      if (![ln isNotNull])
        n = [self->item valueForKey:@"login"];
      else {
        if (![fn isNotNull])
          n = ln;
        else
          n = [StrClass stringWithFormat:@"%@ %@", fn, ln];
      }
      d = [StrClass stringWithFormat:@"%@: %@", kind, n];
    }
  }

  maxLen = [self maxLabelLength];
  if ([d length] > maxLen)
    // TODO: use a category or even better a formatter
    d = [StrClass stringWithFormat:@"%@..", [d substringToIndex:maxLen-2]];
  return d;
}

/* processing */

- (NSArray *)distinctCategories:(NSArray *)_items {
  int i, cnt;
  id  obj;
  NSMutableArray *ma;
  NSString *l;

  ma = [NSMutableArray arrayWithCapacity:16];
  l = [[self labels] valueForKey:@"resCategory"];

  if (l == nil) l = @"resCategory";
  
  i = 0; cnt = [_items count];
  
  while (i < cnt) {
    NSMutableDictionary *rD;
    NSString            *s;

    obj = [_items objectAtIndex:i++];
    
    rD = [[NSMutableDictionary alloc] initWithCapacity:1];
    
    s = [[StrClass alloc] initWithFormat:@"%@ (%@)",
                  [obj valueForKey:@"category"], l];
    [rD setObject:s forKey:@"name"];
    [s release]; s = nil;
    
    if (![ma containsObject:rD])
      [ma addObject:rD];
    
    [rD release]; rD = nil;
  }
  return ma;
}

- (void)_initializePreSelectedItems {
  // TODO: split up this big method!
  NSMutableArray *array = nil;
  id             tmp;
  NSUserDefaults *defs;
  BOOL           reload = NO;
  
  defs = [self userDefaults];
  
  tmp = [defs arrayForKey:@"scheduler_popup_persons"];
  if ((self->idsForPerson == nil) || ![self->idsForPerson isEqual:tmp])
    reload = YES;

  ASSIGN(self->idsForPerson, tmp);

  tmp = [defs arrayForKey:@"scheduler_popup_teams"];
  if ((self->idsForTeams == nil) || ![self->idsForTeams isEqual:tmp])
    reload = YES;

  ASSIGN(self->idsForTeams, tmp);

  tmp = [defs arrayForKey:@"scheduler_popup_resourceNames"];
  if ((self->resources == nil) || ![self->resources isEqual:tmp])
    reload = YES;

  {
    NSEnumerator   *enumerator = nil;
    NSMutableArray *r          = nil;
    NSString       *n          = nil;
    NSString       *s          = nil;

    s = [[self labels] valueForKey:@"resCategory"];
    if (s == nil) s = @"resCategory";
    
    r = [NSMutableArray arrayWithCapacity:8];
    
    enumerator = [tmp objectEnumerator];

    while ((n = [enumerator nextObject])) {
      if ([n hasSuffix:@"(resCategory)"]) {
        n = [[n  componentsSeparatedByString:@" ("] objectAtIndex:0];
        [r addObject:[StrClass stringWithFormat:@"%@ (%@)", n, s]];
      }
      else 
        [r addObject:n];
    }
    ASSIGN(self->resources, r);
  }

  if (reload) {
    if (self->preSelectedItems != nil) {
      [self->possibleItems removeObjectsInArray:self->preSelectedItems];
      [self->preSelectedItems release]; self->preSelectedItems = nil;
    }
    
    array = [[NSMutableArray alloc] init];
    
    tmp = [self _getGIDsForIds:self->idsForPerson entityName:@"Person"];
    if (tmp != nil)
      [array addObjectsFromArray:tmp];
    
    tmp = [self _getGIDsForIds:self->idsForTeams entityName:@"Team"];
    if (tmp != nil)
      [array addObjectsFromArray:tmp];

    if (self->resources != nil)
      [array addObjectsFromArray:self->resources];
  
    { /* remove activeAccount */
      NSEnumerator *enumerator;
      id           obj;
      NSNumber     *acid;
      
      acid = [[[self session] activeAccount] valueForKey:@"companyId"];

      enumerator = [array objectEnumerator];
      while ((obj = [enumerator nextObject])) {
        if (![obj isKindOfClass:StrClass]) {
          if ([[obj valueForKey:@"companyId"] isEqual:acid])
            break;
        }
      }
      if (obj != nil)
        [array removeObject:obj];
    }
    if ([array count] == 0) {
      id tmp = nil;
      tmp = [self _fetchAllTeamGlobalIDs];
      if ([tmp count] > 0) {
        tmp = [[self _fetchGroupedCoreAttrsOfTeamsWithGIDs:tmp] allValues];
        if (tmp) [array addObjectsFromArray:tmp];
      }
    }
    
    [array sortUsingFunction:compareItems context:nil];
    
    self->preSelectedItems = [array copy];
    
    [self->possibleItems addObjectsFromArray:self->preSelectedItems];
    
    if (![self->possibleItems containsObject:self->selectedItem])
      self->selectedItem = [self->possibleItems objectAtIndex:0];
    
    [array release]; array = nil;
  }
}

- (NSArray *)_getGIDsForIds:(NSArray *)_ids entityName:(NSString *)_entityName{
  NSEnumerator *enumerator = nil;
  id           obj         = nil;
  NSArray      *tmp        = nil;
  EOEntity     *entity     = nil;
  id           *objs       = NULL;
  int          cnt         = 0;
  NSArray      *gids       = nil;
  NSString     *command;
  NSArray      *args       = nil;
  EODatabase   *db;
  
  command = [_entityName stringByAppendingString:@"::get-by-globalid"];
  
  if ([_entityName isEqualToString:@"Team"])
    args = teamCoreAttrNames;
  else if ([_entityName isEqualToString:@"Person"])
    args = personCoreAttrNames;
  else
    [self logWithFormat:@"WARNING: unknown entityName %@", _entityName];
  
  if (!((_ids != nil) && ([_ids count] > 0)))
    return [NSArray array];

  db = [[(OGoSession *)[self session] commandContext] 
	                     valueForKey:LSDatabaseKey];
  entity     = [db entityNamed:_entityName];
  enumerator = [_ids objectEnumerator];
  objs       = calloc([_ids count] + 1, sizeof(id));
  while ((obj = [enumerator nextObject])) {
    NSDictionary *d;
      
    d = [DictClass dictionaryWithObject:obj forKey:@"companyId"];
    objs[cnt] = [entity globalIDForRow:d];
    cnt++;
  }
  gids = [[NSArray alloc] initWithObjects:objs count:cnt];
  if (objs) free(objs); objs = NULL;
  tmp  = [[self runCommand:command,
                  @"gids", gids,
                  @"groupBy", @"globalID",
                  @"attributes", args, nil] allValues];
  [gids release];
  return tmp;
}

/* notifications */

- (void)syncAwake {
  [self _initializePreSelectedItems];
  
  if (self->possibleItems == nil) {
    id ac;

    ac = [[self session] activeAccount];
    self->possibleItems = [[NSMutableArray alloc] init];
  
    [self->possibleItems addObject:ac];
    [self->possibleItems addObject:@""];

    if (self->selectedItem != nil) {
      if ((![self->preSelectedItems containsObject:self->selectedItem]) &&
          (self->selectedItem != ac)) {
        [self->possibleItems addObject:self->selectedItem];
        [self->possibleItems addObject:@""];
      }
    }
    else {
      self->selectedItem = [ac retain];
    }
    [self->possibleItems addObjectsFromArray:self->preSelectedItems];    
  }
#if 0
  [self reconfigure];
#endif
  [super syncAwake];
}

- (void)sleep {
#if 0
  RELEASE(self->item);  self->item = nil;
#endif
  self->meTooCond = -1;
  [super sleep];
}

/* catch nil-assignments to selected-company */

- (void)_postProcessSearchText {
  /* TODO: split up this big method */
  NSMutableSet *objs = nil;
  int          maxSearch    = 0;
  int          cnt          = 0;
  NSArray      *tmp         = nil;
  
  if ([self->searchText length] == 0)
    return;
    
  maxSearch  = [self defaultAdditionalPopUpEntries];
  
  objs = [[NSMutableSet alloc] init];
  
  /* teams */
  
  if (cnt < maxSearch) {
    tmp = [self _fetchTeamGlobalIDsMatching:self->searchText
		max:(maxSearch - cnt)];
    if (tmp != nil) {
      // TODO: why do we use the grouping here?
      tmp = [[self _fetchGroupedCoreAttrsOfTeamsWithGIDs:tmp] allValues];
      [objs addObjectsFromArray:tmp];        
    }
    cnt = [objs count];
  }
  
  /* accounts */

  if (cnt < maxSearch) {
    tmp = [self _fetchAccountGlobalIDsMatching:self->searchText
		max:(maxSearch - cnt)];
    if (tmp != nil) {
      tmp = [[self _fetchGroupedCoreAttrsOfPersonsWithGIDs:tmp] allValues];
      [objs addObjectsFromArray:tmp];
      {
	/* remove activeAccount */
	NSEnumerator *enumerator = nil;
	id           obj         = nil;
	NSNumber     *acId       = nil;

	acId = [[[self session] activeAccount] valueForKey:@"companyId"];

	enumerator = [obj objectEnumerator];

	while ((obj = [enumerator nextObject])) {
	  if ([obj isEqual:acId])
              break;
	}
	if (obj != nil)
	  [objs removeObject:obj];
      }
    }
    cnt = [objs count];
  }

  /* persons */
  
  if (cnt < maxSearch) {
    tmp = [self _fetchPersonGlobalIDsMatching:self->searchText
		max:(maxSearch - cnt)];
    if (tmp != nil) {
      tmp = [[self _fetchGroupedCoreAttrsOfPersonsWithGIDs:tmp] allValues];
      if (tmp) [objs addObjectsFromArray:tmp];
    }
    cnt = [objs count];
  }

  /* resources */
  
  if (cnt < maxSearch) {
    NSArray *foundObjects = nil;
    
    tmp = [self _fetchResourceGIDsCategoryMatching:self->searchText
		max:(maxSearch - cnt)];
    if (tmp != nil) {
      tmp = [self _fetchCategoriesOfResourcesWithGlobalIDs:tmp];
      tmp = [self distinctCategories:tmp];
	
      if (tmp != nil)
	[objs addObjectsFromArray:[tmp valueForKey:@"name"]];
    }
    tmp = [self _fetchResourceGIDsNameMatching:self->searchText
		max:(maxSearch - cnt)];
    if (tmp != nil) {
      tmp = [self _fetchNamesOfResourcesWithGlobalIDs:tmp];
      if (tmp != nil)
        [objs addObjectsFromArray:[tmp valueForKey:@"name"]];
      cnt = [objs count];
    }
    [self->possibleItems removeAllObjects];
    [self->possibleItems addObject:[[self session] activeAccount]];

    if ((objs != nil) && ([objs count] > 0)) {
      foundObjects = [[objs allObjects] mutableCopy];
      [(NSMutableArray *)foundObjects 
			 sortUsingFunction:compareItems 
			 context:nil];
      [self->possibleItems addObject:@""];
      {
        NSEnumerator   *enumerator = nil;
        id             o           = nil;

        enumerator = [foundObjects objectEnumerator];
        while ((o = [enumerator nextObject])) {
          if ([self->preSelectedItems containsObject:o])
	    continue;

	  [self->possibleItems addObject:o];
        }
      }
    }
    [self->possibleItems addObject:@""];
    [self->possibleItems addObjectsFromArray:self->preSelectedItems];

    if ([objs count] > 0) {
      [self->selectedItem release]; self->selectedItem = nil;
      self->selectedItem = [[foundObjects objectAtIndex:0] retain];
      self->meTooCond = -1;
    }
    else {
      if (![self->possibleItems containsObject:self->selectedItem]) {
        [self->selectedItem release]; self->selectedItem = nil;
        self->selectedItem = [[self->possibleItems objectAtIndex:0] retain];
        self->meTooCond = -1;
      }
    }
    [objs             release]; objs             = nil;
    [self->searchText release]; self->searchText = nil;
    [foundObjects     release]; foundObjects     = nil;
  }
}

/* request processing */

- (void)takeValuesFromRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  [super takeValuesFromRequest:_rq inContext:_ctx];  
  [self _postProcessSearchText];
}

@end /* SkyPersonSelectPopUp */

static Class NSStringClass = Nil;

static NSString *_personName(id _item) {
  NSString *n;
  NSString *f;
  
  if (NSStringClass == Nil)
    NSStringClass = [NSString class];
  
  n = [_item valueForKey:@"name"];
  f = [_item valueForKey:@"firstname"];
  
  if (![n isNotNull]) n = @"";
  if (![f isNotNull]) f = @"";

  if ([f length] == 0) return n;
  if ([n length] == 0) return f;
  return [NSStringClass stringWithFormat:@"%@ %@", f, n];
}

static int compareItems(id _part1, id _part2, void *_ctx) {
  BOOL     tmp  = NO;
  BOOL     tmp1 = NO;  
  NSString *part1Kind = nil;
  NSString *part2Kind = nil;

  if (NSStringClass == Nil) NSStringClass = [NSString class];
  
  /* check for resources */
  tmp = [_part2 isKindOfClass:NSStringClass];
  if ([_part1 isKindOfClass:NSStringClass]) {
    if (tmp)
      return [_part1 caseInsensitiveCompare:_part2];
    else
      return NSOrderedDescending;
  }
  if (tmp)
    return NSOrderedAscending;
  
  part1Kind = ([_part1 respondsToSelector:@selector(entity)])
    ? [[_part1 entity] name]
    : [[_part1 valueForKey:@"globalID"] entityName];
  part2Kind = ([_part2 respondsToSelector:@selector(entity)])
    ? [[_part2 entity] name]
    : [[_part2 valueForKey:@"globalID"] entityName];
  
  tmp = [part2Kind isEqualToString:@"Person"];
  
  if ([part1Kind isEqualToString:@"Person"]) {
    if (tmp) {
      tmp1 = [[_part2 valueForKey:@"isAccount"] boolValue];
      
      if ([[_part1 valueForKey:@"isAccount"] boolValue]) {
        if (tmp1) {
          NSString *pname1, *pname2;

          pname1 = _personName(_part1);
          pname2 = _personName(_part2);
          
          return [pname1 caseInsensitiveCompare:pname2];
        }
        else
          return NSOrderedAscending;
      }
      if (tmp1) {
        return NSOrderedDescending;
      }
      else { /* person - person */
        NSString *pname1, *pname2;

        pname1 = _personName(_part1);
        pname2 = _personName(_part2);
        
        return [pname1 caseInsensitiveCompare:pname2];
      }
    }
    else
      return NSOrderedDescending;
  }
  if (tmp)
    return NSOrderedAscending;
  
  /* both are teams */
  return [[_part1 valueForKey:@"description"]
                  caseInsensitiveCompare:[_part2 valueForKey:@"description"]];
}
