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

#include "LSWTableView.h"
#include "common.h"
#include <OGoFoundation/WOComponent+config.h>
#include <OGoFoundation/LSWConfigHandler.h>
#include <OGoFoundation/WOSession+LSO.h>
#include <OGoFoundation/OGoSession.h>
#include <LSFoundation/LSCommandContext.h>
#include <OGoFoundation/LSWMailEditorComponent.h>

/* NOTE: This component is DEPRECATED - use SkyTableView instead! */

#ifndef MIN
#  define MIN(x,y) ((x>y) ? y : x)
#endif
#ifndef MAX
#  define MAX(x,y) ((x>y) ? x : y)
#endif

@interface LSWTableView(TableViewParent)
- (LSWTableView *)parent;
- (BOOL)isArrayAttribute;
- (void)_setSortedArray;
@end

@implementation LSWTableView

static Class ArrayClass  = Nil;
static Class StringClass = Nil;
static Class DictClass   = Nil;
static BOOL  hasMail     = NO;

+ (void)initialize {
  NGBundleManager *bm;
  
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
  
  if (ArrayClass  == Nil) ArrayClass  = [NSArray      class];
  if (StringClass == Nil) StringClass = [NSString     class];
  if (DictClass   == Nil) DictClass   = [NSDictionary class];

  bm = [NGBundleManager defaultBundleManager];
  if ([bm bundleProvidingResource:@"LSWImapMailEditor"
	  ofType:@"WOComponents"] != nil)
    hasMail = YES;
}

- (id)init {
  if ((self = [super init])) {
    self->isMailAvailable = hasMail;
    self->nullString      = @"";
  }
  return self;
}

- (void)dealloc {
  [self->item              release];
  [self->selectedAttribute release];
  [self->sortedArray       release];
  [self->nullString        release];
  [self->configHandler     release];
  [self->sort              release];
  [self->list              release];
  [self->attributes        release];
  [self->title             release];
  [self->label             release];
  [self->labels            release];
  [self->onNew             release];
  [self->onImport          release];
  [self->onRefresh         release];
  [self->evenRowColor      release];
  [self->oddRowColor       release];
  [self->relatedObject     release];
  [super dealloc];
}

/* final methods */

static inline id _getItemValue(LSWTableView *self) {
  return self->getItemValue(self->item, @selector(valueForKey:),
                            self->attributeKey);
}

static inline id _getAttrValue(LSWTableView *self, NSString *_key) {
  return self->getAttrValue(self->attribute, @selector(valueForKey:),
                            _key);
}

/* notifications */

- (void)syncSleep {
  [self->evenRowColor  release]; self->evenRowColor  = nil;
  [self->oddRowColor   release]; self->oddRowColor   = nil;
  [self->configHandler release]; self->configHandler = nil;
  self->attribute    = nil;
  self->attributeKey = nil;
  self->relKey       = nil;

  self->getItemValue = NULL;
  [self->item release]; self->item = nil;
  [self setRelatedObject:nil];
}
- (void)sleep {
  [self syncSleep];
}

- (void)syncTableViewFromParent {
#define getVal(_a_) getBinding(self, @selector(valueForBinding:), _a_)
  IMP getBinding = [self methodForSelector:@selector(valueForBinding:)];
  id cfg = [self config];

  [self setTitle:            getVal(@"title")];
  [self setLabels:           getVal(@"labels")];
  [self setLabel:            getVal(@"label")];
  [self setList:             getVal(@"list")];
  [self setStart:            [getVal(@"start") unsignedIntValue]];
  [self setBlockSize:        [getVal(@"blockSize") unsignedIntValue]];
  [self setAttributes:       getVal(@"attributes")];
  [self setSelectedAttribute:getVal(@"selectedAttribute")];
  [self setSorter:           getVal(@"sorter")];
  [self setDateFormatter:    getVal(@"dateFormatter")];
  [self setNumberFormatter:  getVal(@"numberFormatter")];
  [self setOnNew:            getVal(@"onNew")];
  [self setOnImport:         getVal(@"onImport")];
  [self setOnRefresh:        getVal(@"onRefresh")];
  [self setIsDescending:     [getVal(@"isDescending") boolValue]];

  if (self->selectedAttribute == nil) {
    NSAssert([self->attributes isKindOfClass:ArrayClass],
             @"attributes not set !");
    [self setSelectedAttribute:[self->attributes objectAtIndex:0]];
  }
  
  [self setEvenRowColor:[cfg valueForKey:@"colors_evenRow"]];
  [self setOddRowColor:[cfg valueForKey:@"colors_oddRow"]];
  
  if (self->isMailAvailable) {
    self->isInternalMailEditor =
      ([[[[self session] userDefaults] objectForKey:@"mail_editor_type"]
                isEqualToString:@"internal"]) ? YES : NO;
  }
#undef getVal
}
- (void)syncTableViewToParent {
#define setVal(_a_, _b_) \
  setBinding(self, @selector(setValue:forBinding:), ((_a_)), ((_b_)))
  IMP setBinding = [self methodForSelector:@selector(setValue:forBinding:)];

  setVal([self item],                                   @"item");
  setVal([NSNumber numberWithUnsignedInt:[self start]], @"start");
  setVal([self selectedAttribute],                      @"selectedAttribute");
  setVal([self relatedObject],                          @"relatedObject");
  setVal([NSNumber numberWithBool:[self isDescending]], @"isDescending");
#undef setVal
}

- (BOOL)synchronizesVariablesWithBindings {
  return NO;
}

- (void)takeValuesFromRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  /* table view contains no form elements */
}

- (id)invokeActionForRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  id result;

  [self syncTableViewFromParent];
  
  [self _setSortedArray];
  result = [super invokeActionForRequest:_rq inContext:_ctx];
  
  [self syncTableViewToParent];
  return result;
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  [self syncTableViewFromParent];

  [self _setSortedArray];  
  [super appendToResponse:_response inContext:_ctx];

  [self syncTableViewToParent];
}

// accessors

- (void)setLabels:(id)_labels {
  ASSIGN(self->labels, _labels);
}

- (void)setOnNew:(NSString *)_onNew {
  if (self->onNew != _onNew) {
    RELEASE(self->onNew);
    self->onNew = [_onNew copyWithZone:[self zone]];
  }
}
- (NSString *)onNew {
  return self->onNew;
}

- (void)setOnImport:(NSString *)_onImport {
  if (self->onImport != _onImport) {
    RELEASE(self->onImport);
    self->onImport = [_onImport copyWithZone:[self zone]];
  }
}
- (NSString *)onImport {
  return self->onImport;
}

- (void)setOnRefresh:(NSString *)_onRefresh {
  if (self->onRefresh != _onRefresh) {
    RELEASE(self->onRefresh);
    self->onRefresh = [_onRefresh copyWithZone:[self zone]];
  }
}
- (NSString *)onRefresh {
  return self->onRefresh;
}

- (void)setList:(NSArray *)_list {
  if (self->list != _list) {
    //NSLog(@"self->list retainCount %d ", [self->list retainCount]);
    //_refCountFromArray(self->list);
    _list = [_list retain];
    [self->list        release]; self->list        = nil;
    [self->sortedArray release]; self->sortedArray = nil;
    self->list = _list;
  }
}

- (NSArray *)list {
  return self->list;
}

- (NSArray *)sortedArray {
  NSAssert(self->sortedArray, @"sorted array not set.");
  return self->sortedArray;
}

- (void)setItem:(id)_item {
  [self setValue:_item forBinding:@"item"];
  
  self->isActionDisabled =
    [[self valueForBinding:@"itemActionDisabled"] boolValue];

  ASSIGN(self->item, _item);

  self->getItemValue = (void*)
    [self->item methodForSelector:@selector(valueForKey:)];
}
- (id)item {
  return self->item;
}

- (void)setIndex:(unsigned)_idx {
  self->index = _idx;
}
- (unsigned)index {
  return self->index;
}

- (void)setNullString:(NSString *)_value {
  NSAssert(_value, @"cannot assign <nil> to nullString");
  if (self->nullString != _value) {
    [self->nullString release]; self->nullString = nil;
    self->nullString = [_value copyWithZone:[self zone]];
  }
}
- (NSString *)nullString {
  return self->nullString;
}

- (void)setEvenRowColor:(NSString *)_color {
  ASSIGN(self->evenRowColor, _color);
}
- (NSString *)evenRowColor {
  return self->evenRowColor;
}
- (void)setOddRowColor:(NSString *)_color {
  ASSIGN(self->oddRowColor, _color);
}
- (NSString *)oddRowColor {
  return self->oddRowColor;
}

- (void)setDateFormatter:(NSFormatter *)_formatter {
  self->dateFormatter = _formatter;
}
- (NSFormatter *)dateFormatter {
  return self->dateFormatter;
}

- (void)setNumberFormatter:(NSFormatter *)_formatter {
  self->numberFormatter = _formatter;
}
- (NSFormatter *)numberFormatter {
  return self->numberFormatter;
}

- (NSString *)textColor {
  id action;
  id normalColor = nil;
  id electColor  = nil;
  id tmp         = nil;

  action = _getAttrValue(self, @"changeFontColorCondition");
  
  tmp = _getAttrValue(self, @"fontColor");
  if ((normalColor = [[self config] valueForKey:tmp]) == nil)
    normalColor = tmp;
  tmp = _getAttrValue(self, @"electFontColor");
  if ((electColor = [[self config] valueForKey:tmp]) == nil)
    electColor = tmp;

  if (normalColor == nil) normalColor = @"#000000";
  if (electColor == nil)  electColor  = @"#000000";
  
  if (action == nil) return normalColor;
  else if ([[self performParentAction:action] boolValue]) return electColor;
  else return normalColor;
  
};

- (NSString *)align {
  id align;
  if ((align = _getAttrValue(self, @"align")) == nil) {
    return @"LEFT";
  }
  return align;
}

- (NSString *)rowColor {
  return (((self->index - self->start) % 2) == 0)
    ? self->evenRowColor
    : self->oddRowColor;
}

- (void)setAttributes:(NSArray *)_attributes {
  if (![_attributes isKindOfClass:ArrayClass]) {
    NSLog(@"ERROR[%s] :attributes parameters is not an array: <%@>",
          __PRETTY_FUNCTION__, _attributes);
    return;
  }
  ASSIGN(self->attributes, _attributes);
}
- (NSArray *)attributes {
  return self->attributes;
}

- (void)setAttributeConfig:(NSDictionary *)_attribute {
  self->attribute    = _attribute;
  self->attributeKey = [_attribute valueForKey:@"key"];
  self->relKey       = [_attribute valueForKey:@"relKey"];
  self->getAttrValue = (void *)[self->attribute methodForSelector:
                                    @selector(valueForKey:)];
}
- (NSDictionary *)attributeConfig {
  return self->attribute;
}

- (void)setSelectedAttribute:(NSDictionary *)_selectedAttribute {
  if (!([_selectedAttribute isKindOfClass:DictClass] ||
        (_selectedAttribute == nil))) {
    NSLog(@"ERROR[%s]: invalid attribute parameter <%@>",
          __PRETTY_FUNCTION__, _selectedAttribute);
    return;
  }
  
  ASSIGN(self->selectedAttribute, _selectedAttribute);
}

 - (NSDictionary *)selectedAttribute {
  return self->selectedAttribute;
}

- (unsigned)blockSize {
  return self->blockSize;
}
- (void)setBlockSize:(unsigned)_blockSize {
  if (_blockSize == 0)
    _blockSize = 10;
  self->blockSize = _blockSize;
}

- (void)setIsDescending:(BOOL)_isDescending {
  self->isDescending = _isDescending;
}
- (BOOL)isDescending {
  return self->isDescending;
}

- (unsigned)idx {
  return self->idx;
}
- (void)setIdx:(unsigned)_idx {
  self->idx = _idx;
}

- (void)setStart:(unsigned)_start {
  self->start = _start;
}
- (unsigned)start {
  return self->start;
}

- (void)setTitle:(NSString *)_title {
  if (self->title != _title) {
    [self->title autorelease];
    self->title = [_title copy];
  }
}
- (NSString *)title {
  return self->title;
}

- (void)setLabel:(NSString *)_label {
  if (self->label != _label) {
    [self->label autorelease];
    self->label = [_label copy];
  }
}
- (NSString *)label {
  return self->label;
}

- (NSString *)attributeKey {
  return self->attributeKey;
}
- (NSString *)attributeRelKey {
  return self->relKey;
}

- (NSString *)attributeLabel {
  id labelKey = _getAttrValue(self, @"labelKey");
  id value    = _getAttrValue(self, @"label");
  
  if ((labelKey != nil) && (self->labels != nil)) {
    NSString *tmp = [self->labels valueForKey:labelKey];

    value = (tmp != nil) ? tmp : labelKey;
  }
  return value ? value : _getAttrValue(self, @"key");
}

- (NSString *)currentSortAttrName {
  id value = [self->selectedAttribute valueForKey:@"label"];

  return  value ? value : [self->selectedAttribute valueForKey:@"key"];
};

- (NSArray *)arrayAttrList {
  return _getItemValue(self);
}

- (id)attributeValue {
  NSDictionary *labelDict;
  id   value;
  BOOL isLocalized;
  
  value       = _getItemValue(self);
  labelDict   = _getAttrValue(self, @"labels");
  isLocalized = [_getAttrValue(self, @"isLocalized") boolValue];
  
  if (self->relKey != nil)
    value = [value valueForKey:self->relKey];

  if (![value isNotNull])
    value = [self->attribute valueForKey:@"nilString"];  

  if (isLocalized && (self->labels != nil)) {
    NSString *tmp = [self->labels valueForKey:[value stringValue]];

    value = (tmp != nil) ? tmp : value;
  }
  if (labelDict) {
    id l;
    
    l = [labelDict objectForKey:[value stringValue]]; // if it is NSNumber
    value = (l != nil) ? l : value;
  }
  return value;
}
- (void)setAttributeValue:(id)_value {
  [self->item takeValue:_value forKey:self->attributeKey];
}

- (id)objectImageAlt {
  id   alt, altLabel;
  BOOL isAltLocalized;
  
  alt            = _getAttrValue(self, @"alt");
  altLabel       = _getAttrValue(self, @"altLabel");
  isAltLocalized = [_getAttrValue(self, @"isAltLocalized") boolValue];
  
  if (alt == nil) {
    return [altLabel isKindOfClass:StringClass]
      ? altLabel
      : [self attributeValue];
  }

  alt = [self->item valueForKey:alt];

  if (alt) {
    if (isAltLocalized && (self->labels != nil)) {
      NSString *tmp = [self->labels valueForKey:[alt stringValue]];

      return (tmp != nil) ? tmp : alt;
    }
    if ([altLabel isKindOfClass:DictClass]) {
      NSString *l;
      
      l = [(NSDictionary *)altLabel objectForKey:alt];
      return (l == nil) ? alt : l;
    }
    return alt;
  }
  return [self attributeValue];
}

- (NSFormatter *)attributeValueFormatter {
  id value = [self attributeValue];

  if(([value isKindOfClass:[NSDate class]]) &&
     (self->dateFormatter != nil))
    {
      return self->dateFormatter;
    }
  if (([value isKindOfClass:[NSNumber class]]) &&
      (self->numberFormatter != nil))
    {
      return self->numberFormatter;
    }

  return [(id)[self session] formatterForValue:[self attributeValue]];
}

- (void)setRelatedObject:(id)_object {
  id tmp = self->relatedObject;
  self->relatedObject = [_object retain];
  [tmp release];
}
- (id)relatedObject {
  return self->relatedObject;
}

- (NSString *)relatedObjectAlt {
  id alt;
  
  if ((alt = _getAttrValue(self, @"alt")) == nil)
    return [self->relatedObject valueForKey:self->relKey];
  
  if ([alt isKindOfClass:ArrayClass]) {
    NSMutableString *mString    = nil;
    NSEnumerator    *enumerator = nil;
    id obj;
    
    mString = [NSMutableString stringWithCapacity:64];
    enumerator = [alt objectEnumerator];
    while ((obj = [enumerator nextObject])) {
      if ([obj isKindOfClass:DictClass]) {
        id o;
        
        o = [self->relatedObject valueForKey:
                   [(NSDictionary *)obj objectForKey:@"relKey"]];
        if (o != nil) {
          id appendObj;
          
          appendObj = [o valueForKey:
                           [(NSDictionary *)obj objectForKey:@"relValue"]];
          [mString appendString:([appendObj isKindOfClass:StringClass])
                   ? appendObj
                   : @""];
        }
      }
      else {
        id result;
        
        result = [self->relatedObject valueForKey:obj];
        [mString appendString:([result isKindOfClass:StringClass])
                 ? result
                 : obj];
      }
    }
    return mString;
  }
  else
    return [self->relatedObject valueForKey:alt];
}

- (id)relatedObjectValue {
  return [self->relatedObject valueForKey:self->relKey];
}

- (id)cellObjectValue {
  return [self isArrayAttribute]
    ? [self relatedObjectValue]
    : [self attributeValue];
}

// links in relation attributes

- (NSString *)linkAction { // link action
  return _getAttrValue(self, @"action");
}
- (NSString *)linkHref { // link href
  NSString *s;

  if ((s = [self attributeValue]))
    return [_getAttrValue(self, @"href") stringByAppendingString:s];

  return _getAttrValue(self, @"href");
}

- (NSString *)image {
  id image;

  if ((image = _getAttrValue(self, @"image")) == nil)
    return nil;
  
  if (![image isKindOfClass:DictClass])
    return image;
  
  if (![self isArrayAttribute])
    return [(NSDictionary *)image objectForKey:_getItemValue(self)];
  
  return [(NSDictionary *)image objectForKey:
                            [self->relatedObject valueForKey:self->relKey]];
}
- (NSString *)imageLabel {
  /* the ALT of image */
  
  if ([self isArrayAttribute])
    return [self relatedObjectAlt];
  if ([self isLinkAttribute])
    return [self attributeValue];
  
  return [self objectImageAlt];
}

- (NSString *)linkTarget {
  return _getAttrValue(self, @"target");
}

- (unsigned)listCount {
  return (self->sortedArray == nil) ? 0 : [self->sortedArray count];
}

- (unsigned)currentPageNumber {
  if (!(self->blockSize > 0)) {
    NSLog(@"ERROR[%s]: invalid block size %i (component=%@) !",
          __PRETTY_FUNCTION__, self->blockSize, [[self parent] name]);
  }
  return self->start / self->blockSize + 1;
}

- (unsigned)lastPageNumber {
  unsigned cnt;

  cnt = [self->sortedArray count];
  return (cnt == 0) ? 1 : ((cnt - 1) / self->blockSize + 1);
}

- (unsigned)objectsFrom {
  unsigned cnt;

  cnt = [self->sortedArray count];
  return (cnt == 0) ? 0 : self->start + 1;
}
- (unsigned)objectsTo {
  unsigned cnt;

  cnt = [self->sortedArray count];
  if (cnt == 0) return 0;
  
  return self->start + 1 + MIN(cnt - (self->start + 1), self->blockSize - 1);
}

- (BOOL)isNew {
  return (self->onNew == nil) ? NO : YES;
}

- (BOOL)isImport {
  return (self->onImport == nil) ? NO : YES;
}

- (BOOL)isRefresh {
  return (self->onRefresh == nil) ? NO : YES;
}

- (BOOL)isNotFirstPage {
  return ([self currentPageNumber] != 1) ? YES : NO;
}
- (BOOL)isFirstPage {
  return ![self isNotFirstPage];
}
- (BOOL)isNotLastPage {
  return [self lastPageNumber] != [self currentPageNumber] ? YES : NO;
}
- (BOOL)isLastPage {
  return ![self isNotLastPage];
}

- (NSString *)currentOrderingString {
  return ([self isSelectedAttribute])
    ? (self->isDescending ? @"upward_sorted.gif" : @"downward_sorted.gif")
    : @"non_sorted.gif";
}

- (BOOL)isLastRelatedObject {
  return (self->idx == [[self arrayAttrList] count] - 1);
}

- (BOOL)isActionDisabled {
  return self->isActionDisabled;
}
- (BOOL)isLinkAttribute {
  return ((([self linkAction] != nil) && !self->isActionDisabled) ||
          _getAttrValue(self, @"href") != nil) ? YES : NO;
}

- (BOOL)isSelectedAttribute {
  return self->sort
    ? (([self->selectedAttribute isEqual:self->attribute]) ? YES : NO)
    : NO;
}

- (void)setIsInternalMailEditor:(BOOL)_flag {
  self->isInternalMailEditor = _flag;
}
- (BOOL)isInternalMailEditor {
  return self->isInternalMailEditor;
}

- (NSString *)currentAttributeCellColor {
  NSString *color;
  
  color = [self isSelectedAttribute]
    ? [[self config] valueForKey:@"colors_sortedAttributeCell"]
    : [[self config] valueForKey:@"colors_tableViewAttributeCell"];

  return color;
}

- (BOOL)isSortableAttribute {
  return self->sort
    ? [_getAttrValue(self, @"sort") boolValue]
    : NO;
}

- (BOOL)isActionLink {
  return (([self linkAction] != nil) && !self->isActionDisabled) ? YES : NO;
}
- (BOOL)isHrefLink {
  return (_getAttrValue(self, @"href") != nil) ? YES : NO;
}
- (BOOL)isImageLink {
  return (_getAttrValue(self, @"image") != nil) ? YES : NO;  
}

- (BOOL)hasImage {
  return (_getAttrValue(self, @"image") != nil) ? YES : NO;  
}

- (BOOL)isArrayAttribute {
  id value = _getItemValue(self);
  return [value isKindOfClass:ArrayClass];
}

- (NSString *)separator {
  return [self isImageLink] ? @"" : @",";
}

// sorting

- (void)setSorter:(id<LSWTableViewSorter>)_sorter {
  ASSIGN(self->sort, _sorter);
}
- (id<LSWTableViewSorter>)sorter {
  return self->sort;
}

// config

- (id)config {
  if (self->configHandler == nil) {
    self->configHandler = [[LSWConfigHandler allocWithZone:[self zone]]
                                             initWithComponent:self];
  }
  return self->configHandler;
}

// ******************** actions ********************

- (id)sort {
  NSAssert(self->selectedAttribute, @"no selected attribute available");
  NSAssert(self->attribute,         @"no attribute available");

  self->isDescending = ![self->selectedAttribute isEqual:self->attribute]
    ? NO // if the selected attribute is changed, ascending order is the default
    : !self->isDescending;

  [self->sortedArray release]; self->sortedArray = nil;
  [self setSelectedAttribute:self->attribute];

  return nil;
}

- (id)new {
  id r;
  [self syncTableViewToParent];
  r = [self performParentAction:self->onNew];
  [self syncTableViewFromParent];
  return r;
}

- (id)import {
  id r;
  [self syncTableViewToParent];
  r = [self performParentAction:self->onImport];
  [self syncTableViewFromParent];
  return r;
}

- (id)refresh {
  id r;
  [self syncTableViewToParent];
  r = [self performParentAction:self->onRefresh];
  [self syncTableViewFromParent];
  return r;
}

- (id)firstBlock {
  self->start = 0;
  return nil;
} 

- (id)lastBlock {
  self->start = ([self lastPageNumber] - 1)  * self->blockSize;
  return nil;
} 

- (id)nextBlock {
  if ([self isNotLastPage])
    self->start = self->start + self->blockSize;
  return nil;
} 

- (id)previousBlock {
  if ([self isNotFirstPage])
    self->start = self->start - self->blockSize;
  return nil;
}

- (id)viewObject {
  id r;
  [self syncTableViewToParent];
  r = [self performParentAction:[self linkAction]];
  [self syncTableViewFromParent];
  return r;
}

- (id)mailTo {
  WOComponent *mailEditor;

  mailEditor = (id)[[self application] pageWithName:@"LSWImapMailEditor"];
  
  if (mailEditor != nil) {
    [(id)mailEditor addReceiver:self->item type:@"to"];
    [(id)mailEditor setContentWithoutSign:@""];
    [[[self session] navigation] enterPage:(id<OGoContentPage>)mailEditor];
  }
  return nil;
}

- (void)_setSortedArray {
  if (self->sortedArray != nil)
    return;

  if (self->selectedAttribute == nil) {
    NSAssert([self->attributes isKindOfClass:ArrayClass],
	     @"attributes not set !");
    [self setSelectedAttribute:[self->attributes objectAtIndex:0]];
  }

  NSAssert(self->sortedArray == nil, @"sorted array should be nil !");
    
  if (self->list) {
    self->sortedArray =
      [[self->sort sortArray:self->list
	           key:[self->selectedAttribute valueForKey:@"key"]
	           isDescending:self->isDescending] retain];

    NSAssert1(self->sortedArray, @"sort of array %@ failed.", self->list);
  }
  else
    self->sortedArray = [[NSArray alloc] init];
}

@end /* LSWTableView */

/* dynamic element additions */

@implementation WODynamicElement(LSWTableViewAdditions)

- (void)appendFontToResponse:(WOResponse *)_response
  color:(NSString *)sC
  face:(NSString *)sF
  size:(NSString *)sS
{
  [_response appendContentString:@"<font "];
  if (sC) {
    [_response appendContentString:@" color=\""];
    [_response appendContentHTMLAttributeValue:sC];
    [_response appendContentCharacter:'"'];
  }
  if (sF) {
    [_response appendContentString:@" face=\""];
    [_response appendContentHTMLAttributeValue:sF];
    [_response appendContentCharacter:'"'];
  }
  if (sS) {
    [_response appendContentString:@" size=\""];
    [_response appendContentHTMLAttributeValue:sS];
    [_response appendContentCharacter:'"'];
  }
  [_response appendContentCharacter:'>'];
}

@end /* WODynamicElement(LSWTableViewAdditions) */
