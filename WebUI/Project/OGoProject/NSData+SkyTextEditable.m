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

#include "NSData+SkyTextEditable.h"
#include "common.h"

@implementation NSData(SkyTextEditable)

- (BOOL)isSkyTextEditable {
  const unsigned char *bytes;
  unsigned i, len, lineLen, lineCount;
  
  if ((len = [self length]) == 0)
    /* empty data can be edited */
    return YES;
  if (len > 1000000) { /* want to edit 1MB in a <textarea> ?? */
#if DEBUG
      NSLog(@"%s: not editable, to large", __PRETTY_FUNCTION__);
#endif
    return NO;
  }
  
  bytes = [self bytes];
  for (i = 0, lineLen = 0, lineCount = 0; i < len; i++, lineLen++) {
    if (bytes[i] == '\0') {
      /* contains 'NULL' characters */
#if DEBUG
      NSLog(@"%s: not editable, contains \\0 chars", __PRETTY_FUNCTION__);
#endif
      return NO;
    }
    
    if (bytes[i] == '\n') {
      lineCount++;
      lineLen = 0;
    }
    
    if (lineLen > 1000) {
      /* too long line */
#if DEBUG
      NSLog(@"%s: not editable, contains line with length %d",
            __PRETTY_FUNCTION__, lineLen);
#endif
      return NO;
    }
    if (lineCount > 4000) {
      /* too many lines */
#if DEBUG
      NSLog(@"%s: not editable, contains too many lines (%d)",
            __PRETTY_FUNCTION__, lineCount);
#endif
      return NO;
    }
  }
  
  return YES;
}

@end /* NSData(SkyTextEditable) */
