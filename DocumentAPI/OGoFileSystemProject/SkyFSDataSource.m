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

#include "SkyFSDataSource.h"
#include "SkyFSFileManager.h"
#include "SkyFSFileManager+Internals.h"
#include "SkyFSDocument.h"
#include "common.h"

@implementation SkyFSDataSource

static BOOL debugOn = NO;

- (id)initWithFileManager:(SkyFSFileManager *)_fm
  context:(id)_ctx
  project:(id)_project
  path:(NSString *)_path
{
  BOOL isDir;

  _path = [_fm _makeAbsoluteInSky:_path];

  if (![_fm fileExistsAtPath:_path isDirectory:&isDir]) {
    NSLog(@"ERROR[%s]: try to create SkyFSDataSource with no existing"
          @"path (%@)", __PRETTY_FUNCTION__, _path);
    [self release];
    return nil;
  }
  if (!isDir) {
    NSLog(@"ERROR[%s]: SkyFSDataSource can only be used with directories"
          @" path (%@) fileManager %@", __PRETTY_FUNCTION__, _path, _fm);
    [self release];
    return nil;
  }
  if ((self = [super init])) {
    self->fileManager = [_fm      retain];
    self->context     = [_ctx     retain];
    self->project     = [_project retain];
    self->path        = [_path    copy];
  }
  return self;
}

- (void)dealloc {
  [self->path        release];
  [self->context     release];
  [self->project     release];
  [self->fileManager release];
  [self->fetchSpecification   release];
  [super dealloc];
}

/* accessors */

- (id)editingContext {
  /* HH asks: Is this actually used? */
  return self->context;
}

- (void)setFetchSpecification:(EOFetchSpecification *)_fs {
  ASSIGN(self->fetchSpecification, _fs);
  /* TODO: should post datasource changed? */
}
- (EOFetchSpecification *)fetchSpecification {
  return self->fetchSpecification;
}

/* operations */

- (Class)documentClass {
  return [SkyFSDocument class];
}

- (SkyFSDocument *)_newDocumentWithFilename:(NSString *)_filename
  attributes:(NSDictionary *)_attrs
{
  /* Note: returns a retain object! */
  return [[[self documentClass] alloc]
           initWithFileManager:self->fileManager context:self->context
           project:self->project path:self->path
           fileName:_filename attributes:_attrs];
}

- (NSArray *)fetchObjects {
  NSEnumerator   *enumerator;
  NSArray        *paths, *docs;
  NSMutableArray *documents;
  NSString       *str, *base;
  
  if (debugOn) [self debugWithFormat:@"fetch objects ..."];
  
  paths      = [self->fileManager directoryContentsAtPath:self->path];
  documents  = [NSMutableArray arrayWithCapacity:[paths count]];
  enumerator = [paths objectEnumerator];
  
  if (debugOn) [self debugWithFormat:@"  process %d pathes ...",[paths count]];

  base = self->path;
  if (![base hasSuffix:@"/"]) base = [base stringByAppendingString:@"/"];
  
  while ((str = [enumerator nextObject])) {
    SkyFSDocument *doc;
    NSDictionary  *attrs;
    BOOL          isDir;
    NSString      *filePath;
    
    filePath = [base stringByAppendingString:str];
    if (debugOn) [self debugWithFormat:@"    check path: '%@'", filePath];
    
    if (![self->fileManager fileExistsAtPath:filePath isDirectory:&isDir]) 
      continue;
    
    attrs = [self->fileManager fileAttributesAtPath:filePath traverseLink:NO];
    
    if ((doc = [self _newDocumentWithFilename:str attributes:attrs])) {
      [documents addObject:doc];
      [doc release]; doc = nil;
    }
  }
  docs = [documents sortedArrayUsingKeyOrderArray:
                         [self->fetchSpecification sortOrderings]];
  if (debugOn) [self debugWithFormat:@"fetched %d documents.", [docs count]];
  return docs;
}

- (void)deleteObject:(id)_object {
  [NSException raise:@"NSInvalidArgumentException"
               format:@"datasource %@ can't delete object %@",
                 self, _object];
}

- (void)insertObject:(id)_object {
  [NSException raise:@"NSInvalidArgumentException"
               format:@"datasource %@ can't insert object %@",
                 self, _object];
}

- (id)createObject {
  return [[[SkyFSDocument alloc] initWithFileManager:self->fileManager
                                  context:self->context
                                  project:self->project
                                  path:self->path
                                  fileName:nil attributes:nil] autorelease];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

/* description */

- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:128];
  [ms appendFormat:@"<0x%p[%@]:", self, NSStringFromClass([self class])];
  
  if (self->path)    [ms appendFormat:@" path=%@", self->path];
  if (self->project) [ms appendFormat:@" project=%@", self->project];
  
  [ms appendString:@">"];
  return ms;
}

@end /* SkyFSDataSource */
