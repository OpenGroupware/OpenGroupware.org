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

/*
  see: http://www.biblioscape.com/rtf15_spec.htm
*/

#include "NSString+rtf.h"
#import <Foundation/Foundation.h>
#include <NGExtensions/NGMemoryAllocation.h>
#include <NGExtensions/NSObject+Logs.h>
#include <ctype.h>

@interface RTFBlock : NSObject
{
  NSMutableArray  *subBlocks;
  NSMutableArray  *parameters;
  NSMutableData   *content;
  RTFBlock        *parent; /* not retained */
}

- (void)addBlock:(RTFBlock *)_block;
- (void)addParameter:(NSString *)_para;
- (void)appendChar:(char)_char;
- (NSData *)content;
- (RTFBlock *)parent;
- (NSString *)contentAsString;

@end /* RTFBlock */

@implementation RTFBlock

+ (id)blockWithParent:(RTFBlock *)_parent {
  RTFBlock *b;

  b = [[[RTFBlock alloc] init] autorelease];
  b->parent = _parent;
  return b;
}

- (void)dealloc {
  [self->parameters release];
  [self->content    release];
  [self->subBlocks  release];
  self->parent = nil;
  [super dealloc];
}

- (void)addBlock:(RTFBlock *)_block {
  if (_block) {
    if (self->subBlocks == nil)
      self->subBlocks = [[NSMutableArray alloc] initWithCapacity:10];

    [self->subBlocks addObject:_block];
  }
}

- (void)addParameter:(NSString *)_para {
  if (_para) {
    if (self->parameters == nil)
      self->parameters = [[NSMutableArray alloc] initWithCapacity:10];

    [self->parameters addObject:_para];
  }
}

- (void)appendChar:(char)_c {
  if (_c == 0)
    return;

  if (self->content == nil) {
    self->content = [[NSMutableData alloc] initWithCapacity:100];
  }
  [self->content appendBytes:&_c length:1];
}

- (NSData *)content {
  return self->content;
}

- (NSString *)contentAsString {
  return [[[NSString alloc] initWithData:self->content
                            encoding:[NSString defaultCStringEncoding]]
                     autorelease];
}

- (RTFBlock *)parent {
  return self->parent;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@: content %s parameters %@ blocks %@",
                   [super description], [self->content bytes],
                   self->parameters, self->subBlocks];
}

@end /* RTFBlock */

@implementation NSString(RTF)

static inline char __hexToChar(char c) {
  if ((c > 47) && (c < 58)) // '0' .. '9'
    return c - 48;
  if ((c > 64) && (c < 71)) // 'A' .. 'F'
    return c - 55;
  if ((c > 96) && (c < 103)) // 'a' .. 'f'
    return c - 87;
  return -1;
}

#warning no unicode support

- (NSString *)plainTextStringByDecodingRTF {
  int        srcCnt;
  char       *source;
  char       cntrWord[64];
  int        cnt, blockCnt, cntrCnt;
  BOOL       isFlag;
  RTFBlock   *block;

  cnt      = 0;
  blockCnt = 0;
  isFlag   = NO;
  cntrCnt   = 0;

  srcCnt = [self cStringLength];

  if (srcCnt == 0)
    return @"";

  source = calloc(sizeof(char), srcCnt + 1);
  [self getCString:source];
  source[srcCnt] = '\0';

  if (source[0] != '{') {
    free(source); source = NULL;
    return self;
  }
  cnt++;
  block = [RTFBlock blockWithParent:nil];

  while (cnt < srcCnt) {
    char c;

    c = source[cnt++];

    if (c == '{') {
      RTFBlock *tmp;

      tmp = [RTFBlock blockWithParent:block];
      [block addBlock:tmp];
      block = tmp;
    }
    else if (c == '}') {
      if ([block parent] != nil) 
        block = [block parent];
    }
    else if (isFlag) {
      if (c == ' ' || c == '\r' || c == '\n' || c == '\\') {
        if (cntrCnt == 3) {
          if (cntrWord[0] == 'p' && cntrWord[1] == 'a' && cntrWord[2] == 'r')
            {
              [block appendChar:'\n'];
            }
        }
        isFlag = NO;
        [block addParameter:
               [NSString stringWithCString:cntrWord length:cntrCnt]];
        cntrCnt = 0;
        if (c == '\\') {
          BOOL isChar;

          isChar = NO;

          if (cnt < srcCnt) {
            char t;

            t= source[cnt];

            if (t == '\\' || t == '{' || t == '}') {
              cnt++;
              isChar = YES;
              isFlag = NO;
              [block appendChar:t];
            }
          }
          if (!isChar)
            isFlag = YES;
        }
      }
      else {
        cntrWord[cntrCnt++] = c;
      }
    }
    else if (c == '\\') {
      BOOL isChar;
      
      isChar = NO;
      if (cnt < srcCnt) {
        char t;

        t= source[cnt];

        if (t == '\'') {
          cnt++;
          
          if ((cnt + 1) < srcCnt) { /* got hex value */
            char cuml;

            cuml = (__hexToChar(source[cnt]) * 16) +
              __hexToChar(source[cnt+1]);

            cnt += 2;
            
            [block appendChar:cuml];
            isChar = YES;
          }
        }
        else {
          if (t == '\\' || t == '{' || t == '}') {
            cnt++;
            isChar = YES;
            [block appendChar:t];
          }
        }
      }
      if (!isChar) {
        isFlag = YES;
        if (cntrCnt > 0) {
          cntrWord[cntrCnt] = '\0';
        }
        cntrCnt = 0;
      }
    }
    else if (c == '\n' || c == '\r') {
    }
    else {
      cntrCnt = 0;
      [block appendChar:c];
    }
  }
  free(source); source = NULL;
  return [block contentAsString];
}

- (NSString *)stringByEncodingRTF {
  char     *result, *source;
  int      resLen, srcLen, cntSrc, cntRes;
  NSString *string;

  static const char hexT[16] = {'0','1','2','3','4','5','6','7','8',
                                '9','a','b','c','d','e','f'};
  static const char *pref    = "{\\rtf1\\ansi ";
  static const char *suff    = "}";
  static const int  prefLen  = 12;
  static const int  suffLen  = 1;

  resLen         = ([self cStringLength] * 5) /* '\n' --> '\\par\n' */
                 + prefLen + suffLen;
  result         = calloc(sizeof(char), resLen + 1); 
  result[resLen] = '\0';
  srcLen         = [self cStringLength];
  source         = calloc(sizeof(char), srcLen + 1);
  source[srcLen] = '\0';
  [self getCString:source];

  cntSrc = 0;
  strncpy(result, pref, prefLen);
  cntRes = prefLen;

  while (cntSrc < srcLen) {
    unsigned char c;

    if (cntRes + 5 >= resLen)
      break;
    
    c = source[cntSrc++];

    if (c == '\\' || c == '{' || c == '}') {
      result[cntRes++] = '\\';
      result[cntRes++] = c;
    }
    else if (c == '\n') {
      static const char *par = "\\par\n";
      static const int  l    = 5;

      strncpy(result + cntRes, par, l);
      cntRes += l;
    }
    else if (c > 127) {
      result[cntRes++] = '\\';
      result[cntRes++] = '\'';
      result[cntRes++] = hexT[(c >> 4) & 15];
      result[cntRes++] = hexT[c & 15];
    }
    else {
      result[cntRes++] = c;
    }
  }
  if ((cntRes + suffLen) <= resLen) {
    strncpy(result + cntRes, suff, suffLen);
    cntRes += suffLen;
  }
  
  if (cntSrc < srcLen) {
    [self logWithFormat:@"%s: error during rtf encoding %@ -> %s",
          __PRETTY_FUNCTION__, self, result];
  }
  string = [NSString stringWithCString:result length:cntRes];
  
  free(source); source = NULL;
  free(result); result = NULL;

  return string;
}

@end /* NSString(RTF) */
