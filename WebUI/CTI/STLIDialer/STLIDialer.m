/*
  Copyright (C) 2000-2006 SKYRIX Software AG

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

@interface STLIDialer : NSObject
@end

#include "STLIConnection.h"

@implementation STLIDialer

- (NSString *)cleanupNumber:(NSString *)_number {
  NSDictionary *prefixMappings;
  NSEnumerator *prefixes;
  NSString     *prefix;

  prefixMappings = [[NSUserDefaults standardUserDefaults]
                                    dictionaryForKey:@"STLIDialerPrefixMap"];
  
  _number = [_number stringByReplacingString:@" " withString:@""];
  _number = [_number stringByReplacingString:@"-" withString:@""];

#if 0
  // first sort based on prefix length !!!
  prefixes = [prefixMappings keyEnumerator];
  while ((prefix = [prefixes nextObject])) {
    if ([_number hasPrefix:prefix]) {
      _number = [_number substringFromIndex:[prefix length]];
      _number = [[prefixMappings objectForKey:prefix]
                                 stringByAppendingString:_number];
      break;
    }
  }
#endif
  
#warning need prefix mapping table here ...
  if ([_number hasPrefix:@"+493916623"])
    _number = [_number substringFromIndex:10];
  else if ([_number hasPrefix:@"+49"]) {
    _number = [_number substringFromIndex:3];
    _number = [@"00" stringByAppendingString:_number];
  }
  else
    _number = nil;
  
  return _number;
}

- (BOOL)canDialNumber:(NSString *)_number {
  _number = [self cleanupNumber:_number];
  return [_number length] > 0 ? YES : NO;
}

- (BOOL)dialNumber:(NSString *)_number fromDevice:(NSString *)_device {
  STLIConnection *stli;
  BOOL ok;
  
  ok = YES;

  _number = [self cleanupNumber:_number];
  if ([_number length] == 0)
    return NO;
  
  stli = [[STLIConnection alloc] init];
  if (![stli startMonitoringDevice:_device]) {
    NSLog(@"%s: couldn't monitor device '%@': %@",
          __PRETTY_FUNCTION__, _device, [stli lastException]);
    [stli bye];
    RELEASE(stli);
    ok = NO;
    return NO;
  }
  
  /* place call */

#if DEBUG
  NSLog(@"STLIDialer: will dial '%@' from device '%@'",
        _number, _device);
#endif
  
  ok = [stli makeCallFromLocalDevice:_device
             toDevice:_number];
  
  /* tear down */
  
  [stli stopMonitoringDevice:_device];
  [stli bye];
  RELEASE(stli);
  
  return ok;
}

@end /* STLIDialer */
