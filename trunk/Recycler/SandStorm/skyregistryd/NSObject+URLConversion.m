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

#include "NSObject+URLConversion.h"
#include "common.h"

@implementation NSObject(URLConversion)

- (NSURL *)asURL {
  NSString *tmp;

  tmp = [self stringValue];
  if ([tmp length] > 0) {
    return [NSURL URLWithString:tmp];
  }
  return nil;
}

@end /* NSObject(URLConversion) */

@implementation NSDictionary(URLConversion)

- (NSURL *)asURL {
  NSMutableString *ms;
  id v;
        
  ms = [NSMutableString stringWithCapacity:128];
        
  v = [self objectForKey:@"scheme"];
  [ms appendString:(v ? [v stringValue] : @"http")];
  [ms appendString:@"://"];
        
  v = [self objectForKey:@"host"];
  [ms appendString:(v ? [v stringValue] : @"localhost")];
        
  if ((v = [self objectForKey:@"port"])) {
    [ms appendString:@":"];
    [ms appendString:[v stringValue]];
  }
        
  v = [[self objectForKey:@"uri"] stringValue];
  [ms appendString:([v length] > 0) ? v : @"/RPC2"];
        
  return [NSURL URLWithString:ms];
}

@end /* NSDictionary(URLConversion) */

@implementation NSURL(URLConversion)

- (NSURL *)asURL {
  return self;
}

@end /* NSURL(URLConversion) */

