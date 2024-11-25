/*
  Copyright (C) 2024 Helge Heß

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

/**
 * 2024-11-21(hh)
 * Those overrides are necessary for non-libFoundation libraries, because KVC
 * on dictionaries is implemented slightly different,
 * and OGo relies on it.
 * In lF `-valueForKey:` on `NSDictionary` returns `nil` if the dictionary
 * value is `NSNull`. While Apple/GNUstep Foundation returns the `NSNull`.
 *
 * lF *does* allow `NSNull` in `-takeValue:forKey:`, it even rewrites `nil` to 
 * `NSNull`.
 *
 * Note: GNUstep seems to support `-takeValue:forKey:`, but the new API
 *       is `-setValue:forKey:`!
 */

#if !LIB_FOUNDATION_LIBRARY

#include <EOControl/EOControl.h>
#include "common.h"

@implementation NSNull(NSKeyValueCoding)
- (void)takeValue:(id)_value forKey:(NSString *)_key {
  NSLog(@"Attempt to call takeValue:forKey:%@ on NSNull", _key);
}
- (void)takeStoredValue:(id)_value forKey:(NSString *)_key {
  NSLog(@"Attempt to call takeStoredValue:forKey:%@ on NSNull", _key);
}
// GNUstep does this in `-valueForUndefinedKey:`
- (id)valueForKey:(NSString *)_key { return nil; }
@end

@implementation NSDictionary(NSKeyValueCoding)

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  NSLog(@"Attempt to call takeValue:forKey:%@ on immutable NSDictionary", _key);
}
- (void)takeStoredValue:(id)_value forKey:(NSString *)_key {
  NSLog(@"Attempt to call takeStoredValue:forKey:%@ on immutable NSDictionary",
        _key);
}

- (id)valueForKey:(NSString *)_key {
  // Note: The string key is a lie, in OGo it is sometimes (and incorrectly)
  //       used as a more general `-objectForKey:` where the key is `id`.
  //       Those should be fixed.
  // E.g. `LSGetSessionLogsForGlobalIDs` does this w/ EOKeyGlobalID's
  id obj;
  
  if (_key == nil)
    return nil;
  
  // Note: Different behaviour for `@` keys!
  if ((obj = [self objectForKey:_key]) != nil) {
    static NSNull *null = nil;  
    if (null == nil) null = [NSNull null]; // Note: not thread-safe.
    if (obj == null) return nil;
    return obj;
  }
  
  if ([key isKindOfClass:[NSString class]] && [_key hasPrefix: @"@"])
    return [super valueForKey:[_key substringFromIndex:1]];

  return nil;
}

@end

@implementation NSMutableDictionary(NSKeyValueCoding)

- (void)takeValuesFromDictionary:(NSDictionary*)dictionary {
  [self addEntriesFromDictionary:dictionary];
}

// TBD: do we need takeStoredValue:forKey:?
// TBD: Do we need setValue:forKey:? Or do we assume new API usage implies
//      current behaviour. Probably.

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  // GNUstep *removes* the value!
  if (_value == nil) _value = [NSNull null];
  [self setObject:_value forKey:_key];
}

@end

#endif // !LIB_FOUNDATION_LIBRARY
