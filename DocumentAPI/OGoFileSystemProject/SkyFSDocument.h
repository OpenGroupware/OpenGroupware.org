/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#ifndef __SkyFSDocument_H__
#define __SkyFSDocument_H__

#import <OGoDocuments/SkyDocument.h>
#import <NGExtensions/NGFileManager.h>

@class EOGlobalID, NSString, NSData, NGMimeType, SkyFSFileManager;

@interface SkyFSDocument : SkyDocument
  < SkyBLOBDocument, SkyStringBLOBDocument >
{
  SkyFSFileManager   *fileManager;
  id                  context;
  id                  project;
  NSString            *fileName;
  NSData              *content;
  NSString            *contentString;
  BOOL                contentChanged;
  BOOL                attributesChanged;
  NSString            *path;
  NSMutableDictionary *attributes;
  NGMimeType          *mimeType;
  NSString            *fileType;

  id blobAsDOM;
}

- (id)initWithFileManager:(id<NSObject,NGFileManager>)_fileManager 
  context:(id)_ctx project:(id)_project 
  path:(NSString *)_path fileName:(NSString *)_fn
  attributes:(NSDictionary *)_attrs;

- (BOOL)isInsertable;

- (id<NGFileManager>)fileManager;

- (NSString *)path;
- (NSString *)mimeType;

- (void)setContent:(NSData *)_data;
- (NSData *)content;
- (void)setContentString:(NSString *)_blob;
- (NSString *)contentAsString;


@end /* SkyFSDocument */

@interface SkyFSDocument(DOM) < SkyDOMBLOBDocument >
@end

#endif /* __SkyFSDocument_H__ */

