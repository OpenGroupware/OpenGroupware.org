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

#include <OGoFoundation/OGoComponent.h>

@class NSString, NSArray;

@interface SkyAptTypeSelection : OGoComponent
{
  NSString *selection;

  NSArray  *aptTypes;
  id       item;
  NSString *inputType;
  int      itemIndex;
}

@end /* SkyAptTypeSelection */

#include "common.h"

@implementation SkyAptTypeSelection

- (void)dealloc {
  [self->aptTypes release];
  [self->item     release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self->aptTypes  release]; self->aptTypes  = nil;
  [self->inputType release]; self->inputType = nil;
  [super sleep];
}

/* accessors */

- (void)setSelection:(NSString *)_sel {
  ASSIGN(self->selection, _sel);
}
- (NSString *)selection {
  return self->selection;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item,_item);
}
- (id)item {
  return self->item;
}

- (void)setItemIndex:(int)_idx {
  self->itemIndex = _idx;
}
- (int)itemIndex {
  return self->itemIndex;
}

/* apt types list */

- (id)defaults {
  return [[self session] userDefaults];
}

- (NSString *)inputType {
  if (self->inputType == nil) {
    self->inputType =
      [[[self defaults] stringForKey:@"scheduler_apttype_input_type"] copy];
    if (self->inputType == nil)
      self->inputType = @"Icons";
  }
  return self->inputType;
}

- (NSArray *)defaultAppointmentTypes {
  return [[self defaults] arrayForKey:@"SkyScheduler_defaultAppointmentTypes"];
}
- (NSArray *)customAppointmentTypes {
  return [[self defaults] arrayForKey:@"SkyScheduler_customAppointmentTypes"];
}

- (NSArray *)configuredAptTypes {
  NSArray *configured;
  NSArray *custom;
  
  if ((configured = [self defaultAppointmentTypes]) == nil)
    configured = [NSArray array];
  
  if ((custom = [self customAppointmentTypes]))
    configured = [configured arrayByAddingObjectsFromArray:custom];
  
  return configured;
}
- (NSArray *)aptTypes {
  if (self->aptTypes == nil)
    self->aptTypes = [[self configuredAptTypes] retain];
  
  return self->aptTypes;
}


- (BOOL)hasAptTypes {
  return ([[self aptTypes] count] > 0) ? YES : NO;
}

- (NSString *)aptTypeLabel {
  NSString *label;

  if ((label = [self->item valueForKey:@"label"]))
    return label;
  
  label = [self->item valueForKey:@"type"];
  label = [NSString stringWithFormat:@"aptType_%@",label];
  label = [[self labels] valueForKey:label];
  return label;
}


/* aptType selection */

- (void)setAptTypeSelection:(id)_type {
  NSString *key;

  key = [_type valueForKey:@"type"];
  key = [key isNotNull]
     ? ([key isEqualToString:@"none"] ? nil : key)
    : nil;

  [self setSelection:key];
}

- (id)aptTypeSelection {
  NSEnumerator *e;
  id           one;
  NSString     *wanted;

  e      = [[self aptTypes] objectEnumerator];
  wanted = [self selection];

  while ((one = [e nextObject])) {
    NSString *key;

    key    = [one valueForKey:@"type"];
    
    if ((![wanted isNotEmpty]) && [key isEqualToString:@"none"])
      return one;
    if ([wanted isEqualToString:key])
      return one;
  }
  return nil;
}

/* button selection */
#if 0
- (void)setButtonSelected:(BOOL)_flag {
  if (_flag) 
    [self setAptTypeSelection:self->item];
}
- (BOOL)buttonSelected {
  NSString *wanted;
  NSString *key;

  key    = [self->item valueForKey:@"type"];
  wanted = [self selection];

  if ((![wanted isNotEmpty]) && [key isEqualToString:@"none"])
    return YES;
  if ([wanted isEqualToString:key])
    return YES;
  
  return NO;
}
#endif

- (NSString *)buttonValue {
  return [self->item valueForKey:@"type"];
}

- (void)setSelectedButton:(NSString *)_button {
  [self setSelection:[_button isEqualToString:@"none"] ? nil : _button];
}
- (NSString *)selectedButton {
  NSString *sel;
  
  sel = [self selection];
  return [sel isNotEmpty] ? sel : @"none";
}

- (NSString *)aptTypeImageFilename {
  NSString *icon;
  
  icon = [self->item valueForKey:@"icon"];
  return [icon isNotEmpty] ? icon : @"apt_icon_default.gif";
}

- (NSString *)jsScriptOnClick {
  char buf[128];
  
  snprintf(buf, sizeof(buf), "javascript:selectAptType(%d)", [self itemIndex]);
  return [NSString stringWithCString:buf];
}

@end /* SkyAptTypeSelection */
