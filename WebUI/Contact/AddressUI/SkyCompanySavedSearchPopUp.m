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

#include <OGoFoundation/OGoComponent.h>

@class EOQualifier;
@class NSNumber;

@interface SkyCompanySavedSearchPopUp : OGoComponent
{
  EOQualifier *qualifier;        // <>  qualifer
  NSString    *maxSearchCount;   // <>  maxSearchCount
  NSNumber    *hasSearched;      //  >  hasSearched
  NSString    *recommendedTitle; //  >  recomendedTitle

  NSString    *udKey;            //  >  userDefaultKey // NEDED

  NSString    *searchTitle;      // <>  searchTitle
                                 //  >  searchSelected // action
                                 //  >  searchSaved    // action
  NSNumber    *showTab;

  NSString    *saveTitle;

  BOOL        mustUpdateParent;
  NSArray     *listKeys;
}

@end /* SkyCompanySavedSearchPopUp */

#include "common.h"
#include <EOControl/EOKeyGlobalID.h>
#include <OGoFoundation/OGoSession.h>

@interface SkyCompanySavedSearchPopUp(PrivateMethodes)
- (NSArray *)arrayForQualifier:(EOQualifier *)_qual;
- (EOQualifier *)buildQualifierWithArray:(NSArray *)_array;
@end /* SkyCompanySavedSearchPopUp(PrivateMethodes) */

@implementation SkyCompanySavedSearchPopUp

- (void)dealloc {
  [self->qualifier        release];
  [self->maxSearchCount   release];
  [self->hasSearched      release];
  [self->recommendedTitle release];
  [self->udKey            release];
  [self->searchTitle      release];
  [self->saveTitle        release];
  [self->listKeys         release];
  [self->showTab          release];
  [super dealloc];
}

/* notifications */

- (void)resetIVars {
  [self->qualifier        release]; self->qualifier        = nil;
  [self->maxSearchCount   release]; self->maxSearchCount   = nil;  
  [self->hasSearched      release]; self->hasSearched      = nil;
  [self->recommendedTitle release]; self->recommendedTitle = nil;
  [self->udKey            release]; self->udKey            = nil;
  [self->searchTitle      release]; self->searchTitle      = nil;
  [self->listKeys         release]; self->listKeys         = nil;
  [self->showTab          release]; self->showTab          = nil;
  self->mustUpdateParent = NO;
}

- (void)sleep {
  [self resetIVars];
  [super sleep];
}

/* accessors */

- (void)setQualifier:(EOQualifier *)_qual {
  ASSIGN(self->qualifier,_qual);
}
- (EOQualifier *)qualifier {
  return self->qualifier;
}

- (void)setMaxSearchCount:(NSString *)_max {
  ASSIGN(self->maxSearchCount,_max);
}
- (NSString *)maxSearchCount {
  return self->maxSearchCount;
}

- (void)setHasSearched:(NSNumber *)_hasSearched {
  ASSIGN(self->hasSearched,_hasSearched);
}
- (NSNumber *)hasSearched {
  return self->hasSearched;
}

- (void)setRecommendedTitle:(NSString *)_title {
  ASSIGN(self->recommendedTitle,_title);
}
- (NSString *)recommendedTitle {
  return self->recommendedTitle;
}

- (void)setUdKey:(NSString *)_key {
  if (![self->udKey isEqualToString:_key]) {
    ASSIGN(self->udKey,_key);
    [self->listKeys release]; self->listKeys = nil;
  }
}
- (NSString *)udKey {
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

- (void)setShowTab:(NSNumber *)_showTab {
  ASSIGN(self->showTab,_showTab);
}
- (NSNumber *)showTab {
  if (self->showTab == nil) {
    NSUserDefaults *ud;
    NSDictionary   *settings;
    ud       = [[self session] userDefaults];
    settings = [ud objectForKey:[self udKey]];
    self->showTab = [settings objectForKey:@"showTab"];
    [self setShowTab:[NSNumber numberWithBool:[self->showTab boolValue]]];
  }
  return self->showTab;
}

- (NSArray *)listKeys {
  if (self->listKeys == nil) {
    NSUserDefaults *ud;
    NSDictionary   *settings;
    NSArray        *allKeys;
    NSMutableArray *wantedKeys;
    unsigned i, max;
    ud = [[self session] userDefaults];
    settings = [ud objectForKey:[self udKey]];
    allKeys  = [settings allKeys];
    max      = [allKeys count];
    wantedKeys = [NSMutableArray array];
    for (i = 0; i < max; i++) {
      id key  = [allKeys objectAtIndex:i];
      id flag = [[settings objectForKey:key] objectForKey:@"showTab"];
      if (![flag boolValue]) [wantedKeys addObject:key];
    }
    self->listKeys =
      [[wantedKeys sortedArrayUsingSelector:@selector(compare:)] retain];
  }
  return self->listKeys;
}

- (BOOL)hasSearchSelected {
  NSString *key;
  if ((key = [self searchTitle]) == nil) return NO;
  return [[self listKeys] containsObject:key];
}

- (BOOL)hidePopUp {
  return self->mustUpdateParent;
}

// syncing
- (BOOL)synchronizesVariablesWithBindings {
  return NO;
}

- (void)syncParentStateFromParent {
  [self setUdKey:           [self valueForBinding:@"userDefaultKey"]];
  [self setHasSearched:     [self valueForBinding:@"hasSearched"]];
  [self setMaxSearchCount:  [self valueForBinding:@"maxSearchCount"]];
  [self setQualifier:       [self valueForBinding:@"qualifier"]];
}
- (void)syncFromParent {
  [self syncParentStateFromParent];
  [self setRecommendedTitle:[self valueForBinding:@"recommendedTitle"]];
  [self setSearchTitle:     [self valueForBinding:@"searchTitle"]];
  self->mustUpdateParent =
    [[self valueForBinding:@"updateQualifier"] boolValue];
}

- (void)syncToParent {
  if ([self canSetValueForBinding:@"maxSearchCount"])
    [self setValue:[self maxSearchCount] forBinding:@"maxSearchCount"];
  if ([self canSetValueForBinding:@"qualifier"])
    [self setValue:[self qualifier] forBinding:@"qualifier"];
  if ([self canSetValueForBinding:@"searchTitle"])
    [self setValue:[self searchTitle] forBinding:@"searchTitle"];
}

- (BOOL)showSaveForm {
  // must not be forced update from parent component
  if (self->mustUpdateParent) return NO;
  // hasSearched must be YES
  if (![[self hasSearched] boolValue]) return NO;
  return YES;
}
- (BOOL)showLoadForm {
  return [[self listKeys] count] ? YES : NO;
}

- (void)rebuildQualifierAndMaxSearchCount {
  NSUserDefaults *ud;
  NSDictionary   *entry;
  NSArray        *ar;

  ud = [[self session] userDefaults];

  if (![[self searchTitle] length]) {
    [self setQualifier:nil];
    [self setMaxSearchCount:[ud objectForKey:@"LSMaxSearchCount"]];
    //NSLog(@"WARNING[%s] cannot rebuild qualifer", __PRETTY_FUNCTION__);
    return;
  }

  entry = [[ud objectForKey:[self udKey]] objectForKey:[self searchTitle]];

  ar = [entry objectForKey:@"qualifier"];
  [self setQualifier:[self buildQualifierWithArray:ar]];
  [self setMaxSearchCount:[entry objectForKey:@"maxSearchCount"]];
}

// action
- (id)loadSearch {
  [self rebuildQualifierAndMaxSearchCount];
  [self syncToParent];
  if ([self hasBinding:@"searchSelected"])
    return [self valueForBinding:@"searchSelected"];
  return nil;
}

- (id)removeSearch {
  NSString       *key;
  NSUserDefaults *ud;
  id             settings;
  if ([(key = [self searchTitle]) length] == 0) {
    NSLog(@"%s: failed removing saved search", __PRETTY_FUNCTION__);
    return nil;
  }
  ud = [[self session] userDefaults];
  settings = [ud objectForKey:[self udKey]];
  settings = [settings mutableCopy];
  
  [settings removeObjectForKey:key];
  [ud setObject:settings forKey:[self udKey]];

  [settings release]; settings = nil;
  [ud synchronize];
  [self->listKeys release]; self->listKeys = nil;
  return nil;
}

- (id)saveSearch {
  NSDictionary   *info;
  id             qual;
  NSUserDefaults *ud;
  id             settings;

  // old // qual = [self arrayForQualifier:[self qualifier]];
  // new
  qual = [[self qualifier] description];
  if (qual == nil) {
    NSLog(@"%s: got no qualifier", __PRETTY_FUNCTION__);
    return nil;
  }
  if ([[self saveTitle] length] == 0) {
    NSLog(@"%s: got no title", __PRETTY_FUNCTION__);
    return nil;
  }
  info = [NSDictionary dictionaryWithObjectsAndKeys:
                       qual,                  @"qualifier",
                       [self maxSearchCount], @"maxSearchCount",
                       [self showTab],        @"showTab",
                       nil];

  ud       = [[self session] userDefaults];
  settings = [ud objectForKey:[self udKey]];
  if (settings == nil) {
    settings = [NSDictionary dictionaryWithObjectsAndKeys:
                             info, [self saveTitle], nil];
  }
  else {
    settings = [[settings mutableCopy] autorelease];
    [settings setObject:info forKey:[self saveTitle]];
  }
  [ud setObject:settings forKey:[self udKey]];
  [ud synchronize];
  [self->listKeys release]; self->listKeys = nil;
  
  if ([self hasBinding:@"searchSaved"])
    return [self valueForBinding:@"searchSaved"];

  [self setSearchTitle:[self saveTitle]];
  return [self loadSearch];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx
{
  [self syncFromParent];
  if ([self showSaveForm]) {
    NSString *title;
    title = [self recommendedTitle];
    if ([title length]) {
      //NSLog(@"%s: taking recommended title: %@", __PRETTY_FUNCTION__, title);
      [self setSaveTitle:title];
    }
    // will show save form, reset title
    [self setSearchTitle:nil];
    [self setShowTab:[NSNumber numberWithBool:YES]];
  }
  [super appendToResponse:_response inContext:_ctx];
  if (mustUpdateParent) {
    [self rebuildQualifierAndMaxSearchCount];
    [self syncToParent];
  }
}

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx
{
  [self syncParentStateFromParent];
  [super takeValuesFromRequest:_req inContext:_ctx];
}

@end /* SkyCompanySavedSearchPopUp */

@implementation SkyCompanySavedSearchPopUp(PrivateMethodes)

- (NSArray *)arrayForAndQualifier:(EOAndQualifier *)_qual {
  unsigned       i, max;
  NSMutableArray *ma;
  NSArray        *quals;
  id             one;

  quals = [_qual qualifiers];
  max   = [quals count];
  ma = [NSMutableArray arrayWithCapacity:max + 1];
  [ma addObject:@"and"];
  for (i = 0; i < max; i++) {
    one = [self arrayForQualifier:[quals objectAtIndex:i]];
    if (!one) return nil;
    [ma addObject:one];
  }
  return ma;
}
- (NSArray *)arrayForOrQualifier:(EOOrQualifier *)_qual {
  unsigned       i, max;
  NSMutableArray *ma;
  NSArray        *quals;
  id             one;

  quals = [_qual qualifiers];
  max   = [quals count];
  ma = [NSMutableArray arrayWithCapacity:max + 1];
  [ma addObject:@"or"];
  for (i = 0; i < max; i++) {
    one = [self arrayForQualifier:[quals objectAtIndex:i]];
    if (!one) return nil;
    [ma addObject:one];
  }
  return ma;
}
- (NSArray *)arrayForNotQualifier:(EONotQualifier *)_qual {
  NSMutableArray *ma;
  EOQualifier    *qual;
  id             one;

  qual = [_qual qualifier];
  ma = [NSMutableArray arrayWithCapacity:2];
  [ma addObject:@"not"];
  one = [self arrayForQualifier:qual];
  if (!one) return nil;
  [ma addObject:one];
  return ma;
}
- (NSArray *)arrayForKeyValueQualifiers:(EOKeyValueQualifier *)_qual {
  NSMutableArray *ma;
  NSString       *key;
  id             value;
  NSString       *operator;
  NSString       *type = nil;

  key      = [_qual key];
  operator = NSStringFromSelector([_qual selector]);
  value    = [_qual value];
  if ([value isKindOfClass:[NSNumber class]]) {
    value = [value stringValue];
    type  = @"number";
  }
  else if ([value isKindOfClass:[NSCalendarDate class]]) {
    type = @"date";
    value = [value descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S %z"];
  }
  else if ([value isKindOfClass:[EOKeyGlobalID class]]) {
    type = @"gid";
    value = [NSString stringWithFormat:@"%@:%@",
                      [value keyValues][0], [value entityName]];
  }

  ma = [NSMutableArray arrayWithCapacity:5];
  [ma addObject:@"kv"];
  [ma addObject:key];
  [ma addObject:operator];
  [ma addObject:value];
  if (type != nil) [ma addObject:type];
  return ma;
}

- (NSArray *)arrayForQualifier:(EOQualifier *)_qual {
  if (_qual == nil) return nil;
  if ([_qual isKindOfClass:[EOAndQualifier class]])
    return [self arrayForAndQualifier:(EOAndQualifier *)_qual];
  else if ([_qual isKindOfClass:[EOOrQualifier class]])
    return [self arrayForOrQualifier:(EOOrQualifier *)_qual];
  else if ([_qual isKindOfClass:[EONotQualifier class]])
    return [self arrayForNotQualifier:(EONotQualifier *)_qual];
  else if ([_qual isKindOfClass:[EOKeyValueQualifier class]])
    return [self arrayForKeyValueQualifiers:(EOKeyValueQualifier *)_qual];
  NSLog(@"WARNING[%s]: cannot handle qualifier class %@",
        __PRETTY_FUNCTION__, NSStringFromClass([_qual class]));
  return nil;
}


- (EOQualifier *)buildAndQualifierWithArray:(NSArray *)_array {
  NSMutableArray *ma;
  EOQualifier    *qual;
  unsigned i, max;

  max = [_array count];
  if (max < 2) {
    NSLog(@"WARNING[%s]: cannot build and-qualifier",
          __PRETTY_FUNCTION__);
    return nil;
  }
  ma = [NSMutableArray arrayWithCapacity:max-1];
  for (i = 1; i < max; i++) {
    qual = [self buildQualifierWithArray:[_array objectAtIndex:i]];
    if (qual == nil) return nil;
    [ma addObject:qual];
  }

  return [[[EOAndQualifier alloc] initWithQualifierArray:ma] autorelease];
}

- (EOQualifier *)buildOrQualifierWithArray:(NSArray *)_array {
  NSMutableArray *ma;
  EOQualifier    *qual;
  unsigned i, max;

  max = [_array count];
  if (max < 2) {
    NSLog(@"WARNING[%s]: cannot build or-qualifier",
          __PRETTY_FUNCTION__);
    return nil;
  }
  ma = [NSMutableArray arrayWithCapacity:max-1];
  for (i = 1; i < max; i++) {
    qual = [self buildQualifierWithArray:[_array objectAtIndex:i]];
    if (qual == nil) return nil;
    [ma addObject:qual];
  }

  return [[[EOOrQualifier alloc] initWithQualifierArray:ma] autorelease];
}

- (EOQualifier *)buildNotQualifierWithArray:(NSArray *)_array {
  EOQualifier    *qual;
  unsigned max;

  max = [_array count];
  if (max < 2) {
    NSLog(@"WARNING[%s]: cannot build not-qualifier",
          __PRETTY_FUNCTION__);
    return nil;
  }
  qual = [self buildQualifierWithArray:[_array objectAtIndex:1]];
  if (qual == nil) return nil;

  return [[[EONotQualifier alloc] initWithQualifier:qual] autorelease];
}

- (EOQualifier *)buildKeyValueQualifierWithArray:(NSArray *)_array {
  NSString       *key;
  id             value;
  SEL            operator;
  unsigned max;

  max = [_array count];
  if (max < 4) {
    [self logWithFormat:@"WARNING[%s]: cannot build key-value-qualifier",
          __PRETTY_FUNCTION__];
    return nil;
  }

  key      = [_array objectAtIndex:1];
  operator = NSSelectorFromString([_array objectAtIndex:2]);
  value    = [_array objectAtIndex:3];
  if (max > 4) {
    NSString *type;
    
    type = [_array objectAtIndex:4];
    if ([type isEqualToString:@"date"]) {
      value = [NSCalendarDate dateWithString:value
                              calendarFormat:@"%Y-%m-%d %H:%M:%S %z"];
    }
    else if ([type isEqualToString:@"number"]) {
      value = [NSNumber numberWithFloat:[value floatValue]];
    }
    else if ([type isEqualToString:@"string"]) {
      value = [value stringValue];
    }
    else if ([type isEqualToString:@"gid"]) {
      NSRange r;
      id  pkey;
      
      r = [value rangeOfString:@":"];
      if (r.length > 0) {
        pkey  = [value substringToIndex:r.location];
        pkey  = [NSNumber numberWithInt:[pkey intValue]];
        value = [EOKeyGlobalID globalIDWithEntityName:
				 [value substringFromIndex:
					  (r.location + r.length)]
                               keys:&pkey keyCount:1 zone:NULL];
      }
    }
    else {
      [self logWithFormat:
	      @"WARNING[%s]: unknown qualifier value-type:%@ is:[%@]",
              __PRETTY_FUNCTION__, type, NSStringFromClass([value class])];
    }
  }

  return [[[EOKeyValueQualifier alloc] initWithKey:key
                                       operatorSelector:operator
                                       value:value] autorelease];
}

- (EOQualifier *)buildQualifierWithArray:(id)_array {
  NSString *type;

  if ([_array isKindOfClass:[NSString class]]) {
    return [[[EOQualifier alloc] initWithString:_array] autorelease];
  }
  
  if ([_array count] == 0) {
    NSLog(@"WARNING[%s]: cannot build qualifier from empty array",
          __PRETTY_FUNCTION__);
    return nil;
  }

  type = [_array objectAtIndex:0];
  if ([type isEqualToString:@"and"]) 
    return [self buildAndQualifierWithArray:_array];
  else if ([type isEqualToString:@"or"])
    return [self buildOrQualifierWithArray:_array];
  else if ([type isEqualToString:@"not"])
    return [self buildNotQualifierWithArray:_array];
  else if ([type isEqualToString:@"kv"])
    return [self buildKeyValueQualifierWithArray:_array];
  NSLog(@"WARNING[%s]: unknown qualifier type: %@",
        __PRETTY_FUNCTION__, type);
  return nil;
}


@end /* SkyCompanySavedSearchPopUp(PrivateMethodes) */
