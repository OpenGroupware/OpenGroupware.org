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

/*
   > dataSource
   > list
  <> batchSize
  <> selections

  <> item
  <> index
   > identifier
  <> previousItem
  <> previousIndex
  
  <> sortedKey
  <> isDescending

  <  groups
  <  objectsOfGroup
   > showGroupTitle        (default: YES)
  
   > scrollOnClient
  <> autoScroll
  <  count           // number of elements in dataSource

   > sortAction
   > sortCaseInsensitive    (default: NO)
   > showBatchResizeButtons (default: YES)

   > titleString
   > footerString

   > cacheTimeout    // seconds
*/

//#define PROFILE 1

#include <OGoFoundation/OGoComponent.h>
#include <NGExtensions/EOCacheDataSource.h>
#include "common.h"

@interface SkyTableView : OGoComponent
{
@protected
  NSArray        *list;
  EODataSource   *dataSource;
  NSMutableArray *selections;
  id             item;
  unsigned       index;
  
  BOOL           isDescending;
  BOOL           scrollOnClient;
  int            autoScroll;
  NSString       *sortedKey;
  unsigned       batchSize;
  unsigned       currentBatch;

  NSString *shiftId; // used by shiftClickScript (changed never)
  NSString *allId;   // used by selectAllCheckboxScript

  NSString *titleString;
  NSString *footerString;

  int indexOfFirst;
  int indexOfLast;

  // grouping
  NSDictionary   *groupingDict;
  NSArray        *groupAttributes;  // array of groupNames
  NGBitSet       *showGroupSet;
}
- (void)setList:(NSArray *)_list;
- (NSString *)identifier;
@end

@interface NSDictionary(SkyTableViewGrouping)
- (NSArray *)flattenedArrayWithHint:(unsigned)_hint andKeys:(NSArray *)_keys;
- (NSArray *)attributesWithHint:(unsigned int)_hint andKeys:(NSArray *)_keys;
- (NGBitSet *)bitSetWithHint:(unsigned int)_hint;
@end

static NSString *SkyTableView_SelectAllCheckboxesScript = nil;
static NSString *SkyTableView_ShiftClickScript = nil;

@implementation SkyTableView

static Class EOCacheDataSourceClass = Nil;
static Class StrClass = Nil;

+ (void)initialize {
  NSBundle *bundle;
  NSString *path;
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  StrClass               = [NSString class];
  EOCacheDataSourceClass = [EOCacheDataSource class];

  bundle = [NSBundle bundleForClass:self];
  
  path = [bundle pathForResource:@"SkyTableView_SelectAllCheckboxesScript"
                 ofType:@"js"];
  SkyTableView_SelectAllCheckboxesScript =
    [[StrClass alloc] initWithContentsOfFile:path];
  if (SkyTableView_SelectAllCheckboxesScript == nil)
    NSLog(@"WARNING: did not find checkboxes JavaScript for SkyTableView!");
  
  path = [bundle pathForResource:@"SkyTableView_ShiftClickScript"
                 ofType:@"js"];
  SkyTableView_ShiftClickScript = 
    [[StrClass alloc] initWithContentsOfFile:path];
  if (SkyTableView_ShiftClickScript == nil)
    NSLog(@"WARNING: did not find shiftclick JavaScript for SkyTableView!");
}

static inline NSString *_currentId(SkyTableView *self) {
  NSArray *tmp;

  tmp = [[[self context] elementID] componentsSeparatedByString:@"."];
  
  return [tmp componentsJoinedByString:@""];
}

- (id)init {
  if ((self = [super init])) {
    self->shiftId         = [_currentId(self) copy];
    self->showGroupSet    = [[NGBitSet alloc] initWithCapacity:128];
  }
  return self;
}

- (void)dealloc {
  [self->list            release];
  [self->item            release];
  [self->dataSource      release];
  [self->selections      release];
  [self->allId           release];
  [self->shiftId         release];
  [self->sortedKey       release];

  [self->titleString     release];
  [self->footerString    release];

  [self->groupingDict    release];
  [self->groupAttributes release];
  [self->showGroupSet    release];
  
  [super dealloc];
}

/* sorting */

- (void)_sortList {
  // is only called if self->dataSource== nil
  EOSortOrdering *so;
  SEL            sel;
  BOOL           isInsen;
  NSArray        *soArray;

  BEGIN_PROFILE;

  isInsen = ([self canGetValueForBinding:@"sortCaseInsensitive"])
    ? [[self valueForBinding:@"sortCaseInsensitive"] boolValue]
    : NO;
  
  sel = (self->isDescending)
    ? (isInsen) ? EOCompareCaseInsensitiveDescending : EOCompareDescending
    : (isInsen) ? EOCompareCaseInsensitiveAscending  : EOCompareAscending;
  
  so = [EOSortOrdering sortOrderingWithKey:self->sortedKey selector:sel];
  
  soArray = [NSArray arrayWithObject:so];
  [self setList:[self->list sortedArrayUsingKeyOrderArray:soArray]];
  
  END_PROFILE;
}

- (void)_updateFetchSpecification {
  EOFetchSpecification *fetchSpec;
  EOSortOrdering       *so;
  SEL                  sel;
  BOOL                 isInsen;

  if (self->sortedKey == nil)
    return;

  BEGIN_PROFILE;

  isInsen = ([self canGetValueForBinding:@"sortCaseInsensitive"])
    ? [[self valueForBinding:@"sortCaseInsensitive"] boolValue]
    : NO;
    
  sel = (self->isDescending)
    ? (isInsen) ? EOCompareCaseInsensitiveDescending : EOCompareDescending
    : (isInsen) ? EOCompareCaseInsensitiveAscending  : EOCompareAscending;
    
  so = [EOSortOrdering sortOrderingWithKey:self->sortedKey selector:sel];
    
  if ((fetchSpec = [self->dataSource fetchSpecification]) == nil) {
    fetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:nil
                                      qualifier:nil
                                      sortOrderings:
                                        [NSArray arrayWithObject:so]];
    [self->dataSource setFetchSpecification:fetchSpec];
  }
  else {
    NSArray *sos = nil;

    sos = [NSArray arrayWithObject:so];
    
    if ([[fetchSpec sortOrderings] isEqual:sos] == NO) {
      [fetchSpec setSortOrderings:[NSArray arrayWithObject:so]];
      [self->dataSource setFetchSpecification:fetchSpec];
    }
  }
  
  END_PROFILE;
}

- (void)_updateListFromDataSource {
  EOFetchSpecification *fetchSpec = nil;
  NSArray              *groupings = nil;

  BEGIN_PROFILE;

  if (![self canGetValueForBinding:@"sortAction"])
    [self _updateFetchSpecification];
  else
    [self performParentAction:[self valueForBinding:@"sortAction"]];
  
  fetchSpec = [self->dataSource fetchSpecification];

  PROFILE_CHECKPOINT("after update fspec");
  
  if ((groupings = [fetchSpec groupings])) {
    unsigned int cnt;
    NSArray      *tmp;
    EOGrouping   *grouping;
    NSArray      *allKeys;


    tmp = [self->dataSource fetchObjects];
    cnt = [tmp count];

    grouping  = [groupings lastObject];
    [grouping setSortOrderings:[fetchSpec sortOrderings]];

    [self->groupingDict release]; self->groupingDict = nil;
    self->groupingDict = [[tmp arrayGroupedBy:grouping] retain];

    allKeys = [self->groupingDict allKeys];
    allKeys = [allKeys sortedArrayUsingSelector:@selector(compare:)];
    [self->groupAttributes release]; self->groupAttributes = nil;
    self->groupAttributes = 
      [[self->groupingDict attributesWithHint:cnt andKeys:allKeys] retain];
    
    [self setList:[self->groupingDict flattenedArrayWithHint:[tmp count]
                             andKeys:allKeys]];
    
    PROFILE_CHECKPOINT("after groupings");
  }
  else {
    RELEASE(self->groupAttributes); self->groupAttributes = nil;

    [self setList:[self->dataSource fetchObjects]];
    
    PROFILE_CHECKPOINT("after no groupings");
  }
  
  END_PROFILE;
}

/* accessors */

- (void)setIsDescending:(BOOL)_isDescending {
  self->isDescending = _isDescending;
}
- (BOOL)isDescending {
  return self->isDescending;
}

- (void)setSortedKey:(NSString *)_sortedKey {
  ASSIGN(self->sortedKey, _sortedKey);
}
- (NSString *)sortedKey {
  return self->sortedKey;
}

- (BOOL)scrollOnClient {
  return self->scrollOnClient;
}

- (int)autoScroll {
  return self->autoScroll;
}
- (void)setAutoScroll:(int)_autoScroll {
  self->autoScroll = _autoScroll;
}

- (unsigned)batchSize {
  return self->batchSize;
}
- (void)setBatchSize:(unsigned)_batchSize {
  self->batchSize = _batchSize;
}

- (void)setList:(NSArray *)_list {
  ASSIGN(self->list, _list);
}

- (NSArray *)list {
  return self->list;
}

- (void)setDataSource:(EODataSource *)_dataSource {
  int cacheTimeout = -1;

  if (self->dataSource == _dataSource)
    return;

  BEGIN_PROFILE;
  
  if ([self canGetValueForBinding:@"cacheTimeout"])
    cacheTimeout = [self intValueForBinding:@"cacheTimeout"];
  
  // use a cacheDataSource
  if (cacheTimeout > 0) {
#if DEBUG && 0
      [self debugWithFormat:@"use cached datasource (timeout=%i)",
              cacheTimeout];
#endif
      if ([self->dataSource isKindOfClass:EOCacheDataSourceClass] &&
          [(EOCacheDataSource *)self->dataSource source] == _dataSource) {
        if (cacheTimeout != [(EOCacheDataSource *)self->dataSource timeout])
          [(EOCacheDataSource *)self->dataSource setTimeout:cacheTimeout];
        return;
      }
      RELEASE(self->dataSource); self->dataSource = nil;
      self->dataSource = [[EOCacheDataSource allocWithZone:[self zone]]
                                             initWithDataSource:_dataSource];
      
      [(EOCacheDataSource *)self->dataSource setTimeout:cacheTimeout];
  }
  // do not use dataSource
  else {
    ASSIGN(self->dataSource, _dataSource);
  }
  
  END_PROFILE;
}

- (void)setSelections:(NSArray *)_selections {
  ASSIGN(self->selections, _selections);
}
- (NSArray *)selections {
  return self->selections;
}

- (void)setItem:(id)_item {
  [self setValue:_item forBinding:@"item"];
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (void)setIndex:(unsigned)_index {
  [self setValue:[NSNumber numberWithInt:_index] forBinding:@"index"];
  self->index = _index;
}
- (unsigned)index {
  return self->index;
}

// --- grouping -----------------------------------------

- (NSArray *)groups {
  return (self->groupAttributes)
    ? [self->groupAttributes objectAtIndex:self->index]
    : nil;
}

- (void)setGroups:(NSArray *)_groups {
  [self setValue:[self groups] forBinding:@"groups"];
  [self setValue:[self->groupingDict objectForKey:[self groups]]
        forBinding:@"objectsOfGroup"];
}

- (BOOL)showGroup {
  return (self->groupAttributes != nil)
    ? [self->showGroupSet isMember:self->index]
    : YES;
}
- (void)setShowGroup:(BOOL)_bool {
  if (_bool)
    [self->showGroupSet addMember:self->index];
  else
    [self->showGroupSet removeMember:self->index];
}

- (BOOL)showGroupTitle {
  return ([self canGetValueForBinding:@"showGroupTitle"])
    ? [[self valueForBinding:@"showGroupTitle"] boolValue]
    : YES;
}

// --- checkboxes  --------------------------------------

- (BOOL)isSelectAllAsCheckBox {
  if (self->batchSize > [self->list count])
    return YES;

  return NO;
}

- (BOOL)isAllSelected {
  return ([self->list count] == 0)
    ? NO
    : ([self->selections count] == [self->list count]);
}

- (id)selectAll {
  [self->selections removeAllObjects];
  [self->selections addObjectsFromArray:self->list];
  
  return nil;
}

- (id)deselectAll {
  [self->selections removeAllObjects];

  return nil;
}

- (BOOL)isChecked {
  return [self->selections containsObject:self->item];
}

- (void)setIsChecked:(BOOL)_flag {
  if (_flag && ![self->selections containsObject:self->item])
    [self->selections addObject:self->item];
  else if (!_flag && [self->selections containsObject:self->item])
    [self->selections removeObject:self->item];
}

- (BOOL)isCheckBoxes {
  if (![[self context] isInForm])
    return NO;
  
  return [self hasBinding:@"selections"];
  //return (self->selections != nil) ? YES : NO;
}

- (NSString *)shiftClick {
  return [StrClass stringWithFormat:@"shiftClick%@(%d)",
                   self->shiftId, self->index];
}

- (NSString *)allSelect {
  return [StrClass stringWithFormat:@"allselect%@()", self->allId];
}

- (NSString *)checkBoxName {
  return [StrClass stringWithFormat:@"%@%@", self->shiftId,
                   [self identifier]];
}

- (NSString *)checkBoxValue {
  return [StrClass stringWithFormat:@"%@%d", self->shiftId, self->index];
}

- (void)setIndexOfFirst:(int)_val {
  self->indexOfFirst = _val;
}
- (int)indexOfFirst {
  return self->indexOfFirst;
}
- (void)setIndexOfLast:(int)_val {
  self->indexOfLast = _val;
}
- (int)indexOfLast {
  return self->indexOfLast;
}

- (NSString *)selectAllCheckboxesScript {
  RELEASE(self->allId); self->allId = nil;
  self->allId = [_currentId(self) copy];
  
  return [StrClass stringWithFormat:SkyTableView_SelectAllCheckboxesScript,
                   self->allId,
                   self->allId,
                   self->allId,
                   self->allId,
                   [self indexOfFirst],
                   [self indexOfLast] + 1,
                   self->shiftId,
                   self->allId];
}

- (NSString *)shiftClickScript {
  return [StrClass stringWithFormat:SkyTableView_ShiftClickScript,
                   self->shiftId,self->shiftId, self->shiftId, self->shiftId,
                   self->shiftId,self->shiftId];
}

- (NSString *)markAllCheckboxName {
  return [StrClass stringWithFormat:@"markAllCheckbox%@", self->allId];
}

// --- actions ------------------------------------------

- (id)tableViewSortAction {
  NSString *parentAction = nil;

  parentAction = [self valueForBinding:@"sortAction"];

  if (parentAction != nil) {
    if ([self canSetValueForBinding:@"sortedKey"])
      [self setValue:self->sortedKey   forBinding:@"sortedKey"];
    if ([self canSetValueForBinding:@"isDescending"])
      [self setValue:[NSNumber numberWithBool:self->isDescending]
            forBinding:@"isDescending"];
    
    [self performParentAction:parentAction];
  }
  else if (self->dataSource) {
    [self _updateFetchSpecification];
  }
  else
    [self _sortList];

  return nil;
}

// --- syncing ------------------------------------------

- (void)setPreviousItem:(id)_previousItem {
  [self setValue:_previousItem forBinding:@"previousItem"];
}

- (void)setPreviousIndex:(unsigned)_previousIndex {
  [self setValue:[NSNumber numberWithInt:_previousIndex]
        forBinding:@"previousIndex"];
}

- (void)setCurrentBatch:(unsigned)_batch {
  self->currentBatch = _batch;
}
- (unsigned)currentBatch {
  return self->currentBatch;
}

- (void)setIdentifier:(NSString *)_identifier {
  [self setValue:_identifier forBinding:@"identifier"];
}

- (NSString *)identifier {
  id tmp;
  
  tmp = [self valueForBinding:@"identifier"];
  return (tmp) ? tmp : [StrClass stringWithFormat:@"%d", self->index];
}

- (BOOL)showBatchResizeButtons {
  if (![self canGetValueForBinding:@"showBatchResizeButtons"])
    return YES;

  return [[self valueForBinding:@"showBatchResizeButtons"] boolValue];
}

- (void)setTitleString:(NSString *)_titleString {
  ASSIGN(self->titleString, _titleString);
}
- (NSString *)titleString {
  return self->titleString;
}

- (void)setFooterString:(NSString *)_footerString {
  ASSIGN(self->footerString, _footerString);
}
- (NSString *)footerString {
  return self->footerString;
}

- (BOOL)hasFooterString {
  return (self->footerString != nil) ? YES : NO;
}

- (BOOL)hasTitleString {
  return (self->titleString != nil) ? YES : NO;
}

- (void)syncFromParent {
#define getVal(_a_) getBinding(self, @selector(valueForBinding:), _a_)

  id  tmp;
  IMP getBinding;

  BEGIN_PROFILE;

  getBinding = [self methodForSelector:@selector(valueForBinding:)];
  
  [self setDataSource:getVal(@"dataSource")];
  [self setSelections:getVal(@"selections")];
  
  if ([self canGetValueForBinding:@"isDescending"] &&
     ([self canSetValueForBinding:@"isDescending"] ||
       (self->sortedKey == nil)))
    self->isDescending = [getVal(@"isDescending") boolValue];

  if ([self canGetValueForBinding:@"sortedKey"] &&
      ([self canSetValueForBinding:@"sortedKey"] || (self->sortedKey == nil)))
    [self setSortedKey:getVal(@"sortedKey")];

  [self setTitleString:getVal(@"titleString")];
  [self setFooterString:getVal(@"footerString")];  

  if (self->dataSource) {
    [self _updateListFromDataSource];
  }
  else
    [self setList:getVal(@"list")];
  
  [self setValue:[NSNumber numberWithInt:[self->list count]]
        forBinding:@"count"];

  self->batchSize      = [getVal(@"batchSize") unsignedIntValue];
  tmp = getVal(@"currentBatch");
  if (tmp != nil)
    self->currentBatch = [tmp unsignedIntValue];
  self->scrollOnClient = [getVal(@"scrollOnClient") boolValue];
  self->autoScroll     = [getVal(@"autoScroll") intValue];

  END_PROFILE;
  
#undef getVal
}

- (void)syncToParent {
#define setVal(_val_, _b_) \
  if ([self canSetValueForBinding:_b_])\
    setBinding(self, @selector(setValue:forBinding:), ((_val_)), ((_b_)))
  
  IMP setBinding;

  BEGIN_PROFILE;
  
  setBinding = [self methodForSelector:@selector(setValue:forBinding:)];
  
  setVal(self->selections, @"selections");

  setVal(self->sortedKey,  @"sortedKey");
  setVal([NSNumber numberWithBool:self->isDescending], @"isDescending");
  setVal([NSNumber numberWithInt:self->batchSize],     @"batchSize");
  setVal([NSNumber numberWithInt:self->currentBatch],  @"currentBatch");
  setVal([NSNumber numberWithInt:self->autoScroll],    @"autoScroll");

  RELEASE(self->list); self->list = nil;

  END_PROFILE;

#undef setVal
}

// --- responder

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  [self syncFromParent];
  [super takeValuesFromRequest:_req inContext:_ctx];
  [self syncToParent];
}

- (id)invokeActionForRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  id result;

  [self syncFromParent];
  result = [super invokeActionForRequest:_req inContext:_ctx];
  [self syncToParent];
  
  return result;
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  BEGIN_PROFILE;
  [self syncFromParent];
  PROFILE_CHECKPOINT("after sync from parent");
  [super appendToResponse:_response inContext:_ctx];
  PROFILE_CHECKPOINT("after append to response");
  [self syncToParent];
  END_PROFILE;
}

- (BOOL)synchronizesVariablesWithBindings {
  return NO;
}

@end /* SkyTableView */

#define ProfileComponents NO

@implementation NSDictionary(TableView)

- (NSArray *)flattenedArrayWithHint:(unsigned int)_hint 
  andKeys:(NSArray *)_keys
{
  NSMutableArray *result  = nil;
  unsigned int   i, cnt;
  NSTimeInterval st     = 0.0;
  
  if (ProfileComponents)
    st = [[NSDate date] timeIntervalSince1970];

  // should be improved
  result = [[NSMutableArray alloc] initWithCapacity:_hint]; 

  for (i = 0, cnt = [_keys count]; i < cnt; i++) {
    NSString *key;
    NSArray  *tmp;

    key = [_keys objectAtIndex:i];
    tmp = [self objectForKey:key];
    [result addObjectsFromArray:tmp];
  }

  if (ProfileComponents) {
    NSTimeInterval diff;
    diff = [[NSDate date] timeIntervalSince1970] - st;
    
    printf("NSDictionary.flattenedArray: %0.4fs\n", diff);
  }
  return result;
}

- (NSArray *)attributesWithHint:(unsigned int)_hint andKeys:(NSArray *)_keys {
  NSMutableArray *result  = nil;
  unsigned int   i, cnt;
  NSTimeInterval st     = 0.0;
  
  if (ProfileComponents)
    st = [[NSDate date] timeIntervalSince1970];

  result = [[NSMutableArray allocWithZone:[self zone]]
                            initWithCapacity:_hint+1];

  for (i = 0, cnt = [_keys count]; i < cnt; i++) {
    unsigned j, cnt2;
    NSString *key;

    key  = [_keys objectAtIndex:i];

    cnt2 = [[self objectForKey:key] count];
    for (j = 0; j < cnt2; j++)
      [result addObject:key];
  }

  if (ProfileComponents) {
    NSTimeInterval diff;
    diff = [[NSDate date] timeIntervalSince1970] - st;
    
    printf("NSDictionary.attributes: %0.4fs\n", diff);
  }
  
  return result;
}

- (NGBitSet *)bitSetWithHint:(unsigned int)_hint {
  NGBitSet     *bitSet  = nil;
  NSEnumerator *keyEnum;
  NSString     *key;
  unsigned int firstPos = 0;
  NSTimeInterval st     = 0.0;
  
  if (ProfileComponents)
    st = [[NSDate date] timeIntervalSince1970];
 
  bitSet = [NGBitSet bitSetWithCapacity:_hint];
  
  keyEnum = [self keyEnumerator];
  while ((key = [keyEnum nextObject])) {
    [bitSet addMember:firstPos];
    firstPos += [[self objectForKey:key] count];
  }

  if (ProfileComponents) {
    NSTimeInterval diff;
    diff = [[NSDate date] timeIntervalSince1970] - st;
    
    printf("NSDictionary.bitSet: %0.4fs\n", diff);
  }
  
  return bitSet;
}

@end /* NSDictionary(TableView) */
