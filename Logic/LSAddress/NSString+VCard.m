/*
  Copyright (C) 2004 Helge Hess

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

#include "NSString+VCard.h"
#include "common.h"

@implementation NSString(VCard)

- (unsigned)numberOfUnsafeVCardCharacters {
  unsigned i, len, cnt;
  
  if ((len = [self length]) == 0)
    return 0;
  
  for (i = 0, cnt = 0; i < len; i++) {
    unichar c;
    
    c = [self characterAtIndex:i];
    if (c == ',' || c == ';' || c == '\n' || c == '\\') cnt++;
  }
  return cnt;
}

- (NSString *)stringByEscapingUnsafeVCardCharacters {
  unsigned i, cnt, len;
  unichar  *newStr;
  NSString *result;

  if ((cnt = [self numberOfUnsafeVCardCharacters]) == 0)
    return self;

  len    = [self length];
  newStr = calloc(len + cnt + 10, sizeof(unichar));
  for (i = 0, cnt = 0; i < len; i++) {
    unichar c;
    
    c = [self characterAtIndex:i];
    if (c == ',' || c == ';' || c == '\\') {
      newStr[i + cnt] = '\\';
      cnt++;
    }
    else if (c == '\n') {
      newStr[i + cnt] = '\\';
      cnt++;
      c = 'n';
    }
    newStr[i + cnt] = c;
  }
  newStr[i + cnt] = '\0';
  result = [NSString stringWithCharacters:newStr length:(i + cnt)];
  if (newStr != NULL) free(newStr); newStr = NULL;
  
  return result;
}

@end /* NSString(VCard) */
