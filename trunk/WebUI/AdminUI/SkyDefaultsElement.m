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

#include "SkyDefaultsElement.h"
#include "common.h"

@implementation SkyDefaultsElement

- (id)initWithDictionary:(NSDictionary *)_dict
  forLanguage:(NSString *)_language
  withValue:(id)_value
{
  if ((self = [super init])) {
    NSDictionary *langDict;
    id           tmp;
    
    self->name = [[_dict valueForKey:@"name"] retain];

    if (_value != nil)
      self->value = [_value retain];

    self->type = ((tmp = [_dict valueForKey:@"type"]) != nil)
      ? [tmp retain]
      : @"string";

    if ((tmp = [_dict valueForKey:@"values"]) != nil)
      self->predefinedValues = [tmp retain];

    self->valueSeperator   = [[_dict valueForKey:@"valueSeperator"] copy];
    self->flags.isCritical = [[_dict valueForKey:@"critical"] boolValue];
    self->flags.isPassword = [[_dict valueForKey:@"password"] boolValue];
    self->flags.isTextArea = [[_dict valueForKey:@"isTextArea"] boolValue];
    
    if ((langDict = [_dict valueForKey:_language]) != nil) {
      self->title = [[langDict valueForKey:@"title"] retain];
      self->info  = [[langDict valueForKey:@"info"]  retain];
    }
    else {
      [self logWithFormat:@"Couldn't initialize element for language '%@'",
            _language];
      [self release];
      return nil;
    }

    if ((self->rows = [[_dict valueForKey:@"rows"] intValue]) == 0)
      self->rows = 10;
    
    if ((self->cols = [[_dict valueForKey:@"cols"] intValue]) == 0)
      self->cols = 60;
  }
  return self;
}

+ (SkyDefaultsElement *)elementWithDictionary:(NSDictionary *)_dict
  forLanguage:(NSString *)_language
  withValue:(id)_value
{
  return [[[self alloc] initWithDictionary:_dict forLanguage:_language
                        withValue:_value] autorelease];
}

- (void)dealloc {
  [self->name             release];
  [self->title            release];
  [self->info             release];
  [self->type             release];
  [self->value            release];
  [self->predefinedValues release];
  [self->valueSeperator   release];
  [super dealloc];
}

/* accessors */

- (NSString *)name {
  return self->name;
}

- (NSString *)title {
  return self->title;
}

- (NSString *)info {
  return self->info;
}

- (NSString *)type {
  return self->type;
}

- (BOOL)isCritical {
  return self->flags.isCritical ? YES : NO;
}
- (BOOL)isPassword {
  return self->flags.isPassword ? YES : NO;
}
- (BOOL)isTextArea {
  return self->flags.isTextArea ? YES : NO;
}


- (void)setValue:(id)_value {
  if (_value == nil)
    _value = @"";
  
  ASSIGN(self->value, _value);
}
- (id)value {
  return self->value;
}

- (NSArray *)predefinedValues {
  return self->predefinedValues;
}

- (NSString *)valueSeperator {
  return self->valueSeperator;
}

- (int)rows {
  return self->rows;
}

- (int)cols {
  return self->cols;
}

@end /* SkyDefaultsElement */
