/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#ifndef __Projects_SxDocument_H__
#define __Projects_SxDocument_H__

#include <ZSFrontend/SxObject.h>

/*
  SxDocument
    
    parent-folder: SxDocumentFolder
*/

@class NSString, NSDictionary;
@class EOGlobalID;
@class SxProjectFolder, SkyDocument;

@interface SxDocument : SxObject
{
  NSDictionary *attrCache;
}

- (id)initWithName:(NSString *)_key inContainer:(id)_folder;

/* accessors */

- (EOGlobalID *)projectGlobalIDInContext:(id)_ctx;
- (SxProjectFolder *)projectFolder;

- (id)fileManagerInContext:(id)_ctx;
- (id)fileManager;
- (NSString *)storagePath;

- (SkyDocument *)documentInContext:(id)_ctx;

@end

#endif /* __Projects_SxDocument_H__ */
