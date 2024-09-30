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

#include "SkyPalmEntryListState.h"
#import <Foundation/Foundation.h>
#import <EOControl/EOControl.h>
#include <NGExtensions/NGBundleManager.h>

@interface NSUserDefaults(EntryListStateMethods)
- (void)syncronize;
@end

@interface SkyPalmEntryListState(PrivatMethods)
- (id)initWithDefaults:(NSUserDefaults *)_ud
             companyId:(NSNumber *)_comp
                subKey:(NSString *)_subKey;
- (EOQualifier *)qualifier;
- (EOFetchSpecification *)fetchSpecification;
@end

@interface SkyPalmJobListState : SkyPalmEntryListState
{}
@end
@interface SkyPalmAddressListState : SkyPalmEntryListState
{}
@end

@interface SkyPalmDateListState : SkyPalmEntryListState
{
  NSCalendarDate *startdate;
  NSCalendarDate *enddate;
  NSArray        *palmIds;
}
@end

@interface SkyPalmMemoListState : SkyPalmEntryListState
{}
@end

static NSString *BlockSize             = @"BlockSize";
static NSString *SortOrder             = @"SortOrder";
static NSString *SortKey               = @"SortKey";
static NSString *Attributes            = @"Attributes";
static NSString *HideDeleted           = @"HideDeleted";
static NSString *AutoscrollSize        = @"AutoscrollSize";
static NSString *SelectedCategory      = @"SelectedCategory";
static NSString *SelectedDevice        = @"SelectedDevice";

@implementation SkyPalmEntryListState

+ (SkyPalmEntryListState *)listStateWithDefaults:(NSUserDefaults *)_ud
                                       companyId:(NSNumber *)_comp
                                          subKey:(NSString *)_subKey
                                       forPalmDb:(NSString *)_palmDb
{
  id state;
  if ([_palmDb isEqualToString:@"AddressDB"])
    state = [SkyPalmAddressListState alloc];
  else if ([_palmDb isEqualToString:@"DatebookDB"])
    state = [SkyPalmDateListState alloc];
  else if ([_palmDb isEqualToString:@"MemoDB"])
    state = [SkyPalmMemoListState alloc];
  else if ([_palmDb isEqualToString:@"ToDoDB"])
    state = [SkyPalmJobListState alloc];
  else {
    NGBundleManager *bm;
    EOQualifier     *q;
    NSBundle        *bundle;

    bm = [NGBundleManager defaultBundleManager];
    q  = [EOQualifier qualifierWithQualifierFormat:
                      @"palmDb=%@", _palmDb];
    bundle = [bm bundleProvidingResourceOfType:@"SkyPalmEntryLists"
                 matchingQualifier:q];
    if (bundle != nil) {
      if (![bundle load]) {
        NSLog(@"%s: failed to load bundle: %@", __PRETTY_FUNCTION__, bundle);
        return nil;
      }
      {
        id resources, resource, cname;
        resources = [bundle providedResourcesOfType:@"SkyPalmEntryLists"];
        resources = [resources filteredArrayUsingQualifier:q];
        resource  = [resources lastObject];

        cname = [resource valueForKey:@"entryListState"];
        if ([cname length])
          state = [NGClassFromString(cname) alloc];
        else {
          NSLog(@"%s invalid class for palmDb: %@",
                __PRETTY_FUNCTION__, _palmDb);
          return nil;
        }
      }
    }
    else {
      NSLog(@"%s didn't find entryListState for palmDb: %@",
            __PRETTY_FUNCTION__, _palmDb);
      return nil;
    }
  }
  
  state = [state initWithDefaults:_ud companyId:_comp subKey:_subKey];
  return AUTORELEASE(state);
}

- (id)initWithDefaults:(NSUserDefaults *)_ud
             companyId:(NSNumber *)_comp
                subKey:(NSString *)_subKey
{
  if ((self = [super init])) {
    NSAssert((_ud != nil), @"SkyPalmEntryListState: userDefaults are <nil>");
    ASSIGN(self->defaults,_ud);
    ASSIGN(self->companyId,_comp);
    ASSIGN(self->subKey,_subKey);
    self->currentBatch = 1;
    self->fetchSpec    = nil;
  }
  return self;
}

- (id)initWithDefaults:(NSUserDefaults *)_ud
             companyId:(NSNumber *)_comp {
  return [self initWithDefaults:_ud companyId:_comp subKey:@""];
}

- (id)init {
  NSAssert(NO, @"Don't initalize ListState this way!");
  RELEASE(self);
  return nil;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->subKey);
  RELEASE(self->defaults);
  RELEASE(self->companyId);
  RELEASE(self->fetchSpec);
  [super dealloc];
}
#endif

// keys

- (NSString *)_userDefaultsKeyForKey:(NSString *)_key {
  return [NSString stringWithFormat:@"SkyPalm%@List_%@_%@",
                   [self listKey], self->subKey, _key];
}
- (NSString *)_batchSizeKey {
  return [self _userDefaultsKeyForKey:BlockSize];
}
- (NSString *)_sortOrderKey {
  return [self _userDefaultsKeyForKey:SortOrder];
}
- (NSString *)_sortedKeyKey {
  return [self _userDefaultsKeyForKey:SortKey];
}
- (NSString *)_attributesKey {
  return [self _userDefaultsKeyForKey:Attributes];
}
- (NSString *)_hideDeletedKey {
  return [self _userDefaultsKeyForKey:HideDeleted];
}
- (NSString *)_autoscrollSizeKey {
  return [self _userDefaultsKeyForKey:AutoscrollSize];
}
- (NSString *)_selectedCategoryKey {
  return [self _userDefaultsKeyForKey:SelectedCategory];
}
- (NSString *)_selectedDeviceKey {
  return [self _userDefaultsKeyForKey:SelectedDevice];
}

// values

- (void)setCurrentBatch:(unsigned)_currentBatch {
  self->currentBatch = _currentBatch;
}
- (unsigned)currentBatch {
  return self->currentBatch;
}

- (void)setIsDescending:(BOOL)_flag {
  if ([self isDescending] != _flag) {
    [self->defaults setBool:_flag forKey:[self _sortOrderKey]];
    RELEASE(self->fetchSpec);  self->fetchSpec = nil;
  }
}
- (BOOL)isDescending {
  NSString *key = nil;
  key = [self _sortOrderKey];
  if ([self->defaults objectForKey:key] == nil) {
    [self->defaults setBool:NO forKey:key];
    return NO;
  }
  return [self->defaults boolForKey:key];
}

- (int)batchSize {
  NSString *key = nil;
  id       obj;
  key = [self _batchSizeKey];
  if ((obj = [self->defaults objectForKey:key]) == nil) {
    [self->defaults setObject:[NSNumber numberWithInt:150] forKey:key];
    return 150;
  }
  return [obj intValue];
}
- (void)setEditBatchSize:(int)_batchSize {
  [self->defaults setObject:[NSNumber numberWithInt:_batchSize]
       forKey:[self _batchSizeKey]];
}
- (int)editBatchSize {
  return [self batchSize];
}

- (void)setSortedKey:(NSString *)_sortedKey {
  if (![[self sortedKey] isEqualToString:_sortedKey]) {
    [self->defaults setObject:_sortedKey forKey:[self _sortedKeyKey]];
    RELEASE(self->fetchSpec);  self->fetchSpec = nil;
  }
}
- (NSString *)sortedKey {
  NSString *key = nil;
  key = [self _sortedKeyKey];
  if ([self->defaults objectForKey:key] == nil) {
    [self->defaults setObject:[self defaultSortKey] forKey:key];
    return [self defaultSortKey];
  }
  return [self->defaults stringForKey:key];
}

- (void)setAttributes:(NSArray *)_attributes {
  [self->defaults setObject:_attributes forKey:[self _attributesKey]];
}
- (NSArray *)attributes {
  NSString *key   = nil;
  NSArray  *attrs = nil;
  
  key = [self _attributesKey];
  if ((attrs = [self->defaults objectForKey:key]) == nil) {
    [self->defaults setObject:[self defaultAttributes] forKey:key];
  }
  return attrs;
}

- (void)setHideDeleted:(BOOL)_hide {
  if ([self hideDeleted] != _hide) {
    [self->defaults setBool:_hide forKey:[self _hideDeletedKey]];
    RELEASE(self->fetchSpec);   self->fetchSpec = nil;
  }
}
- (BOOL)hideDeleted {
  NSString *key = nil;
  key = [self _hideDeletedKey];
  if ([self->defaults objectForKey:key] == nil) {
    [self->defaults setBool:NO forKey:key];
    return NO;
  }
  return [self->defaults boolForKey:key];
}

- (int)autoscrollSize {
  NSString *key = nil;
  id       obj;
  key = [self _autoscrollSizeKey];
  if ((obj = [self->defaults objectForKey:key]) == nil) {
    [self->defaults setObject:[NSNumber numberWithInt:0] forKey:key];
    return 0;
  }
  return [obj intValue];
}
- (void)setEditAutoscrollSize:(int)_scrollSize {
  [self->defaults setObject:[NSNumber numberWithInt:_scrollSize]
       forKey:[self _autoscrollSizeKey]];
}
- (int)editAutoScrollSize {
  return [self autoscrollSize];
}

// 0 - 15 the category_index
// -1 means all
- (void)setSelectedCategory:(int)_selectedCategory {
  if ([self selectedCategory] != _selectedCategory) {
    [self->defaults setObject:[NSNumber numberWithInt:_selectedCategory]
         forKey:[self _selectedCategoryKey]];
    RELEASE(self->fetchSpec); self->fetchSpec = nil;
  }
}
- (int)selectedCategory {
  NSString *key = nil;
  NSNumber *obj = nil;
  key = [self _selectedCategoryKey];
  if ((obj = [self->defaults objectForKey:key]) == nil) {
    [self->defaults setObject:[NSNumber numberWithInt:-1] forKey:key];
    return -1;
  }
  return [obj intValue];
}

// nil or ""  means all
- (void)setSelectedDevice:(NSString *)_selectedDevice {
  if (_selectedDevice == nil) _selectedDevice = @"";
  if ([self selectedDevice] != _selectedDevice) {
    [self->defaults setObject:_selectedDevice
         forKey:[self _selectedDeviceKey]];
    RELEASE(self->fetchSpec); self->fetchSpec = nil;
  }
}
- (NSString *)selectedDevice {
  NSString *key = nil;
  key = [self _selectedDeviceKey];
  if ([self->defaults objectForKey:key] == nil) {
    [self->defaults setObject:@"" forKey:key];
    return @"";
  }
  return [self->defaults stringForKey:key];
}

- (void)synchronize {
  [self->defaults synchronize];
}

// fetchSpecification
- (EOQualifier *)flagQualifier {
  if (![self hideDeleted])
    return nil;
  return [EOQualifier qualifierWithQualifierFormat:
                      @"is_deleted=0 AND is_archived=0"];
}
- (EOQualifier *)deviceQualifier {
  NSString *dev = [self selectedDevice];
  if (![dev length])
    return nil;
  return [EOQualifier qualifierWithQualifierFormat:@"device_id=%@", dev];
}
- (EOQualifier *)categoryQualifier {
  int index = [self selectedCategory];
  if (index == -1)
    return nil;
  return [EOQualifier qualifierWithQualifierFormat:
                      @"category_index=%@", [NSNumber numberWithInt:index]];
}
- (EOQualifier *)companyQualifier {
  return [EOQualifier qualifierWithQualifierFormat:@"company_id=%@",
                      self->companyId];
}
- (EOQualifier *)qualifier {
  EOQualifier    *one = nil;
  NSMutableArray *all = [NSMutableArray array];

  [all addObject:[self companyQualifier]];
  if ((one = [self flagQualifier]))
    [all addObject:one];
  if ((one = [self categoryQualifier]))
    [all addObject:one];
  if ((one = [self deviceQualifier]))
    [all addObject:one];

  one = [[EOAndQualifier alloc] initWithQualifierArray:all];
  return AUTORELEASE(one);
}

- (EOFetchSpecification *)fetchSpecification {
  EOFetchSpecification *fs;
  SEL                  sel;
  NSArray              *so;

  if (self->fetchSpec != nil)
    return self->fetchSpec;

  sel = ([self isDescending])
    ? EOCompareDescending
    : EOCompareAscending;
  so  = [NSArray arrayWithObject:
                 [EOSortOrdering sortOrderingWithKey:[self sortedKey]
                                 selector:sel]];

  fs = [EOFetchSpecification fetchSpecificationWithEntityName:
                             [self entityName]
                             qualifier:[self qualifier]
                             sortOrderings:so];
  {
    id hints = [fs hints];
    id hide  = [NSNumber numberWithBool:([self hideDeleted]) ? YES : NO];
    id fetchSky = [NSNumber numberWithBool:YES];
    if (hints == nil)
      hints =
        [NSDictionary dictionaryWithObjectsAndKeys:
                      hide,     @"hideDeleted",
                      fetchSky, @"fetchSkyrixRecords",
                      nil];
    else {
      hints = [[hints mutableCopy] autorelease];
      [hints setObject:hide forKey:@"hideDeleted"];
      [hints setObject:fetchSky forKey:@"fetchSkyrixRecords"];
    }
    [fs setHints:hints];
  }
  ASSIGN(self->fetchSpec,fs);
  return self->fetchSpec;
}

- (NSString *)entityName {
  NSLog(@"entityName NOT overwriten! this won't work!");
  return nil;
}
- (NSArray *)defaultAttributes {
  NSLog(@"defaultAttributes NOT overwriten! this won't work!");
  return nil;
}
- (NSArray *)allAttributes {
  NSLog(@"allAttributes NOT overwriten! this won't work!");
  return nil;
}
- (NSString *)listKey {
  NSLog(@"listKey NOT overwriten! this won't work!");
  return nil;
}
- (NSString *)defaultSortKey {
  NSLog(@"defaultSortKey NOT overwriten! this won't work!");
  return nil;
}
- (NSString *)palmDb {
  NSLog(@"palmDb NOT overwriten! this won't work!");
  return nil;
}

@end /* SkyPalmEntryListState */

@implementation SkyPalmJobListState
- (NSString *)entityName {
  return @"palm_todo";
}
- (NSArray *)allAttributes {
  return [NSArray arrayWithObjects:
                  @"attribute_jobStatus",
                  @"attribute_description",
                  @"attribute_duedate",
                  @"attribute_categoryName",
                  @"attribute_priority",
                  @"attribute_deviceId",
                  @"attribute_palmSync",
                  @"attribute_skyrixRecord",
                  @"attribute_skyrixSync",
                  nil];
}
- (NSArray *)defaultAttributes {
  return [NSArray arrayWithObjects:
                  @"attribute_priority",
                  @"attribute_description",
                  @"attribute_duedate",
                  @"attribute_jobStatus",
                  @"attribute_skyrixRecord",
                  @"attribute_skyrixSync",
                  @"attribute_palmSync",
                  nil];
}
- (NSString *)listKey {
  return @"Job";
}
- (NSString *)defaultSortKey {
  return @"isCompleted";
}
- (NSString *)palmDb {
  return @"ToDoDB";
}
@end /* SkyPalmJobListState */

@implementation SkyPalmAddressListState
- (NSString *)entityName {
  return @"palm_address";
}
- (NSArray *)allAttributes {
  return [NSArray arrayWithObjects:
                  @"attribute_description",
                  @"attribute_firstname",
                  @"attribute_lastname",
                  @"attribute_company",
                  @"attribute_main",
                  @"attribute_work",
                  @"attribute_mobile",
                  @"attribute_email",
                  @"attribute_deviceId",
                  @"attribute_palmSync",
                  @"attribute_categoryName",
                  @"attribute_skyrixRecord",
                  @"attribute_skyrixSync", nil];
}
- (NSArray *)defaultAttributes {
  return [NSArray arrayWithObjects:
                  @"attribute_description",
                  @"attribute_main",
                  @"attribute_categoryName",
                  @"attribute_skyrixRecord",
                  @"attribute_skyrixSync",
                  @"attribute_palmSync", nil];
}
- (NSString *)listKey {
  return @"Address";
}
- (NSString *)defaultSortKey {
  return @"lastname";
}
- (NSString *)palmDb {
  return @"AddressDB";
}
@end /* SkyPalmAddressListState */

@implementation SkyPalmDateListState

- (id)init {
  if ((self = [super init])) {
    self->startdate = nil;
    self->enddate   = nil;
    self->palmIds   = nil;
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->startdate);
  RELEASE(self->enddate);
  RELEASE(self->palmIds);
  [super dealloc];
}

// accessors
- (void)setStartdate:(NSCalendarDate *)_date {
  ASSIGN(self->startdate,_date);
}
- (NSCalendarDate *)startdate {
  return self->startdate;
}
- (void)setEnddate:(NSCalendarDate *)_date {
  ASSIGN(self->enddate,_date);
}
- (NSCalendarDate *)enddate {
  return self->enddate;
}
- (void)setPalmIds:(NSArray *)_pIds {
  ASSIGN(self->palmIds,_pIds);
}
- (NSArray *)palmIds {
  return self->palmIds;
}

- (BOOL)fetchRepeatings {
  return ((self->startdate != nil) && (self->enddate != nil))
    ? YES : NO;
}

- (EOQualifier *)palmIdQualifier {
  if ((self->palmIds == nil) || ([self->palmIds count] == 0))
    return nil;
  return [EOQualifier qualifierWithQualifierFormat:
                      [NSString stringWithFormat:@"palm_id=%@",
                                [self->palmIds componentsJoinedByString:
                                     @"OR palm_id="]]];
}

- (EOQualifier *)dateQualifier {
  if ((self->startdate == nil) || (self->enddate == nil))
    return nil;
  return [EOQualifier qualifierWithQualifierFormat:
                      @"(startdate<%@ AND enddate>%@) "
                      @"OR ( NOT (repeat_type=0))",
                      self->enddate, self->startdate];
}

// overwriting
- (EOQualifier *)qualifier {
  EOQualifier    *qual     = nil;
  NSMutableArray *allQuals = [NSMutableArray array];

  [allQuals addObject:[super qualifier]];
  if ((qual = [self palmIdQualifier]))
    [allQuals addObject:qual];
  if ((qual = [self dateQualifier]))
    [allQuals addObject:qual];

  qual = [[EOAndQualifier alloc] initWithQualifierArray:allQuals];
  return AUTORELEASE(qual);
}

- (EOFetchSpecification *)fetchSpecification {
  EOFetchSpecification *fs = [super fetchSpecification];
  if ([self fetchRepeatings]) {
    id hints = [fs hints];
    if (hints == nil)
      hints =
        [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithBool:YES], @"fetchRepeatings",
                      self->startdate,               @"startdate",
                      self->enddate,                 @"enddate",
                      nil];
    else {
      hints = [hints mutableCopy];
      [hints setObject:[NSNumber numberWithBool:YES]
             forKey:@"fetchRepeatings"];
      [hints setObject:self->startdate forKey:@"startdate"];
      [hints setObject:self->enddate   forKey:@"enddate"];
      AUTORELEASE(hints);
    }
    [fs setHints:hints];
  }
  return fs;
}

- (NSString *)entityName {
  return @"palm_date";
}
- (NSArray *)allAttributes {
  return [NSArray arrayWithObjects:
                  @"attribute_startdate",
                  @"attribute_enddate",
                  @"attribute_date",
                  @"attribute_description",
                  @"attribute_repeat",
                  @"attribute_deviceId",
                  @"attribute_palmSync",
                  @"attribute_skyrixRecord",
                  @"attribute_skyrixSync",
                  nil];
}
- (NSArray *)defaultAttributes {
  return [NSArray arrayWithObjects:
                  @"attribute_date",
                  @"attribute_description",
                  @"attribute_repeat",
                  @"attribute_skyrixRecord",
                  @"attribute_skyrixSync",
                  @"attribute_palmSync",
                  nil];
}
- (NSString *)listKey {
  return @"Date";
}
- (NSString *)defaultSortKey {
  return @"startdate";
}
- (NSString *)palmDb {
  return @"DatebookDB";
}
@end /* SkyPalmDateListState */

@implementation SkyPalmMemoListState
- (NSString *)entityName {
  return @"palm_memo";
}
- (NSArray *)allAttributes {
  return [NSArray arrayWithObjects:
                  @"attribute_memo",
                  @"attribute_categoryName",
                  @"attribute_deviceId",
                  @"attribute_palmSync",
                  @"attribute_skyrixRecord",
                  @"attribute_skyrixSync",
                  nil];
}
- (NSArray *)defaultAttributes {
  return [NSArray arrayWithObjects:
                  @"attribute_memo",
                  @"attribute_categoryName",
                  @"attribute_skyrixRecord",
                  @"attribute_skyrixSync",
                  @"attribute_palmSync",
                  nil];
}
- (NSString *)listKey {
  return @"Memo";
}
- (NSString *)defaultSortKey {
  return @"category_index";
}
- (NSString *)palmDb {
  return @"MemoDB";
}
@end /* SkyPalmMemoListState */
