/*
  Copyright (C) 2005 Helge Hess

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

#ifndef __OGoDocInlineViewers_OGoDocPartViewer_H__
#define __OGoDocInlineViewers_OGoDocPartViewer_H__

#include <OGoFoundation/OGoComponent.h>
#include <OGoDocuments/SkyDocumentFileManager.h>

/*
  OGoDocPartViewer

  Abstract superclass for viewer components which are used inside the
  OGo document viewer (usually as the content of one tab).

  Note: this component turns automatic synchronisation off.

  Required bindings:
  - fileManager
  - document
  - documentGlobalID
  - documentPath
*/

@class NSString, NSDictionary;
@class EOGlobalID, EODataSource;
@class SkyProjectDocument;

@interface OGoDocPartViewer : OGoComponent
{
  id<NSObject,SkyDocumentFileManager> fileManager;
  EODataSource       *historyDataSource;
  SkyProjectDocument *document;
  EOGlobalID         *documentGID;
  NSDictionary       *fsinfo;
}

/* notifications */

- (void)reset;
- (void)syncSleep;

/* accessors */

- (void)setFileManager:(id<NSObject,SkyDocumentFileManager>)_fm;
- (id<NSObject,SkyDocumentFileManager>)fileManager;

- (EOGlobalID *)documentGlobalID;
- (id)document;

- (EODataSource *)historyDataSource;

- (BOOL)canReadFile;

- (NSDictionary *)fileSystemInfo;

- (NSString *)_documentPath;
- (NSString *)documentName;
- (NSString *)documentMimeType;
- (NSDictionary *)documentAttributes;

/* actions */

- (id)editStandardAttrs;
- (id)editProperties;

@end

#endif /* __OGoDocInlineViewers_OGoDocPartViewer_H__ */
