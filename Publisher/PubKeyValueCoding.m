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

#include "PubKeyValueCoding.h"
#include "common.h"
#include <EOControl/EOKeyGlobalID.h>
#include <OGoDocuments/SkyDocumentFileManager.h>

@implementation NSObject(SKYValueForKey)

- (id)npsValueForKey:(NSString *)_key inContext:(id)_ctx {
  if ([_key isEqualToString:@"self"])
    return self;
  
  return [self valueForKey:_key];
}

- (id)npsValueForKeyPath:(NSString *)_keypath inContext:(id)_ctx {
  NSEnumerator *keys;
  NSString     *key;
  id value;
  
  value = self;
  
  keys = [[_keypath componentsSeparatedByString:@"."] objectEnumerator];
  while ((key = [keys nextObject]) && (value != nil))
    value = [value npsValueForKey:key inContext:_ctx];

  //NSLog(@"npsValueForKeyPath:'%@' -> '%@'", _keypath, value);
  
  return value;
}

- (NSString *)npsStringifyValue:(id)_value inContext:(id)_ctx {
  if (_value == nil)
    return @"";
  if (_value == [NSNull null])
    return @"";
  
  if ([_value isKindOfClass:[EOKeyGlobalID class]])
    return [[_value keyValues][0] stringValue];
  
  if ([_value isKindOfClass:[NSClassFromString(@"SkyDocument") class]])
    return [_value npsStringValueForKey:@"id" inContext:_ctx];
  
  if ([_value isKindOfClass:[NSClassFromString(@"NSBoolNumber") class]])
    return [_value boolValue] ? @"1" : @"0";
  
  return [_value stringValue];
}

- (NSString *)npsStringValueForKey:(NSString *)_key inContext:(id)_ctx {
  return [self npsStringifyValue:
                 [self npsValueForKey:_key inContext:_ctx]
               inContext:_ctx];
}

- (NSString *)npsStringValueForKeyPath:(NSString *)_keypath inContext:(id)_ctx{
  return [self npsStringifyValue:
                 [self npsValueForKeyPath:_keypath inContext:_ctx]
               inContext:_ctx];
}

@end /* NSObject(SKYValueForKey) */
