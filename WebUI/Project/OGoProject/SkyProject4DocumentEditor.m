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

#include <OGoFoundation/LSWContentPage.h>

@class NSString, NSData;
@class EOGlobalID;

@interface SkyProject4DocumentEditor : LSWContentPage
{
  id         fileManager;
  EOGlobalID *folderGID;
  EOGlobalID *fileGID;
  
  NSString   *fileName;
  NSString   *subject;
  
  id document;
  
  NSString *folderPath;
  NSString *projectId;

  NSString *text;
  NSData   *blob;

  struct {
    int isImport:1;
    int fileManagerCreatByProj:1;
    int documentCreaByFM:1;
    int useEpoz:1;
    int reserved:28;
  } speFlags;
  
  id project;
}

- (void)setDocument:(id)_doc;
- (id)document;
- (BOOL)hasDocument;

- (BOOL)hasVersioning;
- (BOOL)hasLocking;

- (id)fileManager;

- (void)setFolderId:(EOGlobalID *)_gid;

@end

#include "OGoComponent+FileManagerError.h"
#include "common.h"

/* TODO: include proper headers and add typing to avoid warnings! */

@implementation SkyProject4DocumentEditor

/* TODO: add version check */

- (void)dealloc {
  [self->subject     release];
  [self->document    release];
  [self->fileName    release];
  [self->fileManager release];
  [self->folderGID   release];
  [self->fileGID     release];
  [self->folderPath  release];
  [self->projectId   release];
  [self->text        release];
  [self->project     release];
  [self->blob        release];
  [super dealloc];
}

- (id)editDocument:(SkyProjectDocument *)_object {
  [self setDocument:_object];
  return self;
}
- (id)editAsNewDocument:(SkyProjectDocument *)_object {
  id fm, ds, doc;
  
  if ((fm = [_object fileManager]) == nil) {
    [self logWithFormat:@"missing filemanager in object ..."];
    return nil;
  }
  if ((ds = [fm dataSourceAtPath:@"."]) == nil) {
    [self logWithFormat:@"missing datasource at path . ..."];
    return nil;
  }
  
  doc = [ds createObject];
  [doc takeValue:[_object valueForKey:@"NSFileSubject"]
       forKey:@"NSFileSubject"];
  [doc setContentString:[_object contentAsString]];
  [self setDocument:doc];
  return self;
}

- (id)activateDocument:(SkyProjectDocument *)_object
  verb:(NSString *)_verb type:(NGMimeType *)_type
{
  if (_object == nil) {
    [self logWithFormat:@"missing object to invoke with command '%@'", _verb];
    return nil;
  }
  
  if ([_verb isEqualToString:@"edit"])
    return [self editDocument:_object];
  if ([_verb isEqualToString:@"editAsNew"])
    return [self editAsNewDocument:_object];
  
  return nil;
}

- (id)activateObject:(id)_object
  verb:(NSString *)_verb type:(NGMimeType *)_type
{
  SkyProjectDocument *doc;
  
  if (_object == nil)
    return nil;

  doc = nil;
  if ([_object isKindOfClass:[EOGlobalID class]]) {
    id cmdctx;
    cmdctx = [(LSWSession *)[self session] commandContext];
    doc = [[cmdctx documentManager]
                   documentForGlobalID:_object];
  }
  else if ([_object isKindOfClass:[NSURL class]]) {
    id cmdctx;
    cmdctx = [(LSWSession *)[self session] commandContext];
    doc = [[cmdctx documentManager]
                   documentForURL:_object];
  }
#if 0  
  else if ([_object isKindOfClass:[SkyProjectDocument class]])
    doc = _object;
#endif
  else if ([_object isKindOfClass:[SkyDocument class]])
    doc = _object;
  
  
  if (doc)
    return [self activateDocument:doc verb:_verb type:_type];
  
  [self logWithFormat:@"couldn't activate object %@", _object];
  return nil;
}

/* accessors */

- (void)setFileManager:(id)_fm {
  if (self->fileManager == _fm) 
    return;
  self->speFlags.fileManagerCreatByProj = 0;
  ASSIGN(self->fileManager, _fm);
}
- (id)fileManager {
  if (self->fileManager)
    return self->fileManager;
  
  if (self->document) {
    if ([self->document respondsToSelector:@selector(fileManager)])
      return [self->document fileManager];
  }
  else if (self->project) {
    self->speFlags.fileManagerCreatByProj = 1;
    self->fileManager =
      [[OGoFileManagerFactory fileManagerInContext:
                                [(id)[self session] commandContext]
			      forProjectGID:[self->project globalID]] retain];
  }
  return self->fileManager;
}

- (void)setFolderId:(EOGlobalID *)_gid {
  ASSIGNCOPY(self->folderGID, _gid);
}
- (EOGlobalID *)folderId {
  return self->folderGID;
}

- (void)setFileId:(EOGlobalID *)_gid {
  ASSIGNCOPY(self->fileGID, _gid);
}
- (EOGlobalID *)fileId {
  return self->fileGID;
}

- (void)setFileName:(NSString *)_fileName {
  ASSIGNCOPY(self->fileName, _fileName);
}
- (NSString *)fileName {
  return self->fileName;
}

- (void)setText:(NSString *)_text {
  if (![self hasDocument]) {
    ASSIGN(self->text, _text);
    return;
  }
  
  [[self document] setContentString:_text];
}
- (NSString *)text {
  return [self hasDocument]
    ? [[self document] contentAsString]
    : self->text;
}

- (void)setBlob:(NSData *)_blob {
  if (![self hasDocument]) {
    ASSIGN(self->blob, _blob);
    return;
  }
}
- (NSData *)blob {
  return [self hasDocument]
    ? [[self document] content]
    : self->blob;
}

- (void)setSubject:(NSString *)_subject {
  if ([self hasDocument]) 
    [[self document] takeValue:_subject forKey:@"NSFileSubject"];
  else
    ASSIGN(self->subject, _subject);
}
- (NSString *)subject {
  return [self hasDocument]
    ?[[self document] valueForKey:@"NSFileSubject"]
    :self->subject;
}

- (NSString *)folderPath {
  EOGlobalID *fgid;
  NSString *path;
  
  if ((fgid = [self folderId])) {
    path = [[self fileManager] pathForGlobalID:fgid];
    [self debugWithFormat:@"got path %@ for folder-id %@", path, fgid];
  }
  else if ((fgid = [self fileId])) {
    path = [[self fileManager] pathForGlobalID:fgid];
    path = [path stringByDeletingLastPathComponent];
    [self debugWithFormat:@"got path %@ for file-id %@", path, fgid];
  }
  else
    path = nil;
  
  return path;
}
- (NSString *)filePath {
  EOGlobalID *fgid;
  NSString *path;
  
  if ((fgid = [self fileId])) {
    path = [[self fileManager] pathForGlobalID:fgid];
  }
  else if ((fgid = [self folderId])) {
    path = [[self fileManager] pathForGlobalID:fgid];
    path = [path stringByAppendingPathComponent:[self fileName]];
  }
  else
    path = nil;
  
  return path;
}

- (void)setDocument:(id)_doc {
  if (_doc == self->document)
    return;
  
  self->speFlags.documentCreaByFM = 0;
  
  if (_doc) {
    if ([_doc isNew])
      [self setFolderId:[[_doc fileManager] globalIDForPath:@"."]];
    else
      [self setFileId:[_doc globalID]];
    
    [self setFileName:[[_doc path] lastPathComponent]];
    [self setSubject:[_doc valueForKey:@"NSFileSubject"]];
  }    
  ASSIGN(self->document, _doc);
}
- (id)document {
  SkyProjectFileManager *fm;
  
  if (self->document)
    return self->document;

  if ((fm = (id)[self fileManager]) == nil)
    return nil;
  
  self->speFlags.documentCreaByFM = 1;
  if ([self fileId]) {
    NSString *p;
      
    p  = [fm pathForGlobalID:[self fileId]];
    self->document = [[fm documentAtPath:p] retain];
  }
  else {
    EODataSource *ds;

    ds = [fm dataSourceAtPath:@"."];
    self->document = [[ds createObject] retain];
    if ([self->subject  length])
      [self->document takeValue:self->subject forKey:@"NSFileSubject"];
  }
  return self->document;
}
- (BOOL)hasDocument {
  return [self document] != nil ? YES : NO;
}

- (BOOL)hasVersioning {
  return [[self fileManager] supportsVersioningAtPath:[self filePath]];
}
- (BOOL)hasLocking {
  return [[self fileManager] supportsLockingAtPath:[self filePath]];
}

- (BOOL)hasSaveAndRelease {
  if ([self fileId] == nil)
    return NO;
  return [self hasVersioning];
}
- (BOOL)hasSaveAndUnlock {
  if ([self fileId] == nil)
    return NO;
  return (![self hasVersioning] && [self hasLocking]) ? YES : NO;
}

- (NSString *)windowTitle {
  NSString *path;
  NSString *edit;

  edit = [[self labels] valueForKey:@"EditFileAtPath"];

  edit = (edit != nil)
    ? edit
    : @"Edit file at path ";
  
  path = [self fileId]
    ? [[self fileManager] pathForGlobalID:[self fileId]]
    : [[self fileManager] pathForGlobalID:[self folderId]];
  
  path = [edit stringByAppendingString:path];
  
  return path;
}

- (BOOL)showTitle {
  return [[self fileManager]
                isKindOfClass:NSClassFromString(@"SkyProjectFileManager")];
}
- (BOOL)showFilename {
  return [self fileId] ? NO : YES;
}

- (BOOL)isEditorPage {
  return YES;
}

- (void)setIsEpozEnabled:(BOOL)_flag {
  self->speFlags.useEpoz = _flag ? 1 : 0;
}
- (BOOL)isEpozEnabled {
  return self->speFlags.useEpoz ? YES : NO;
}

- (void)setIsImport:(BOOL)_imp {
  self->speFlags.isImport = _imp ? 1 : 0;
}
- (BOOL)isImport {
  return self->speFlags.isImport ? YES : NO;
}

/* actions */

- (id)_createFile {
  SkyProjectFileManager *fm;
  SkyProjectDocument    *ldocument;
  WOComponent *viewer;
  id          l;
  NSString    *fname;
  NSString    *fp;
  
  l     = [self labels];
  fname = [self fileName];

  if (![fname length]) {
    [self setErrorString:[l valueForKey:@"missing filename"]];
    return nil;
  }
  
  if ((fm = [self fileManager]) == nil) {
    if (self->project == nil) {
      [self setErrorString:[l valueForKey:@"Missing project"]];
      return nil;
    }
  }
  ldocument = [self document];
  
  fp    = [fm pathForGlobalID:[self folderId]];
  if (![fp length])
    fp = @"/";
  
  fname = [fp stringByAppendingPathComponent:fname];

  if ([fm fileExistsAtPath:fname]) {
    [self setErrorString:[[self labels]
                                valueForKey:@"fm_error_7"]];
    return nil;
  }
  [ldocument takeValue:fname forKey:@"NSFilePath"];
  
  if ([self->subject length])
    [ldocument takeValue:self->subject forKey:@"NSFileSubject"];
  
  if ([self->text length])
    [ldocument setContentString:self->text];
  else if ([self->blob length])
    [ldocument setContent:self->blob];
    

  if (![ldocument save])
    return [self printErrorWithSource:fname destination:nil];
  
  /* leave editor */
  [[(LSWSession *)[self session] navigation] leavePage];
  [self setDocument:ldocument];
  
  /* enter viewer */
  viewer = [self activateObject:ldocument withVerb:@"view"];
  
  return viewer;
}

- (id)_saveAndRelease:(BOOL)_release unlock:(BOOL)_unlock {
  /* TODO: better error messages in this method! */
  SkyProjectFileManager *fm;
  SkyProjectDocument    *ldocument;

  if (!(ldocument = [self document]))
    return [self _createFile];
  
  if ([ldocument isNew]) {
    /* create new file */
    return [self _createFile];
  }
  
  fm = [self fileManager];
  
  //  [fm flush]; /* clear cache for new path */
  
  /* lookup document */
  
  if ([ldocument path])
    [self setFileName:[[ldocument path] lastPathComponent]];
  
  /* first checkout or lock file */
  
  if ([ldocument isVersioned]) {
    if (![ldocument isLocked]) {
      if (![ldocument checkoutDocument]) {
        [self setErrorString:@"checkout of document failed !"];
        return nil;
      }
    }
  }
  else if ([self hasLocking]) {
    if (![ldocument isLocked]) {
      if (![ldocument lockDocument]) {
        [self setErrorString:@"locking of document failed !"];
        return nil;
      }
    }
  }
  
  /* now write contents */
  if (![ldocument save]) {
    [self setErrorString:@"saving of document failed !"];
    return nil;
  }
  
  /* now handle auto-release/unlock */
    
  if (_release) {
    if (![ldocument releaseDocument])
      [self setErrorString:@"couldn't release file after writing data .."];
  }
  else if (_unlock) {
    if (![ldocument unlockDocument])
      [self setErrorString:@"couldn't unlock file after writing data .."];
  }
  
  return [[(LSWSession *)[self session] navigation] leavePage];
}

- (id)save {
  return [self _saveAndRelease:NO unlock:NO];
}
- (id)saveAndRelease {
  return [self _saveAndRelease:YES unlock:NO];
}
- (id)saveAndUnlock {
  return [self _saveAndRelease:NO unlock:YES];
}

- (id)cancel {
  return [[(LSWSession *)[self session] navigation] leavePage];
}

- (id)saveAndMove {
  id fm;
  LSWContentPage *page;
  NSDictionary   *d;
  NSString       *fname, *s;
  
  if (![self isImport])
    return [self save];

  if ((fm = [self fileManager]) == nil)
    return [self save];

  if (!(fname   = [self fileName]))
    fname = @"";
  if ((s = [self subject]) == nil)
    s = @"";
  
  d = [NSDictionary dictionaryWithObjectsAndKeys:
                        s,          @"NSFileSubject",
                        fname,      @"NSFileName",
                        [NSNumber numberWithInt:[self->blob length]],
                        NSFileSize,
                        self->blob, @"content", nil];
  page = [self pageWithName:@"SkyProject4MovePanel"];
  
  [page takeValue:[NSArray arrayWithObject:d] forKey:@"newDocuments"];
  [page takeValue:fm                          forKey:@"fileManager"];
  [self enterPage:page];
  return page;
}

/* viewer forms */

- (void)setProject:(id)_p {
  if (self->project == _p)
    return;
  ASSIGN(self->project, _p);
  
  if (self->speFlags.fileManagerCreatByProj) {
    [self setFileManager:nil];
    if (self->speFlags.documentCreaByFM)
      [self setDocument:nil];
  }
}
- (id)project {
  return self->project;
}

- (void)takeValue:(id)_v forKey:(id)_key {
  if ([_key isEqualToString:@"blob"])
    [self setBlob:_v];
  else if ([_key isEqualToString:@"fileName"])
    [self setFileName:_v];
  else if ([_key isEqualToString:@"subject"])
    [self setSubject:_v];
  else if ([_key isEqualToString:@"isImport"])
    [self setIsImport:[_v boolValue]];
  else
    [super takeValue:_v forKey:_key];
}


- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"blob"])
    return [self blob];
  if ([_key isEqualToString:@"fileName"])
    return [self fileName];
  if ([_key isEqualToString:@"subject"])
    return [self subject];
  if ([_key isEqualToString:@"isImport"])
    return [NSNumber numberWithBool:[self isImport]];
  
  return [super valueForKey:_key];
}

@end /* SkyProject4DocumentEditor */

@implementation SkyProject4DocumentEditor(Restore)

- (void)setFolderPath:(NSString *)_path {
  ASSIGN(self->folderPath, _path);
}

- (NSString *)projectId {
  id gid;

  gid = [[[self fileManager] fileSystemAttributesAtPath:@"/"]
                objectForKey:@"NSFileSystemNumber"];
  if (gid)
    return [[gid keyValues][0] stringValue];

  return nil;
}

- (void)setProjectId:(id)_pid {
  ASSIGN(self->projectId, _pid);
}

- (void)prepareForRestorePage {
}

- (void)verifyDataForRestorePage {
  EOGlobalID *gid;
  NSString   *fPath;
  BOOL       isDir;

  if (!self->projectId) {
    [self setErrorString:[[self labels] valueForKey:@"Missing project id"]];
    return;
  }

  if (!self->folderPath)
    self->folderPath = @"/";

  gid = [EOKeyGlobalID globalIDWithEntityName:@"Project"
                       keys:&self->projectId keyCount:1 zone:NULL];

  [self->fileManager release]; self->fileManager = nil;
  
  self->fileManager =
    [[OGoFileManagerFactory fileManagerInContext:
                            [(id)[self session] commandContext]
                            forProjectGID:gid] retain];

  [self->fileManager changeCurrentDirectoryPath:self->folderPath];
  [self setFolderId:[self->fileManager globalIDForPath:self->folderPath]];

  [self->fileGID release];  self->fileGID  = nil;
  [self->document release]; self->document = nil;
  
  fPath = [self->folderPath stringByAppendingPathComponent:self->fileName];
  
  if ([self->fileManager fileExistsAtPath:fPath isDirectory:&isDir]) {
    if (!isDir) {
      SkyProjectFileManager *fm;
      
      fm = self->fileManager ;
      self->document = [[fm documentAtPath:fPath] retain];
      self->fileGID = [[self->document globalID] retain];
    }
  }
  if (self->document == nil) {
    EODataSource *ds;
    
    ds = [self->fileManager dataSourceAtPath:self->folderPath];
    self->document = [[ds createObject] retain];
  }
  if (self->text)
    [self->document setContentString:self->text];

  if (self->subject)
    [self->document takeValue:self->subject forKey:@"NSFileSubject"];
}


@end /* SkyProject4DocumentEditor(Restore) */
