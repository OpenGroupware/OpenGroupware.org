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

#ifndef __SkyProjectDocument_H__
#define __SkyProjectDocument_H__

#include <OGoDocuments/SkyDocument.h>

/*
  SkyProjectDocument

  Note: this document object does not represent a project but a file in a
        database project. The 'document' class for project documents is
	'SkyProject'.
  
  TODO: document
*/

@class NSString, NSData, NSMutableDictionary, NSDictionary, NSArray;
@class SkyObjectPropertyManager, SkyProjectFileManager, SkyProjectFolderDataSource;
@class LSCommandContext;
@class EODataSource;

/*
  Default-Namespace: http://www.skyrix.com/namespaces/project-document
*/

#ifndef XMLNS_PROJECT_DOCUMENT
#define XMLNS_PROJECT_DOCUMENT \
  @"http://www.skyrix.com/namespaces/project-document"
#endif

@interface SkyProjectDocument : SkyDocument
  < SkyBLOBDocument, SkyStringBLOBDocument >
{
  SkyProjectFileManager      *fileManager;
  SkyProjectFolderDataSource *dataSource;
  
  // TODO: make it a bitset-struct
  struct {
    BOOL isEdited;
    BOOL blobChanged;
    BOOL subjectChanged;
    BOOL isValid;
    BOOL isComplete;
  } status;
  
   /* core attributes */
  NSString     *subject;
  NSData       *blob;
  id           blobAsDOM;
  EOGlobalID   *globalID;
  NSMutableDictionary *fileAttributes;
  
  /* default extended attributes (native-namespace) */
  NSMutableDictionary *attributes;
  NSMutableDictionary *updateAttrs;
  NSMutableDictionary *newAttrs;
  
  /* extended attributes */
  NSMutableDictionary *extendedAttributes;
  NSMutableDictionary *updateExtAttrs;
  NSMutableDictionary *newExtAttrs;
}

- (id)initWithGlobalID:(EOGlobalID *)_gid
  fileManager:(SkyProjectFileManager*)_fm;

/* document status */

- (void)invalidate;
- (BOOL)isValid;

- (BOOL)isNew;
- (BOOL)isEdited;
- (BOOL)isComplete; /* is no if doc is initialize with attrs, use reload */

/* document system properties */

- (BOOL)isVersioned;
- (BOOL)isDeletable;
- (BOOL)isReadable;
- (BOOL)isWriteable;
- (BOOL)isInsertable;
- (BOOL)isEdited;
- (BOOL)isLocked;
- (BOOL)isDirectory;

- (void)setSubject:(NSString *)_subj;
- (NSString *)subject;
- (NSString *)path;

/* attributes */

- (NSDictionary *)extendedAttributes;
- (NSDictionary *)extendedAttributesForNamespace:(NSString *)_ns;
- (NSDictionary *)attributes;
- (NSDictionary *)fileAttributes;

- (NSArray *)documentKeys;
- (NSArray *)readOnlyDocumentKeys;

/* related objects */

- (SkyProjectFileManager *)fileManager;
- (EODataSource *)folderDataSource;
- (EODataSource *)historyDataSource;

/* equality */

- (BOOL)isEqual:(id)_obj;
- (BOOL)isEqualToDocument:(SkyProjectDocument *)_doc;

@end

@interface SkyProjectDocument(DOM) < SkyDOMBLOBDocument >
@end

@interface SkyProjectDocument(ConvenienceMethods)

- (BOOL)save;
- (BOOL)delete;
- (BOOL)reload;

/* versioning */

- (BOOL)checkoutDocument;
- (BOOL)releaseDocument;

/* locking */

- (BOOL)lockDocument;
- (BOOL)unlockDocument;

@end

@interface SkyProjectDocument(Log)
- (void)logDownloadOfVersion:(NSString *)_version;
- (void)logDownload;
@end

#endif /* __SkyProjectDocument_H__ */
