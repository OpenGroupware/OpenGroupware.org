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
// $Id: NSString+csv.m 1 2004-08-20 11:17:52Z znek $

#include "NSString+csv.h"
#import <Foundation/Foundation.h>
#include <NGExtensions/NGMemoryAllocation.h>
#include <ctype.h>

@implementation NSString(CommaSeparatedValues)

static inline NSString *parseQuotedString(const char *buffer,
                                          unsigned *pos,
                                          unsigned length)
{
  char     *newBuf;  
  char     quote, c;
  BOOL     escaped = NO;
  unsigned len = 0;


  // length shouldnt be too big
  newBuf = NGMallocAtomic((length-(*pos)) + 1);
  quote  = buffer[*pos];
  // jump over quote
  (*pos)++;
  
  while ((*pos) < length) {
    // get the character
    c = buffer[*pos];
    (*pos)++;
    
    if (escaped) 
      escaped = NO;
    
    else {
      if (c == quote) {
        // if next character is a quote too, take it as an escaped quote
        // '' -> '
        if (((*pos) == length) || ((c = buffer[*pos]) != quote)) {
          break;
        }
        // next character is a quote too
        // -> go to next position
        (*pos)++;
      }
      
      else if (c == '\\') {
        escaped = YES;
        continue;
      }
    }
    

    newBuf[len++] = c;
  }

  newBuf[len] = '\0';

#if !LIB_FOUNDATION_LIBRARY
  {
    NSString *s;

    s = [NSString stringWithCString:newBuf];
    free(newBuf);
    return s;
  }
#else
  return [NSString stringWithCStringNoCopy:newBuf freeWhenDone:YES];
#endif
}

static inline NSString *parseSimpleString(const char *buffer,
                                          unsigned *pos,
                                          unsigned length,
                                          const char separator)
{
  char     c;
  unsigned len     = 0;
  unsigned realLen = 0;
  unsigned start   = (*pos);
  
  while ((*pos) < length) {
    // get the character
    c = buffer[*pos];

    if (c == separator)
      break;
    
    (*pos)++;
    len++;
    if (!isspace(c)) // ignore spaces
      realLen = len;
  }

  return [NSString stringWithCString:buffer+start length:realLen];
}

static inline NSString *parseValue(const char *buffer,
                                   unsigned *pos,
                                   unsigned length,
                                   char     separator,
                                   char     *quotes,
                                   unsigned quoteCount)
{
  char c;
  unsigned i;

  while (((*pos) < length) && (isspace((c = buffer[*pos]))) &&
         (c != separator)) {
    // ignore leading spaces
    (*pos)++;
    continue;
  }

  if ((*pos) == length)
    return @"";

  for (i = 0; i < quoteCount; i++) {
    if (c == quotes[i]) {
      return parseQuotedString(buffer, pos, length);
    }
  }

  // not a space but a character
  if (c == '\n') {
    // new line must be quoted if in a value ..
    // so return empty value and dont got no next position
    return @"";
  }

  return parseSimpleString(buffer, pos, length, separator);
}

- (NSArray *)parsedCSV {
  return [self parsedCSVWithSeparator:','];
}
// calls parsedCSVWithSeparator:quotes:'\'','\"' quotesCount:2
- (NSArray *)parsedCSVWithSeparator:(char)_separator {
  static char quotes[2] = { '\'', '\"' };
  return [self parsedCSVWithSeparator:_separator quotes:quotes quotesCount:2];
}

- (NSArray *)parsedCSVWithSeparator:(char)_separator
                             quotes:(char *)_quotes
                        quotesCount:(unsigned)_quoteCount
{
  const char     *cstr;
  char           c;
  unsigned       pos;
  unsigned       len;
  NSMutableArray *lines;
  NSMutableArray *columns;
  BOOL           expectValue;
  id             tmp;

  cstr        = [self cString];
  len         = [self cStringLength];
  pos         = 0;
  columns     = [[NSMutableArray alloc] initWithCapacity:8];
  lines       = nil;
  expectValue = YES;

  while (pos < len) {
    c = cstr[pos];
    
    if (c == '\n') {
      // new line
      if (lines == nil)
        lines = [[NSMutableArray alloc] initWithCapacity:8];
      [lines addObject:[[columns copy] autorelease]];
      [columns removeAllObjects];

      pos++;
      expectValue = YES;
      continue;
    }
    
    if (isspace(c) && c != _separator) {
      // ignore spaces
      pos++;
      continue;
    }
    
    if (expectValue) {      

      tmp = parseValue(cstr, &pos, len, _separator, _quotes, _quoteCount);
      
      if (tmp == nil) {
        // TODO: better warning
        NSLog(@"WARNING[%s] csv parsing failed", __PRETTY_FUNCTION__);
        [columns release];
        [lines   release];
        return nil;
      }

      [columns addObject:tmp];
      expectValue = NO;
    }
    else {
      // expect a separator
      if (c == _separator) {
        
        pos++;
        expectValue = YES;
        continue;
      }
      else {
        NSLog(@"WARNING[1:%s] unexpected character '%c' "
              @"at %d during csv parsing. expected separator.",
              __PRETTY_FUNCTION__, c, pos);
        //NSLog(@"WARNING[2] parsed %@ so far", columns);
        //NSLog(@"WARNING[3] parsed %@ so far", lines);
        [columns release];
        [lines   release];
        return nil;
      }
    }
  }

  if (lines) {
    if ([columns count])
      [lines addObject:[[columns copy] autorelease]];
    lines = [lines autorelease];
  }
  else {
    lines = [NSArray arrayWithObject:columns];
  }
  [columns release];

  return lines;
}

- (NSString *)csvStringWithQuotes:(char)_quote {
  const char   *cstr;
  char         c;
  char         *buffer;
  register int pos;
  NSString     *quotestr;

  if ([self length] == 0)
    return self;
  
  quotestr = [NSString stringWithCString:&_quote length:1];
  if ([self rangeOfString:quotestr].length == 0)
    // simple string
    return self;

  cstr   = [self cString];
  buffer = NGMallocAtomic([self cStringLength] * 2 + 3);
  pos    = 0;
  buffer[pos++] = _quote;
    
  while (*cstr) {
    c = *cstr;
    if (c == '\\') {      
      buffer[pos] = '\\'; pos++;
      buffer[pos] = '\\';
    }
    else if (c == _quote) {
      buffer[pos] = '\\'; pos++;
      buffer[pos] = _quote;
    }
    else {
      buffer[pos] = *cstr;
    }
    cstr++;
    pos++;
  }
  
  buffer[pos++] = _quote;
  buffer[pos]   = '\0';

#if !LIB_FOUNDATION_LIBRARY
  {
    NSString *s;

    s = [NSString stringWithCString:buffer];
    free(buffer);
    return s;
  }
#else
  return [NSString stringWithCStringNoCopy:buffer freeWhenDone:YES];
#endif
}

@end /* NSString(CommaSeparatedValues) */

@implementation NSArray(CommaSeparatedValues)

- (NSString *)csvStringWithSeparator:(char)_separator
                              quote:(char)_quote
{
  unsigned        i, max;
  id              tmp;
  NSString        *sep;
  NSMutableString *ms;

  max = [self count];
  ms  = [[NSMutableString alloc] initWithCapacity:32];
  sep = [[NSString alloc] initWithFormat:@"%c", _separator];
  
  for (i = 0; i < max; i++) {
    if (i)
      [ms appendString:sep];

    tmp = [[[self objectAtIndex:i] stringValue] csvStringWithQuotes:_quote];
    if (tmp == nil) {
      // TODO: better warnings
      NSLog(@"WARNING[%s] failed building csv string", __PRETTY_FUNCTION__);
      [ms release];
      [sep release];
      return nil;
    }

    [ms appendString:tmp];
  }

  [sep release];
  return [ms autorelease];
}

- (NSString *)csvString { // uses ',' as separator and '\'' as quote
  return [self csvStringWithSeparator:',' quote:'\''];
}

@end /* NSArray(CommaSeparatedValues) */
