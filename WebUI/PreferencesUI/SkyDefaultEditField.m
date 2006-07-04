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

#include "common.h"

#define DEF_POPUP     1
#define DEF_STRING    2
#define DEF_TEXT      3
#define DEF_CHECKBOX  4
#define DEF_PASSWD    5

@interface SkyDefaultEditField : WOComponent
{
  //  NSDictionary *labels;
  int valueType;
  id  value;
  id  item;
}

@end

@implementation SkyDefaultEditField

- (void)dealloc {
  [self->item  release];
  [self->value release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  /* release cached bindings */
  self->valueType = 0;
  [self->item  release]; self->item  = nil;
  [self->value release]; self->value = nil;
  [super sleep];
}

/* accessors */

- (BOOL)synchronizesVariablesWithBindings {
  return NO;
}

- (BOOL)isEditable {
  return [[self valueForBinding:@"isEditable"] boolValue];
}

- (id)labels {
  return [self valueForBinding:@"labels"];
}

- (int)valueType {
  NSString *key;
  
  if (self->valueType > 0)
    return self->valueType;

  key = [self valueForBinding:@"valueType"];

  if ([key hasPrefix:@"popup"])
    self->valueType = DEF_POPUP;
  else if ([key hasPrefix:@"text"])
    self->valueType = DEF_TEXT;
  else if ([key hasPrefix:@"checkbox"])
    self->valueType = DEF_CHECKBOX;
  else if ([key hasPrefix:@"passwd"])
    self->valueType = DEF_PASSWD;
  else if ([key hasPrefix:@"int"])
    self->valueType = DEF_STRING;
  else
    self->valueType = DEF_STRING;

  return self->valueType;
}

- (BOOL)isCheckBox {
  return [self valueType] == DEF_CHECKBOX ? YES : NO;
}
- (BOOL)isText {
  return [self valueType] == DEF_TEXT ? YES : NO;
}
- (BOOL)isPopUp {
  return [self valueType] == DEF_POPUP ? YES : NO;
}
- (BOOL)isString {
  return [self valueType] == DEF_STRING ? YES : NO;
}
- (BOOL)isPasswd {
  return [self valueType] == DEF_PASSWD ? YES : NO;
}

/* values */

- (void)setValue:(id)_value {
  if ([self isEditable])
    [self setValue:_value forBinding:@"value"];
}
- (id)value {
  if (self->value)
    return self->value;
  
  self->value = RETAIN([self valueForBinding:@"value"]);

  return self->value;
}

- (void)setDefPopUpValue:(id)_value {
  [self setValue:_value];
}
- (id)defPopUpValue {
  return [self value];
}

- (void)setDefTextValue:(NSString *)_value {
  [self setValue:_value];
}
- (NSString *)defTextValue {
  return [self value];
}

- (void)setDefStringValue:(NSString *)_value {
  [self setValue:_value];
}
- (NSString *)defStringValue {
  return [self value];
}

- (void)setDefCheckBoxValue:(BOOL)_flag {
  [self setValue:[NSNumber numberWithBool:_flag]];
}
- (BOOL)defCheckBoxValue {
  return [[self value] boolValue];
}

- (NSString *)readOnlyValue {
  id l = [self labels];
  
  switch ([self valueType]) {
    case DEF_POPUP:
      return l ? [l valueForKey:[self value]] : [self value];
      
    case DEF_CHECKBOX:
      return [[self labels] valueForKey:
			      [self defCheckBoxValue] ? @"YES":@"NO"];
        
    case DEF_STRING:
    case DEF_TEXT:
    default:
      return [self value];
  }
}

/* item */

- (void)setItem:(id)_i {
  ASSIGN(self->item, _i);
}
- (id)item {
  return self->item;
}

/* labels */

- (NSString *)itemLabel {
  NSString *i;
  id l;
  
  i = [[self item] stringValue]; // Note: required on OSX 10.3
  l = [self labels];
  return l != nil ? (NSString *)[l valueForKey:i] : i;
}

@end /* SkyDefaultEditField */
