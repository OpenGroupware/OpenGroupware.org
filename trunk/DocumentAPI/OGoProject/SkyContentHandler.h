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

@protocol SkyBlobHandler
-(NSData *)blob;
@end /* SkyContentHandler */


@interface NSFileManager(BlobHandler)
- (BOOL)supportsBlobHandler;
- (id<SkyBlobHandler>)blobHandlerAtPath:(NSString *)_path;
@end

@interface NSFileManagerBlobHandler : NSObject <SkyBlobHandler> 
{
@protected
  NSFileManager *fm;
  NSString      *path;
}

+ (id)emptyBlobHandler;
- (id)initWithFileManager:(id<NGFileManager>)_fm path:(NSString *)_path;

/* accessors */

- (NSData *)blob;

@end /* NSFileManagerBlobHandler */
