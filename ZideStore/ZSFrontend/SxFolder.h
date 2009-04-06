/*
  Copyright (C) 2002-2009 SKYRIX Software AG
  Copyright (C) 2006-2009 Helge Hess

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

#ifndef __Frontend_SxFolder_H__
#define __Frontend_SxFolder_H__

#import <Foundation/NSObject.h>

/*
  SxFolder

  This is intended as a general superclass for OGo virtual folders. It
  does all the basic setup, common methods, etc.
*/

@class NSSet, NSString, NSArray;
@class EOFetchSpecification;
@class LSCommandContext;

@interface SxFolder : NSObject
{
  NSString *nameInContainer;
  id       container; /* can be non-retained */
  
  NSString *baseURL;
  id       baseContext; // non-retained
  NSArray  *subPropMapper;
}

- (id)initWithName:(NSString *)_name inContainer:(id)_container;

/* accessors */

- (void)setContainer:(id)_container;
- (id)container;

- (BOOL)doExplainQueries;

/* naming */

- (NSString *)fileExtensionForChildrenInContext:(id)_ctx;

/* OpenGroupware.org */

- (LSCommandContext *)commandContextInContext:(id)_ctx;

/* Exchange Access Control */

- (BOOL)isReadAllowed;
- (BOOL)isModificationAllowed;
- (BOOL)isItemCreationAllowed;
- (BOOL)isFolderCreationAllowed;
- (BOOL)isDeletionAllowed;

- (NSString *)outlookFolderClass;

/* ZideLook specialties */

- (void)setAssociatedContents:(NSString *)_value;
- (NSString *)associatedContents;

/* property sets */

- (NSSet *)propertySetNamed:(NSString *)_name;

/* factory */

- (Class)recordClassForKey:(NSString *)_key;
- (id)childForNewKey:(NSString *)_key      inContext:(id)_ctx;
- (id)childForExistingKey:(NSString *)_key inContext:(id)_ctx;

/* URLs */

- (NSString *)baseURL;

/* ZideLook queries common for all folders */

- (BOOL)isWebDAVListQuery:(EOFetchSpecification *)_fs;
- (BOOL)isETagsQuery:(EOFetchSpecification *)_fs;

/* actions */

- (id)GETAction:(id)_ctx;
- (id)PUTAction:(id)_ctx;
- (id)DELETEAction:(id)_ctx;

- (id)getIDsAndVersionsAction:(id)_ctx;
- (NSString *)getIDsAndVersionsInContext:(id)_ctx;
- (NSArray *)getIDsAndVersionsArrayInContext:(id)_ctx;

@end

@interface SxFolder(ZL)

- (id)cdoAccess;

- (int)zlGenerationCount;

- (id)performSubFolderQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx;

@end

@interface SxFolder(WebDAV)

/* URLs */

- (NSArray *)extractBulkPrimaryKeys:(EOFetchSpecification *)_fs;
- (NSArray *)extractBulkGlobalIDs:(EOFetchSpecification *)_fs;
- (NSArray *)davURLRecordsForChildGIDs:(NSArray *)_gids inContext:(id)_ctx;

/* DAV operations */

- (id)performWebDAVQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx;
- (id)performWebDAVBulkQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx;

// this method is used to classify a request !
- (SEL)fetchSelectorForQuery:(EOFetchSpecification *)_fs
  onAttributeSet:(NSSet *)_attrSet
  inContext:(id)_ctx;

/* folder allprop sets */

- (NSString *)folderAllPropSetName;
- (NSString *)entryAllPropSetName;
- (BOOL)isBulkQueryContext:(id)_ctx; /* required for selecting the proper set */
- (NSArray *)defaultWebDAVPropertyNamesInContext:(id)_ctx;

@end

/* 
  if the following method is implemented by subclasses, it's called 
  automatically 
*/

@interface SxFolder(GlobalIDBulkQueries)

- (id)performBulkQuery:(EOFetchSpecification *)_fs
  onGlobalIDs:(NSArray *)_gids
  inContext:(id)_ctx;

/* query for just the 'davURL' */
- (id)performDavURLQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx;

/* query for just 'DAV:getetag' */
- (id)performETagsQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx;

@end

@interface NSObject(ContainerRetainManagement)

/* 
  Whether a child is supposed to retain this container. This must return
  "NO" for containers which keep a cache of their children, otherwise you
  get retain cycles. Default is YES.
*/
- (BOOL)shouldRetainAsSoContainer;

@end

#endif /* __Frontend_SxFolder_H__ */
