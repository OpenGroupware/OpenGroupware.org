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

#include <OGoProject/SkyProjectHistoryDocument.h>
#include <OGoProject/NSString+XMLNamespaces.h>
#include <OGoDocuments/SkyDocumentType.h>
#include <NGExtensions/NGFileFolderInfoDataSource.h>
#include "common.h"

@interface NSObject(PreventWarnings)
- (id)documentAtPath:(NSString *)_path;
@end /* PreventWarnings */

@implementation SkyProjectHistoryDocument

- (id)initWithFileAttributes:(NSDictionary *)_attr
  fileManager:(id)_fm
{
  if ((self = [super init])) {
    self->fileManager = _fm;
    self->path        = [_attr objectForKey:@"NSFilePath"];
    self->filename    = [_attr objectForKey:@"NSFileName"];
    self->version     = [_attr objectForKey:@"SkyVersionName"];
    self->subject     = [_attr objectForKey:@"NSFileSubject"];
    self->globalID    = [_attr objectForKey:@"globalID"];
    self->size        = [[_attr objectForKey:@"NSFileSize"] unsignedIntValue];

    RETAIN(self->fileManager);
    RETAIN(self->path);
    RETAIN(self->filename);
    RETAIN(self->version);
    RETAIN(self->subject);
    RETAIN(self->globalID);
  }
  return self;
}
#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->fileManager);
  RELEASE(self->blob);
  RELEASE(self->path);
  RELEASE(self->filename);
  RELEASE(self->version);
  RELEASE(self->subject);
  RELEASE(self->globalID);
  RELEASE(self->mainDocument);
  [super dealloc];
}
#endif

- (NSString *)path {
  return self->path;
}
- (NSString *)filename {
  return self->filename;
}
- (NSString *)version {
  return self->version;
}
- (unsigned)size {
  return self->size;
}

- (void)setSubject:(NSString *)_s {
  if (![_s isEqualToString:[self subject]]) {
    NSDictionary *attr;

    attr = [NSDictionary dictionaryWithObject:_s forKey:@"NSFileSubject"];
    if (![[self fileManager] changeFileAttributes:attr atPath:[self path]]) {
      NSLog(@"%s - setSubject failed", __PRETTY_FUNCTION__);
      return;
    }
    ASSIGN(self->subject, _s);
  }
}
- (NSString *)subject {
  return self->subject;
}

- (NSData *)blob {
  if (self->blob == nil) {
    self->blob = [[self fileManager] contentsAtPath:[self path]];
    RETAIN(self->blob);
  }
  return self->blob;
}

- (void)setContent:(NSData *)_c {} // <SkyBLOBDocument> wants setContent
- (NSData *)content {
  return [self blob];
}

- (void)setContentString:(NSString *)_c {} // see setContent
- (NSString *)contentAsString {
  NSData   *data;
  NSString *s;
  
  if (!(data = [self content]))
    return nil;
  
  s = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
  return AUTORELEASE(s);
}

- (id)fileManager {
  return self->fileManager;
}

- (BOOL)isVersioned {
  return NO;
}
- (BOOL)isDeletable {
  return NO;
}
- (BOOL)isReadable {
  return YES;
}
- (BOOL)isWriteable {
  return NO;
}
- (BOOL)isInsertable {
  return NO;
}
- (BOOL)isLocked {
  return NO;
}
- (BOOL)isDirectory {
  return NO;
}

/* identification */


- (BOOL)isEqual:(id)_obj {
  if (_obj == self)
    return YES;

  if ([_obj isKindOfClass:[SkyProjectHistoryDocument class]])
    return [[self path] isEqualToString:[_obj path]];
  
  return NO;
}

- (EOGlobalID *)globalID {
  return nil;
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"NSFilePath"]) {
    return [self path];
  }
  else if ([_key isEqualToString:@"NSFileName"]) {
    return [self filename];
  }
  else if ([_key isEqualToString:@"NSFileSubject"]) {
    return [self subject];
  }
  else if ([_key isEqualToString:@"NSFileSize"]) {
    return [NSNumber numberWithInt:[self size]];
  }
  
  return nil;
}

- (id)mainDocument {
  if (self->mainDocument == nil) {
    NSString *p;

    p = [[self path] stringByDeletingPathVersion];
    self->mainDocument = [[self fileManager] documentAtPath:p];
    RETAIN(self->mainDocument);
  }
  return self->mainDocument;
}

@end /* SkyProjectHistoryDocument */
