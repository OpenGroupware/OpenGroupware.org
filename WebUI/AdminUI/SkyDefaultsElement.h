/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#ifndef __AdminUI_SkyDefaultsElement_H__
#define __AdminUI_SkyDefaultsElement_H__

#import <Foundation/NSObject.h>

/*
  SkyDefaultsElement

  TODO: document, what is this good for?
*/

@class NSString, NSDictionary, NSArray;

@interface SkyDefaultsElement : NSObject
{
@private
  NSString *name;
  NSString *title;
  NSString *info;
  NSString *type;
  NSString *valueSeperator;
  NSArray  *predefinedValues;

  id value;
  struct { // TODO: make it a real bitset ...
    BOOL isCritical;
    BOOL isPassword;
    BOOL isTextArea;
  } flags;

  int rows;
  int cols;
}

+ (SkyDefaultsElement *)elementWithDictionary:(NSDictionary *)_dict
  forLanguage:(NSString *)_language
  withValue:(id)_value;

/* accessors */

- (NSString *)name;
- (NSString *)title;
- (NSString *)info;
- (NSString *)type;
- (BOOL)isCritical;
- (BOOL)isPassword;
- (BOOL)isTextArea;
- (NSArray *)predefinedValues;

- (void)setValue:(id)_value;
- (id)value;

- (NSString *)valueSeperator;
- (int)rows;
- (int)cols;

@end /* SkyDefaultsElement */

#endif /* __AdminUI_SkyDefaultsElement_H__ */
