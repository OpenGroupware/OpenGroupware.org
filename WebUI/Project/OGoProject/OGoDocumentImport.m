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

@interface OGoDocumentImport : LSWContentPage
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
    int fileManagerCreatByProj:1;
    int documentCreaByFM:1;
    int reserved:30;
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

// TODO: this was created as a copy of SkyProject4DocumentEditor, the editor
//       specific parts need to get removed

@implementation OGoDocumentImport

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

- (BOOL)isImport {
  [self logWithFormat:@"WARNING(%s): called deprecated method.",
	  __PRETTY_FUNCTION__];
  return YES;
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
  [[(OGoSession *)[self session] navigation] leavePage];
  [self setDocument:ldocument];
  
  /* enter viewer */
  viewer = [self activateObject:ldocument withVerb:@"view"];
  
  return viewer;
}

- (id)save {
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
  
  return [[(OGoSession *)[self session] navigation] leavePage];
}

- (id)cancel {
  return [[(OGoSession *)[self session] navigation] leavePage];
}

- (id)saveAndMove {
  id fm;
  LSWContentPage *page;
  NSDictionary   *d;
  NSString       *fname, *s;
  
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
  [self enterPage:page]; // TODO: do we need the enter?
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

@end /* OGoDocumentImport */
