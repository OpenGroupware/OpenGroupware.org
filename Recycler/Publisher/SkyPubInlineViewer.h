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

#ifndef __SkyPubInlineViewer_H__
#define __SkyPubInlineViewer_H__

#include <OGoFoundation/LSWComponent.h>
#include <OGoDocuments/SkyDocumentFileManager.h>

@class NSFileManager, NSString;
@class SkyPubLinkManager, SkyPubFileManager, SkyDocument;

@interface SkyPubInlineViewer : LSWComponent
{
  id<NSObject,NGFileManager> fileManager;
  SkyPubFileManager *pubFileManager;
  NSString          *viewPath;
  SkyDocument       *document;
  SkyPubLinkManager *linkManager;
}

- (void)setFileManager:(id<NSObject,NGFileManager>)_fm;
- (id<NSObject,NGFileManager>)fileManager;

- (void)setPubFileManager:(SkyPubFileManager *)_fm;
- (SkyPubFileManager *)pubFileManager;

- (void)setViewPath:(NSString *)_viewPath;
- (NSString *)viewPath;

- (void)setDocument:(SkyDocument *)_document;
- (SkyDocument *)document;
- (SkyPubLinkManager *)linkManager;

@end

@interface WOComponent(LM)
- (SkyPubLinkManager *)linkManager;
@end

#endif /* __SkyPubInlineViewer_H__ */
