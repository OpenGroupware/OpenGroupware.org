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

#ifndef __SkyPubLinkManager_H__
#define __SkyPubLinkManager_H__

#import <Foundation/NSObject.h>

@class NSString, NSArray;
@class EOGlobalID;

@protocol SkyPubLink

- (BOOL)isValid;

- (NSString *)linkAttribute;
- (NSString *)linkAttributeNamespace;
- (NSString *)linkValue;
- (BOOL)isAbsoluteURL;
- (BOOL)isAbsolutePath;

- (NSString *)linkType;
- (NSString *)linkTitle;

- (EOGlobalID *)targetObjectIdentifier;
- (NSString *)targetTitle;
- (NSString *)targetReleaseState;

@end

@class SkyDocument, SkyPubFileManager;

@interface SkyPubLinkManager : NSObject
{
  SkyDocument       *document;
  NSArray           *linkCache;
  SkyPubFileManager *fileManager;
}

- (id)initWithDocument:(id)_doc fileManager:(id)_fileManager;

/* accessors */

- (SkyDocument *)document;
- (SkyPubFileManager *)fileManager;

/* query */

- (NSArray *)allLinks;
- (id<NSObject,SkyPubLink>)linkForElementNode:(id)_node;

@end

#endif /* __SkyPubLinkManager_H__ */
