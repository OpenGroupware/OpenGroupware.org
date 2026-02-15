/*
  Copyright (C) 2006 Helge Hess

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

#include "OGoListComponent.h"
#include "WOComponent+Navigation.h"
#include "common.h"

/**
 * Returns YES if the string contains a dot that is NOT
 * the last character (i.e. it is a real key-path like
 * `addr01.street`). A trailing dot (e.g. `P-Nr.`) is
 * just part of the key name and not a key-path separator.
 */
static BOOL isKeyPath(NSString *s) {
  NSUInteger len = [s length];
  if (len == 0) return NO;
  NSRange r = [s rangeOfString:@"."];
  if (r.length == 0) return NO;
  /* trailing dot is not a key path */
  return (r.location + r.length) < len;
}

static BOOL didWarnTrailingDot = NO;

static void warnTrailingDot(NSString *key) {
  if (didWarnTrailingDot) return;
  didWarnTrailingDot = YES;
  NSLog(@"OGoListComponent: column key '%@' has a "
        @"trailing dot, using valueForKey:.", key);
}

@implementation OGoListComponent

+ (int)version {
  return [super version] + 2 /* v4 */;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (void)dealloc {
  [self->currentColumn release];
  [self->dataSource    release];
  [self->item          release];
  [self->favoritesKey  release];
  [self->favoriteIds   release];
  [self->configList    release];
  [self->configKey     release];
  [self->configOptList release];
  [self->currentColumnOpt release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self->item          release]; self->item          = nil;
  [self->favoriteIds   release]; self->favoriteIds   = nil;
  [self->configList    release]; self->configList    = nil;
  [self->currentColumn release]; self->currentColumn = nil;
  [self->currentColumnOpt release]; self->currentColumnOpt = nil;
  [super sleep];
}

/* accessors */

- (void)setDataSource:(EODataSource *)_dataSource {
  ASSIGN(self->dataSource, _dataSource);
}
- (EODataSource *)dataSource {
  return self->dataSource;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (NSString *)itemIdString {
  [self errorWithFormat:@"%s: subclass must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

- (void)setIsInConfigMode:(BOOL)_flag {
  self->isInConfigMode = _flag;
}
- (BOOL)isInConfigMode {
  return self->isInConfigMode;
}

/* custom columns */

- (void)setCurrentColumnIndex:(int)_idx {
  self->currentColumnIdx = _idx;
}
- (int)currentColumnIndex {
  return self->currentColumnIdx;
}

- (int)columnLabelIndex {
  /* we start at 0 and the first column is not configurable */
  return [self currentColumnIndex] + 2;
}

- (void)setCurrentColumn:(NSString *)_s {
  ASSIGNCOPY(self->currentColumn, _s);
}
- (NSString *)currentColumn {
  return self->currentColumn;
}
- (NSString *)currentSortKey {
  NSString *s = [self currentColumn];
  return (s == nil || isKeyPath(s)) ? nil : (id)s;
}

- (void)setCurrentColumnOpt:(NSString *)_s {
  ASSIGNCOPY(self->currentColumnOpt, _s);
}
- (NSString *)currentColumnOpt {
  return self->currentColumnOpt;
}
- (NSString *)currentColumnOptLabel {
  return [[self labels] valueForKey:[self currentColumnOpt]];
}

- (NSString *)currentColumnCheckerName {
  return [NSString stringWithFormat:@"cb%i", [self currentColumnIndex]];
}
- (BOOL)isCurrentColumnOptActive {
  return [[self currentColumn] isEqualToString:[self currentColumnOpt]];
}

- (NSString *)currentColumnLabel {
  return [[self labels] valueForKey:[self currentColumn]];
}

- (id)currentColumnValue {
  NSString *kp = [self currentColumn];
  id v;

  if (isKeyPath(kp))
    v = [[self item] valueForKeyPath:kp];
  else {
    if ([kp hasSuffix:@"."])
      warnTrailingDot(kp);
    v = [[self item] valueForKey:kp];
  }

  if (![[self columnType] isEqualToString:@"plain"])
    return v;

  if ([v isKindOfClass:[NSDate class]]) /* birthday */
    return [v descriptionWithCalendarFormat:@"%Y-%m-%d"];

  if (isKeyPath(kp)) /* addresses */
    return v;
  if ([kp rangeOfString:@"name"].length > 0)
    return v;

  /* attempt to localize everything else ... */
  if ([v isKindOfClass:[NSString class]])
    return [[self labels] valueForKey:v];

  return v;
}

- (NSString *)columnTypeForKey:(NSString *)s {
  if ([s hasPrefix:@"email"]) return @"email";
  if ([s hasSuffix:@"tel"])   return @"phone";
  if ([s hasSuffix:@"fax"])   return @"phone"; // TODO: hm, do we want that?
  if ([s hasSuffix:@"url"])   return @"url";
  if ([s rangeOfString:@"_tel_"].length > 0) return @"phone";
  if ([s rangeOfString:@"_fax_"].length > 0) return @"phone";
  return @"plain";
}
- (NSString *)columnType {
  return [self columnTypeForKey:[self currentColumn]];
}

- (NSString *)columnOptItemGroup {
  NSString *s = [self currentColumnOpt];

  s = isKeyPath(s)
    ? (NSString *)@"address"
    : [self columnTypeForKey:s];
  s = [@"listcoltype_" stringByAppendingString:s];
  return [[self labels] valueForKey:s];
}

- (NSDictionary *)mailColumnDict {
  return [NSDictionary dictionaryWithObjectsAndKeys:
			 [self currentColumn], @"key",
		         @"3", @"type", /* email */
		       nil];
}

/* actions */

- (id)viewItem {
  return [self activateObject:[self item] withVerb:@"view"];
}

/* list configuration */

- (NSString *)defaultConfigKey {
  return nil; /* override in subclasses */
}
- (void)setConfigKey:(NSString *)_s {
  ASSIGNCOPY(self->configKey, _s);
}
- (NSString *)configKey {
  return [self->configKey isNotEmpty] 
    ? self->configKey : [self defaultConfigKey];
}

- (NSUserDefaults *)userDefaults {
  return [[self session] userDefaults];
}

- (NSArray *)configList {
  if (self->configList == nil) {
    NSArray *t;
    
    t = [[self userDefaults] arrayForKey:[self configKey]];
    if (![t isNotEmpty])
      t = [[self userDefaults] arrayForKey:[self defaultConfigKey]];
    
    self->configList = [t copy];
  }
  return self->configList;
}

- (NSArray *)configOptList {
  if (self->configOptList == nil) {
    NSString *opt = [[self defaultConfigKey] stringByAppendingString:@"_opts"];
    self->configOptList = [[[self userDefaults] arrayForKey:opt] copy];
  }
  return self->configOptList;
}

- (void)setCurrentColumnSelection:(NSString *)_newValue {
  NSMutableArray *ma;
  
  if (![_newValue isNotEmpty])
    return;
  if ([_newValue isEqualToString:[self currentColumn]])
    return; /* didn't change */
  
  /* changed */
  ma = [[self configList] mutableCopy];
  [ma replaceObjectAtIndex:[self currentColumnIndex] withObject:_newValue];
  [self->configList release]; self->configList = nil;
  self->configList = [ma copy];
  [ma release]; ma = nil;
}
- (NSString *)currentColumnSelection {
  return [self currentColumn];
}


/* config actions */

- (id)leaveConfigMode {
  [self setIsInConfigMode:NO];
  return nil; /* stay on page */
}

- (id)applyConfig {
  [[self userDefaults] setObject:[self configList] forKey:[self configKey]];
  [[self userDefaults] synchronize];
  [self setIsInConfigMode:NO]; /* we leave the config on apply */
  return nil; /* stay on page */
}

- (id)addColumn {
  NSArray *cfglist;
  
  cfglist = [self configOptList];
  cfglist = [[self configList] arrayByAddingObject:[cfglist objectAtIndex:0]];
  [[self userDefaults] setObject:cfglist forKey:[self configKey]];
  [[self userDefaults] synchronize];
  [self->configList release]; self->configList = nil;
  
  return nil; /* stay on page */
}

- (id)removeColumn {
  NSMutableArray *cfglist;
  
  cfglist = [[self configList] mutableCopy];
  [self->configList release]; self->configList = nil;
  
  if ([cfglist count] > 0)
    [cfglist removeObjectAtIndex:([cfglist count] - 1)];
  
  self->configList = [cfglist copy];
  [cfglist release]; cfglist = nil;
  
  [[self userDefaults] setObject:self->configList forKey:[self configKey]];
  [[self userDefaults] synchronize];
  
  return nil; /* stay on page */
}


/* favorites */

- (NSString *)defaultFavoritesKey {
  return nil; /* override in subclasses */
}
- (void)setFavoritesKey:(NSString *)_key {
  ASSIGN(self->favoritesKey, _key);
}
- (NSString *)favoritesKey {
  return [self->favoritesKey isNotEmpty] 
    ? self->favoritesKey : [self defaultFavoritesKey];
}

- (NSArray *)favoriteIds {
  if (self->favoriteIds == nil) {
    self->favoriteIds =
      [[[[self session] userDefaults] arrayForKey:[self favoritesKey]] copy];
  }
  return self->favoriteIds;
}

- (BOOL)isInFavorites {
  return [[self favoriteIds] containsObject:[self itemIdString]];
}

- (BOOL)_modifyFavorites:(BOOL)_doRemove {
  NSMutableArray *favIds;
  NSUserDefaults *ud;

  if (_doRemove && ![self isInFavorites])
    return NO; /* not in favorites */
  if (!_doRemove && [self isInFavorites])
    return NO; /* already in favorites */
  
  favIds = [[self favoriteIds] mutableCopy];
    
  if (_doRemove)
    [favIds removeObject:[self itemIdString]];
  else {
    if (favIds == nil)
      favIds = [[NSMutableArray alloc] initWithCapacity:2];
    [favIds addObject:[self itemIdString]];
  }

  ud = [[self session] userDefaults];
  [ud setObject:favIds forKey:[self favoritesKey]];
  [ud synchronize];
  
  [self->favoriteIds release]; self->favoriteIds = nil;
  [favIds release]; favIds = nil;
  return YES;
}

/* favorite actions */

- (id)updateFavoritesAction {
  if ([self hasBinding:@"onFavoritesChange"])
    return [self valueForBinding:@"onFavoritesChange"];
  return nil /* stay on page */;
}

- (id)addToFavorites {
  [self _modifyFavorites:NO /* NO means "add favorite" */];
  return [self updateFavoritesAction];
}
- (id)removeFromFavorites {
  [self _modifyFavorites:YES /* YES means "remove favorite" */];
  return [self updateFavoritesAction]; 
}

@end /* OGoListComponent */
