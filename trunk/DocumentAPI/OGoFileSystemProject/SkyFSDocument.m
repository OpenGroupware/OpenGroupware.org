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

#include "SkyFSDocument.h"
#include "SkyFSFileManager.h"
#include "common.h"
#include <NGMime/NGMimeType.h>

@interface SkyFSDocument(Deletable)
- (BOOL)isDeletable;
@end

@implementation SkyFSDocument

- (id)initWithFileManager:(id<NSObject,NGFileManager>)_fileManager
  context:(id)_ctx
  project:(id)_project
  path:(NSString *)_path
  fileName:(NSString *)_fn
  attributes:(NSDictionary *)_attrs
{
  if ((self = [super init])) {
    self->fileManager = [_fileManager retain];
    self->context     = [_ctx retain];
    self->path        = [_path copy];
    self->project     = [_project retain];
    self->fileName    = [_fn copy];
    self->attributes  = [_attrs retain];
    self->attributesChanged = NO;
    self->contentChanged    = NO;
  }
  return self;
}

- (void)dealloc {
  [self->blobAsDOM     release];
  [self->fileManager   release];
  [self->context       release];
  [self->path          release];
  [self->project       release];
  [self->fileName      release];
  [self->mimeType      release];
  [self->fileType      release];
  [self->attributes    release];
  [self->content       release];
  [self->contentString release];
  [super dealloc];
}

- (BOOL)isInsertable {
  BOOL flag;

  if ([self->fileManager
           fileExistsAtPath:[self path] isDirectory:&flag]) {
    if (flag) {
      return [self->fileManager isWritableFileAtPath:[self path]];
    }
  }
  return NO;
}

- (SkyDocumentType *)documentType {
#if LIB_FOUNDATION_LIBRARY
  return [self subclassResponsibility:_cmd];
#else
  NSLog(@"%s: subclass should override this method!", __PRETTY_FUNCTION__);
  return nil;
#endif
}

- (BOOL)isComplete {
  return self->fileName?YES:NO;
}

- (EOGlobalID *)globalID {
  if (self->fileName)
    return [self->fileManager globalIDForPath:[self path]];
  else {
    NSLog(@"ERROR(%s) couldn`t create globalID for document with no fileName",
          __PRETTY_FUNCTION__);
    return nil;
  }
}

/* properties */

- (BOOL)isReadable {
  return YES;
}
- (BOOL)isWriteable {
  return [self->fileManager isReadableFileAtPath:[self path]];
}
- (BOOL)isRemovable {
  return [self isDeletable];
}
- (BOOL)isNew {
  return self->fileName?NO:YES;
}
- (BOOL)isEdited {
  return self->contentChanged;
}

- (NSString *)subject {
  return [self valueForKey:@"NSFileSubject"];
}


/* SKYRiX context the document lives in */

- (id)context {
  return self->context;
}

/* feature check */

- (BOOL)supportsFeature:(NSString *)_featureURI {
  /* TODO: do we need special handling for directories? */
  
  if ([_featureURI isEqualToString:SkyDocumentFeature_BLOB])
    return YES;
  if ([_featureURI isEqualToString:SkyDocumentFeature_STRINGBLOB])
    return YES;
  if ([_featureURI isEqualToString:SkyDocumentFeature_DOMBLOB])
    return YES;
  
  return [super supportsFeature:_featureURI];
}

/* saving and deleting */

- (BOOL)save {
  BOOL isDir;

  if (![self->fileName length]) {
    NSLog(@"%s: couldn`t save file, missing fileName", __PRETTY_FUNCTION__);
    return NO;
  }
  if ([self->fileManager fileExistsAtPath:[self path] isDirectory:&isDir]) {
    if (isDir & [self->content length]) {
      NSLog(@"%s: couldn`t save content in directory ... (%@)",
            __PRETTY_FUNCTION__, [self path]);
      return NO;
    }
    if (self->contentChanged) {
      self->contentChanged = NO;
      if (![self->fileManager writeContents:[self content]
                atPath:[self path]]) {
        NSLog(@"%s: couldn`t write content %@ at path %@",
              __PRETTY_FUNCTION__, self->content, [self path]);
        return NO;
      }
    }
    if (self->attributesChanged) {
      self->attributesChanged = NO;
      if (![self->fileManager changeFileAttributes:self->attributes
                atPath:[self path]]) {
        NSLog(@"%s: couldn`t changeFileAttributes %@ at path %@",
              __PRETTY_FUNCTION__, self->attributes, [self path]);
        return NO;
      }
    }
  }
  else {
    NSDictionary *d;
    
    if (![self->fileManager createFileAtPath:[self path]
              contents:self->content attributes:self->attributes]) {
      NSLog(@"%s: couldn`t create new file at path %@ "
            @"content %@ attributes %@",
            __PRETTY_FUNCTION__, [self path], self->content, self->attributes);
      return NO;
    }
    d = [self->fileManager fileAttributesAtPath:[self path] traverseLink:NO];
    if ([d count])
      ASSIGN(self->attributes, d);
  }
  return YES;
}

- (BOOL)isVersioned {
  return NO;
}

- (BOOL)isLocked {
  return NO;
}

- (BOOL)isDeletable {
  return [self->fileManager isDeletableFileAtPath:[self path]];
}

- (BOOL)delete {
  return [self->fileManager removeFileAtPath:[self path] handler:nil];
}

- (BOOL)reload {
  return NO;
}

- (void)logDownload {
}

- (void)setContent:(NSData *)_data {
  if (self->content == _data) return;
  
  self->contentChanged = YES;
  [self->contentString release]; self->contentString = nil;
  ASSIGN(self->content, _data);
}

- (NSData *)content {
  if (self->content == nil)
    self->content = [[self->fileManager contentsAtPath:[self path]] retain];
  return self->content;
}

- (NSStringEncoding)contentEncoding {
  return [NSString defaultCStringEncoding];
}

- (void)setContentString:(NSString *)_blob {
  self->contentChanged = YES;
  ASSIGN(self->contentString, _blob);
  
  [self->content release]; self->content = nil;
  self->content = [[self->contentString dataUsingEncoding:
                       [self contentEncoding]] retain];
  self->contentChanged = YES;
}
- (NSString *)contentAsString {
  if (self->contentString == nil) {
    self->contentString = 
      [[NSString alloc] initWithData:[self content]
                        encoding:[self contentEncoding]];
  }
  return self->contentString;
}

- (id<NGFileManager>)fileManager {
  return self->fileManager;
}

- (NSString *)path {
  return [self->path stringByAppendingPathComponent:self->fileName];
}

- (void)resetAttrs {
  [self->mimeType release]; self->mimeType = nil;
  [self->fileType release]; self->fileType = nil;
}

- (NSString *)mimeType {
  return [self valueForKey:@"NSFileMimeType"];
}

- (NSString *)fileName {
  return self->fileName;
}

- (NSNumber *)fileSize {
  return [self->attributes objectForKey:NSFileSize];
}

- (void)takeValue:(id)_v forKey:(NSString *)_key {

  if (_v == nil)
    return;

  if ([_key isEqualToString:@"NSFilePath"]) {
    [self->fileName release]; self->fileName = nil;
    [self->path     release]; self->path     = nil;
    
    self->path = [[_v stringByDeletingLastPathComponent] retain];
    self->fileName = [[_v lastPathComponent] retain];
    [self resetAttrs];
    return;
  }
  if (self->attributes == nil) {
    self->attributes = [[NSMutableDictionary alloc] initWithCapacity:64];
  }
  else if (![self->attributes isKindOfClass:[NSMutableDictionary class]]) {
    NSDictionary *tmp;
    
    tmp = [self->attributes mutableCopy];
    [self->attributes release];
    self->attributes = (NSMutableDictionary *)tmp;
  }
  self->attributesChanged = YES;
  [self->attributes setObject:_v forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  id v;

  if ([_key isEqualToString:@"NSFilePath"])
    v = [self path];
  else if ([_key isEqualToString:@"NSFileName"])
    v = [self fileName];
  else if ([_key isEqualToString:@"globalID"])
    v = [self globalID];
  else
    v = [self->attributes valueForKey:_key];
  return v;
}

/* description */

- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:128];
  [ms appendFormat:@"<0x%08X[%@]:", self, NSStringFromClass([self class])];
  
  if (self->path) [ms appendFormat:@" path=%@", self->path];
  
  if (self->content)       [ms appendString:@" loaded"];
  if (self->contentString) [ms appendString:@" string"];
  
  if (self->attributesChanged) 
    [ms appendString:@" attrchanged"];
  
  [ms appendString:@">"];
  return ms;
}

@end /* SkyFSDocument */
