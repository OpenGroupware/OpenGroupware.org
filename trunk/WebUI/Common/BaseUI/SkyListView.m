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

#include "SkyListView.h"
#include "common.h"
#include <OGoFoundation/WOSession+LSO.h>
#include <OGoFoundation/WOComponent+config.h>
#include <OGoFoundation/LSWMailEditorComponent.h>

@interface SkyListView(PrivateMethodes)
- (int)_rows;
- (int)_itemIndex;
- (id)_item;
- (NSString *)_getValue;
- (NSString *)_createId;
@end

@implementation SkyListView

+ (int)version {
  return 5;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (id)init {
  if ((self = [super init])) {
    self->groupName     = [[self _createId] copy];
    self->columns       = 3;
    self->showTableTag  = YES;
    self->popUpValueKey = @"checkValue";
  }
  return self;
}

- (void)dealloc {
  [self->action        release];
  [self->list          release];
  [self->item          release];
  [self->attributes    release];
  [self->selectedItems release];
  [self->row           release];
  [self->column        release];
  [self->attribute     release];
  [self->groupName     release];
  [self->nilString     release];
  [self->labels        release];
  [self->popUpList     release];
  [self->popUpItem     release];
  [self->popUpValueKey release];
  [self->itemTemplate  release];
  [super dealloc];
}

/* notifications */

- (void)syncSleep {
  self->attribute  = nil;
  [self->attributes   release]; self->attributes   = nil;
  [self->itemTemplate release]; self->itemTemplate = nil;
  [self->list         release]; self->list         = nil;
  [self->action       release]; self->action       = nil;
  [super syncSleep];
}

/* accessors */

- (void)setLabels:(id)_labels {
  ASSIGN(self->labels, _labels);
}
- (id)labels {
  return self->labels;
}

- (void)setAction:(NSString *)_action {
  ASSIGN(self->action, _action);
}
- (NSString *)action {
  return self->action;
}

- (void)setList:(NSArray *)_list {
  if ((id)self->selectedItems == (id)_list) {
    RELEASE(self->list); self->list = nil;
    self->list = [_list copy];
  }
  else
    ASSIGN(self->list, _list);
}
- (NSArray *)list {
  return self->list;
}

- (void)setPopUpList:(NSArray *)_list {
  ASSIGN(self->popUpList, _list);
}
- (NSArray *)popUpList {
  return self->popUpList;
}

- (void)setPopUpValueKey:(NSString *)_key {
  ASSIGN(self->popUpValueKey, _key);
}
- (NSString *)popUpValueKey {
  return self->popUpValueKey;
}

- (void)setPopUpItem:(id)_item {
  ASSIGN(self->popUpItem, _item);
}
- (id)popUpItem {
  return self->popUpItem;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (void)setColumns:(unsigned int)_columns {
  if (_columns > 0)
    self->columns = _columns;
}
- (unsigned int)columns {
  return self->columns;
}

- (void)setSortHorizontal:(BOOL)_flag {
  self->sortHorizontal = _flag;
}
- (BOOL)sortHorizontal {
  return self->sortHorizontal;
}

- (void)setShowTableTag:(BOOL)_flag {
  self->showTableTag = _flag;
}
- (BOOL)showTableTag {
  return self->showTableTag;
}

- (void)setSelectedItems:(NSMutableArray *)_selectedItems {
  self->selectedItems = [_selectedItems mutableCopy];
}
- (NSMutableArray *)selectedItems {
  return self->selectedItems;
}

- (void)setAttributes:(NSArray *)_attributes {
  ASSIGN(self->attributes, _attributes);
}
- (NSArray *)attributes {
  return self->attributes;
}

- (void)setItemTemplate:(NSString *)_template {
  ASSIGN(self->itemTemplate,_template);
}
- (NSString *)itemTemplate {
  return self->itemTemplate;
}

- (BOOL)selectInverse {
  return selectInverse;
}
- (void)setSelectInverse:(BOOL)_flag {
  self->selectInverse = _flag;
}

- (void)setUseRadioButtons:(BOOL)_flag {
  self->useRadioButtons = _flag;
}
- (BOOL)useRadioButtons {
  return self->useRadioButtons;
}

- (void)setUsePopUp:(BOOL)_flag {
  self->usePopUp = _flag;
}
- (BOOL)usePopUp {
  return self->usePopUp;
}

- (BOOL)useCheckBox {
  return !self->usePopUp && !self->useRadioButtons;
}

- (BOOL)withNil {
  return (self->nilString != nil) ? YES : NO;
}

- (NSString *)groupName {
  return self->groupName;
}

- (void)setNilString:(NSString *)_str {
  ASSIGN(self->nilString, _str);
}
- (NSString *)nilString {
  return (self->nilString != nil) ? self->nilString : @"no object";
}
- (NSString *)popUpNilString {
  return self->nilString;
}

/* private accessors */

- (void)setColumn:(NSNumber *)_column {
  ASSIGN(self->column, _column);
}
- (NSNumber *)column {
  return self->column;
}

- (void)setRow:(NSNumber *)_row {
  ASSIGN(self->row, _row);
}
- (NSNumber *)row {
  return self->row;
}

- (void)setAttribute:(NSDictionary *)_attribute {
  ASSIGN(self->attribute, _attribute);
}
- (NSDictionary *)attribute {
  return self->attribute;
}

/* complex accessors */

- (NSArray *)rowList {
  int            rows, i;
  NSMutableArray *rowList;
  
  rows    = [self _rows];
  rowList = [NSMutableArray arrayWithCapacity:rows];
  for (i = 0; i < rows; i++)
    [rowList addObject:[NSNumber numberWithInt:i]];
  
  return (NSArray *)rowList;
}

- (NSArray *)columnList {
  NSMutableArray *columnList;
  int i;
  
  columnList = [NSMutableArray arrayWithCapacity:self->columns];
  for (i = 0; i < self->columns; i++)
    [columnList addObject:[NSNumber numberWithInt:i]];
  
  return (NSArray *)columnList;
}

- (NSString *)valueString {
  NSMutableString *result;
  NSString *s;
  
  if ((self->attributes == nil) || ([self->attributes count] == 0))
    return [self _item];

  if ([self _item] == nil)
    return @"";
  
  result = [NSMutableString stringWithCapacity:128];
  if ((s = [self->attribute objectForKey:@"prefix"])) [result appendString:s];
  if ((s = [self _getValue]))                         [result appendString:s];
  if ((s = [self->attribute objectForKey:@"suffix"])) [result appendString:s];
  return (NSString *)result;
}

- (NSString *)templateValue {
  return [self->itemTemplate
	      stringByReplacingVariablesWithBindings:[self _item]
	      stringForUnknownBindings:@""];
}

/* conditionals */

- (BOOL)isShowChecker {
  if ((int)[self->list count] <= [self _itemIndex])
    return NO;

  return [self->selectedItems isKindOfClass:[NSArray class]];
}

- (void)setIsChecked:(BOOL)_flag {
  BOOL status = (self->selectInverse) ? !_flag : _flag;
  id   myItem = nil;

  myItem = [self _item];

  if (myItem != nil) {
    if (status && ![self->selectedItems containsObject:myItem])
      [self->selectedItems addObject:myItem];
    else if (!status)
      [self->selectedItems removeObject:myItem];
  }
#if DEBUG
  else
    NSLog(@"Warning: SkyListView list has changed");
#endif
}

- (BOOL)isChecked {
  id myItem = [self _item];

  if (myItem == nil) return YES;

  return (self->selectInverse)
    ? ![self->selectedItems containsObject:[self _item]]
    : [self->selectedItems containsObject:[self _item]];
}

- (void)setPopUpSelection:(NSString *)_selection {
  if ([_selection isNotNull]) {
    [self setIsChecked:YES];
    [[self _item] takeValue:_selection forKey:self->popUpValueKey];
  }
  else {
    [[self _item] takeValue:[EONull null] forKey:self->popUpValueKey];
    [self setIsChecked:NO];
  }
}
- (NSString *)popUpSelection {
  NSString *sel = nil;

  sel = [[self _item] valueForKey:self->popUpValueKey];
  if ((![sel isNotNull]) && [self->popUpList count] > 0)
    sel = [self->popUpList objectAtIndex:0];

  return sel;
}

- (NSString *)popUpItemLabel {
  NSString *l;
  
  if (self->labels == nil)
    return self->popUpItem;

  l = [self->labels valueForKey:self->popUpItem];
  return (l != nil) ? l : self->popUpItem;
}

- (void)setIsEmptyChecked:(BOOL)_flag {
  if (_flag == YES)
    [self->selectedItems removeAllObjects];
}
- (BOOL)isEmptyChecked {
  return ([self->selectedItems count] == 0);
}

- (BOOL)isItalicStyle {
  NSString *key = [self->attribute objectForKey:@"key"];

  return ([[key componentsSeparatedByString:@"."] count] > 1) ? YES : NO;
}

/* PrivateMethodes */

- (int)_rows {
  int r = [self->list count] / self->columns;

  return (([self->list count] % self->columns) > 0) ? r+1 : r;
}
- (int)_itemIndex {
  int r   = [self->row    intValue];
  int c   = [self->column intValue];

  return (self->sortHorizontal) ? r*self->columns+c : c*[self _rows]+r;
}
- (int)nilColSpan {
  int attrCount = 0;

  if ((self->attributes != nil) && ([self->attributes count] > 0))
    attrCount = [self->attributes count];
  else
    attrCount = 1;
  
  return (self->columns * attrCount + self->columns - 1);
}
- (id)_item {
  int idx = [self _itemIndex];
  
  return (int)[self->list count] > idx ? [self->list objectAtIndex:idx] : nil;
}

- (NSString *)_getValue {
  // TODO: split up
  id              obj;
  NSString        *key;
  NSArray         *keyList;
  NSEnumerator    *keyEnum;
  NSString        *tmp;

  obj     = [self _item];
  key     = [self->attribute valueForKey:@"key"];

  if (key && [key rangeOfString:@"."].length > 0) {
    keyList = [key componentsSeparatedByString:@"."];
    keyEnum = [keyList objectEnumerator];

    while ((key = [keyEnum nextObject])) {
      obj = [obj valueForKey:key];
    
      if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableString *result = [NSMutableString stringWithCapacity:64];
        int             i, cnt; 

        key = [keyEnum nextObject];

        for (i = 0, cnt = [(NSArray *)obj count]; i < cnt; i++) {
          NSString *s;

          if ((s = [[obj objectAtIndex:i] valueForKey:key]))
            [result appendString:s];
          
          if (i < cnt - 1) {
            s = [self->attribute valueForKey:@"separator"];
            if (s) [result appendString:s];
          }
        }
        return result;
      }
    }
  }
  if (key && [key rangeOfString:@","].length > 0) {
    NSMutableString *result;
    BOOL first = YES;

    result  = [NSMutableString stringWithCapacity:64];
    keyList = [key componentsSeparatedByString:@","];
    keyEnum = [keyList objectEnumerator];

    while ((key = [keyEnum nextObject])) {
      NSString *s = [obj valueForKey:key];

      if (s == nil)
        s = @"";

      if (!first && [s length] > 0) {
        NSString *s;
        
        if ((s = [self->attribute valueForKey:@"separator"]))
          [result appendString:s];
      }
      else
        first = NO;
      
      if (s) [result appendString:s];
    }
    return result;
  }
  
  if (key)
    obj = [obj valueForKey:key];

  if ((tmp = [self->attribute valueForKey:@"binding"]) != nil) {
    WOComponent *parent = [self parent];
    SEL         sel     = NSSelectorFromString(tmp);
    NSString    *result = nil;
    
    if ([parent respondsToSelector:sel]) {
      [self setValue:[self _item] forBinding:@"item"];
      result = [parent performSelector:sel];
      [self setValue:[self item] forBinding:@"item"];
    }
    return (result) ? result : @"";
  }
  if ([obj respondsToSelector:@selector(stringValue)])
    return [obj stringValue];
  return @"";
}

- (NSString *)_createId {
#ifdef __MINGW32__
  static unsigned cid = 0;
  cid++;
  return [NSString stringWithFormat:@"%d", cid];
#else
  return [NSString stringWithFormat:@"%d", random()];
#endif
}

- (BOOL)hasAttributes {
  return !((self->attributes == nil) || ([self->attributes count] == 0));
};
- (BOOL)hasTemplate {
  return (self->itemTemplate != nil && ([self->itemTemplate length] > 0));
}

@end /* SkyListView */
