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

#include "LSWPartBodyViewer.h"
#include "common.h"

@implementation NSString(LSWTextPlainBodyViewerTextWrap)

- (NSString *)stringByWrappingWithWrapLen:(int)_wrapLen
  wrapLongLines:(BOOL)wrapLongLines
{
  // TODO: This method is really too big ! split up !
  // TODO: uses private class cluster classes !!!
  static NSArray *linkMethods = nil;
  NSString       *str;
  BOOL           isUTF16;

  str = self;
  
  if (linkMethods == nil) {
    linkMethods =
      [[NSArray alloc] initWithObjects:
                         @"http:",@"https:", @"file:",
                         @"ftp:", @"news:", @"mailto:", nil];
  }

#if LIB_FOUNDATION_LIBRARY
  isUTF16 =  [self isKindOfClass:[NSInlineUTF16String class]];
#else
  isUTF16 = NO;
#endif
  
  if (_wrapLen == 0) _wrapLen = 10000;

  // wrap long lines
  if ((_wrapLen != -1) && ((int)[str length] > _wrapLen)) {
    NSArray *lines;
    id      wrapped;
    int     cnt, numLines;
    
    lines = [str componentsSeparatedByString:@"\r"];
#if LIB_FOUNDATION_LIBRARY
    if (isUTF16) { /* work around for missing NSMutableInlineUTF16String */
      NSEnumerator *enumerator;
      id           obj;

      enumerator = [lines objectEnumerator];

      wrapped    = [[[NSInlineUTF16String allocForCapacity:0 zone:nil]
                                          initWithCharacters:NULL length:0]
                                          autorelease];
      while ((obj = [enumerator nextObject]))
        wrapped = [wrapped stringByAppendingString:obj];
    }
    else
#endif
      wrapped = [lines componentsJoinedByString:@""];
    
    lines    = [wrapped componentsSeparatedByString:@"\n"];
    numLines = [lines count];

#if LIB_FOUNDATION_LIBRARY
    if (isUTF16)
      wrapped  = [[[NSInlineUTF16String allocForCapacity:0 zone:nil]
                                        initWithCharacters:NULL length:0]
                                        autorelease];
    else
#endif
      wrapped = [NSMutableString stringWithCapacity:[wrapped length]];

    for (cnt = 0; cnt < numLines; cnt++) {
      str = [lines objectAtIndex:cnt];

      if (cnt != 0) {
        if (isUTF16)
          wrapped = [wrapped stringByAppendingString:@"\n"];
        else
          [wrapped appendString:@"\n"];
      }
      if ((int)[str length] > _wrapLen) {
        do {
          int len       = _wrapLen;
          BOOL noSpaces = NO;

          while (len > 0) {
            if ([str characterAtIndex:len] == ' ') {
              break;
            }
            len--;
          }
          if (len == 0) {
            BOOL doWrap;

            doWrap = YES;
            if (wrapLongLines) {
              NSEnumerator *enumerator;
              NSString     *obj;
              
              enumerator = [linkMethods objectEnumerator];
              while ((obj = [enumerator nextObject])) {
                if ([str hasPrefix:obj]) {
                  doWrap = NO;
                  break;
                }
              }
            }
            if (wrapLongLines && doWrap) {
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
          if (isUTF16) {
            wrapped = [wrapped stringByAppendingString:
                               [str substringToIndex:len]];
            wrapped = [wrapped stringByAppendingString:@"\n"];
          }
          else {
            [wrapped appendString:[str substringToIndex:len]];
            [wrapped appendString:@"\n"];
          }
          /* ignore leading space */
          if (noSpaces)
            str = [str substringFromIndex:len];
          else {
            str = [str substringFromIndex:len + 1];
          }
        }
        while ((int)[str length] > _wrapLen);
        
        if (isUTF16)
          wrapped = [wrapped stringByAppendingString:str];
        else
          [wrapped appendString:str];
      }
      else {
        if (isUTF16)
          wrapped = [wrapped stringByAppendingString:str];
        else
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

@end /* NSString(LSWTextPlainBodyViewerTextWrap) */
