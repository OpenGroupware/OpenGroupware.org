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

#include "NSString+XMLNamespaces.h"
#include "common.h"

@implementation NSString(XMLNamespaces) 

- (BOOL)hasXMLNamespace {
  return [self characterAtIndex:0] == '{';
}

- (NSString *)xmlNamespace {
  NSRange r;
  
  if ([self characterAtIndex:0] != '{')
    return nil;
  
  r = [self rangeOfString:@"}"];
  if (r.length == 0)
    return nil;
  
  r.length   = r.location - 1;
  r.location = 1;
  return [self substringWithRange:r];
}

- (NSString *)stringByRemovingXMLNamespace {
  NSRange r;
  
  r = [self rangeOfString:@"}"];
  if (r.length == 0)
    return self;
  if (r.location >= ([self length] + 1))
    return nil;
  
  return [self substringFromIndex:(r.location + 1)];
}

- (NSString *)stringBySettingXMLNamespace:(NSString *)_str {
  // TODO: slow and unicode unsafe
  if (![self hasXMLNamespace]) {
    int  len = [_str cStringLength] + [self cStringLength] + 3;
    char buf[len];
    
    sprintf(buf, "{%s}%s", [_str cString], [self cString]); // UNICODE
    return [NSString stringWithCString:buf length:len];
  }
  NSLog(@"ERROR[%s]: string has already an XML namespace set: '%@'", 
	__PRETTY_FUNCTION__, _str);
  return _str;
}

@end /* NSString(Namespaces) */
