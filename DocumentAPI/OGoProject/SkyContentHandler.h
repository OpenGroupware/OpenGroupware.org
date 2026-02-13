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

#include <Foundation/NSFileManager.h>
#include <NGExtensions/NGFileManager.h>

@class NSString, NSData;

/**
 * @protocol SkyBlobHandler
 * @brief Protocol for lazy-loading binary content from a
 *        file manager.
 *
 * Defines a single method to retrieve binary data (BLOB)
 * on demand, avoiding eager loading of potentially large
 * file contents.
 */
@protocol SkyBlobHandler
-(NSData *)blob;
@end /* SkyBlobHandler */

/**
 * @category NSFileManager(BlobHandler)
 * @brief Adds BLOB handler support to NSFileManager.
 *
 * Extends NSFileManager to indicate it supports the BLOB
 * handler pattern and to vend SkyBlobHandler instances for
 * file paths.
 */
@interface NSFileManager(BlobHandler)
- (BOOL)supportsBlobHandler;
- (id<SkyBlobHandler>)blobHandlerAtPath:(NSString *)_path;
@end

/**
 * @class NSFileManagerBlobHandler
 * @brief SkyBlobHandler that reads content from an
 *        NGFileManager path.
 *
 * Lazily loads the binary content of a file from an
 * NGFileManager instance. Returns an empty blob handler
 * if the path is empty or the file does not exist.
 *
 * @see SkyBlobHandler
 */
@interface NSFileManagerBlobHandler : NSObject <SkyBlobHandler>
{
@protected
  NSFileManager *fm;
  NSString      *path;
}

+ (id)emptyBlobHandler;
- (id)initWithFileManager:(id<NSObject,NGFileManager>)_fm path:(NSString *)_p;

/* accessors */

- (NSData *)blob;

@end /* NSFileManagerBlobHandler */
