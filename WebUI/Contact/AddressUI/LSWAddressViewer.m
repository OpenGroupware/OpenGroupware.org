/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#include <OGoFoundation/LSWContentPage.h>

@class SkyAddressDocument;

@interface LSWAddressViewer : LSWContentPage
{
@protected
  SkyAddressDocument *address;
  BOOL               isEditEnabled;
}
@end

#include "common.h"
#include <OGoContacts/SkyAddressDocument.h>

@implementation LSWAddressViewer

- (void)dealloc {
  [self->address release];
  [super dealloc];
}

/* public accessors */

- (void)setAddress:(id)_address {
  ASSIGN(self->address, _address);
}
- (SkyAddressDocument *)address {
  return self->address;
}

- (void)setIsEditEnabled:(BOOL)_flag {
  self->isEditEnabled = _flag;
}
- (BOOL)isEditEnabled {
  return self->isEditEnabled;
}

/* accessors */

- (NSString *)title {
  NSString *type;
  NSString *key;
  NSString *result;
  
  type   = [self->address type];
  key    = [@"addresstype_" stringByAppendingString:type];
  result = [[self labels] valueForKey:key];
  
  return (result != nil) ? result : type;
}

/* actions */

- (id)edit {
  return [self activateObject:self->address withVerb:@"edit"];
}

- (NSString *)addressFormat {
  NSString *format;
  static NSString *defaultFormat = nil;

  if (defaultFormat == nil) {
    defaultFormat =
      @"$name1$ $name2$ $name3$\\r\\n"
      @"$street$\\r\\n"
      @"$zip$ $city$\\r\\n"
      @"$country$\\r\\n";
    [defaultFormat retain];
  }

  format = [[[self session] userDefaults]
                   objectForKey:@"address_clipboard_format"];
  return [format length] > 0 ? format : defaultFormat;
}

- (NSDictionary *)addressBinding {
  NSMutableDictionary *md;
  SkyAddressDocument *a;
  id tmp;

  a = [self address];
  md = [NSMutableDictionary dictionaryWithCapacity:9];
  
  if ((tmp = [a name1])   != nil) [md setObject:tmp forKey:@"name1"];
  if ((tmp = [a name2])   != nil) [md setObject:tmp forKey:@"name2"];
  if ((tmp = [a name3])   != nil) [md setObject:tmp forKey:@"name3"];
  if ((tmp = [a street])  != nil) [md setObject:tmp forKey:@"street"];
  if ((tmp = [a zip])     != nil) [md setObject:tmp forKey:@"zip"];
  if ((tmp = [a city])    != nil) [md setObject:tmp forKey:@"city"];
  if ((tmp = [a country]) != nil) [md setObject:tmp forKey:@"country"];
  if ((tmp = [a state])   != nil) [md setObject:tmp forKey:@"state"];
  if ((tmp = [a type])    != nil) [md setObject:tmp forKey:@"type"];
  return md;
}

- (NSString *)addressString {
  return [[self addressFormat] stringByReplacingVariablesWithBindings:
				 [self addressBinding]
                               stringForUnknownBindings:@""];
}

@end /* LSWAddressViewer */
