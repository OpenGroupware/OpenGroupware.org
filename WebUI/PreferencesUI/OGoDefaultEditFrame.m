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

#include <NGObjWeb/WOComponent.h>

@class NSString, NSUserDefaults;

@interface OGoDefaultEditFrame : WOComponent
{
  id componentLabels;
  NSUserDefaults *defaults;
  id value;
  id formatter;
  
  BOOL isEditableValue;
  BOOL isEditableDef;
  BOOL isText;
  BOOL isInViewerMode;

  BOOL localizeValue;

  NSString *useFormatter;
  NSString *key;
}

- (void)setDefaults:(NSUserDefaults *)_d;
- (NSUserDefaults *)defaults;

- (id)value;
- (BOOL)isRoot;

@end /* OGoDefaultEditField */

#include "SimpleTextSepFormatter.h"
#include "ArrayFormatter.h"
#include "BoolFormatter.h"
#include "common.h"

@implementation OGoDefaultEditFrame

- (void)dealloc {
  [self->componentLabels release];
  [self->defaults        release];
  [self->key             release];
  [self->value           release];
  [self->useFormatter    release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  ASSIGN(self->value, nil);
  [super sleep];
}

- (NSString *)oldRootAccess {
  return [@"rootAccess" stringByAppendingString:self->key];
}

- (NSString *)isEditableKey {
  return [@"isEditable_" stringByAppendingString:self->key];
}

/* generate response */

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  if ([self->key isNotEmpty]) {
    id o;
    
    o = [[self defaults] objectForKey:[self isEditableKey]];

    if (o == nil)
      o = [[self defaults] objectForKey:[self oldRootAccess]];

    self->isEditableValue = (o != nil) ? [o boolValue] : self->isEditableDef;
  }
  [super appendToResponse:_response inContext:_ctx];
}

/* handle requests */

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  BOOL oldIsEditable;

  oldIsEditable = self->isEditableValue;

  [super takeValuesFromRequest:_req inContext:_ctx];

  if (oldIsEditable != self->isEditableValue) {
    [self->defaults setObject:[NSNumber numberWithBool:self->isEditableValue]
         forKey:[self isEditableKey]];
  }
}

/* value */

- (void)setValue:(id)_v {
  ASSIGN(self->value, _v);
}
- (id)value {
  if (![self->key isNotEmpty]) {
    NSLog(@"missing key ...");
    return nil;
  }
  if (self->value == nil)
    self->value = [[self->defaults valueForKey:self->key] retain];

  return self->value;
}

/* permissions */

- (BOOL)isEditable {
  return ((self->isEditableValue || [self isRoot]) &&
          !self->isInViewerMode);
}

- (void)setIsEditableValue:(BOOL)_b {
  self->isEditableValue = _b;
}
- (BOOL)isEditableValue {
  return self->isEditableValue;
}

- (NSString *)readOnlyValue {
  if (self->localizeValue)
    return [self->componentLabels valueForKey:[[self value] stringValue]];

  return [self value];
}

- (NSString *)defaultLabel {
  return [self->componentLabels valueForKey:self->key];
}

/* accessors */

- (void)setFormatter:(id)_form {
  ASSIGN(self->formatter, _form);
}
- (id)formatter {
  if (self->formatter == nil && [self->useFormatter isNotEmpty]) {
    if ([self->useFormatter isEqualToString:@"stringField"])
      self->formatter = [[SimpleTextSepFormatter alloc] init];
    else if ([self->useFormatter isEqualToString:@"array"])
      self->formatter = [[ArrayFormatter alloc] init];
    else if ([self->useFormatter isEqualToString:@"bool"])
      self->formatter = [[BoolFormatter alloc] initWithLables:[self labels]];
  }
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

/* actions */

- (id)resetEditable {
  [self->defaults removeObjectForKey:[self isEditableKey]];
  [self->defaults removeObjectForKey:[self oldRootAccess]];
  [self->defaults synchronize];
  self->isEditableValue = NO;
  return nil;
}

- (id)resetValue {
  [self->defaults removeObjectForKey:self->key];
  [self->defaults synchronize];
  ASSIGN(self->value, nil);
  return nil;
}

- (BOOL)isEditableDef {
  return self->isEditableDef;
}
- (void)setIsEditableDef:(BOOL)_i {
  self->isEditableDef = _i;
}

- (BOOL)isRoot {
  return [[self session] activeAccountIsRoot];
}

- (void)setLocalizeValue:(BOOL)_b {
  self->localizeValue = _b;
}
- (BOOL)localizeValue {
  return self->localizeValue;
}

- (BOOL)isText {
  return self->isText;
}
- (void)setIsText:(BOOL)_b {
  self->isText = _b;
}

- (BOOL)isInViewerMode {
  return  self->isInViewerMode;
}
- (void)setIsInViewerMode:(BOOL)_v {
  self->isInViewerMode = _v;
}

- (void)setUseFormatter:(NSString *)_s {
  ASSIGN(self->useFormatter, _s);
}
- (NSString *)useFormatter {
  return self->useFormatter;
}

@end /* OGoDefaultEditField */
