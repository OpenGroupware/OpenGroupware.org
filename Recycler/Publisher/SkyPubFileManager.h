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

#ifndef __SkyPubFileManager_H__
#define __SkyPubFileManager_H__

#include <NGExtensions/NGCustomFileManager.h>
#include <OGoDocuments/SkyDocumentFileManager.h>

@class NSException, NSURL, NSMutableDictionary;
@class SkyDocument;

@interface SkyPubFileManager : NGCustomFileManager < SkyDocumentFileManager >
{
  id<NGFileManager,NSObject> fileManager;
  NGCustomFileManagerInfo    *fminfo;
  
  NSMutableDictionary *pathToDoc;
}

- (id)initWithFileManager:(id<NGFileManager,NSObject>)_fm;

/* accessors */

- (id<NGFileManager,NSObject>)fileManager;
- (NSException *)lastException;

/* documents */

- (id)documentAtPath:(NSString *)_path;

/* index */

- (NSString *)indexFilePathForDirectory:(NSString *)_path;

/* cache management */

- (void)enableCache;
- (void)disableCache;
- (void)flush;
- (void)pubFlush;

- (void)addDocumentToCache:(SkyDocument *)_doc;
- (id)documentCachedAtPath:(NSString *)_path;

@end

@interface NSObject(PubFileManager)
- (SkyPubFileManager *)asPubFileManager;
@end

#endif /* __SkyPubFileManager_H__ */
