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
// Created by Helge Hess on Sun Feb 03 2002.

#include "TaskMethodSignature.h"
#include "common.h"
#include <NGXmlRpc/NGXmlRpcInvocation.h>

@interface TaskMethodSignature(PrivateMethods)
- (NSString *)_replaceTemporaryFileNameBinding:(NSString *)_arguments;
@end /* TaskMethodSignature(PrivateMethods) */

@implementation TaskMethodSignature

- (id)initWithSignature:(NSString *)_sig config:(NSDictionary *)_dict {
  id tmp;
  
  self->encoding  = [NSString defaultCStringEncoding];
  self->signature = [[_sig componentsSeparatedByString:@","] retain];

  self->tempFileMapping = [[NSMutableDictionary alloc] initWithCapacity:2];
  
  if ((tmp = [_dict objectForKey:@"cmdline"])) {
    if ([tmp isKindOfClass:[NSArray class]])
      self->cmdargs = [tmp copy];
    else
      self->cmdargs = [[tmp componentsSeparatedByString:@" "] retain];
  }
  else
    self->cmdargs = [[NSArray alloc] init];

  self->input      = [[_dict objectForKey:@"stdin"]       copy];
  self->result     = [[_dict objectForKey:@"result"]      copy];
  self->resultType = [[_dict objectForKey:@"resultType"]  copy];
  self->tempFiles  = [[_dict objectForKey:@"tempfiles"]   copy];

  self->csvKeys    = [[_dict objectForKey:@"csvKeys"] copy];
  self->csvSeparator = [[_dict objectForKey:@"csvSeparator"] copy];
  
  if ([self->signature count] < 1) {
    NSLog(@"missing signature (%@) ...", _sig);
    RELEASE(self);
    return nil;
  }
  self->argCount = [self->signature count] - 1;
  
  return self;
}

- (void)dealloc {
  RELEASE(self->input);
  RELEASE(self->cmdargs);
  RELEASE(self->result);
  RELEASE(self->resultType);
  RELEASE(self->signature);
  RELEASE(self->tempFiles);
  RELEASE(self->tempFileMapping);
  RELEASE(self->csvKeys);
  RELEASE(self->csvSeparator);

  [super dealloc];
}

/* accessors */

- (NSArray *)xmlRpcSignature {
  return self->signature;
}
- (unsigned)numberOfArguments {
  return self->argCount;
}

- (NSString *)temporaryBindingPrefix {
  return @"$tempfile_";
}

- (NSFileManager *)fileManager {
  return [NSFileManager defaultManager];
}

/* matching */

- (BOOL)doesMatchArguments:(NSArray *)_args {
  return self->argCount == [_args count] ? YES : NO;
}
- (BOOL)canProcessArguments:(NSArray *)_args {
  return self->argCount == [_args count] ? YES : NO;
}

/* private methods */

- (NSString *)_temporaryFileName {
  return [[NSProcessInfo processInfo] temporaryFileName:@"/tmp/skysysd.temp"];
}

- (NSString *)_replaceTemporaryFileNameBinding:(NSString *)_binding {
  NSString *tempFileName;
  
  tempFileName = [self _temporaryFileName];
  [self addTemporaryFileName:tempFileName forBinding:_binding];

  return tempFileName;
}

- (void)_cleanUpTemporaryFiles {
  NSEnumerator *tempFileEnum;
  NSString     *tempFile;

  tempFileEnum = [self->tempFileMapping objectEnumerator];
  while((tempFile = [tempFileEnum nextObject])) {
    if(![[self fileManager] removeFileAtPath:tempFile
                            handler:nil]) {
      [self logWithFormat:@"couldn't remove temp path: %@", tempFile];
    }
  }
  [self->tempFileMapping removeAllObjects];
}

/* operations */

- (void)addTemporaryFileName:(NSString *)_fileName
  forBinding:(NSString *)_binding
{
  [self->tempFileMapping setObject:_fileName forKey:_binding];
}

- (NSArray *)argumentsWithPatternDictionary:(NSDictionary *)_dict {
  NSMutableArray *args;
  NSEnumerator   *e;
  NSString       *pattern;
  
  args = [NSMutableArray arrayWithCapacity:[self->signature count]];
  
  e = [self->cmdargs objectEnumerator];

  while ((pattern = [e nextObject])) {
    NSString *arg;

    if([pattern hasPrefix:[self temporaryBindingPrefix]]) {
      NSString *key;
      
      arg = [self _replaceTemporaryFileNameBinding:pattern];

      if((key = [self->tempFiles objectForKey:pattern]) != nil) {
        NSString *fileData;

        // TODO: handle encoding 
        
        key = [key substringWithRange:NSMakeRange(1,[key length]-2)];

        if ((fileData = [_dict objectForKey:key]) != nil) {
          [fileData writeToFile:arg atomically:NO];
        }
        else {
          [self debugWithFormat:@"input parameter for key %@ missing", key];
        }
      }
    }
    else {
      arg = [pattern stringByReplacingVariablesWithBindings:_dict];
    }
    [args addObject:arg];
  }
  return args;
}

- (NSData *)standardInputWithPatternDictionary:(NSDictionary *)_pd 
  parameters:(NSArray *)_paras
{
  NSString *s;
  
  if (self->input == nil) return nil;
  s = [self->input stringByReplacingVariablesWithBindings:_pd];
  return [s dataUsingEncoding:self->encoding];
}

- (NSString *)standardOutputStringWithData:(NSData *)_data {
  NSString *s;
  if (_data == nil) return nil;
  s = [[NSString alloc] initWithData:_data encoding:self->encoding];
  return AUTORELEASE(s);
}
- (NSString *)standardErrorStringWithData:(NSData *)_data {
  NSString *s;
  if (_data == nil) return nil;
  s = [[NSString alloc] initWithData:_data encoding:self->encoding];
  return AUTORELEASE(s);
}

- (NSDictionary *)dictionaryForCSVEntry:(NSString *)_entry {
  NSArray *elements;
  NSMutableDictionary *resultEntry;
  int i;

  elements = [_entry componentsSeparatedByString:self->csvSeparator];
  resultEntry = [NSMutableDictionary dictionaryWithCapacity:
                                     [elements count]];
  for (i = 0; i < [elements count]; i++) {
    [resultEntry takeValue:[elements objectAtIndex:i]
                 forKey:[self->csvKeys objectAtIndex:i]];
  }

  return resultEntry;
}

- (id)processResultType:(id)_result {
  id ret;
  NSString *s;
    
  s = [_result stringValue];
  if ([s hasSuffix:@"\n"])
    s = [s substringToIndex:([s length] - 1)];
  
  if ([self->resultType isEqualToString:@"arrayOfLines"]) {
    ret = ([s length] == 0)
      ? [NSArray array]
      : [s componentsSeparatedByString:@"\n"];
  }
  else if ([self->resultType isEqualToString:@"contentsOfFile"]) {
      ret = [NSData dataWithContentsOfFile:_result];
      [self _cleanUpTemporaryFiles];
  }
  else if ([self->resultType isEqualToString:@"CSVEntry"]) {
    ret = [self dictionaryForCSVEntry:s];
  }
  else if ([self->resultType isEqualToString:@"arrayOfCSVEntries"]) {
    NSMutableArray *res;
    NSEnumerator   *elemEnum;
    NSString       *elem;

    res = [NSMutableArray arrayWithCapacity:16];
    
    elemEnum = [[s componentsSeparatedByString:@"\n"] objectEnumerator];
    while ((elem = [elemEnum nextObject])) {
      [res addObject:[self dictionaryForCSVEntry:elem]];
    }
    ret = res;
  }
  else
    ret = _result;
  
  return ret;
}

- (id)stdoutResultWithPatternDictionary:(NSDictionary *)_pd {
  id ret;
  
  ret = ([[self->signature objectAtIndex:0] isEqualToString:@"base64"])
    ? [_pd objectForKey:@"stdoutData"]
    : [_pd objectForKey:@"stdout"];
  return ret;
}
- (id)stderrResultWithPatternDictionary:(NSDictionary *)_pd {
  id ret;
  
  ret = ([[self->signature objectAtIndex:0] isEqualToString:@"base64"])
    ? [_pd objectForKey:@"stderrData"]
    : [_pd objectForKey:@"stderr"];
  return ret;
}

- (id)coerceValue:(id)_value toXmlRpcType:(NSString *)_type {
  return [_value asXmlRpcValueOfType:_type];
}

- (id)resultWithPatternDictionary:(NSDictionary *)_pd {
  id ret;
  
  if ([self->result isEqualToString:@"$stdout$"])
    ret = [self stdoutResultWithPatternDictionary:_pd];
  else if ([self->result isEqualToString:@"$stderr$"])
    ret = [self stdoutResultWithPatternDictionary:_pd];
  else if ([self->result hasPrefix:[self temporaryBindingPrefix]])
    ret = [self->tempFileMapping objectForKey:self->result];
  else
    ret = [self->result stringByReplacingVariablesWithBindings:_pd];
  
  ret = [self processResultType:ret];
  return [self coerceValue:ret toXmlRpcType:[self->signature objectAtIndex:0]];
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:@"<0x%p[%@]: signature=%@>",
                     self, NSStringFromClass([self class]),
                     self->signature];
}

@end /* TaskMethodSignature */
