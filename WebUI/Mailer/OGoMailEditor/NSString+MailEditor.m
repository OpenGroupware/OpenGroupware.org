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

#include "NSString+MailEditor.h"
#include "common.h"
#include <NGExtensions/NSString+Ext.h>

@implementation NSString(MailEditor)

- (NSString *)shortened:(unsigned int)_length {
  NSString *s;
  
  if (([self length] <= _length) || ([self length] <= 4))
    return self;
  
  s = [self substringToIndex:_length-2];
  s = [s stringByAppendingString:@".."];
  return s;
}

- (NSString *)mailWrappedStringWithLength:(int)_wrapLen
  wrapLongLines:(BOOL)wrapLongLines
{
  NSString *str = self;
  
  if (_wrapLen == 0) _wrapLen = 10000;
  
  // wrap long lines
  if ((_wrapLen != -1) && ([str length] > _wrapLen)) {
    NSArray         *lines;
    NSMutableString *wrapped;
    int             cnt, numLines;
    
    wrapped       = [NSMutableString stringWithCapacity:[str length]];
    lines         = [str componentsSeparatedByString:@"\r"];
    str           = [lines componentsJoinedByString:@""];
    lines         = [str componentsSeparatedByString:@"\n"];
    numLines      = [lines count];

    for (cnt = 0; cnt < numLines; cnt++) {
      str = [lines objectAtIndex:cnt];
      
      if (cnt != 0)
        [wrapped appendString:@"\n"];

      if ([str length] > _wrapLen) {
        do {
          int len;
          BOOL noSpaces;

          len      = _wrapLen;
          noSpaces = NO;

          while (len > 0) {
            if ([str characterAtIndex:len] == ' ') {
              break;
            }
            len--;
          }
          if (len == 0) {
            if (wrapLongLines) {
              len      = _wrapLen;
              noSpaces = YES;
            }
            else {
              int l   = [str length];

              len = _wrapLen;
              while (len < l) {
                if ([str characterAtIndex:len] == ' ') {
                  break;
                }
                len++;
              }
              if (len == l)
                noSpaces = YES;
            }
          }          
          
          [wrapped appendString:[str substringToIndex:len]];
          [wrapped appendString:@"\n"];
          /* ignore leading space */
          str = [str substringFromIndex:(noSpaces) ? len : len + 1];
        }
        while ([str length] > _wrapLen);
        [wrapped appendString:str];
      }
      else {
        [wrapped appendString:str];
      }
    }
    str = wrapped;
  }
  if ([str length] > 2) {
    if ([str hasSuffix:@"\n"])
      return [str substringToIndex:([str length] - 1)];
  }
  return str;
}

- (NSString *)stringByRemovingString:(NSString *)_s {
  return [self stringByReplacingString:_s withString:@""];
}
- (NSString *)stringByRemovingCharacter:(unichar)_c {
  switch (_c) {
    case ',':  return [self stringByReplacingString:@","  withString:@""];
    case '\'': return [self stringByReplacingString:@"'"  withString:@""];
    case '<':  return [self stringByReplacingString:@"<"  withString:@""];
    case '"':  return [self stringByReplacingString:@"\"" withString:@""];
      
    default: {
      NSString *s;
      NSLog(@"WARNING(%s): expensive, fix in source! char: '%c'(%i)",
            __PRETTY_FUNCTION__, _c, _c);
      s = [[NSString alloc] initWithCharacters:&_c length:1];
      self = [self stringByReplacingString:s withString:@""];
      if (s == self) 
        [s autorelease]; 
      else
        [s release];
      return self;
    }
  }
}

- (BOOL)mailAddressContainsPersonName {
  /* whether the (email address) string has the form "Donald <dd@dd.com>" */
  if ([self rangeOfString:@","].length  > 0) return YES;
  if ([self rangeOfString:@"\""].length > 0) return YES;
  if ([self rangeOfString:@"<"].length  > 0) return YES;
  if ([self rangeOfString:@">"].length  > 0) return YES;
  return NO;
}

- (NSString *)stringByRemovingMailSpecialsInPersonName {
  /* escaping the name would be better, but removing is easier ;-) */
  NSString *name = self;
  
  name = [name stringByRemovingCharacter:','];
  name = [name stringByRemovingCharacter:'"'];
  name = [name stringByRemovingCharacter:'\''];
  return name;
}

- (BOOL)hasMailReplyPrefix {
  if ([self hasPrefix:@"Re:"])
    return YES;
  if ([self hasPrefix:@"RE:"])
    return YES;
  return NO;
}
- (NSString *)stringByAddingMailReplyPrefix {
  if ([self hasMailReplyPrefix])
    return self;
  
  return [@"Re: " stringByAppendingString:self];
}

- (BOOL)doesLookLikeMailAddressWithDomain {
  NSString *s;
  NSRange  r;
  
  r = [self rangeOfString:@"@"];
  if (r.length == 0)
    return NO;
  if (r.location == 0) /* missing receiver, eg: '@blah' */
    return NO;
  
  s = [self substringFromIndex:(r.location + r.length)];
  if ([s length] == 0) /* nothing after the @, eg: 'blah@' */
    return NO;
  
  /* we want at least one dot: 'a@b.de' but never: 'a@b' */
  r = [s rangeOfString:@"."];
  if (r.length == 0)
    return NO;
  
  return YES;
}

@end /* NSString(MailEditor) */
