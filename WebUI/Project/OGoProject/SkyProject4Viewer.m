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
// $Id$

#include <OGoFoundation/LSWViewerPage.h>
#include <OGoDocuments/SkyDocumentFileManager.h>

@class NSString, NSMutableSet, NSArray, NSMutableArray;
@class WOComponent;

/*
  Defaults: (??)
    SkyProjectFileManager_show_unknown_files : show unknown files
*/

@interface NSObject(Private)
- (NSString *)_unvalidateNotificationNameForPath:(NSString *)_path;
@end

@interface SkyProject4Viewer : LSWViewerPage
{
  id<NSObject,SkyDocumentFileManager> fileManager;
  NSMutableDictionary *pathToDS;
  
  WOComponent         *currentForm;
  NSDictionary        *fsinfo;
  WOComponent         *folderForm;
  NSString            *folderFormDirPath;
  WOComponent         *headForm;
  WOComponent         *tailForm;
  NSString            *folderDropPath;

  BOOL                isFormsEnabled;

  id                  project;
  NSArray             *jobs;
}

- (void)setFileManager:(id)_fm;

- (void)setTestMode:(BOOL)_flag;
- (BOOL)isTestMode;

@end

#include "WOComponent+P4Forms.h"
#include <NGMime/NGMimeType.h>
#include "common.h"

@interface NSObject(DSP)
- (EOGlobalID *)globalID;
- (id)dataSourceAtPath:(NSString *)_path;
- (NSDictionary *)fileSystemAttributes;
@end

@interface SkyProject4Viewer(Forms) // TODO: find headerfile for that
- (void)printErrorWithSource:(NSString *)_path destination:(NSString *)_dest;
@end

@implementation SkyProject4Viewer

static BOOL showUnknownFiles_value = NO;
static BOOL showUnknownFiles_flag  = NO;

static inline BOOL _showUnknownFiles(id self) {
  if (!showUnknownFiles_flag) {
    showUnknownFiles_flag  = YES;
    showUnknownFiles_value = [[NSUserDefaults standardUserDefaults]
                                      boolForKey:@"SkyProjectFileManager_show_"
                                              @"unknown_files"];
  }
  return showUnknownFiles_value;
}

- (void)refreshView:(id)_foo {
  [self->jobs release]; self->jobs = nil;
}

- (id)init {
  if ((self = [super init])) {
    NGBundleManager *bm;
    NSNotificationCenter *nc;

    bm = [NGBundleManager defaultBundleManager];
    if ([bm bundleProvidingResource:@"SkyP4FormPage"
            ofType:@"WOComponents"] != nil)
      self->isFormsEnabled = YES;
    self->project = nil;
    self->jobs = nil;

    nc = [NSNotificationCenter defaultCenter];

    [nc addObserver:self selector:@selector(refreshView:)
        name:@"SkyNewJobNotification" object:nil];
  }
  return self;
}

#if 0 // hh asks: ??
- (void)clearPathCache {
  [self->pathToDS removeAllObjects];
}
#endif

- (void)dealloc {
  [self->folderDropPath release];
  [self->headForm release];
  [self->tailForm release];
  [self->folderFormDirPath release];
  [self->folderForm  release];
  [self->fsinfo      release];
  [self->currentForm release];
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
  
  if (self->currentForm) {
    NSString *fm;
    
    fm = [self->currentForm name];
    
    if ((![fm isEqualToString:s]) && (![fm isEqualToString:@".index.sfm"]))
      s = [NSString stringWithFormat:@"%@ (%@)", s, fm];
  }
  
  if ([self isTestMode]) {
    NSString *t;
    
    t = [[self labels] valueForKey:@"test"];
    s = [NSString stringWithFormat:@"%@: %@", t, s];
  }
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
  id gid;

  if (self->currentForm)
    return NO;
  if ((id)_object == (id)self->fileManager)
    return YES;
  
  gid = [[self fileSystemAttributes] objectForKey:@"NSFileSystemNumber"];
  if ([_object isEqual:gid])
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
  
  if (self->project) 
    return self->project;

  projectID = [[self fileSystemAttributes]
                     valueForKey:@"NSFileSystemNumber"];
  if (projectID == nil) {
    [self logWithFormat:@"Couldn't find valid project ID"];
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
    static EOQualifier *hideFoldersQ = nil;
    static EOQualifier *showFoldersQ = nil;
    
    hideFolders = [[[(LSWSession *)[self session] userDefaults]
                                 objectForKey:@"skyp4_filelist_hide_folders"]
                                 boolValue];
    
    if (hideFolders) {
      if (hideFoldersQ == nil) {
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
      }
      else
        q = hideFoldersQ;
    }
    else {
      if (showFoldersQ == nil) {
        q = nil;
        if (!_showUnknownFiles(self)) {
          q = [EOQualifier qualifierWithQualifierFormat:
                           @"(NSFileType != 'NSFileTypeUnknown')", nil];
        }
        showFoldersQ = [q retain];
      }
      else
        q = showFoldersQ;
    }
    
    fspec = [EOFetchSpecification fetchSpecificationWithEntityName:nil
                                  qualifier:q
                                  sortOrderings:nil];
    
    if ([[self fileManager] supportsFolderDataSourceAtPath:path])
      ds = [(id<NGFileManagerDataSources>)[self fileManager]
                                          dataSourceAtPath:path];
    
    if (self->pathToDS == nil)
      self->pathToDS = [[NSMutableDictionary alloc] initWithCapacity:8];
    if (ds)
      [self->pathToDS setObject:ds forKey:path];
    
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

- (BOOL)hasIndexForm {
  if ([[self fileManager] fileExistsAtPath:@"/project.sfm"])
    return YES;
  
  return NO;
}

- (BOOL)showOnlyIndexForm {
  if (![self hasIndexForm])
    return NO;
  if ([self isTestMode])
    return YES;
  if ([self isAccountDesigner])
    return NO;
  return YES;
}

- (WOComponent *)indexFormComponent {
  id formDoc;
  
  if (self->currentForm)
    return self->currentForm;
  
  if ((formDoc = [[self fileManager] documentAtPath:@"/project.sfm"]) == nil)
    return nil;
  
  self->currentForm =
    [[self formForDocument:formDoc className:@"SkyP4AppFormComponent"] retain];
  
  return self->currentForm;
}

- (void)setCurrentForm:(WOComponent *)_form {
  if (self->currentForm != _form) {
    ASSIGN(self->currentForm, _form);

    [_form takeValue:[self fileManager] forKey:@"fileManager"];
  }
}
- (WOComponent *)currentForm {
  if (self->currentForm)
    return self->currentForm;
  
  return [self indexFormComponent];
}

/* folder form */

- (WOComponent *)folderForm {
  NSString *path;
  id       formDoc;
  
  path = [[self fileManager] currentDirectoryPath];
  path = [path stringByAppendingPathComponent:@".index.sfm"];
  
  if ([path isEqualToString:self->folderFormDirPath])
    return self->folderForm;
  
  ASSIGN(self->folderForm, (id)nil);
  ASSIGNCOPY(self->folderFormDirPath, path);
  
  if ((formDoc = [[self fileManager] documentAtPath:path]) == nil)
    return nil;
  
  self->folderForm = [[self formForDocument:formDoc] retain];
  [self->folderForm
       takeValue:[[self fileManager] documentAtPath:@"."]
       forKey:@"document"];
  
  return self->folderForm;
}

- (BOOL)showFolderForm {
  return [self folderForm] != nil ? YES : NO;
}
- (BOOL)showFolderContent {
  return YES;
  //return ![self showFolderForm] || [self isAccountDesigner];
}

- (WOComponent *)headForm {
  id doc;
  
  if (self->headForm)
    return [self->headForm isNotNull] ? self->headForm : nil;
  
  if ((doc = [[self fileManager] documentAtPath:@"/.project_head.sfm"]) ==nil){
    [self debugWithFormat:@"found no head form file ..."];
    self->headForm = [[NSNull null] retain];
    return nil;
  }
  
  if ((self->headForm = [[self formForDocument:doc] retain]) == nil)
    [self logWithFormat:@"couldn't create component for head form %@", doc];
  return self->headForm;
}
- (WOComponent *)tailForm {
  id doc;
  
  if (self->tailForm)
    return [self->tailForm isNotNull] ? self->tailForm : nil;
  
  if ((doc = [[self fileManager] documentAtPath:@"/.project_tail.sfm"]) ==nil){
    [self debugWithFormat:@"found no tail form file ..."];
    self->tailForm = [[NSNull null] retain];
    return nil;
  }
  
  if ((self->tailForm = [[self formForDocument:doc] retain]) == nil)
    [self logWithFormat:@"couldn't create component for tail form %@", doc];
  
  return self->tailForm;
}

- (BOOL)hasHeadForm {
  return [self headForm] != nil ? YES : NO;
}
- (BOOL)hasTailForm {
  return [self tailForm] != nil ? YES : NO;
}

/* test mode */

- (BOOL)canTest {
  if (![self hasIndexForm])
    return NO;
  if (![self isAccountDesigner])
    return NO;
  return self->isFormsEnabled;
}

- (void)setTestMode:(BOOL)_flag {
  [[self session] setObject:[NSNumber numberWithBool:_flag]
                  forKey:@"SkyP4FormTestMode"];
}
- (BOOL)isTestMode {
  return [[[self session] objectForKey:@"SkyP4FormTestMode"] boolValue];
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
  return [[NSString stringWithFormat:
                    @"wa/LSWViewAction/viewProject?projectId=%@&documentId=%@",
                    [[self object] valueForKey:@"projectId"],
                    [self pidForCurrentDirectoryPath]] stringByEscapingURL];
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
  [(LSWSession *)[self session]
         addFavorite:
           [[self fileSystemAttributes] objectForKey:NSFileSystemNumber]];
  return nil;
}

- (id)edit {
  return [self activateObject:
               [[self fileSystemAttributes] objectForKey:@"NSFileSystemNumber"]
               withVerb:@"edit"];
}

- (id)reloadIndexForm {
  [self setCurrentForm:nil];
  return nil;
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
    [self printErrorWithSource:dropFilePath destination:destPath];
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

- (id)goTestMode {
  [self setTestMode:YES];
  return nil;
}

- (id)disableTest {
  [self setTestMode:NO];
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
  ASSIGN(self->headForm, (id)nil);
  ASSIGN(self->tailForm, (id)nil);
  [(SkyProjectFileManager *)self->fileManager flush];
  [pool release];
  
  return nil;
}

@end /* SkyProject4Viewer */
