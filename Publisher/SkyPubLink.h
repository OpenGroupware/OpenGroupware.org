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

#ifndef __SkyPubLink_H__
#define __SkyPubLink_H__

#include "SkyPubLinkManager.h"

@class EOGlobalID;
@class SkyPubFileManager;

@interface SkyPubLink : NSObject < SkyPubLink >
{
  id                node;
  SkyPubLinkManager *manager; // non-retained
}

+ (id)linkWithNode:(id)_node manager:(SkyPubLinkManager *)_manager;

/* accessors */

- (SkyPubFileManager *)fileManager;

/* link */

- (NSString *)linkValue;

- (BOOL)isValid;
- (BOOL)isAbsoluteURL;
- (BOOL)isAbsolutePath;

/* target */

- (SkyDocument *)targetDocument;
- (EOGlobalID *)targetObjectIdentifier;
- (NSString *)absoluteTargetPath;
- (NSString *)relativeTargetPath;
- (NSString *)targetTitle;

@end

@interface SkyPubAnkerLink : SkyPubLink
@end

@interface SkyPubInputLink : SkyPubLink
@end

@interface SkyPubLinkLink : SkyPubLink
@end

@interface SkyPubImgLink : SkyPubLink
@end

@interface SkyPubScriptLink : SkyPubLink
@end

@interface SkyPubBGImgLink : SkyPubLink
@end

@interface SkyPubFormLink : SkyPubLink
@end

@interface SkyPubXLink : SkyPubLink
@end

#endif /* __SkyPubLink_H__ */
