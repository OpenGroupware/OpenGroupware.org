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
// $Id: LSWEnterpriseAdvancedSearch.m 1 2004-08-20 11:17:52Z znek $

#include <OGoFoundation/LSWComponent.h>

@class NSString, NSArray, NSMutableDictionary, EOQualifier, NSData;

@interface LSWEnterpriseAdvancedSearch : LSWComponent
{
@private
  NSString            *maxSearchCount;
  NSArray             *extendedAttributeKeys;
  NSMutableDictionary *enterprise;
  EOQualifier         *qualifier;
  id                  item;      // non-retained
  NSData              *formletterData;

  NSString            *udKey;
  NSString            *searchTitle;
  NSString            *saveTitle;
  BOOL                showTab;
}

/* PrivateMethods */

- (void)_createQualifier;
- (void)setMaxSearchCount:(NSString *)_maxSearchCount;
- (NSString *)maxSearchCount;
- (NSMutableDictionary *)_createSearchInfo;
- (void)_setSearchFields:(NSDictionary *)_fields;
- (id)search;

@end /* LSWEnterpriseAdvancedSearch */

#include "common.h"
#include <NGExtensions/NSString+Ext.h>
#include <OGoContacts/SkyEnterpriseAddressConverterDataSource.h>

@implementation LSWEnterpriseAdvancedSearch

- (id)init {
  if ((self = [super init])) {
    NSMutableArray *keys = nil;
    NSArray *attrs       = nil;
    int     i, cnt;
    
    // TODO: move this code to a method
    keys = [NSMutableArray arrayWithCapacity:16];

    attrs = [[[self session]
                    userDefaults]
                    arrayForKey:@"SkyPublicExtendedEnterpriseAttributes"];

    for (i = 0, cnt = [attrs count]; i < cnt; i++)
      [keys addObject:[[attrs objectAtIndex:i] objectForKey:@"key"]];
    
    keys = (id)[keys sortedArrayUsingSelector:@selector(compare:)];
    self->extendedAttributeKeys = [keys retain];
    
    self->enterprise = [[NSMutableDictionary alloc] initWithCapacity:16];
    
    self->qualifier      = nil;
    self->formletterData = nil;
  }
  return self;
}

- (void)dealloc {
  [self->enterprise release];
  [self->extendedAttributeKeys release];
  [self->formletterData release];
  [self->qualifier release];
  [self->maxSearchCount release];

  [self->udKey       release];
  [self->searchTitle release];
  [self->saveTitle   release];
  [super dealloc];
}

// defaults

- (NSArray *)extendedEnterpriseAttributesKeys {
  return self->extendedAttributeKeys;
}

// accessors

- (void)setEnterprise:(NSMutableDictionary *)_enterprise {
  ASSIGN(self->enterprise, _enterprise);
}
- (NSMutableDictionary *)enterprise {
  return self->enterprise;
}

- (void)setQualifier:(EOQualifier *)_qualifier {}
- (EOQualifier *)qualifier {
  return self->qualifier;
}

- (void)setItem:(id)_item {
  self->item = _item;
}
- (id)item {
  return self->item;
}

- (void)setMaxSearchCount:(NSString *)_maxSearchCount {
  ASSIGN(self->maxSearchCount, _maxSearchCount);
}
- (NSString *)maxSearchCount {
  return self->maxSearchCount;
}

- (void)setFormletterData:(id)_data {
  ASSIGN(self->formletterData, _data);
}
- (id)formletterData {
  return self->formletterData;
}

- (BOOL)hasExtendedAttributes {
  return ([self->extendedAttributeKeys count] > 0);
}

- (NSArray *)currentValues {
  return [self->extendedAttributeKeys
              sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)currentLabel {
  NSString *label;

  label = [[self labels] valueForKey:self->item];
  return (label == nil) ? self->item : label;
}

// actions

- (NSMutableDictionary *)_createSearchInfo {
  NSMutableDictionary *dict;
  NSArray             *keys;
  int                 i, cnt;

  keys = [self->enterprise allKeys];
  cnt  = [keys count];
  dict = [NSMutableDictionary dictionaryWithCapacity:cnt+1];
  
  for (i = 0; i < cnt; i++) {
    NSArray  *components;
    NSString *key;
    id       value;
    
    key        = [keys objectAtIndex:i];
    value      = [self->enterprise objectForKey:key];
    
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
  [self->enterprise removeAllObjects];
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
      [self->enterprise setObject:value forKey:key];
  }
}

- (void)_createQualifier {
  NSMutableDictionary *dict;
  NSArray             *keys;
  int                 i, cnt;

  keys = [self->enterprise allKeys];
  cnt  = [keys count];
  dict = [NSMutableDictionary dictionaryWithCapacity:cnt+1];
  
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
    [self->qualifier release];
    self->qualifier = [[EOQualifier qualifierWithQualifierFormat:format]
                                    retain];
  }
}

- (id)search {
  [self _createQualifier];
  [self->formletterData release]; self->formletterData = nil;
  return [self performParentAction:@"advancedSearch"];
}

- (id)formletter {
  SkyEnterpriseAddressConverterDataSource *ds    = nil;
  EOFetchSpecification                    *fspec = nil;
  NSDictionary                            *hints = nil;
  NSString                                *kind  = nil;
  id                                      ctx    = nil;
  NSData                                  *data  = nil;

  [self _createQualifier];

  kind  = [[[self session] userDefaults] objectForKey:@"formletter_kind"];
  fspec = [[EOFetchSpecification alloc] init];
  hints = [[NSDictionary alloc] initWithObjectsAndKeys:kind, @"kind", nil];
  ctx   = [(OGoSession *)[self session] commandContext];
  ds    = [[SkyEnterpriseAddressConverterDataSource alloc] 
	    initWithContext:ctx labels:[self labels]];
  
  [fspec setQualifier:self->qualifier];
  [fspec setHints:hints];
  [ds setFetchSpecification:fspec];
  data  = [[ds fetchObjects] lastObject];
  ASSIGN(self->formletterData, data);

  [fspec release]; fspec = nil;
  [ds    release]; ds    = nil;
  [hints release]; hints = nil;
  
  return nil;
}

- (id)clearForm {
  [self _createQualifier];
  [self->enterprise removeAllObjects];

  return nil;
}

- (BOOL)hasFormletter {
  return (self->formletterData != nil);
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

@end /* LSWEnterpriseAdvancedSearch(SavedSearches) */
