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

#include "NSObject+EKVC.h"
#include "common.h"

@implementation NSObject(EKVC)

- (void)takeValuesFromObject:(id)_object keys:(NSString *)_key, ... {
  va_list  list;
  NSString *key;
  
  va_start(list, _key);
  for (key = _key; key; key = va_arg(list, NSString *)) {
    id value;
    
    value = [_object valueForKey:key];
    if (value != nil) {
      if ([[value stringValue] length] > 0)
        [self takeValue:value forKey:key];
    }
  }
  va_end(list);
}

@end /* NSObject(EKVC) */

@implementation NSMutableDictionary(EKVC)

- (void)removeAllNulls {
  // TODO: what is this supposed to do?
  static Class NullClass = Nil;
  NSDictionary *dummy   = nil;
  NSEnumerator *keyEnum = nil;
  NSString     *key;

  if (NullClass == Nil)
    NullClass = [EONull class];

  dummy   = [[NSDictionary alloc] initWithDictionary:self]; // TODO: release?
  keyEnum = [dummy keyEnumerator];
  
  while ((key = [keyEnum nextObject])) {
    if (([[dummy objectForKey:key] isKindOfClass:NullClass]))
      [self removeObjectForKey:key];
  }
}

@end /* NSMutableDictionary */
