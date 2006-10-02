/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

#include "LSWEnterprises.h"
#include "common.h"
#include <OGoFoundation/LSWNotifications.h>
#include <NGExtensions/EOCacheDataSource.h>
#include <OGoContacts/SkyEnterpriseDataSource.h>
#include <NGMime/NGMimeType.h>

@interface WOComponent(LSWAddressAdditions)
- (id)fullSearch;
- (id)advancedSearch;
- (id)tabClicked;
@end

@interface LSWEnterprises(PrivateMethodes)
- (void)setMaxSearchCount:(NSString *)_maxSearchCount;
- (void)setSearchTitle:(NSString *)_title;
- (void)setTabKey:(NSString *)_key;
@end

@implementation LSWEnterprises

static unsigned   maxLength = 0;
static id         LSMaxSearchCount       = nil;
static NGMimeType *mimeTypeEnterpriseDoc = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  maxLength = [ud integerForKey:@"contacts_maxTabTitleLength"];
  if (maxLength < 10) maxLength = 16;
  
  LSMaxSearchCount = [[ud objectForKey:@"LSMaxSearchCount"] copy];

  mimeTypeEnterpriseDoc = 
    [[NGMimeType mimeType:@"objc" subType:@"SkyEnterpriseDocument"] copy];
}

- (EOFetchSpecification *)fetchSpecification {
  EOFetchSpecification *fspec;

  fspec = [[self->dataSource fetchSpecification] copy];
  
  if (fspec == nil)
    fspec = [[EOFetchSpecification alloc] init];

  return [fspec autorelease];
}

- (id)init {
  id p;

  /* this component is a session-singleton */
  if ((p = [self persistentInstance]) != nil) {
    [self release];
    return [p retain];
  }
  
  if ((self = [super init])) {
    SkyEnterpriseDataSource *ds;
    NSNotificationCenter *nc;
    LSCommandContext *ctx;

    [self registerAsPersistentInstance];
    
    ctx = [(OGoSession *)[self session] commandContext];
    ds  = [(SkyEnterpriseDataSource *)[SkyEnterpriseDataSource alloc] 
				      initWithContext:ctx];
    self->dataSource = [[EOCacheDataSource alloc] initWithDataSource:ds];
    [ds release]; ds = nil;
    
    [self setMaxSearchCount:LSMaxSearchCount];
    
    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(enterpriseAdded:)
	name:SkyNewEnterpriseNotification object:nil];
    
    [self setTabKey:@"enterpriseSearch"];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->maxSearchCount release];
  [self->dataSource     release];
  [self->enterprise     release];
  [self->searchText     release];
  [self->tabKey         release];
  [self->searchText     release];
  [super dealloc];
}

/* accessors */

- (NSString *)activeConfigKey {
  if ([self->tabKey isEqualToString:@"_favorites_"])
    return @"enterprise_favlist_cols";
  if ([self->tabKey isEqualToString:@"enterpriseSearch"])
    return @"enterprise_searchlist_cols";
  if ([self->tabKey isEqualToString:@"advancedSearch"])
    return @"enterprise_advsearchlist_cols";
  if ([self->tabKey isEqualToString:@"search"])
    return @"enterprise_fullsearchlist_cols";
  
  return [NSString stringWithFormat:@"enterprise_customlist_%i",self->itemIdx];
}
- (void)setIsInConfigMode:(BOOL)_flag {
  self->isInConfigMode = _flag ? 1 : 0;
}
- (BOOL)isInConfigMode {
  return self->isInConfigMode ? YES : NO;
}

- (void)setTabKey:(NSString *)_key {
  ASSIGNCOPY(self->tabKey, _key);
}
- (NSString *)tabKey {
  return self->tabKey;
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

- (NSMutableString *)iconItem {
  // TODO: why does this return a mutable string?
  return [NSMutableString stringWithString:[[self item] lowercaseString]];
}

- (unsigned)maxTabTitleLength {
  return maxLength;
}

- (NSString *)customTabLabel {
  // TODO: use formatter for that
  NSString *label;
  int max;

  label = [self item];
  max = [self maxTabTitleLength];
  max = (max < 10) ? 10 : max;
  if ([label length] > max)
    return [[label substringToIndex:max-2] stringByAppendingString:@".."];
  
  return label;
}

- (NSString *)iconForTab { // TODO: this is deprecated, right?
  NSMutableString *myIcon;
  NSString        *t;

  myIcon = [self iconItem];
  t = [self tabKey];
  
  if ([t isEqualToString: @"enterpriseSearch"] ||
      [t isEqualToString: @"search"] ||
      [t isEqualToString: @"advancedSearch"]) {
    return [myIcon stringByAppendingString:@"_right"];
  }

  if ([[t lowercaseString] isEqualToString:myIcon])
    return myIcon;

  if ([[t lowercaseString] compare:myIcon] > 0)
    return [myIcon stringByAppendingString:@"_left"];
  
  return [myIcon stringByAppendingString: @"_right"];
}

- (NSString *)advTabIcon { // TODO: this is deprecated, right?
  NSString *t;

  t = [self tabKey];

  if ([t isEqualToString: @"enterpriseSearch"])
    return @"advanced_right";

  if ([t isEqualToString: @"advancedSearch"])
    return @"advanced";
  
  return @"advanced_left";
}

- (NSString *)fullTabIcon { // TODO: this is deprecated, right?
  NSString *t;

  t = [self tabKey];

  if ([t isEqualToString: @"enterpriseSearch"] ||
      [t isEqualToString: @"advancedSearch"]) {
    return @"full_right";
  } 

  if ([t isEqualToString: @"search"])
    return @"full";
  
  return @"full_left";
}

- (void)setSearchText:(NSString *)_text {
  ASSIGNCOPY(self->searchText, _text);
}
- (NSString *)searchText {
  return self->searchText;
}

- (void)setHasSearched:(BOOL)_searched {
  self->hasSearched = _searched;
}
- (BOOL)hasSearched {
  return self->hasSearched;
}

- (int)blockSize {
  OGoSession *sn = [self session];
  
  return [[[sn userDefaults] objectForKey:@"address_blocksize"] intValue];
}

- (void)setCurrentBatch:(unsigned)_currentBatch {
  self->currentBatch = _currentBatch;
}
- (unsigned)currentBatch {
  return self->currentBatch;    
}

- (void)setIsDescending:(BOOL)_isDescending {
  self->isDescending = _isDescending;
}
- (BOOL)isDescending {
  return self->isDescending;    
}

- (void)setEnterprise:(id)_enterprise {
  ASSIGN(self->enterprise, _enterprise);
}
- (id)enterprise {
  return self->enterprise;    
}

- (EODataSource *)dataSource {
  return self->dataSource;
}

- (void)setMaxSearchCount:(NSString *)_maxSearchCount {
  ASSIGN(self->maxSearchCount, _maxSearchCount);
}
- (NSString *)maxSearchCount {
  return self->maxSearchCount;
}

- (NSString *)limitedSearchLabel {
  return [NSString stringWithFormat:@"%@ %@ %@",
                     [[self labels] valueForKey:@"limitedSearchLabel"],
                     self->maxSearchCount,
                     [[self labels] valueForKey:@"recordsLabel"]];
}

- (BOOL)isSearchLimited {
  int maxSearch;

  maxSearch = [self->maxSearchCount intValue];

  return ([[self->dataSource fetchObjects] count] == (unsigned)maxSearch);
}

/* actions */

- (void)enterpriseAdded:(NSNotification *)_n {
  id obj;

  obj = [_n object];

  if ((obj == nil) || ![obj respondsToSelector:@selector(globalID)]) {
    NSLog(@"invalid notification caught: %@", _n);    
  }
  else {
    EOQualifier *q;
    EOFetchSpecification *fspec;

    q = [EOQualifier qualifierWithQualifierFormat:@"globalID=%@",
                     [obj globalID]];

    fspec = [self fetchSpecification];
    [fspec setQualifier:q];
    [self->dataSource setFetchSpecification:fspec];
  }
}

- (id)_viewIfOneEnterprise {
  NSArray *enterprises;

  enterprises = [self->dataSource fetchObjects];
  
  if ([enterprises count] == 1)
    return [self activateObject:[enterprises lastObject] withVerb:@"view"];
  
  return nil;
}

- (WOComponent *)tabClicked {
  EOFetchSpecification *fspec;
  
  fspec = [self fetchSpecification];
  [fspec setQualifier:nil];
  [self->dataSource setFetchSpecification:fspec];
  
  self->currentBatch = 0;

  if ([self->tabKey isEqualToString:@"advancedSearch"])
    [self setMaxSearchCount:LSMaxSearchCount];
  
  [self setSearchTitle:nil];
  return nil;
}

- (id)letterClicked {
  EOFetchSpecification *fspec;
  EOKeyValueQualifier  *qual;
  NSString             *value;

  value = [self->tabKey stringByAppendingString:@"*"];
  qual = [[EOKeyValueQualifier alloc] initWithKey:@"name"
                                      operatorSelector:EOQualifierOperatorLike
                                      value:value];

  fspec = [self fetchSpecification];
  [fspec setQualifier:qual];
  [self->dataSource setFetchSpecification:fspec];

  self->currentBatch = 0;

  [qual release];
                                                  
  return nil;
}

- (WOComponent *)fullSearch {
  EOFetchSpecification *fspec;
  EOKeyValueQualifier  *qual;
  NSString             *s;

  s = self->searchText;
  if ([s isEqualToString:@"%"]) s = @"";

  qual = [[EOKeyValueQualifier alloc] initWithKey:@"fullSearchString"
                                      operatorSelector:EOQualifierOperatorLike
                                      value:s];

  fspec = [self fetchSpecification];
  [fspec setQualifier:qual];
  [self->dataSource setFetchSpecification:fspec];

  self->hasSearched = YES;
  [qual release];

  return [self _viewIfOneEnterprise];
}

- (id)enterpriseSearch {
  EOFetchSpecification *fspec;
  EOQualifier          *qual  = nil;
  NSString             *s     = nil;

  fspec = [self fetchSpecification];
  s = self->searchText;
  
  if ([s length] > 0) {
    qual = [EOQualifier qualifierWithQualifierFormat:
                        [NSString stringWithFormat:
                                  @"name like '*%@*' or number like '*%@*' or "
                                  @"keywords like '*%@*'", s, s, s]];
    [fspec setQualifier:qual];
    [self->dataSource setFetchSpecification:fspec];
    self->currentBatch = 0;
    self->hasSearched  = YES;
  }
  return [self _viewIfOneEnterprise];
}

- (id)viewFavorites {
  EOFetchSpecification *fspec;
  EOQualifier          *qual;
  NSArray              *favs;

  fspec = [self fetchSpecification];
  favs  = [[[self session] userDefaults] objectForKey:@"enterprise_favorites"];
  if (![favs count]) favs = [NSArray arrayWithObject:@"0"];
  
  qual = [[EOKeyValueQualifier alloc]
                               initWithKey:@"companyId"
                               operatorSelector:EOQualifierOperatorEqual
                               value:favs];

  [fspec setQualifier:qual];
  [self->dataSource setFetchSpecification:fspec];

  self->hasSearched = YES;
  [qual release];

  return nil;
}

- (id)updateFavorites {
  if ([self->tabKey isEqualToString:@"_favorites_"])
    return [self viewFavorites];
  return nil;
}

- (WOComponent *)advancedSearch {
  EOFetchSpecification *fspec;

  fspec = [self fetchSpecification];

  [fspec setQualifier:[self valueForKey:@"qualifier"]];
  [fspec setFetchLimit:[self->maxSearchCount intValue]];
  [self->dataSource setFetchSpecification:fspec];
  
  [self setTabKey:@"enterpriseSearch"];
  [self->searchText release]; self->searchText = nil;

  self->currentBatch      = 0;
  self->hasSearched       = YES;
  
  return [self _viewIfOneEnterprise];
}

- (id)showColumnConfigEditor {
  [self setIsInConfigMode:YES];
  return nil; /* start on page */
}


/* printing */

- (id)printList {
  OGoComponent *page;
  WOResponse   *r;
  
  page = [self pageWithName:@"OGoPrintCompanyList"];
  [page takeValue:[self dataSource]      forKey:@"dataSource"];
  [page takeValue:[self activeConfigKey] forKey:@"configKey"];
  [page takeValue:[self labels]          forKey:@"labels"];
  
  r = [page generateResponse];
  [r setHeader:@"text/html" forKey:@"content-type"];
  
  return r;
}


/* custom tabs */

- (void)setSearchTitle:(NSString *)_title {
  ASSIGNCOPY(self->searchTitle,_title);
}
- (NSString *)searchTitle {
  return self->searchTitle;
}

- (EOQualifier *)qualifier {
  return [[self->dataSource fetchSpecification] qualifier];
}
- (void)setQualifier:(EOQualifier *)_qual {
  EOFetchSpecification *fSpec = [self fetchSpecification];
  [fSpec setQualifier:_qual];
  [self->dataSource setFetchSpecification:fSpec];
}

- (NSArray *)savedSearches {
  NSMutableArray *ma;
  NSUserDefaults *ud;
  NSArray        *ar;
  NSDictionary   *all;
  NSString       *key;
  unsigned i, max;
  
  ud  = [[self session] userDefaults];
  all = [ud objectForKey:@"enterprise_custom_qualifiers"];
  ar  = [all allKeys];
  ma  = [NSMutableArray array];
  max = [ar count];
  for (i = 0; i < max; i++) {
    NSDictionary *d;
    
    key = [ar objectAtIndex:i];
    d = [all objectForKey:key];
    if ([[d objectForKey:@"showTab"] boolValue])
      [ma addObject:key];
  }
  return ma;
}

- (id)customTabClicked {
  id result, title;
  
  result = [self tabClicked];
  title  = [[self savedSearches] objectAtIndex:[self itemIndex]];
  if (result == nil) [self setSearchTitle:title];
  return result;
}
- (id)searchSaved {
  [self setSearchText:@""];
  self->hasSearched = NO;
  return nil;
}
- (id)searchSelected {
  EOFetchSpecification *fspec;
  unsigned int         maxSearch;
  unsigned int         maxMax;

  maxSearch = [[self maxSearchCount] intValue];
  maxMax    = [LSMaxSearchCount intValue];
  if (maxSearch < 10 || maxSearch > maxMax) { // TODO: clean that stuff up!
    NSString *s;
    char buf[64];
    
    maxSearch = maxMax;
    sprintf(buf, "%d", maxSearch);
    s = [[NSString alloc] initWithCString:buf];
    [self setMaxSearchCount:s];
    [s release];
  }

  fspec = [self fetchSpecification];
  [fspec setFetchLimit:maxSearch];
  [self->dataSource setFetchSpecification:fspec];

  [self setSearchText:@""];
  self->hasSearched = NO;
  
  return nil;
}

- (id)removeTab {
  // TODO: move tab management to separate class!
  id             title;
  NSUserDefaults *ud;
  NSMutableDictionary *settings;
  
  title    = [[self savedSearches] objectAtIndex:[self itemIndex]];
  ud       = [[self session] userDefaults];
  settings =
    [[ud dictionaryForKey:@"enterprise_custom_qualifiers"] mutableCopy];
  [settings removeObjectForKey:title];
  [ud setObject:settings forKey:@"enterprise_custom_qualifiers"];
  [ud synchronize];

  [settings release];
  return nil;
}

- (WOComponent *)newEnterprise {
  WOComponent *ct;
  
  ct = [[self session] instantiateComponentForCommand:@"new" 
		       type:mimeTypeEnterpriseDoc];
  [self enterPage:(id)ct];
  return nil; // TODO: would just returning the component be sufficient?
}

- (id)import {
  WOComponent *page;

  if ((page = [self pageWithName:@"SkyContactImportUploadPage"]) != nil)
    [page takeValue:@"Enterprise" forKey:@"contactType"];
  [self enterPage:page];
  return page; // TODO: would just returning the component be sufficient?
}

- (id)formLetterTarget {
  return [[self context] contextID];
}

@end /* LSWEnterprises */
