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

#include "SkyPubFileManager.h"
#include "SkyPubDataSource.h"
#include "SkyDocument+Pub.h"
#include <NGExtensions/EOFilterDataSource.h>
#include "common.h"

static NSMapTable *wrapperCache = NULL;

@implementation NSObject(PubFileManager)

- (SkyPubFileManager *)asPubFileManager {
  SkyPubFileManager *wrapper;
  
  if (wrapperCache) {
    if ((wrapper = NSMapGet(wrapperCache, self)))
      return [[wrapper retain] autorelease];
  }
  
  if (![self conformsToProtocol:@protocol(NGFileManager)])
    return nil;

  return
    [[[SkyPubFileManager alloc] initWithFileManager:(id)self] autorelease];
}

@end /* NSObject(PubFileManager) */

@implementation SkyPubFileManager

static BOOL cacheMappings = YES;
static BOOL onlyCacheDirs = NO;

+ (int)version {
  return [super version] + 0 /* v0 */;
}
+ (void)initialize {
  NSAssert2([super version] == 0,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (SkyPubFileManager *)asPubFileManager {
  return self;
}

+ (SkyPubFileManager *)wrappedFileManager:(id<NGFileManager,NSObject>)_fm {
  return [(id)_fm asPubFileManager];
}

- (id)initWithFileManager:(id<NGFileManager,NSObject>)_fm {
  if (wrapperCache == NULL && cacheMappings) {
    wrapperCache = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,
                                    NSNonOwnedPointerMapValueCallBacks,
                                    256);
  }
  if ((self = [super init])) {
    self->fileManager = RETAIN(_fm);
    
    self->fminfo =
      [[NGCustomFileManagerInfo alloc] initWithCustomFileManager:self
                                       fileManager:_fm];
    
    if (wrapperCache)
      NSMapInsert(wrapperCache, self->fileManager, self);
  }
  return self;
}
- (id)init {
  return [self initWithFileManager:nil];
}

- (void)dealloc {
  if ((self->fileManager != nil) && (wrapperCache != NULL))
    NSMapRemove(wrapperCache, self->fileManager);
  
  [self->fminfo resetMaster];
  [self->pathToDoc   release];
  [self->fminfo      release];
  [self->fileManager release];
  [super dealloc];
}

/* accessors */

- (NSException *)lastException {
  if ([self->fileManager respondsToSelector:@selector(lastException)])
    return [(id)self->fileManager lastException];
  return nil;
}

- (id<NGFileManager,NSObject>)fileManager {
  return self->fileManager;
}

- (NGCustomFileManagerInfo *)fileManagerInfoForPath:(NSString *)_path {
  return self->fminfo;
}

- (void)enableCache {
  if (self->pathToDoc == nil)
    self->pathToDoc = [[NSMutableDictionary alloc] initWithCapacity:256];
}
- (void)disableCache {
  NSAutoreleasePool *pool;
  
  pool = [[NSAutoreleasePool alloc] init];
  [self->pathToDoc release]; self->pathToDoc = nil;
  [pool release];
}

/* index */

- (NSString *)indexFilePathForDirectory:(NSString *)_dirPath {
  SkyDocument *folderDoc;
  
  if ((folderDoc = [self documentAtPath:_dirPath]) == nil)
    return nil;
  
  return [folderDoc pubIndexFilePath];
}

/* datasources */

- (EODataSource *)dataSourceAtPath:(NSString *)_path {
  EODataSource *ds;
  
  if ((ds = [super dataSourceAtPath:_path]) == nil)
    return nil;
  
  return [[[SkyPubDataSource alloc]
                             initWithFileManager:self dataSource:ds]
                             autorelease];
}

/* gid backmapping */

- (NSString *)pathForGlobalID:(EOGlobalID *)_gid {
  NSString *p;

  p = [self->fileManager pathForGlobalID:_gid];
  p = [self makeAbsolutePath:p];
  
  return p;
}

/* SkyProjectFileManager special ... */

- (id)documentCachedAtPath:(NSString *)_path {
  SkyDocument *doc;
  doc = [self->pathToDoc objectForKey:_path];
  return [doc isNotNull] ? doc : nil;
}

- (void)addDocumentToCache:(SkyDocument *)_doc path:(NSString *)path {
  if (onlyCacheDirs) {
    if (![[_doc valueForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
      /* only cache dirs */
      return;
  }
  
  if ((path != nil) && (_doc != nil))
    [self->pathToDoc setObject:_doc forKey:path];
}
- (void)addDocumentToCache:(id)_doc {
  [self addDocumentToCache:_doc path:[_doc valueForKey:@"NSFilePath"]];
}

- (void)pubFlush {
  [self->pathToDoc removeAllObjects];
}
- (void)flush {
  [self pubFlush];
  if ([self->fileManager respondsToSelector:_cmd])
    [(SkyPubFileManager *)self->fileManager flush];
}

- (BOOL)isOperation:(NSString *)_op allowedOnPath:(NSString *)_path {
  if (![self->fileManager
            respondsToSelector:@selector(isOperation:allowedOnPath:)]) {
    if ([_op rangeOfString:@"w"].length > 0) {
      if (![self->fileManager isWritableFileAtPath:_path])
        return NO;
    }
    if ([_op rangeOfString:@"r"].length > 0) {
      if (![self->fileManager isReadableFileAtPath:_path])
        return NO;
    }
    if ([_op rangeOfString:@"d"].length > 0) {
      if (![self->fileManager isDeletableFileAtPath:_path])
        return NO;
    }
    return YES;
  }
  
  return [(id)self->fileManager isOperation:_op allowedOnPath:_path];
}

/* existance */

- (BOOL)fileExistsAtPath:(NSString *)_path isDirectory:(BOOL *)_isDir {
  SkyDocument *doc;
  BOOL ok;

  /* check cache */
  
  if ((doc = [self->pathToDoc objectForKey:_path])) {
    if (![doc isNotNull]) {
      /* it is cached that it doesn't exists .. */
      if (_isDir) *_isDir = NO;
      return NO;
    }
    
    if (_isDir) {
      *_isDir = [[doc valueForKey:NSFileType]
                      isEqualToString:NSFileTypeDirectory] ? YES : NO;
    }
    return YES;
  }

  ok = [self->fileManager fileExistsAtPath:_path isDirectory:_isDir];
  if (!ok) {
    //[self logWithFormat:@"did not find path: %@ in %@", 
    //        _path, self->fileManager];
    [self->pathToDoc setObject:[NSNull null] forKey:_path];
  }
  return ok;
}

/* documents */

- (id)documentAtPath:(NSString *)_path {
  id doc;

  if ((doc = [self->pathToDoc objectForKey:_path]))
    return ![doc isNotNull] ? nil : doc;
  
  _path = [self standardizePath:[self makeAbsolutePath:_path]];
  
  if ((doc = [self->pathToDoc objectForKey:_path]))
    return ![doc isNotNull] ? nil : doc;

#if 0
  NSLog(@"doc cache miss: %@ (fm=0x%08X,src=0x%08X,cache=%s)",
        _path, self, self->fileManager,
        pathToDoc?"yes":"no");
#endif
  
  doc = [(id)self->fileManager documentAtPath:_path];
  
  /* only cache directories ... */
  if (doc == nil)
    /* cache doc as non-existing */
    [self->pathToDoc setObject:[NSNull null] forKey:_path];
  else
    [self addDocumentToCache:doc path:_path];
  
  return doc;
}

/* description */

- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:64];
  [ms appendFormat:@"<0x%08X[%@]:", self, NSStringFromClass([self class])];
  
  if (self->fileManager)
    [ms appendFormat:@" source=%@", self->fileManager];

  if (self->pathToDoc)
    [ms appendFormat:@" #cache=%i", [self->pathToDoc count]];
  
  [ms appendString:@">"];
  return ms;
}

@end /* SkyPubFileManager */
