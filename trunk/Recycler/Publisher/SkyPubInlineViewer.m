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

#include "SkyPubInlineViewer.h"
#include "SkyPubFileManager.h"
#include "SkyPubLinkManager.h"
#include "SkyDocument+Pub.h"
#include "common.h"

@interface NSObject(ResetDOM)
- (void)resetDOM;
@end

@implementation SkyPubInlineViewer

+ (int)version {
  return [super version] + 0 /* v2 */;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (void)dealloc {
  RELEASE(self->pubFileManager);
  RELEASE(self->linkManager);
  RELEASE(self->viewPath);
  RELEASE(self->document);
  RELEASE(self->fileManager);
  [super dealloc];
}

/* notifications */

- (void)sleep {
  if ([self->document respondsToSelector:@selector(resetDOM)])
     [self->document resetDOM];
  
  RELEASE(self->linkManager); self->linkManager = nil;
  RELEASE(self->document);    self->document = nil;
  RELEASE(self->viewPath);    self->viewPath = nil;
  [super sleep];
}

/* accessors */

- (void)setFileManager:(id<NSObject,NGFileManager>)_fm {
  if (self->fileManager == _fm)
    return;
  
  if ([_fm isKindOfClass:[SkyPubFileManager class]]) {
    [self setPubFileManager:(id)_fm];
    return;
  }
  
  ASSIGN(self->fileManager, _fm);
  [self->pubFileManager release]; self->pubFileManager = nil;
}
- (id<NSObject,NGFileManager>)fileManager {
  return self->fileManager;
}

- (void)setPubFileManager:(SkyPubFileManager *)_fm {
  ASSIGN(self->pubFileManager, _fm);
  ASSIGN(self->fileManager,    [_fm fileManager]);
}
- (SkyPubFileManager *)pubFileManager {
  if (self->pubFileManager == nil && self->fileManager != nil) {
    self->pubFileManager = [[(id)self->fileManager asPubFileManager] retain];
  }
  return self->pubFileManager;
}

- (NSString *)projectName {
  return [[[self pubFileManager]
                 fileSystemAttributesAtPath:[self viewPath]]
                 objectForKey:@"NSFileSystemName"];
}
- (EOGlobalID *)projectGlobalID {
  return [[[self pubFileManager]
                 fileSystemAttributesAtPath:[self viewPath]]
                 objectForKey:@"NSFileSystemNumber"];
}

- (void)setViewPath:(NSString *)_viewPath {
  ASSIGNCOPY(self->viewPath, _viewPath);
}
- (NSString *)viewPath {
  return self->viewPath;
}

- (void)setDocument:(SkyDocument *)_document {
  if (_document != self->document) {
    ASSIGN(self->document, _document);
    ASSIGN(self->linkManager, nil);
  }
}
- (SkyDocument *)document {
  return self->document;
}

- (SkyPubLinkManager *)linkManager {
  if (self->linkManager)
    return self->linkManager;
  
  self->linkManager =
    [[SkyPubLinkManager alloc] initWithDocument:[self document]
                               fileManager:[self pubFileManager]];
  
  return self->linkManager;
}

/* notifications */

/* methods */

@end /* SkyPubInlineViewer */
