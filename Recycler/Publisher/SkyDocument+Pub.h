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

#ifndef __SkyDocument_Pub_H__
#define __SkyDocument_Pub_H__

#include <OGoDocuments/SkyDocument.h>
#include <OGoDocuments/SkyDocumentFileManager.h>

@class NSString, NSArray, NSURL;
@class EODataSource;

@interface SkyDocument(Pub)

/* environment */

- (id<NSObject,SkyDocumentFileManager>)pubFileManager;
- (EODataSource *)pubChildDataSource;

/* path operations */

- (NSURL *)pubURL;

- (NSString *)pubPath;
- (NSString *)pubStandardizePath:(NSString *)_path;
- (NSString *)pubMakeAbsolutePath:(NSString *)_relpath;
- (NSString *)pubMakeRelativePath:(NSString *)_relpath;

/* links */

- (BOOL)pubIsValidLink:(NSString *)_link;
- (NSString *)pubRelativeTargetPathForLink:(NSString *)_link;
- (NSString *)pubAbsoluteTargetPathForLink:(NSString *)_link;

/* related documents */

- (SkyDocument *)parentDocument;
- (SkyDocument *)nextDocument;
- (SkyDocument *)previousDocument;
- (SkyDocument *)pubDocumentAtPath:(NSString *)_path;

// this 1) checks for attribute 'IndexFile'
//      2) checks for index.xhtml
//      3) checks for index.html
- (NSString *)pubIndexFilePath;
- (SkyDocument *)pubIndexDocument;

/* lists */

// returns all children
- (NSArray *)pubChildListDocuments;
// returns all directories and regular files
- (NSArray *)pubTocListDocuments;
// returns all documents of the project
- (NSArray *)pubAllDocuments;
// returns all symbolic links
- (NSArray *)pubRelatedLinkDocuments;
// returns all folders up to the root-folder, if self=folder self is added too
- (NSArray *)pubFolderDocumentsToRoot;

/* SKYRiX specific lists */

- (NSArray *)pubAllPersons;
- (NSArray *)pubAllEnterprises;
- (NSArray *)pubAllAccounts;
- (NSArray *)pubAllJobs;
- (NSArray *)pubAllAppointments;
- (NSArray *)pubAllProjects;
- (NSArray *)pubAllTeams;

@end /* SkyDocument(Pub) */

@interface SkyDocument(SKY)

- (NSString *)npsDocumentType;
- (NSString *)npsDocumentClassName;

/*
  Supports special keys:
  
    body - invalid in this context !!!
    contentType
    lastChanged
    hasSuperLinks
    id
    isRoot
    name
    path
    objClass
    objType
    prefixPath
    title
    version
    visibleName
    visiblePath
    parent
*/

@end

#endif /* __SkyDocument_Pub_H__ */
