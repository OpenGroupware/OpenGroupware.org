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

#include <OGoFoundation/OGoContentPage.h>

@class NSArray, NSString;
@class EOQualifier;
@class EOCacheDataSource;

@interface LSWPersons : OGoContentPage
{
  EOCacheDataSource *dataSource;
  NSString          *maxSearchCount;
  NSArray           *searchArray;
  id                item; // non-retained
  int               itemIdx;
  NSString          *searchText;
  NSString          *searchTitle;
  
  struct {
    int hasSearched:1;
    int isSearchLimited:1;
    int reserved:30;
  } opFlags;
  
  // for tab view
  NSString     *tabKey;
}

/* actions */

- (WOComponent *)tabClicked;
- (WOComponent *)fullSearch;
- (WOComponent *)advancedSearch;

@end

#include <OGoFoundation/LSWNotifications.h>
#include "LSWAddressFunctions.h"
#include <OGoFoundation/SkyWizard.h>
#include <NGMime/NGMimeType.h>
#include <NGExtensions/EOCacheDataSource.h>
#include <OGoContacts/SkyPersonDataSource.h>
#include "common.h"

@interface WOComponent(LSWAddressAdditions)
- (id)fullSearch;
- (id)personSearch;
- (id)advancedSearch;
- (id)tabClicked;
@end

@interface LSWPersons(PrivateMethodes)

- (void)setMaxSearchCount:(NSString *)_maxSearchCount;
- (void)setSearchTitle:(NSString *)_title;
- (void)setTabKey:(NSString *)_key;
- (void)setSearchText:(NSString *)_text;

- (void)setQualifier:(EOQualifier *)_q;
- (EOQualifier *)qualifier;

@end

@implementation LSWPersons

static NGMimeType *personDocType    = nil;
static id         maxSearchCountDef = 0;
static unsigned   maxTabTitleLength = 0;
static BOOL       showLetterTabs    = NO;
static BOOL       hasSkyInfolineGathering = NO;

+ (void)initialize {
  // TODO: check superclass version
  NSUserDefaults  *ud = [NSUserDefaults standardUserDefaults];
  NGBundleManager *bm = [NGBundleManager defaultBundleManager];
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  personDocType = 
    [[NGMimeType mimeType:@"objc" subType:@"SkyPersonDocument"] copy];
  
  maxSearchCountDef = [[ud objectForKey:@"LSMaxSearchCount"] copy];
  maxTabTitleLength = [ud integerForKey:@"contacts_maxTabTitleLength"];
  if (maxTabTitleLength < 10) maxTabTitleLength = 16;
  
  showLetterTabs = [ud boolForKey:@"persons_show_letter_tabs"];
  
  hasSkyInfolineGathering = 
    [bm bundleProvidingResource:@"SkyInfolineGathering" 
        ofType:@"WOComponents"] != nil ? YES : NO;
}

- (EOFetchSpecification *)fetchSpecification {
  EOFetchSpecification *fspec;

  fspec = [[self->dataSource fetchSpecification] copy];
  
  if (fspec == nil)
    fspec = [[EOFetchSpecification alloc] init];
  
  return [fspec autorelease];
}

- (LSCommandContext *)commandContext {
  return [(OGoSession *)[self session] commandContext];
}
- (void)_setupDataSource {
  SkyPersonDataSource *ds;
  
  if (self->dataSource) return;
  
  ds = [(SkyPersonDataSource *)[SkyPersonDataSource alloc] 
                               initWithContext:[self commandContext]];
  self->dataSource = [[EOCacheDataSource alloc] initWithDataSource:ds];
  [ds release];
}

- (void)_registerForNotifications {
  NSNotificationCenter *nc;

  nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(personAdded:)
      name:SkyNewPersonNotification object:nil];
}

- (id)init {
  id p;

  /* this component is a session-singleton */
  if ((p = [self persistentInstance])) {
    [self release];
    return [p retain];
  }
  if ((self = [super init])) {
    [self registerAsPersistentInstance];
    [self _setupDataSource];
    
    self->searchArray = nil;
    [self setTabKey:@"personSearch"];
    self->opFlags.hasSearched = 0;
    
    [self setMaxSearchCount:maxSearchCountDef];
    [self _registerForNotifications];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->dataSource     release];
  [self->searchText     release];
  [self->tabKey         release];
  [self->searchArray    release];
  [self->maxSearchCount release];
  [self->searchTitle    release];
  [super dealloc];
}

/* notifications */

static inline void _newPersonNotifiction(LSWPersons *self, id _obj) {
  [self->dataSource clear];
  self->opFlags.hasSearched = 1;
  [self setTabKey:@"search"];
  [self setSearchText:nil];
}

/* accessors  */

- (void)setSearchText:(NSString *)_text {
  ASSIGNCOPY(self->searchText, _text);
}
- (NSString *)searchText {
  return self->searchText;
}

- (void)setHasSearched:(BOOL)_searched {
  self->opFlags.hasSearched = _searched ? 1 : 0;
}
- (BOOL)hasSearched {
  return self->opFlags.hasSearched ? YES : NO;
}

- (void)setTabKey:(NSString *)_key {
  ASSIGN(self->tabKey, _key);
}
- (NSString *)tabKey {
  return self->tabKey;
}

- (EODataSource *)dataSource {
  return self->dataSource;
}

- (void)setPersonSearchArray:(NSArray *)_searchArray {
  ASSIGN(self->searchArray, _searchArray);
}
- (NSArray *)personSearchArray {
  return self->searchArray;
}

- (void)setMaxSearchCount:(NSString *)_maxSearchCount {
  ASSIGN(self->maxSearchCount, _maxSearchCount);
}
- (NSString *)maxSearchCount {
  return self->maxSearchCount;
}
- (NSString *)limitedSearchLabel {
  NSString *maxSearch;
  id       l;
  
  l         = [self labels];
  maxSearch = [maxSearchCountDef stringValue];
  
  return [NSString stringWithFormat:@"%@ %@ %@",
                     [l valueForKey:@"limitedSearchLabel"],
                     self->maxSearchCount,
                     [l valueForKey:@"recordsLabel"]];
}

- (BOOL)isSearchLimited {
  return self->opFlags.isSearchLimited ? YES : NO;
}

- (void)setItem:(id)_item {
  self->item = _item;
}
- (id)item {
  return self->item;
}

- (void)setItemIndex:(int)_idx {
  self->itemIdx = _idx;
}
- (int)itemIndex {
  return self->itemIdx;
}

- (unsigned)maxTabTitleLength {
  return maxTabTitleLength;
}
- (NSString *)customTabLabel {
  // TODO: cut-off should be done in a formatter!
  NSString *label;
  int      max;
  
  label = [self item];
  max = [self maxTabTitleLength];
  max = (max < 10) ? 10 : max;
  if ([label length] > max) {
    label = [label substringToIndex:(max - 2)];
    return [label stringByAppendingString:@".."];
  }
  return label;
}

- (BOOL)isInfolineEnabled {
  return hasSkyInfolineGathering;
}

- (BOOL)shouldShowLetterButtons {
  // TODO: might reenable that feature
  return [[[self existingSession] valueForKey:@"isTextModeBrowser"] boolValue]
    ? NO : showLetterTabs;
}

/* notifications */

- (EOQualifier *)qualifierForGlobalID:(EOGlobalID *)_gid {
  if (_gid == nil) return nil;
  return [[[EOKeyValueQualifier alloc] initWithKey:@"globalID"
                                       operatorSelector:
                                         EOQualifierOperatorEqual
                                       value:_gid] autorelease];
}

- (void)personAdded:(NSNotification *)_n {
  EOFetchSpecification *fspec;
  id obj;

  obj = [_n object];
  if (![obj respondsToSelector:@selector(globalID)]) {
    [self logWithFormat:@"ERROR: cannot process notification: %@", _n];
    return;
  }
  
  fspec = [self fetchSpecification];
  
  [fspec setQualifier:[self qualifierForGlobalID:[obj globalID]]];
  [self->dataSource setFetchSpecification:fspec];
}

/* qualifiers */

- (EOQualifier *)qualifierForPersonSearch:(NSString *)_s {
  NSString *qs;
  
  if (_s == nil) _s = @"";
  
  qs = [NSString stringWithFormat:
                   @"(name LIKE '*%@*') OR (firstname LIKE '*%@*') OR "
                   @"(nickname LIKE '*%@*') OR (login LIKE '*%@*')", 
                   _s, _s, _s, _s];
  return [EOQualifier qualifierWithQualifierFormat:qs];
}

- (EOQualifier *)qualifierForFullTextSearch:(NSString *)_s {
  EOQualifier *q;
  
  if ([_s isEqualToString:@"%"]) _s = @"";
  
  q = [[EOKeyValueQualifier alloc] initWithKey:@"fullSearchString"
                                   operatorSelector:EOQualifierOperatorLike
                                   value:_s];
  return [q autorelease];
}

- (EOQualifier *)qualifierForPrimaryKeys:(NSArray *)_pkeys {
  EOQualifier *q;
  
  // TODO: document why we need this fake object
  if ([_pkeys count] == 0) _pkeys = [NSArray arrayWithObject:@"0"];
  
  // TODO: EOQualifierOperatorEqual is wrong, should be "in" or something like
  //       that
  q = [[EOKeyValueQualifier alloc] initWithKey:@"companyId"
                                   operatorSelector:EOQualifierOperatorEqual
                                   value:_pkeys];
  return [q autorelease];
}

/* actions */

- (WOComponent *)tabClicked {
  EOFetchSpecification *fspec;

  self->opFlags.hasSearched = 0;
  
  fspec = [self fetchSpecification];
  [fspec setQualifier:nil];  
  [self->dataSource setFetchSpecification:fspec];
  
  if ([self->tabKey isEqualToString:@"advancedSearch"])
    [self setMaxSearchCount:maxSearchCountDef];
  
  [self setSearchTitle:nil];
  [self debugWithFormat:@"tab was clicked .."];
  return nil;
}

- (id)letterClicked {
  EOFetchSpecification *fspec;
  EOKeyValueQualifier  *qual;
  NSString             *value;

  value = [self->tabKey stringByAppendingString:@"*"];
  qual  = [[EOKeyValueQualifier alloc] initWithKey:@"name"
                                       operatorSelector:EOQualifierOperatorLike
                                       value:value];
  fspec = [self fetchSpecification];
  [fspec setQualifier:qual];
  [qual release]; qual = nil;
  [self->dataSource setFetchSpecification:fspec];
  
  return nil;
}

- (NSArray *)_performFetch {
  NSArray  *objects;
  unsigned count;
  int      maxSearch;
  
  if ((objects = [self->dataSource fetchObjects]) == nil)
    return nil;
  if ((count = [objects count]) == 0)
    return objects;
  
  maxSearch = [self->maxSearchCount intValue];
  if (count > maxSearch) 
    self->opFlags.isSearchLimited = 0;
  else {
    // TODO: this is incorrect! the result count can actually be smaller!
    //       how do we reliably detect a restriction? need to pass that info
    //       somehow in the context at the command
    self->opFlags.isSearchLimited = (count == maxSearch) ? 1 : 0;
  }
  return objects;
}

- (id)_viewIfOnePerson {
  NSArray *persons;
  
  persons = [self _performFetch];
  if ([self isSearchLimited]) {
    [self logWithFormat:
	    [@"WARNING: " stringByAppendingString:[self limitedSearchLabel]]];
  }
  
  if ([persons count] == 1)
    return [self activateObject:[persons lastObject] withVerb:@"view"];
  
  return nil;
}

- (id)personSearch {
  EOFetchSpecification *fspec;

  fspec = [self fetchSpecification];
  [fspec setQualifier:[self qualifierForPersonSearch:self->searchText]];
  [self->dataSource setFetchSpecification:fspec];
  
  // TODO: explain, when did the search happen?
  self->opFlags.hasSearched = 1;
  return [self _viewIfOnePerson];
}

- (WOComponent *)fullSearch {
  /*
    This method is invoked by LSWFullSearch and the search qualifier is
    constructed there.
  */
  self->opFlags.hasSearched = 1;
  return [self _viewIfOnePerson];
}

- (id)viewFavorites {
  EOFetchSpecification *fspec;
  NSArray              *favs;
  
  fspec = [self fetchSpecification];
  favs  = [[[self session] userDefaults] objectForKey:@"person_favorites"];
  
  [fspec setQualifier:[self qualifierForPrimaryKeys:favs]];
  [self->dataSource setFetchSpecification:fspec];
  
  self->opFlags.hasSearched = 1;
  
  return nil;
}

- (id)updateFavorites {
  return [self->tabKey isEqualToString:@"_favorites_"]
    ? [self viewFavorites]
    : nil;
}

- (WOComponent *)advancedSearch {
  EOFetchSpecification *fspec;

  fspec = [self fetchSpecification];
  
  [fspec setQualifier:[self qualifier]];
  [fspec setFetchLimit:[self->maxSearchCount intValue]];
  [self->dataSource setFetchSpecification:fspec];
  
  self->opFlags.hasSearched = 1;
  [self setTabKey:@"personSearch"];
  [self->searchText release]; self->searchText = nil;
  
  return [self _viewIfOnePerson];
}

/* custom tabs */

- (void)setSearchTitle:(NSString *)_title {
  ASSIGN(self->searchTitle, _title);
}
- (NSString *)searchTitle {
  return self->searchTitle;
}

- (void)setQualifier:(EOQualifier *)_qual {
  EOFetchSpecification *fSpec;
  
  fSpec = [self fetchSpecification];
  [fSpec setQualifier:_qual];
  [self->dataSource setFetchSpecification:fSpec];
}
- (EOQualifier *)qualifier {
  return [[self->dataSource fetchSpecification] qualifier];
}

- (NSArray *)savedSearches {
  NSMutableArray *ma;
  NSUserDefaults *ud;
  NSArray        *ar;
  NSDictionary   *all;
  unsigned       i, max;
  
  ud  = [[self session] userDefaults];
  all = [ud dictionaryForKey:@"person_custom_qualifiers"];
  ar  = [all allKeys];
  ma  = [NSMutableArray array];
  max = [ar count];
  for (i = 0; i < max; i++) {
    NSString *key;
    
    key = [ar objectAtIndex:i];
    if ([[(NSDictionary *)[all objectForKey:key] 
                          objectForKey:@"showTab"] boolValue])
      [ma addObject:key];
  }
  return ma;
}

- (id)customTabClicked {  
  NSString *title;
  id result;
  
  result = [self tabClicked];
  title  = [[self savedSearches] objectAtIndex:[self itemIndex]];
  if (result == nil) [self setSearchTitle:title];
  return result;
}
- (id)searchSaved {
  [self setSearchText:@""];
  self->opFlags.hasSearched = 0;
  return nil;
}
- (id)searchSelected {
  EOFetchSpecification *fspec;
  unsigned int         maxSearch;
  unsigned int         maxMax;

  maxSearch = [[self maxSearchCount] intValue];
  maxMax    = [maxSearchCountDef unsignedIntValue];
  if (maxSearch < 10 || maxSearch > maxMax) {
    maxSearch = maxMax;
    [self setMaxSearchCount:[NSString stringWithFormat:@"%d", maxSearch]];
  }

  fspec = [self fetchSpecification];
  [fspec setFetchLimit:maxSearch];
  [self->dataSource setFetchSpecification:fspec];

  [self setSearchText:@""];
  self->opFlags.hasSearched = 0;
  
  return nil;
}
- (id)removeTab {
  NSUserDefaults      *ud;
  NSString            *title;
  NSMutableDictionary *settings;
  
  title    = [[self savedSearches] objectAtIndex:[self itemIndex]];
  ud       = [[self session] userDefaults];
  settings = [[ud dictionaryForKey:@"person_custom_qualifiers"] mutableCopy];
  [settings removeObjectForKey:title];
  [ud setObject:settings forKey:@"person_custom_qualifiers"];
  [ud synchronize];
  [settings release];
  return nil;
}

- (id)newPerson {
  return [[self session] 
	   instantiateComponentForCommand:@"new" type:personDocType];
}

- (id)import {
  WOComponent *page;
  
  page = [self pageWithName:@"SkyContactImportUploadPage"];
  [page takeValue:@"Person" forKey:@"contactType"];
  return page;
}

- (id)formLetterTarget {
  return [[self context] contextID];
}

- (Class)wizardClass {
  return NSClassFromString(@"SkyPersonWizard");
}
- (id)wizard {
  SkyWizard *wizard;
  
  wizard = [[self wizardClass] wizardWithSession:[self session]];
  [wizard setStartPage:self];
  return [wizard start];
}

- (id)gathering {
  return [self pageWithName:@"SkyBusinessCardGathering"];
}
- (id)infolineGathering {
  return [self pageWithName:@"SkyInfolineGathering"];
}

@end /* LSWPersons */
