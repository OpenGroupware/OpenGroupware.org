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

#ifndef __SkyDocument_H__
#define __SkyDocument_H__

#import <Foundation/NSObject.h>

/*
  A OGo document is an URL addressable unit consisting of attributes
  and optionally, a BLOB.
  
  The features of a document (whether it has a BLOB, whether it can represent
  the BLOB as DOM or strings), can be queried using -hasFeature:.
*/

@class NSURL, NSData, NSString, NSMutableString;
@class EOGlobalID;
@class SkyDocumentType;

@protocol SkyDocument

/* reflection information on document */
- (SkyDocumentType *)documentType;

/* is the document 'save' complete ? */
- (BOOL)isComplete;

/* feature check */
- (BOOL)supportsFeature:(NSString *)_featureURI;

@end

@protocol SkyDocumentEditing
/* properties */
- (BOOL)isReadable;
- (BOOL)isWriteable;
- (BOOL)isRemovable;
- (BOOL)isNew;
- (BOOL)isEdited;

/* saving and deleting */
- (BOOL)save;
- (BOOL)delete;
- (BOOL)reload;

@end

@protocol SkyBLOBDocument < SkyDocument >

#define SkyDocumentFeature_BLOB @"http://www.skyrix.com/document/blob"

- (void)setContent:(NSData *)_blob;
- (NSData *)content;

@end

@protocol SkyStringBLOBDocument < SkyDocument >

#define SkyDocumentFeature_STRINGBLOB \
  @"http://www.skyrix.com/document/stringblob"

- (void)setContentString:(NSString *)_blob;
- (NSString *)contentAsString;

@end

@protocol SkyDOMBLOBDocument < SkyDocument >

#define SkyDocumentFeature_DOMBLOB  @"http://www.skyrix.com/document/domblob"

- (void)setContentDOMDocument:(id)_dom;
- (id)contentAsDOMDocument;

@end

@interface SkyDocument : NSObject < SkyDocument, SkyDocumentEditing >

/* document identifier */
- (EOGlobalID *)globalID;

/* document URL */
- (NSURL *)documentURL;

/* SKYRiX context the document lives in */
- (id)context;

/* description */

- (void)appendAttributesToDescription:(NSMutableString *)_md;

@end

#endif /* __SkyDocument_H__ */
