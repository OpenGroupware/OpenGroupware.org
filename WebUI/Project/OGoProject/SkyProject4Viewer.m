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

#include <OGoFoundation/LSWViewerPage.h>
#include <OGoDocuments/SkyDocumentFileManager.h>

@class NSString, NSMutableSet, NSArray, NSMutableArray;
@class WOComponent;

/*
  SkyProject4Viewer

  A content page used to show a project. It embeds the documents view tab,
  the jobs tab etc.
  
  Defaults: (??)
    SkyProjectFileManager_show_unknown_files : show unknown files
*/

@interface SkyProject4Viewer : LSWViewerPage
{
  id<NSObject,SkyDocumentFileManager> fileManager;
  NSMutableDictionary *pathToDS;
  
  NSDictionary *fsinfo;
  WOComponent  *folderForm;
  NSString     *folderFormDirPath;
  NSString     *folderDropPath;
  
  id           project;
  NSArray      *jobs;
}

- (void)setFileManager:(id)_fm;
- (id)fileSystemNumber;

@end

#include <NGMime/NGMimeType.h>
#include <OGoFoundation/OGoClipboard.h>
#include "common.h"

@interface NSObject(Private)
- (NSString *)_unvalidateNotificationNameForPath:(NSString *)_path;
@end

@interface NSObject(DSP)
- (EOGlobalID *)globalID;
- (id)dataSourceAtPath:(NSString *)_path;
- (NSDictionary *)fileSystemAttributes;
@end

@implementation SkyProject4Viewer

static BOOL showUnknownFiles_value = NO;
static BOOL showUnknownFiles_flag  = NO;

static inline BOOL _showUnknownFiles(id self) {
  if (!showUnknownFiles_flag) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    showUnknownFiles_flag  = YES;
    showUnknownFiles_value =
      [ud boolForKey:@"SkyProjectFileManager_show_unknown_files"];
  }
  return showUnknownFiles_value;
}

- (void)refreshView:(id)_foo {
  [self->jobs release]; self->jobs = nil;
}

- (id)init {
  if ((self = [super init])) {
    NSNotificationCenter *nc;
    
    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(refreshView:)
        name:@"SkyNewJobNotification" object:nil];
  }
  return self;
}

#if 0 // hh asks: why is it commented out??
- (void)clearPathCache {
  [self->pathToDS removeAllObjects];
}
#endif

- (void)dealloc {
  [self->folderDropPath release];
  [self->fsinfo      release];
  [self->pathToDS    release];
  [self->fileManager release];
  [self->project     release];
  [self->jobs        release];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

/* navigation */

- (NSString *)label {
  NSString *s;
  
  s = [[self fileSystemAttributes] objectForKey:@"NSFileSystemName"];
  return s;
}

- (NSString *)shortTitle {
  NSString *title;

  title = [self label];
  if ([title length] > 15)
    title = [[title substringToIndex:13] stringByAppendingString:@".."];
  return title;
}

- (BOOL)isViewerForSameObject:(id)_object {
  if ((id)_object == (id)self->fileManager)
    return YES;
  
  if ([_object isEqual:[self fileSystemNumber]])
    return YES;
  
  return NO;
}

- (id)activateFileManager:(id<NGFileManager,NSObject>)_object {
  [self setFileManager:_object];
  return self;
}

- (id)activateKeyGlobalID:(EOKeyGlobalID *)gid verb:(NSString *)_verb {
  NSException *exception;
  id fm;
  
  /* should be replaced with a factory */
    
  if (![[gid entityName] isEqualToString:@"Project"]) {
    [self logWithFormat:@"got incorrect gid: %@", gid];
    return nil;
  }
  
  fm        = nil;
  exception = nil;
  NS_DURING {
    fm = [[OGoFileManagerFactory fileManagerInContext:
				   [(id)[self session] commandContext]
				 forProjectGID:gid] retain];
  }
  NS_HANDLER {
    fm = nil;
    printf("ERROR: couldn`t get filemanager, goy exception %s",
	   [[localException description] cString]);
    exception = localException;
  }
  NS_ENDHANDLER;
  
  if (exception) {
    [[[[self session] navigation] activePage]
             setErrorString:[exception reason]];
    return nil;
  }
  
  if (fm == nil) {
    [self logWithFormat:@"couldn't create filemanager for gid %@", gid];
    return nil;
  }
  [fm autorelease];
  
  return [self activateFileManager:fm];
}

- (id)activateObject:(id)_object verb:(NSString *)_verb
  type:(NGMimeType *)_type
{

  if (_object == nil) {
    [self logWithFormat:
            @"missing object for activation with verb %@, type %@ ..",
           _verb, _type];
    return nil;
  }
  
  if ([_object conformsToProtocol:@protocol(NGFileManager)])
    return [self activateFileManager:_object];
  
  if ([_object isKindOfClass:[EOKeyGlobalID class]])
    return [self activateKeyGlobalID:_object verb:_verb];
  
  if ([[_type type] isEqualToString:@"eo"] &&
           [[_type subType] isEqualToString:@"project"]) {
    return [self activateObject:[_object globalID]
                 verb:_verb
                 type:[NGMimeType mimeType:@"eo-gid/project"]];
  }
  
  [self logWithFormat:@"got incorrect activation object: %@", _object];
  return nil;
}

/* notifications */

- (void)sleep {
  [self->fsinfo release]; self->fsinfo = nil;
  [super sleep];
}

/* accessors */

- (void)setProject:(id)_project {
  ASSIGN(self->project, _project);
}
- (id)project {
  id projectID;
  
  if (self->project != nil) 
    return self->project;

  if ((projectID = [self fileSystemNumber]) == nil) {
    [self logWithFormat:@"ERROR: could not find valid project ID"];
    return nil;
  }
    
  self->project =
    [[self run:@"project::get", @"gid", projectID, nil] lastObject];
  self->project = [self->project retain];
  return self->project;
}

- (NSArray *)jobs {
  id toJob;
  
  if (self->jobs)
    return self->jobs;

  NSAssert(([self project] != nil), @"No project set");

  [self runCommand:@"project::get-jobs",
          @"object",      [self project],
          @"relationKey", @"jobs", nil];
  
  toJob = [[self project] valueForKey:@"jobs"];
  ASSIGN(self->jobs, toJob);
  return self->jobs;
}

- (void)setDirectoryPath:(NSNumber *)_pid {
  EOKeyGlobalID *gid;

  if (self->fileManager == nil)
    return;
  
  gid = [EOKeyGlobalID globalIDWithEntityName:@"Doc" 
		       keys:&_pid keyCount:1 zone:NULL];
  [self->fileManager changeCurrentDirectoryPath:
         [self->fileManager pathForGlobalID:gid]];
}

- (void)setFileManager:(id<NSObject,SkyDocumentFileManager>)_fm {
  if (_fm == self->fileManager)
    return;
  ASSIGN(self->fileManager, _fm);
  [self->fileManager changeCurrentDirectoryPath:@"/"];
}
- (id<NSObject,SkyDocumentFileManager>)fileManager {
  return self->fileManager;
}

- (void)setFolderDropPath:(NSString *)_path {
  ASSIGN(self->folderDropPath, _path);
}
- (NSString *)folderDropPath {
  return self->folderDropPath;
}

- (BOOL)defaultFileListShouldHideFolders {
  return [[[(OGoSession *)[self session] userDefaults]
            objectForKey:@"skyp4_filelist_hide_folders"] boolValue];
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

- (NSDictionary *)fileSystemAttributes {
  if (self->fsinfo)
    return self->fsinfo;
  
  self->fsinfo = [[[self fileManager] fileSystemAttributesAtPath:@"/"] copy];
  return self->fsinfo;
}
- (id)fileSystemNumber {
  return [[self fileSystemAttributes] objectForKey:@"NSFileSystemNumber"];
}

/* form project */

- (BOOL)isAccountDesigner {
  return [(SkyProjectFileManager *)[self fileManager]
                                   isOperation:@"f"
                                   allowedOnPath:
                                   [[self fileManager] currentDirectoryPath]];
}

- (BOOL)isEditEnabled {
  // TODO: how to find out whether editing is allowed ??
  return YES;
}

- (BOOL)isPublisherLicensed {
  return YES;
}
- (BOOL)isPublisherEnabled {
  static int isEnabled = -1;
  if (isEnabled == -1)
    isEnabled = NSClassFromString(@"SkyPublishProject") ? 1 : 0;
  return isEnabled;
}

- (BOOL)showOnlyIndexForm {
  return NO;
}

- (BOOL)showFolderContent {
  return YES;
  //return ![self showFolderForm] || [self isAccountDesigner];
}

/* test mode */

- (BOOL)canTest {
  return NO;
}

/* operations */

- (NSString *)_projectConfigKey:(NSString *)_subkey {
  NSString *ckey;
  
  ckey =  [NSString stringWithFormat:@"skyp4_p%@_%@",
                      [[self fileSystemAttributes]
                             objectForKey:@"NSFileSystemName"],
                      _subkey];
  
  return ckey;
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

  if (o == nil) {
    return [[[[self context] request] clientCapabilities] isFastTableBrowser]
      ? NO : YES;
  }
  return [o boolValue];
}

- (id)pidForCurrentDirectoryPath {
  id gid = nil;

  gid = [self->fileManager globalIDForPath:
             [self->fileManager currentDirectoryPath]];

  if ([gid isKindOfClass:[EOKeyGlobalID class]])
    return [gid isNotNull] ? [gid keyValues][0] : [EONull null];

  return [EONull null];
}

- (id)object {
  id obj = nil;

  obj = [[self fileSystemAttributes] objectForKey:@"object"];
  [obj takeValue:[self pidForCurrentDirectoryPath] forKey:@"currentFolderId"];
  
  return obj;
}

- (NSString *)objectUrlKey {
  NSString *s;
  
  // TODO: use some URL construction method?
  s = @"wa/LSWViewAction/viewProject";
  s = [s stringByAppendingFormat:@"?projectId=%@&documentId=%@",
           [[self object] valueForKey:@"projectId"],
           [self pidForCurrentDirectoryPath]];
  return [s stringByEscapingURL];
}

/* Pub Preview URLs */

- (BOOL)hasPubPreview {
  static int hasPub = -1;
  if (hasPub == -1)
    hasPub = NSClassFromString(@"SkyPubDirectAction") ? 1 : 0;
  return hasPub ? YES : NO;
}

- (NSString *)pubPreviewURL {
  NSString *url;
  NSString *qs;
  
  if (![self hasPubPreview])
    return nil;
  
  url = @"/SkyPubDirectAction/pubPreview";
  url = [url stringByAppendingString:[[self fileManager]
                                            currentDirectoryPath]];

  if (![url hasSuffix:@"/"])
    url = [url stringByAppendingString:@"/"];
  
  qs = [[WORequestValueSessionID stringByAppendingString:@"="]
                                 stringByAppendingString:
                                   [[self session] sessionID]];
  
  return [[self context] urlWithRequestHandlerKey:
                           [WOApplication directActionRequestHandlerKey]
                         path:url queryString:qs];
}

/* actions */

- (id)placeInClipboard {
  [[(OGoSession *)[self session] favorites] addObject:[self fileSystemNumber]];
  return nil;
}

- (id)edit {
  return [self activateObject:[self fileSystemNumber] withVerb:@"edit"];
}

- (id)droppedOnFolder {
  id         dropFile;
  EOGlobalID *dropFileGID;
  NSString   *dropFilePath;
  NSString   *destPath;

  if ((dropFile = [self valueForKey:@"droppedFile"]) == nil) {
    [self setErrorString:@"missing drop-object"];
    return nil;
  }
  
  if ((dropFileGID = [dropFile valueForKey:@"globalID"]) == nil) {
    [self setErrorString:@"missing id of dropped object"];
    return nil;
  }
  
  if ((dropFilePath = [[self fileManager]
                             pathForGlobalID:dropFileGID]) == nil) {
    /* should make link ! */
    [self setErrorString:@"dropped object from different filemanager"];
    return nil;
  }

  destPath = [self valueForKey:@"folderDropPath"];
  destPath = [destPath stringByAppendingPathComponent:
                         [dropFilePath lastPathComponent]];
  
  if (![[self fileManager] movePath:dropFilePath
                           toPath:destPath handler:nil]) {
    //[self setErrorString:@"move operation failed"];
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

- (id)closeWindow {
  return [[[self session] navigation] leavePage];
}

- (id)showPublisher {
  id page;

  page = [self pageWithName:@"SkyPublishProject"];
  [page takeValue:[self fileManager] forKey:@"fileManager"];
  return page;
}

- (id)refresh {
  NSAutoreleasePool *pool;
  
  pool = [[NSAutoreleasePool alloc] init];
  [(SkyProjectFileManager *)self->fileManager flush];
  [pool release];
  
  return nil;
}

@end /* SkyProject4Viewer */
