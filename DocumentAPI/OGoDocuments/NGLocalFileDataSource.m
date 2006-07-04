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

#include <OGoDocuments/NGLocalFileDataSource.h>
#include <OGoDocuments/NGLocalFileDocument.h>
#include <OGoDocuments/NGLocalFileManager.h>
#include <NGExtensions/EODataSource+NGExtensions.h>
#include <NGExtensions/NGPropertyListParser.h>
#include "common.h"

@interface NGLocalFileManager(AttrFileManagerAPI)

- (NSDictionary *)fileAttributesAtPath:(NSString *)_path
  traverseLink:(BOOL)_traverseLink
  useAttributesFile:(BOOL)_flag;

@end

@interface NGLocalFileManager(NGLocalFileDataSource)

- (NSDictionary *)attributesDictionaryForDirectoryPath:(NSString *)_path;

@end /* NGLocalFileManager(NGLocalFileDataSource) */

@implementation NGLocalFileManager(NGLocalFileDataSource)

- (NSDictionary *)attributesDictionaryForDirectoryPath:(NSString *)_path {
  NSMutableDictionary *result;
  NSDictionary        *dict;
  NSEnumerator        *enumer;
  NSString            *key;
  BOOL                isDir;
  NSAutoreleasePool   *pool;

  if (![self fileExistsAtPath:_path isDirectory:&isDir])
    return nil;
  if (!isDir)
    return nil;

  pool = [[NSAutoreleasePool alloc] init];
  
  dict = [NSDictionary skyDictionaryWithContentsOfFile:
                         [_path stringByAppendingPathComponent:
                                  @".attributes.plist"]];

  result = [[NSMutableDictionary alloc] initWithCapacity:[dict count]];
  
  enumer = [dict keyEnumerator];
  while ((key = [enumer nextObject])) {
    NSDictionary        *dict1;
    int                 count;
    NSMutableDictionary *dict2 = nil;
    NSString            *p     = nil;

    dict1 = [dict objectForKey:key];
    count = [dict1 count];
    
    p = [[self->cdp stringByAppendingPathComponent2:_path]
                    stringByAppendingPathComponent:key];
    
    dict2 = [[NSMutableDictionary alloc] initWithCapacity:(count + 2)];
    if (count > 0) {
      [dict2 addEntriesFromDictionary:dict1];
    }

    dict1 = [self fileAttributesAtPath:p
		  traverseLink:NO
		  useAttributesFile:NO];
    [dict2 addEntriesFromDictionary:dict1];
    [dict2  setObject:p     forKey:@"NSFilePath"];
    [dict2  setObject:key   forKey:@"NSFileName"];
    [result setObject:dict2 forKey:key];
    [dict2 release];
  }
  
  [pool release];
  return [result autorelease];
}

@end /* NGLocalFileManager(NGLocalFileDataSource) */

@implementation NGLocalFileDataSource

static BOOL debugOn = NO;

- (id)initWithPath:(NSString *)_path fileManager:(id)_fm {
  if ((self = [super init])) {
    NSString *p;
    
    [self debugWithFormat:@"path: %@", _path];
    p = [_fm currentDirectoryPath];
    [self debugWithFormat:@"  cwd:  %@", p];
    p = [p stringByAppendingPathComponent2:_path];
    [self debugWithFormat:@"  path: %@", p];
    
    self->path = [p copy];
    self->fm   = [_fm retain];
  }
  return self;
}

- (void)dealloc {
  [self->path release];
  [self->fm   release];
  [super dealloc];
}

/* accessors */

- (void)setFetchSpecification:(EOFetchSpecification *)_fspec {
  if (![_fspec isEqual:self->fetchSpecification]) {
    ASSIGN(self->fetchSpecification, _fspec);
    [self postDataSourceChangedNotification];
  }
}
- (EOFetchSpecification *)fetchSpecification {
  return self->fetchSpecification;
}

/* operations */

- (NSArray *)fetchObjects {
  NSDate  *st;
  NSArray *result;
  
  st     = [NSDate date];
  result = [self fetchObjectsAtPath:self->path];
  self->duration = [[NSDate date] timeIntervalSinceDate:st];
  
#if PROF && DEBUG
  printf("%s %s %0.5fs\n",
         __PRETTY_FUNCTION__, [self->path cString], self->duration);
#endif
  return result;
}

- (NSArray *)fetchObjectsAtPath:(NSString *)_path {
  NSArray             *array  = nil;
  NSMutableArray      *array2 = nil;
  EOQualifier         *q      = nil;
  NSArray             *so     = nil;
  int                 i;
  BOOL                fetchDeep;
  NGLocalFileDocument *doc    = nil;
  BOOL                isDir;
  NSDictionary        *attributes = nil;
  NSAutoreleasePool   *pool;

  [self debugWithFormat:@"fetch objects at path: '%@'", _path];
  
  if (![self->fm fileExistsAtPath:_path isDirectory:&isDir] || !isDir) {
    // TODO: should return nil and throw exception?
    [self debugWithFormat:@"  does not exist or is no directory .."];
    return [NSArray array];
  }
  
  pool = [[NSAutoreleasePool alloc] init];
  
  array      = [self->fm directoryContentsAtPath:_path];
  array2     = [[NSMutableArray alloc] initWithCapacity:16];
  q          = [[self fetchSpecification] qualifier];
  so         = [[self fetchSpecification] sortOrderings];
  fetchDeep  = [[[[self fetchSpecification] hints] objectForKey:@"fetchDeep"]
                        boolValue];
  attributes = [self->fm attributesDictionaryForDirectoryPath:_path];
  
  [self debugWithFormat:@"apply qualifier: %@", q];
  
  for (i = 0; i < [array count]; i++) {
    NSString  *p   = nil;
    
    p   = [_path stringByAppendingPathComponent:[array objectAtIndex:i]];
    
    doc = [[NGLocalFileDocument alloc] initWithPath:p
                                       fileManager:self->fm
                                       context:attributes];
    
    if (q) {
      if ([(id <EOQualifierEvaluation>)q evaluateWithObject:doc]) 
        [array2 addObject:doc];
    }
    else
      [array2 addObject:doc];
    
    if (fetchDeep) {
      [array2 addObjectsFromArray:[self fetchObjectsAtPath:p]];
    }
    [doc release];
  }
  array = [array2 autorelease];
  
  if (so != nil)
    array = [array sortedArrayUsingKeyOrderArray:so];

  array = [array retain];
  [pool release];
  
  return [array autorelease];
}

- (NSTimeInterval)duration {
  return self->duration;
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

/* description */

- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:64];
  [ms appendFormat:@"<0x%p[%@]:", self, NSStringFromClass([self class])];
  
  if (self->path) [ms appendFormat:@" path=%@", self->path];
  if (self->fm)   [ms appendFormat:@" fm=%@",   self->fm];
  
  if (self->fetchSpecification)
    [ms appendFormat:@" fs=%@", self->fetchSpecification];
  if (self->duration > 0)
    [ms appendFormat:@" duration=%.3fs", self->duration];
  
  [ms appendString:@">"];
  return ms;
}

@end /* NGLocalFileDataSource */
