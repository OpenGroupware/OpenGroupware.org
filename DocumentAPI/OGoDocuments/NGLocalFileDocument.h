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

#ifndef __NGLocalFileDocument_h__
#define __NGLocalFileDocument_h__

#include <OGoDocuments/SkyDocument.h>
#include <OGoDocuments/SkyDocumentFileManager.h>

@class NSNumber, NSData, NSDate, NSArray, NSMutableArray;
@class NSFileManager, NSDirectoryEnumerator, NSDictionary, NSString;
@class EOGlobalID;
@class NGFileDocument;

/**
 * @class NGLocalFileDocument
 * @brief Document backed by a local filesystem file.
 *
 * A concrete SkyDocument subclass that wraps a file on the
 * local filesystem. Provides access to the file content as
 * NSData or NSString (via SkyStringBLOBDocument), as well
 * as file attributes and a subject derived from the path.
 * Content is cached for performance.
 *
 * @see NGLocalFileManager
 * @see NGLocalFileGlobalID
 * @see SkyDocument
 */
@interface NGLocalFileDocument : SkyDocument < SkyStringBLOBDocument >
{
  EOGlobalID   *globalID;
  NSString     *path;
  id           fm;
  NSDictionary *attributes;
  
  /* cache */
  NSData   *content;
  NSString *contentString;
  id       contentDOM;
}

- (id)initWithPath:(NSString *)_path fileManager:(id)_fm;
- (id)initWithGlobalID:(EOGlobalID *)_gid;
- (id)initWithPath:(NSString *)_path fileManager:(id)_fm context:(id)_ctx;
- (id)initWithGlobalID:(EOGlobalID *)_gid context:(id)_ctx;

- (NSString *)path;
- (NSString *)subject;

- (NSDictionary *)attributes;
- (NSDictionary *)fileAttributes;
- (NSString *)contentAsString;

@end /* NGLocalFileDocument */

/**
 * @category NGLocalFileDocument(DOM)
 * @brief Adds DOM BLOB support to NGLocalFileDocument.
 *
 * Allows local file documents to represent their content
 * as a parsed DOM document object.
 */
@interface NGLocalFileDocument(DOM) < SkyDOMBLOBDocument >

- (id)contentAsDOMDocument;

@end /* NGLocalFileDocument(DOM) */

#endif /* __NGLocalFileDocument_h__ */
