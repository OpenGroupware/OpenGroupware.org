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

#include <OGoFoundation/OGoComponent.h>
#include <OGoDocuments/SkyDocumentFileManager.h>

/*
  OGoProjectDocView
  
  A component which displays a view similiar to the one used in the project
  viewer to show the project document hierarchy (the document tab).
  
  TODO: SkyProject4Viewer should actually use this component.

  Parameters:
    'fileManager' (in) - the filemanager to show 
*/

@class NSString, NSDictionary, NSMutableDictionary;

@interface OGoProjectDocView : OGoComponent
{
  id<NSObject,SkyDocumentFileManager> fileManager;
  NSMutableDictionary *pathToDS;
  NSDictionary *fsinfo;
  NSString     *folderDropPath;
}

@end

#include "common.h"

@implementation OGoProjectDocView

static BOOL showUnknownFiles_value = NO;
static BOOL showUnknownFiles_flag  = NO;

#if 0 // hh asks: why is it commented out??
- (void)clearPathCache {
  [self->pathToDS removeAllObjects];
}
#endif

- (void)dealloc {
  [self->pathToDS       release];
  [self->folderDropPath release];
  [self->fileManager    release];
  [super dealloc];
}

/* accessors */

- (void)setFileManager:(id<NSObject,SkyDocumentFileManager>)_fm {
  if (_fm == self->fileManager)
    return;
  ASSIGN(self->fileManager, _fm);
  [self->fileManager changeCurrentDirectoryPath:@"/"];
  [self->pathToDS removeAllObjects];
}
- (id<NSObject,SkyDocumentFileManager>)fileManager {
  return self->fileManager;
}

- (NSDictionary *)fileSystemAttributes {
  if (self->fsinfo != nil)
    return self->fsinfo;
  
  self->fsinfo = [[[self fileManager] fileSystemAttributesAtPath:@"/"] copy];
  return self->fsinfo;
}

- (NSString *)label {
  NSString *s;
  
  s = [[self fileSystemAttributes] objectForKey:@"NSFileSystemName"];
  return s;
}

- (NSString *)shortTitle { // TODO: should be a formatter
  NSString *title;

  title = [self label];
  if ([title length] > 15)
    title = [[title substringToIndex:13] stringByAppendingString:@".."];
  return title;
}

- (void)setFolderDropPath:(NSString *)_path {
  ASSIGNCOPY(self->folderDropPath, _path);
}
- (NSString *)folderDropPath {
  return self->folderDropPath;
}

/* defaults */

- (NSString *)_projectConfigKey:(NSString *)_subkey {
  NSString *ckey;
  
  ckey =  [NSString stringWithFormat:@"skyp4_p%@_%@",
                      [[self fileSystemAttributes]
                             objectForKey:@"NSFileSystemName"],
                      _subkey];
  
  return ckey;
}

- (BOOL)defaultFileListShouldHideFolders {
  return [[[(OGoSession *)[self session] userDefaults]
            objectForKey:@"skyp4_filelist_hide_folders"] boolValue];
}

- (BOOL)defaultHideTreeStatus {
  return [[[[self context] request] clientCapabilities] isFastTableBrowser]
    ? NO : YES;
}

- (void)setHideTree:(BOOL)_flag {
  [[[self session] userDefaults]
          setObject:[NSNumber numberWithBool:_flag]
          forKey:[self _projectConfigKey:@"hidetree"]];
}
- (BOOL)hideTree {
  id o;
  
  o = [[[self session] userDefaults]
              objectForKey:[self _projectConfigKey:@"hidetree"]];
  
  return (o == nil) ? [self defaultHideTreeStatus] : [o boolValue];
}

static inline BOOL _showUnknownFiles(id self) {
  if (!showUnknownFiles_flag) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    showUnknownFiles_flag  = YES;
    showUnknownFiles_value =
      [ud boolForKey:@"SkyProjectFileManager_show_unknown_files"];
  }
  return showUnknownFiles_value;
}

- (EOQualifier *)hideFoldersQualifier {
  static EOQualifier *hideFoldersQ = nil;
  EOQualifier *q;
  
  if (hideFoldersQ != nil)
    return hideFoldersQ;

  if (_showUnknownFiles(self)) {
    q = [EOQualifier qualifierWithQualifierFormat:
                           @"(NSFileType != 'NSFileTypeDirectory')", nil];
  }
  else {
    q = [EOQualifier qualifierWithQualifierFormat:
                           @"(NSFileType != 'NSFileTypeDirectory') AND"
                           @"(NSFileType != 'NSFileTypeUnknown')", nil];
  }
  hideFoldersQ = [q retain];
  return hideFoldersQ;
}
- (EOQualifier *)showFoldersQualifier {
  static EOQualifier *showFoldersQ = nil;
  EOQualifier *q;
    
  if (showFoldersQ != nil)
    return showFoldersQ;

  if (!_showUnknownFiles(self)) {
    q = [EOQualifier qualifierWithQualifierFormat:
		       @"(NSFileType != 'NSFileTypeUnknown')", nil];
  }
  else
    q = nil;
  
  showFoldersQ = [q retain];
  return showFoldersQ;
}

/* datasources */

- (void)cacheDataSource:(EODataSource *)_ds forPath:(NSString *)_path {
  if (_ds == nil || _path == nil)
    return;

  if (self->pathToDS == nil)
    self->pathToDS = [[NSMutableDictionary alloc] initWithCapacity:8];
  
  [self->pathToDS setObject:_ds forKey:_path];
}
- (id)selectedDataSource {
  /* TODO: split up this method */
  EOFetchSpecification *fspec;
  EOQualifier          *q;
  BOOL                 hideFolders;
  NSString             *path;
  id                   ds;
  
  path = [[self fileManager] currentDirectoryPath];

#if 0  
  { /* notifications */
    NSString *notName;
#warning Use internal filemanager methods
    
    notName = [(id)[self fileManager] _unvalidateNotificationNameForPath:path];
    // TODO: remember to unregister in -dealloc when enabling this code!
    [[NSNotificationCenter defaultCenter] addObserver:self
                                          selector:@selector(clearPathCache)
                                          name:notName object:nil];
  }
#endif  
  ds = [self->pathToDS objectForKey:path];
  if (ds == nil || ![ds isValid]) {
    q = ((hideFolders = [self defaultFileListShouldHideFolders]))
      ? [self hideFoldersQualifier]
      : [self showFoldersQualifier];
    
    fspec = [EOFetchSpecification fetchSpecificationWithEntityName:nil
                                  qualifier:q
                                  sortOrderings:nil];
    
    if ([[self fileManager] supportsFolderDataSourceAtPath:path]) {
      ds = [(id<NGFileManagerDataSources>)[self fileManager]
                                          dataSourceAtPath:path];
    }
    
    [self cacheDataSource:ds forPath:path];
    [ds setFetchSpecification:fspec];
  }
  
  return [[ds retain] autorelease];
}

/* actions */

- (id)droppedOnFolder {
  id         dropFile;
  EOGlobalID *dropFileGID;
  NSString   *dropFilePath;
  NSString   *destPath;

  if ((dropFile = [self valueForKey:@"droppedFile"]) == nil) {
    [[[self context] page] setErrorString:@"missing drop-object"];
    return nil;
  }
  
  if ((dropFileGID = [dropFile valueForKey:@"globalID"]) == nil) {
    [[[self context] page] setErrorString:@"missing id of dropped object"];
    return nil;
  }
  
  dropFilePath = [[self fileManager] pathForGlobalID:dropFileGID];
  if (dropFilePath == nil) {
    /* should make link ! */
    [[[self context] page] setErrorString:
			     @"dropped object from different filemanager"];
    return nil;
  }

  destPath = [self valueForKey:@"folderDropPath"];
  destPath = [destPath stringByAppendingPathComponent:
                         [dropFilePath lastPathComponent]];
  
  if (![[self fileManager] movePath:dropFilePath
                           toPath:destPath handler:nil]) {
#if 0 // hh asks: why commented out?
    [[[self context] page] setErrorString:@"move operation failed"];
#endif
    return nil;
  }
  
  return nil;
}

- (id)doShowTree {
  [self setHideTree:NO];
  return nil;
}
- (id)doHideTree {
  [self setHideTree:YES];
  return nil;
}

@end /* OGoProjectDocView */
