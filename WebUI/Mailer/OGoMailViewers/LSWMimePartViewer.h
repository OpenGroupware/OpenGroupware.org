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

#ifndef __OGoMailViewers_LSWMimePartViewer_H__
#define __OGoMailViewers_LSWMimePartViewer_H__

#include <OGoFoundation/OGoComponent.h>
#import <NGObjWeb/WOSession.h>

@class NSString, NSArray, NSNumber, NSData;
@class NGMimeType;

@interface LSWMimePartViewer : OGoComponent
{
@protected
  id          part;
  BOOL        showHeaders;
  BOOL        showBody;  
  int         nestingDepth;
  WOComponent *bodyViewer;
  id          source;
  BOOL        printMode;
}

// part

- (BOOL)isDownloadable;  

- (void)setPart:(id)_part;
- (id)part;

- (void)setSource:(id)_source;
- (id)source;

// body
- (NSData *)contentForURL:(NSURL *)_url;
- (id)body;

// body viewer


- (NSString *)partKey;

- (WOComponent *)bodyViewerComponent;

// headers

- (NGMimeType *)contentType;
- (NSString *)contentId;
- (NSArray *)contentLanguage;
- (NSString *)contentMd5;
- (NSString *)encoding;
- (NSString *)contentDescription;

// accessors

- (BOOL)showBody;
- (void)setShowBody:(BOOL)_body;

- (BOOL)printMode;
- (void)setPrintMode:(BOOL)_print;

@end

@interface WOSession(ViewerSelection)

- (NSString *)viewerComponentForPart:(id)_part;

@end

#endif
