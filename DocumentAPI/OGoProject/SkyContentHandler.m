/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include "SkyContentHandler.h"
#include "common.h"

@interface NSEmptyFileManagerBlobHandler : NSObject <SkyBlobHandler>
- (NSData *)blob;
@end

@implementation NSEmptyFileManagerBlobHandler

- (NSData *)blob {
  return [NSData data];
}

@end /* NSEmptyFileManagerBlobHandler */


@implementation NSFileManagerBlobHandler

static NSEmptyFileManagerBlobHandler *EmptyFileManagerBlobHandler = nil;

+ (id)emptyBlobHandler {
  if (EmptyFileManagerBlobHandler == nil)
    EmptyFileManagerBlobHandler = [[NSEmptyFileManagerBlobHandler alloc] init];
  
  return EmptyFileManagerBlobHandler;
}

- (id)initWithFileManager:(id<NSObject,NGFileManager>)_fm 
  path:(NSString *)_path 
{
  if ([_path length] == 0)
    return [[NSFileManagerBlobHandler emptyBlobHandler] retain];

  if (![_fm fileExistsAtPath:_path])
    return [[NSEmptyFileManagerBlobHandler emptyBlobHandler] retain];
  
  if ((self = [super init])) {
    self->fm   = [_fm retain];
    self->path = [_path copy];
  }
  return self;
}

- (void)dealloc {
  [self->fm   release];
  [self->path release];
  [super dealloc];
}

/* accessors */

-(NSData *)blob {
  return [self->fm contentsAtPath:self->path];
}

@end /* NSFileManagerBlobHandler */

@implementation NSFileManager(BlobHandler)

- (BOOL)supportsBlobHandler {
  return YES;
}

- (id<SkyBlobHandler>)blobHandlerAtPath:(NSString *)_path {
  return [[[NSFileManagerBlobHandler alloc] 
            initWithFileManager:(id<NGFileManager>)self path:_path] 
            autorelease];
}


@end /*NSFileManager(BlobHandler) */

