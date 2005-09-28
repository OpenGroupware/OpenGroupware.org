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
  OGoDefaultEditField

  componentLabels - the label manager of the current bundle
  defaults        - the userdefaults ([defaults synchronize] must be called
                    during save)
  formatter       - a formatter for displaying values
  isEditableDef   - def. is editable or not if no access-default is set
  localizeValue   - display the value as it is or use
                    [componentLabels valueForKey:value]

  valueType       - string, text, password, checkbox, popup
  key             - the default key

  valueList       - valuelist if type is 'popup'
  rows, cols      - rows and cols if type is string or checkbox
*/

#include <NGObjWeb/WOComponent.h>

@class NSString, NSUserDefaults, NSFormatter;

@interface OGoDefaultEditField : WOComponent
{
  enum {
    DefEdit_IsString,
    DefEdit_IsText,
    DefEdit_IsPassword,
    DefEdit_IsCheckBox,
    DefEdit_IsPopup
  } type;
  
  id             componentLabels;
  NSUserDefaults *defaults;
  id             value;
  id             item;
  NSFormatter    *formatter;
  
  struct {
    int isEditable:1;
    int isEditableDef:1;
    int localizeValue:1;
    int spare:29;
  } flags;
  
  NSString *useFormatter;

  NSString *valueType;
  NSString *key;
  NSArray  *valueList;

  int rows;
  int cols;
}

- (void)setDefaults:(NSUserDefaults *)_d;
- (NSUserDefaults *)defaults;

- (id)value;
- (BOOL)isRoot;

@end /* OGoDefaultEditField */

#include "common.h"

@implementation OGoDefaultEditField

- (void)dealloc {
  [self->formatter       release];
  [self->componentLabels release];
  [self->defaults        release];
  [self->valueList       release];
  [self->key             release];
  [self->value           release];
  [self->useFormatter    release];

  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self->value release]; self->value = nil;
  [super sleep];
}

/* handle request */

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  id oldValue, v;

  oldValue = [[self value] copy];
  if (![oldValue isNotNull])
    oldValue = @"";
  
  [super takeValuesFromRequest:_req inContext:_ctx];
  
  if (self->defaults == nil) {
    [self logWithFormat:@"ERROR(%s): Missing defaults object!", 
            __PRETTY_FUNCTION__];
    return;
  }
  v = [self value];

  if (![v isNotNull])
    v = @"";
  
  if (![[oldValue stringValue] isEqual:[v stringValue]])
    [self->defaults setObject:v forKey:self->key];
  
  [oldValue release]; oldValue = nil;
  [self->value release]; self->value = nil;
}

- (id)value {
  if (![self->key isNotEmpty]) {
    [self logWithFormat:@"missing key ..."];
    return nil;
  }
  if (self->value == nil)
    self->value = [[self->defaults valueForKey:self->key] retain];

  return self->value;
}

- (void)setValue:(id)_v {
  ASSIGN(self->value, _v);
}

- (BOOL)isText {
  return (self->type == DefEdit_IsText) ? YES : NO;
}
- (BOOL)isPopUp {
  return (self->type == DefEdit_IsPopup) ? YES : NO;
}
- (BOOL)isCheckBox {
  return (self->type == DefEdit_IsCheckBox) ? YES : NO;
}
- (BOOL)isPassword {
  return (self->type == DefEdit_IsPassword) ? YES : NO;
}
- (BOOL)isString {
  return (self->type == DefEdit_IsString) ? YES : NO;
}

- (NSString *)popupLabel {
  return [self->componentLabels valueForKey:[self->item stringValue]];
}

/* accessors */

- (void)setFormatter:(NSFormatter *)_form {
  ASSIGN(self->formatter, _form);
}
- (NSFormatter *)formatter {
  return self->formatter;
}

- (void)setComponentLabels:(id)_l {
  ASSIGN(self->componentLabels, _l);
}
- (id)componentLabels {
  return self->componentLabels;
}

- (void)setKey:(id)_k {
  ASSIGN(self->key, _k);
}
- (id)key {
  return self->key;
}

- (void)setDefaults:(NSUserDefaults *)_d {
  ASSIGN(self->defaults, _d);
}
- (NSUserDefaults *)defaults {
  return self->defaults;
}

- (void)setItem:(id)_d {
  ASSIGN(self->item, _d);
}
- (id)item {
  return self->item;
}

- (void)setValueList:(id)_v {
  ASSIGN(self->valueList, _v);
}
- (id)valueList {
  return self->valueList;
}

- (int)typeForValueType:(NSString *)_t {
  if ([_t isEqualToString:@"popup"])
    return DefEdit_IsPopup;
  if ([_t isEqualToString:@"text"])
    return DefEdit_IsText;
  if ([_t isEqualToString:@"string"])
    return DefEdit_IsString;
  if ([_t isEqualToString:@"checkbox"])
    return DefEdit_IsCheckBox;
  if ([_t isEqualToString:@"password"])
    return DefEdit_IsPassword;

  [self logWithFormat:@"%s: unsupported type: %@", __PRETTY_FUNCTION__, _t];
  return DefEdit_IsString;
}

- (void)setValueType:(NSString *)_t {
  if ([self->valueType isEqual:_t])
    return;
  
  self->type = [self typeForValueType:_t];
  ASSIGN(self->valueType, _t);
}
- (NSString *)valueType {
  return self->valueType;
}

- (void)setRows:(int)_i {
  self->rows = _i;
}
- (int)rows {
  if (self->rows == 0)
    return 30;
  
  return self->rows;
}

- (void)setCols:(int)_i {
  self->cols = _i;
}
- (int)cols {
  if (self->cols == 0)
    return 10;
  
  return self->cols;
}

- (void)setLocalizeValue:(BOOL)_b {
  self->flags.localizeValue = _b ? 1 : 0;
}
- (BOOL)localizeValue {
  return self->flags.localizeValue ? YES : NO;
}

- (void)setIsEditableDef:(BOOL)_i {
  self->flags.isEditableDef = _i ? 1 : 0;
}
- (BOOL)isEditableDef {
  return self->flags.isEditableDef ? YES : NO;
}

- (void)setIsEditable:(BOOL)_i {
  self->flags.isEditable = _i ? 1 : 0;
}
- (BOOL)isEditable {
  return self->flags.isEditable ? YES : NO;
}

- (BOOL)isRoot {
  return [[self session] activeAccountIsRoot];
}

- (void)setUseFormatter:(NSString *)_s {
  ASSIGNCOPY(self->useFormatter, _s);
}
- (NSString *)useFormatter {
  return self->useFormatter;
}

@end /* OGoDefaultEditField */
