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

#ifndef __OGoProjects_OGoFileManagerFactory_H__
#define __OGoProjects_OGoFileManagerFactory_H__

#import <Foundation/NSObject.h>

@class NSURL, NSArray;
@class EOGlobalID;

/**
 * @protocol SkyFileManager
 * @brief Protocol for OGo project file managers.
 *
 * Defines the initialization method that all OGo project
 * file manager implementations must support.
 */
@protocol SkyFileManager
- (id)initWithContext:(id)_context projectGlobalID:(EOGlobalID *)_gid;
@end

/**
 * @class OGoFileManagerFactory
 * @brief Factory for creating project file managers based
 *        on the project's storage backend.
 *
 * Discovers available project storage backends (Skyrix DB,
 * Subversion, FileSystem) via bundle resources and creates
 * the appropriate NGFileManager subclass for a given
 * project. Provides base URL accessors for each backend
 * and a shared singleton instance.
 *
 * @see SkyFileManager
 * @see SkyProject
 */
@interface OGoFileManagerFactory : NSObject

+ (id)sharedFileManagerFactory;

- (NSArray *)availableProjectBases;

- (id)fileManagerInContext:(id)_context forProject:(id)_project;
- (id)fileManagerInContext:(id)_context forProjectGID:(EOGlobalID *)_gid;

- (NSURL *)skyrixBaseURL;
- (NSURL *)subversionBaseURL;
- (NSURL *)fileSystemBaseURL;

- (NSURL *)newFileSystemURLWithContext:(id)_ctx;

- (NSURL *)newURLForProjectBase:(NSString *)_base
  stringValue:(NSString *)_str
  commandContext:(id)_ctx;

@end

#endif /* __OGoProjects_OGoFileManagerFactory_H__ */
