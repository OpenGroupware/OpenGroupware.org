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

#include <LSFoundation/LSDBObjectNewCommand.h>
#include <LSFoundation/LSDBObjectSetCommand.h>

@interface LSNewTelephoneCommand : LSDBObjectNewCommand

@end /* LSNewTelephoneCommand */

@interface LSSetTelephoneCommand : LSDBObjectSetCommand

@end /* LSSetTelephoneCommand */

#import <Foundation/Foundation.h>
#include <NGExtensions/NSNull+misc.h>
#include <ctype.h>

/* parses a number and trys to build a uique number
 *
 * +<country>-<city>-<number>{-<extension>}
 *
 * example (the skyrix office):
 * +49-391-6623-0
 *
 * a double zero at the start ('00') is replaced with a '+'
 * all other digits are kept.
 * any non-digit sequence is replaced with a '-'
 * (if it's not a '+' at the start)
 *
 */
static inline NSString *_parseRealNumber(NSString *_number) {
  unsigned len = [_number length];
  if (len == 0) return [NSString string];
  {
    char *source, *buffer;
    unsigned i, k;
    unsigned bLen = 0;
    unsigned pLen;
    char c;

    source = malloc(sizeof(char) * (len+1));
    buffer = malloc(sizeof(char) * (len+1));
    
    [_number getCString:source];
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
        if (bLen == 0 && c == '+') isPlus = YES;
        for (k = i+1; (k < len) && (!isdigit(source[k])); k++) {}
        pLen = k - i;
        if (isPlus)
          buffer[bLen++] = '+';
        else
          buffer[bLen++] = '-';
        i+= pLen;
      }
    }

    _number = [NSString stringWithCString:buffer length:bLen];
    
    free(buffer); buffer = NULL;
    free(source); source = NULL;
  }
  
  return _number;
}

@implementation LSNewTelephoneCommand

- (void)_prepareForExecutionInContext:(id)_ctx {
  id obj;
  NSString *number;
  
  [super _prepareForExecutionInContext:_ctx];
  obj = [self object];
  number     = [obj valueForKey:@"number"];
  if ([number isNotNull] && [number length]) {
    NSString *realNumber = [obj valueForKey:@"realNumber"];
    if ((![realNumber isNotNull]) || (![realNumber length])) {
      realNumber = _parseRealNumber(number);
      [obj takeValue:realNumber forKey:@"realNumber"];
    }
  }
}

- (NSString *)entityName {
  return @"Telephone";
}

@end /* LSNewTelephoneCommand */

@implementation LSSetTelephoneCommand

- (void)_prepareForExecutionInContext:(id)_ctx {
  id obj;
  NSString *number;
  
  [super _prepareForExecutionInContext:_ctx];
  obj = [self object];
  number     = [obj valueForKey:@"number"];
  if ([number isNotNull] && [number length]) {
    NSString *realNumber = [obj valueForKey:@"realNumber"];
    if ((![realNumber isNotNull]) || (![realNumber length])) {
      realNumber = _parseRealNumber(number);
      [obj takeValue:realNumber forKey:@"realNumber"];
    }
  }
}

- (NSString *)entityName {
  return @"Telephone";
}

@end /* LSSetTelephoneCommand */
