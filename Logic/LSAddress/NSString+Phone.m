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

#include "NSString+Phone.h"
#include "common.h"
#include <ctype.h>

@implementation NSString(Phone)

static int MinimumPhoneNumberLength = 4;

- (NSString *)stringByNormalizingOGoPhoneNumber {
  unsigned len = [self length];
  char     *source, *buffer; // Unicode
  unsigned i, k;
  unsigned bLen = 0;
  unsigned pLen;
  char c;
  
  if ((len = [self length]) == 0)
    return @"";

  source = calloc(len + 4, sizeof(char));
  buffer = calloc(len + 4, sizeof(char));
    
  [self getCString:source];
  source[len] = '\0';
  buffer[len] = '\0';
    
  for (i = 0; i < len;) {
      c = source[i];
      if (isdigit(c)) {
        if (bLen == 0 && c == '0') {
          // a 0 at start
          for (k = i+1; (k < len) && (isdigit(source[k])); k++) {}
          pLen = k - i;
          if ((pLen > 2) && source[i+1] == '0') {
            // '00' -> '+'
            buffer[bLen++] = '+';
            i += 2; // ignore the '0'
            pLen -= 2;
          }
          memcpy(buffer+bLen, source+i, pLen);
          bLen += pLen;
          i    += pLen;
        }
        else {
          // just copy the number
          buffer[bLen++] = c;
          i++;
        }
      }
      else {
        // no digit
        BOOL isPlus = NO;
	
        if (bLen == 0 && c == '+') 
	  isPlus = YES;
	
        for (k = i+1; (k < len) && (!isdigit(source[k])); k++)
	  ;
	
        pLen = k - i;
	buffer[bLen++] = isPlus ? '+' : '-';
	bLen++;
        i += pLen;
      }
  }

  if (bLen >= MinimumPhoneNumberLength)
    self = [NSString stringWithCString:buffer length:bLen];
  else
    self = @"";
  
  if (buffer) free(buffer); buffer = NULL;
  if (source) free(source); source = NULL;
  return self;
}

@end /* NSString(Phone) */
