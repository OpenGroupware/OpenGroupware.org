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
// $Id: LSWPersonAdvancedSearch.m 1 2004-08-20 11:17:52Z znek $

#include "LSWPersonAdvancedSearch.h"
#include "common.h"
#include <NGExtensions/NSString+Ext.h>
#include <OGoContacts/SkyPersonAddressConverterDataSource.h>

@interface LSWPersonAdvancedSearch(PrivateMethodes)
- (NSArray *)extendedPersonAttributeKeys;
- (void)_createQualifier;
- (NSMutableDictionary *)_createSearchInfo;
- (void)_setSearchFields:(NSDictionary *)_fields;
- (void)setMaxSearchCount:(NSString *)_maxSearchCount;
- (NSString *)maxSearchCount;
- (id)search;
@end

@implementation LSWPersonAdvancedSearch

static NSArray *SkyPublicExtendedPersonAttributes = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  SkyPublicExtendedPersonAttributes = 
    [[ud arrayForKey:@"SkyPublicExtendedPersonAttributes"] copy];
}

- (NSArray *)_extractKeysFromAttributes:(NSArray *)_attrs {
  // TODO: looks like we could just use -valueForKey:@"key"?
  NSMutableArray *keys;
  int i, cnt;

  cnt  = [_attrs count];
  keys = [NSMutableArray arrayWithCapacity:cnt];
  for (i = 0; i < cnt; i++) {
    [keys addObject:
            [(NSDictionary *)[_attrs objectAtIndex:i] objectForKey:@"key"]];
  }
  return [keys sortedArrayUsingSelector:@selector(compare:)];
}

- (id)init {
  if ((self = [super init])) {
    
    self->extendedAttributeKeys = 
      [[self _extractKeysFromAttributes:SkyPublicExtendedPersonAttributes]
             copy];
    
    self->person = [[NSMutableDictionary alloc] initWithCapacity:16];
  }
  return self;
}

- (void)dealloc {
  [self->maxSearchCount        release];
  [self->extendedAttributeKeys release];
  [self->person                release];
  [self->formletterData        release];
  [self->qualifier             release];

  [self->udKey       release];
  [self->searchTitle release];
  [self->saveTitle   release];
  [super dealloc];
}

/* accessors */

- (void)setPerson:(NSMutableDictionary *)_person {
  ASSIGN(self->person, _person);
}
- (NSMutableDictionary *)person {
  return self->person;
}

- (void)setQualifier:(EOQualifier *)_qualifier {
}

- (EOQualifier *)qualifier {
  return self->qualifier;
}

- (NSString *)currentTeleTypeLabel {
  NSString *s;
  s = [self->currentTeleType stringByAppendingString:@"_search"];
  return [[self labels] valueForKey:s];
}

- (NSArray *)currentValues {
  return self->extendedAttributeKeys;
}

- (NSArray *)currentLabel {
  NSString *label = [[self labels] valueForKey:self->item];
  return (label == nil) ? self->item : label;
}

- (BOOL)hasSearched {
  return self->hasSearched;
}
- (void)setHasSearched:(BOOL)_searched {
  self->hasSearched = _searched;
}

- (void)setItem:(id)_item {
  self->item = _item;
}
- (id)item {
  return self->item;
}

- (void)setCurrentTeleType:(NSString *)_teleType {
  self->currentTeleType = _teleType;
}
- (NSString *)currentTeleType {
  return self->currentTeleType;
}

- (NSString *)maxSearchCount {
  return self->maxSearchCount;
}
- (void)setMaxSearchCount:(NSString *)_maxSearchCount {
  ASSIGN(self->maxSearchCount, _maxSearchCount);
}

/* actions */

- (NSMutableDictionary *)_createSearchInfo {
  NSMutableDictionary *dict;
  NSArray             *keys;
  int                 i, cnt;

  keys = [self->person allKeys];
  cnt  = [keys count];
  dict = [NSMutableDictionary dictionaryWithCapacity:cnt+1];
  
  for (i = 0; i < cnt; i++) {
    NSArray  *components;
    NSString *key;
    id       value;
    
    key        = [keys objectAtIndex:i];
    value      = [self->person objectForKey:key];
    
    if (![value isNotNull] || [value length] == 0)
      continue;

    components = [key componentsSeparatedByString:@"#"];
    key        = [components componentsJoinedByString:@"."];

    [dict setObject:value forKey:key];
  }

  return dict;
}

- (void)_setSearchFields:(NSDictionary *)_fields {
  NSArray             *keys;
  int                 i, cnt;

  keys = [_fields allKeys];
  cnt  = [keys count];

  // clear form
  [self->person removeAllObjects];
  [self takeValue:nil forKey:@"companyValueAttribute"];
  [self takeValue:nil forKey:@"companyValueValue"];
  
  for (i = 0; i < cnt; i++) {
    NSArray  *components;
    NSString *key;
    id       value;
    
    key        = [keys objectAtIndex:i];
    value      = [_fields objectForKey:key];
    
    components = [key componentsSeparatedByString:@"."];
    key        = [components componentsJoinedByString:@"#"];

    if ([key isEqualToString:@"companyValueValue"]) 
      [self takeValue:value forKey:@"companyValueValue"];
    else if ([key isEqualToString:@"companyValueAttribute"]) 
      [self takeValue:value forKey:@"companyValueAttribute"];
    
    else if ([value isNotNull] && [value length] != 0)
      [self->person setObject:value forKey:key];
  }
}

- (void)_createQualifier {
  NSMutableDictionary *dict;
  NSArray             *keys;
  int                 i, cnt;

  dict = [self _createSearchInfo];

  if ([self valueForKey:@"companyValueAttribute"] &&
      [self valueForKey:@"companyValueValue"]) {
    [dict setObject:[self valueForKey:@"companyValueValue"]
          forKey:[self valueForKey:@"companyValueAttribute"]];
  }

  {
    NSMutableString *format    = nil;
    BOOL            isFirstKey = YES;
    
    format = [NSMutableString stringWithCapacity:128];
    keys   = [dict allKeys];
    cnt    = [keys count];
    
    for (i = 0; i < cnt; i++) {
      NSString *key  = [keys objectAtIndex:i];
      id       value = [dict objectForKey:key];      

      value = [value stringValue];

      if (isFirstKey)
        isFirstKey = NO;
      else
        [format appendString:@" and "];

      [format appendString:key];

      // TODO: this looks a LOT like duplicate code with PersonsUI!
#if 0
      if (([key isEqualToString:@"keywords"] &&
	   !([(NSString *)value hasPrefix:@"*"] ||
	     [(NSString *)value hasPrefix:@"%"])))
	[format appendString:@" like '*"];
      else
#endif
      [format appendString:@" like '"];        

      if ([value rangeOfString:@"%"].length > 0) 
        value = [value stringByReplacingString:@"%" withString:@"*"];
      [format appendString:value];
      if (![(NSString *)value hasSuffix:@"*"])
        [format appendString:@"*'"];
      else
        [format appendString:@"'"];
    }
    
    [self->qualifier release]; self->qualifier = nil;
    self->qualifier = 
      [[EOQualifier qualifierWithQualifierFormat:format] retain];
  }
}

- (id)search {
  [self _createQualifier];
  [self->formletterData release]; self->formletterData = nil;
  return [self performParentAction:@"advancedSearch"];
}

- (NSString *)defaultFormLetterKind {
  return [[[self session] userDefaults] objectForKey:@"formletter_kind"];
}

- (id)formletter {
  SkyPersonAddressConverterDataSource *ds;
  EOFetchSpecification                *fspec;
  NSDictionary                        *hints;
  NSString                            *kind;
  LSCommandContext                    *ctx;
  NSData  *data = nil;

  [self _createQualifier];
  
  kind  = [self defaultFormLetterKind];
  fspec = [[EOFetchSpecification alloc] init];
  hints = [[NSDictionary alloc] initWithObjectsAndKeys:kind, @"kind", nil];
  ctx   = [(OGoSession *)[self session] commandContext];
  ds    = [[SkyPersonAddressConverterDataSource alloc] 
	    initWithContext:ctx labels:[self labels]];
  
  [fspec setQualifier:self->qualifier];
  [fspec setFetchLimit:[self->maxSearchCount intValue]];
  [fspec setHints:hints];
  [ds setFetchSpecification:fspec];
  
  data  = [[ds fetchObjects] lastObject];
  ASSIGN(self->formletterData, data);
  
  [fspec release];
  [ds    release];
  [hints release];
  return nil;
}

- (id)clearForm {
  [self->person removeAllObjects];
  [self _createQualifier];
  return nil;
}

- (BOOL)hasFormletter {
  return (self->formletterData != nil) ? YES : NO;
}

- (void)setFormletterData:(id)_data {
  ASSIGN(self->formletterData, _data);
}
- (id)formletterData {
  return self->formletterData;
}

/* SavedSearches */

- (void)setUserDefaultKey:(NSString *)_key {
  ASSIGN(self->udKey,_key);
}
- (NSString *)userDefaultKey {
  return self->udKey;
}

- (void)setSearchTitle:(NSString *)_title {
  ASSIGN(self->searchTitle,_title);
}
- (NSString *)searchTitle {
  return self->searchTitle;
}

- (void)setSaveTitle:(NSString *)_title {
  ASSIGN(self->saveTitle,_title);
}
- (NSString *)saveTitle {
  return self->saveTitle;
}

- (void)setShowTab:(BOOL)_flag {
  self->showTab = _flag;
}
- (BOOL)showTab {
  return self->showTab;  
}

- (NSArray *)savedSearches {
  return [[[[[self session] userDefaults] objectForKey:[self userDefaultKey]]
                   allKeys] sortedArrayUsingSelector:@selector(compare:)];
}
- (BOOL)hasSavedSearches {
  return [[self savedSearches] count] ? YES : NO;
}

- (id)saveSearch {
  NSUserDefaults      *ud;
  NSMutableDictionary *settings;
  NSMutableDictionary *info;
  EOQualifier  *qual;

  if (![self->saveTitle length]) {
    [[self parent] setErrorString:
                   [[self labels] valueForKey:@"error_setSearchTitle"]];
    return nil;
  }

  [self _createQualifier];
  info = [self _createSearchInfo];
  {
    id tmp;
    
    if ((tmp = [self valueForKey:@"companyValueAttribute"]))
      [info setObject:tmp forKey:@"companyValueAttribute"];
    if ((tmp = [self valueForKey:@"companyValueValue"]))
      [info setObject:tmp forKey:@"companyValueValue"];
  }
  qual = self->qualifier;

  info = [NSDictionary dictionaryWithObjectsAndKeys:
                       info,                  @"searchFields",
                       [qual description],    @"qualifier",
                       [self maxSearchCount], @"maxSearchCount",
                       [NSNumber numberWithBool:[self showTab]], @"showTab",
                       nil];

  ud       = [[self session] userDefaults];
  settings = [ud objectForKey:[self userDefaultKey]];
  if (settings == nil) {
    settings = [NSDictionary dictionaryWithObjectsAndKeys:
                             info, self->saveTitle, nil];
  }
  else {
    settings = [[settings mutableCopy] autorelease];
    [settings setObject:info forKey:self->saveTitle];
  }
  [ud setObject:settings forKey:[self userDefaultKey]];
  [ud synchronize];
  [self setSaveTitle:@""];
  [self setShowTab:NO];

  return nil;
}

- (id)saveAndSearch {
  [self saveSearch];
  return [self search];
}

- (id)loadSavedSearch {
  NSDictionary   *settings;
  NSDictionary   *info;
  NSUserDefaults *ud;

  if (![self->searchTitle length]) {
    [self _setSearchFields:nil];
    [self setSaveTitle:@""];
    [self setShowTab:NO];
    return nil;
  }

  ud       = [[self session] userDefaults];
  settings = [ud objectForKey:[self userDefaultKey]];
  info     = [settings objectForKey:self->searchTitle];

  if (info == nil) {
    NSString *s;

    s = [[self labels] valueForKey:@"error_cannotLoadSavedSearch"];
    [[self parent] setErrorString:s];
    return nil;
  }

  [self _setSearchFields:[info objectForKey:@"searchFields"]];
  [self setMaxSearchCount:[info objectForKey:@"maxSearchCount"]];
  [self setShowTab:[[info objectForKey:@"showTab"] boolValue]];
  [self setSaveTitle:self->searchTitle];

  return nil;
}

@end /* LSWPersonAdvancedSearch(SavedSearches) */
