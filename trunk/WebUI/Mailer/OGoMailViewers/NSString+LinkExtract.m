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

#include "LSWPartBodyViewer.h"
#include "common.h"

@implementation NSString(LSWTextPlainBodyViewerLinkExtract)

static inline BOOL _isAlphaOrDigit(unichar _ch) {
  if (((_ch > 96) && (_ch < 123)) ||
      ((_ch > 64) && (_ch < 91))  ||
      ((_ch > 47) && (_ch < 58))  ||
      (_ch == '/'))    
    return YES;
  return NO;
}

- (NSString *)_tpGetUrl {
  int     len;
  int     cnt     = 0;
  unichar *str    = NULL;
  unichar *string = NULL;
  
  len = [self length];
  
  string = calloc(len + 4, sizeof(unichar));
  str    = string;
  [self getCharacters:str];
  
  while (cnt < len) {
    if ((*str == ' ') || (*str == '\n') || (*str == '\r') || (*str == '\t') ||
        (*str == '"') || (*str == '\''))
      break;
    
    if ((len - cnt) > 1){
      register unsigned char test = *(str + 1);
      
      if ((!_isAlphaOrDigit(*str)) && 
	  ((test == '\n') || (test == ' ') || (test == '\t') ||
	   (test == '\'') || (test == '"') || (test == '\r')))
        break;
    }
    str++;
    cnt++;
  }
  if (string) free(string);
  if (cnt == 0) {
    [self logWithFormat:@"WARNING: found URL without characters"];
    return @"";
  }
  return [self substringToIndex:cnt];
}

+ (void)_tpParseForLink:(NSString *)_kind intoArray:(NSMutableArray *)_text_ {
  // TODO: change to use -rangeOfString: instead of -indexOfString:
  // TODO: maybe objects should be used instead of the dictionary entries ?
  int  i, cnt = 0;
  
  for (i = 0, cnt = [_text_ count]; i < cnt; i++) {
    id obj;
    
    obj = [_text_ objectAtIndex:i];

    if ([[obj objectForKey:@"kind"] isEqualToString:@"text"]) {
      NSString *str = nil;
      NSRange  r;
      
      str = [obj objectForKey:@"value"];
      r = [str rangeOfString:_kind];
      
      while (r.length > 0) {
        NSString     *s = nil;
        NSDictionary *entry;
        int idx;
        
        idx = r.location;
        [_text_ removeObjectAtIndex:i];
        
        entry = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        [str substringToIndex:idx], @"value",
                                        @"text", @"kind", nil];
        [_text_ insertObject:entry atIndex:i];
        [entry release];
        
        s = [[str substringFromIndex:idx] _tpGetUrl];
        
        if ([s length] > [_kind length]) {
          entry = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  s,      @"value",
                                  _kind,  @"urlKind",
                                  @"url", @"kind", nil];
          
          [_text_ insertObject:entry atIndex:(i + 1)];
          [entry release];
        }
        else {
          entry = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  s,       @"value",
                                  @"text", @"kind", nil];
          
          [_text_ insertObject:entry atIndex:(i + 1)];
          [entry release];
        }
        str = [str substringFromIndex:(idx + [s length])];
        
        entry = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      str,  @"value",
                                      @"text", @"kind", nil];
        [_text_ insertObject:entry atIndex:(i + 2)];
        [entry release];
        
        cnt += 2;
        i   += 2;
        r = [str rangeOfString:_kind];
      }
    }
  }
}

- (NSArray *)findContainedLinks {
  static NSArray *linkMethods = nil;
  NSMutableArray *array     = nil;
  NSEnumerator   *linkKinds = nil;
  NSString       *kind      = nil;
  NSDictionary   *entry;

  if (linkMethods == nil) {
    linkMethods =
      [[NSArray alloc] initWithObjects:
                         @"http:",@"https:", @"file:",
                         @"ftp:", @"news:", @"mailto:", nil];
  }
  
  linkKinds = [linkMethods objectEnumerator];
  
  entry = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  self,    @"value",
                                  @"text", @"kind",
                                nil];
  array = [NSMutableArray arrayWithObject:entry];
  [entry release];
  
  while ((kind = [linkKinds nextObject]))
    [[self class] _tpParseForLink:kind intoArray:array];
  
  return array;
}

@end /* NSString(LSWTextPlainBodyViewerLinkExtract) */
