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

#include <OGoFoundation/LSWContentPage.h>

@class NSString, NSData;
@class EOGlobalID;

@class SkyP4FileUploadData;

@interface SkyProject4DocumentUpload : LSWContentPage
{
  id         fileManager;
  EOGlobalID *folderGID;
  EOGlobalID *fileGID;

  SkyP4FileUploadData *upload1;
  SkyP4FileUploadData *upload2;
  SkyP4FileUploadData *upload3;
}

- (BOOL)isWindowsPath:(NSString *)_path;
- (id)fileManager;
- (EOGlobalID *)fileId;
- (EOGlobalID *)folderId;

@end

#include "NSData+SkyTextEditable.h"
#include "OGoComponent+FileManagerError.h"
#include "common.h"

@interface SkyP4FileUploadData : NSObject
{
  SkyProject4DocumentUpload *component; // non-retained
  NSString *filename;
  NSString *uploadPath;
  NSData   *uploadData;
  NSString *subject;
}
- (id)initWithComponent:(SkyProject4DocumentUpload *)_c;

- (void)setFileName:(NSString *)_fileName;
- (NSString *)fileName;
- (void)setUploadPath:(NSString *)_uploadPath;
- (NSString *)uploadPath;
- (void)setUploadData:(NSData *)_uploadData;
- (NSData *)uploadData;

- (NSString *)uploadFileName;
- (NSString *)filePath;
- (BOOL)hasVersioning;
- (BOOL)hasLocking;

- (BOOL)isValid;
- (BOOL)hasContent;
- (unsigned)size;

- (BOOL)_uploadAndRelease:(BOOL)_release unlock:(BOOL)_unlock;

@end

@implementation SkyProject4DocumentUpload

- (void)dealloc {
  RELEASE(self->upload1);
  RELEASE(self->upload2);
  RELEASE(self->upload3);
  RELEASE(self->fileManager);
  RELEASE(self->folderGID);
  RELEASE(self->fileGID);
  [super dealloc];
}

/* activation */

- (id)activateDocument:(SkyProjectDocument *)_object
  verb:(NSString *)_verb type:(NGMimeType *)_type
{
  if (![_verb isEqualToString:@"upload"]) return nil;
  if (_object == nil) return nil;

  if ([_object isNew]) {
    [self takeValue:[[_object fileManager] globalIDForPath:@"."]
          forKey:@"folderId"];
  }
  else {
    [self takeValue:[_object globalID] forKey:@"fileId"];
  }
  
  [self takeValue:[_object fileManager] forKey:@"fileManager"];
  
  return self;
}

- (id)activateObject:(id)_object
  verb:(NSString *)_verb type:(NGMimeType *)_type
{
  if (_object == nil) return nil;
  if (![_verb isEqualToString:@"upload"]) return nil;
  
  if ([_object isKindOfClass:[SkyDocument class]])
    return [self activateDocument:_object verb:_verb type:_type];
  
  [self logWithFormat:@"couldn't activate object %@", _object];
  return nil;
}

/* accessors */

- (void)setFileManager:(id)_fm {
  ASSIGN(self->fileManager, _fm);
}
- (id)fileManager {
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

- (SkyP4FileUploadData *)_createUploadDataObject {
  return [(SkyP4FileUploadData *)[SkyP4FileUploadData alloc] 
				 initWithComponent:self];
}

- (SkyP4FileUploadData *)uploadData1 {
  if (self->upload1 == nil)
    self->upload1 = [self _createUploadDataObject];
  return self->upload1;
}
- (SkyP4FileUploadData *)uploadData2 {
  if (self->upload2 == nil)
    self->upload2 = [self _createUploadDataObject];
  return self->upload2;
}
- (SkyP4FileUploadData *)uploadData3 {
  if (self->upload3 == nil)
    self->upload3 = [self _createUploadDataObject];
  return self->upload3;
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
  return [[self uploadData1] filePath];
}
- (BOOL)hasVersioning {
  return [[self uploadData1] hasVersioning];
}
- (BOOL)hasLocking {
  return [[self uploadData1] hasLocking];
}

- (BOOL)hasUploadAndRelease {
  if ([self fileId] == nil)
    return NO;
  return [self hasVersioning];
}
- (BOOL)hasUploadAndUnlock {
  if ([self fileId] == nil)
    return NO;
  return (![self hasVersioning] && [self hasLocking]) ? YES : NO;
}

- (NSString *)windowTitle {
  NSString *path;
  NSString *uploadl;
  
  uploadl = [[self labels] valueForKey:@"UploadFileAtPath"];
  
  uploadl = (uploadl != nil)
    ? uploadl
    : @"upload file at path ";
  
  path = [self fileId]
    ? [[self fileManager] pathForGlobalID:[self fileId]]
    : [[self fileManager] pathForGlobalID:[self folderId]];
  
  path = [uploadl stringByAppendingString:path];
  
  return path;
}

- (BOOL)showTitle {
  return [[self fileManager]
                isKindOfClass:NSClassFromString(@"SkyProjectFileManager")];
}
- (BOOL)showFilename {
  return [self fileId] ? NO : YES;
}

/* actions */

- (BOOL)isWindowsPath:(NSString *)_path {
  if ([[[[self context] request] clientCapabilities] isWindowsBrowser])
    return YES;
  
  if ([_path length] > 3) {
    if (([_path characterAtIndex:1] == ':') &&
        ([_path characterAtIndex:2] == '\\')) {
      /* a system path, eg 'C:\WINNT\Profiles\helge\Desktop\blah.pdf' */
      return YES;
    }
    if ([_path hasPrefix:@"\\\\"])
      /* a network path, eg '\\Trex\internet\data\pdf\ssl\ssl_cover.pdf' */
      return YES;
  }
  
  return NO;
}

- (id)_uploadAndRelease:(BOOL)_release unlock:(BOOL)_unlock {
  if (![[self uploadData1] _uploadAndRelease:_release unlock:_unlock])
    return nil;
  
  ASSIGN(self->upload1, (id)nil);
  
  if ([self->upload2 size] > 0) {
    if (![[self uploadData2] _uploadAndRelease:_release unlock:_unlock]) {
      ASSIGN(self->upload1, self->upload2);
      ASSIGN(self->upload2, self->upload3);
      ASSIGN(self->upload3, (id)nil);
      return nil;
    }
    ASSIGN(self->upload2, (id)nil);
  }
  if ([self->upload3 size] > 0) {
    if (![[self uploadData3] _uploadAndRelease:_release unlock:_unlock]) {
      ASSIGN(self->upload1, self->upload3);
      ASSIGN(self->upload3, (id)nil);
      return nil;
    }
    ASSIGN(self->upload3, (id)nil);
  }
  
  return [[(LSWSession *)[self session] navigation] leavePage];
}

- (id)upload {
  return [self _uploadAndRelease:NO unlock:NO];
}
- (id)uploadAndRelease {
  return [self _uploadAndRelease:YES unlock:NO];
}
- (id)uploadAndUnlock {
  return [self _uploadAndRelease:NO unlock:YES];
}

- (id)uploadAndTextEdit {
  NSData *data;
  id page;
  
  data = [[self uploadData1] uploadData];
  
  if ((data != nil) && ![data isSkyTextEditable]) {
    [self setErrorString:@"uploaded data is not editable !"];
    return nil;
  }
  
  if ([self->upload2 hasContent] || [self->upload3 hasContent]) {
    [self setErrorString:
            @"you can't edit files as text if multiple upload files "
            @"are specified !"];
    return nil;
  }
  
  page = [self pageWithName:@"SkyProject4DocumentEditor"];
  
  [page takeValue:[self fileManager] forKey:@"fileManager"];
  
  if ([self fileId])
    [page takeValue:[self fileId] forKey:@"fileId"];
  else
    [page takeValue:[self folderId] forKey:@"folderId"];
  
  /* transfer upload data */
  
  if ([data length] > 0) {
    NSString *s;
    
    s = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
    if (s) {
      [page takeValue:s forKey:@"text"];
      RELEASE(s);
    }
  }
  [page takeValue:[[self uploadData1] valueForKey:@"filename"]
        forKey:@"fileName"];
  [page takeValue:[[self uploadData1] valueForKey:@"subject"]
        forKey:@"subject"];
          
  return page;
}

- (id)cancel {
  return [[(LSWSession *)[self session] navigation] leavePage];
}

@end /* SkyProject4DocumentUpload */

@implementation SkyP4FileUploadData

- (id)initWithComponent:(SkyProject4DocumentUpload *)_c {
  self->component = _c;
  return self;
}

- (void)dealloc {
  RELEASE(self->filename);
  RELEASE(self->uploadPath);
  RELEASE(self->uploadData);
  RELEASE(self->subject);
  [super dealloc];
}

/* accessors */

- (void)setFileName:(NSString *)_fileName {
  ASSIGNCOPY(self->filename, _fileName);
}
- (NSString *)fileName {
  return self->filename;
}

- (void)setUploadPath:(NSString *)_uploadPath {
  ASSIGNCOPY(self->uploadPath, _uploadPath);
}
- (NSString *)uploadPath {
  return self->uploadPath;
}

- (void)setSubject:(NSString *)_subject {
  ASSIGNCOPY(self->subject, _subject);
}
- (NSString *)subject {
  return self->subject;
}

- (void)setUploadData:(NSData *)_uploadData {
  if ([_uploadData isKindOfClass:[NSString class]]) {
    _uploadData =
      [(NSString *)_uploadData dataUsingEncoding:NSISOLatin1StringEncoding];
  }
  ASSIGN(self->uploadData, _uploadData);
}
- (NSData *)uploadData {
  return self->uploadData;
}

/* calculated accessors */

- (BOOL)isWindowsPath:(NSString *)_path {
  return [self->component isWindowsPath:_path];
}

- (NSString *)uploadFilenameFromPath:(NSString *)_path {
  NSString *s;
  
  if ([[self fileName] length] > 0)
    return [self fileName];
  
  if ([self isWindowsPath:_path]) {
    const unsigned char *cstr;
    
    if ((cstr = [_path cString]))
      cstr = rindex(cstr, '\\');
    
    s = (cstr)
      ? [NSString stringWithCString:(cstr + 1)]
      : _path;
  }
  else {
    const unsigned char *cstr;

    if ((cstr = [_path cString]))
      cstr = rindex(cstr, '/');
    
    s = (cstr)
      ? [NSString stringWithCString:(cstr + 1)]
      : _path;
  }
  
  [self setFileName:s];
  return s;
}
- (NSString *)uploadFileName {
  return [self uploadFilenameFromPath:[self uploadPath]];
}

- (NSString *)filePath {
  EOGlobalID *fgid;
  NSString   *path;
  
  if ((fgid = [self->component fileId])) {
    path = [[self->component fileManager] pathForGlobalID:fgid];
  }
  else if ((fgid = [self->component folderId])) {
    path = [[self->component fileManager] pathForGlobalID:fgid];
    path = [path stringByAppendingPathComponent:[self fileName]];
  }
  else
    path = nil;
  
  return path;
}

- (BOOL)hasVersioning {
  return [[self->component fileManager]
                           supportsVersioningAtPath:[self filePath]];
}
- (BOOL)hasLocking {
  return [[self->component fileManager]
                           supportsLockingAtPath:[self filePath]];
}

- (BOOL)isValid {
  return (([[self uploadPath] length] > 0) &&
          ([[self uploadData] length] > 0));
}

- (BOOL)hasContent {
  return (self->uploadData == nil || [self->uploadData length] == 0) ? NO : YES;
}
- (unsigned)size {
  return [self->uploadData length];
}

/* actions */

- (BOOL)_uploadAndRelease:(BOOL)_release unlock:(BOOL)_unlock {
  id       fm;
  NSString *fname;

  if (self->uploadData == nil) {
    [self->component setErrorString:@"missing data for upload ..."];
    return NO;
  }
  if (![self isValid]) {
    [self->component setErrorString:@"missing uploaded file ..."];
    return NO;
  }
  
  fm = [self->component fileManager];
  
  [self->component debugWithFormat:@"upload %d bytes at %@ ..",
          [[self uploadData] length],
          [self uploadPath]];
  
  if ([self->component fileId]) {
    /* don't need to watch path, just store the data */
    
    fname = [fm pathForGlobalID:[self->component fileId]];
    
    /* first checkout or lock file */
    
    if ([self hasVersioning]) {
      if (![fm isFileLockedAtPath:fname]) {
        if (![fm checkoutFileAtPath:fname handler:nil]) {
          [self->component setErrorString:@"checkout of file failed !"];
          return NO;
        }
      }
    }
    else if ([self hasLocking]) {
      if (![fm isFileLockedAtPath:fname]) {
        if (![fm lockFileAtPath:fname handler:nil]) {
          [self->component setErrorString:@"locking of file failed !"];
          return NO;
        }
      }
    }
    
    /* now write contents */
    
    if (![fm writeContents:[self uploadData] atPath:fname]) {
      [self->component setErrorString:@"writing of data failed !"];
      return NO;
    }
    
    /* now handle auto-release/unlock */
    
    if (_release) {
      if (![fm releaseFileAtPath:fname handler:nil])
        [self->component setErrorString:@"couldn't release file after writing data .."];
    }
    else if (_unlock) {
      if (![fm unlockFileAtPath:fname handler:nil])
        [self->component setErrorString:@"couldn't unlock file after writing data .."];
    }
  }
  else {
    /* create new file */
    NSString     *folderPath;
    NSDictionary *attrs = nil;

    attrs = (self->subject)
      ? [NSDictionary dictionaryWithObjectsAndKeys:
                     self->subject, @"NSFileSubject", nil]
      : [NSDictionary dictionary];
    
    fname      = [self uploadFileName];
    folderPath = [fm pathForGlobalID:[self->component folderId]];
    fname      = [folderPath stringByAppendingPathComponent:fname];
    
    [self->component logWithFormat:@"upload %d bytes at %@ ..",
            [[self uploadData] length],
            fname];
    
    if (![fm createFileAtPath:fname
             contents:[self uploadData]
             attributes:attrs]) {
      [self->component printErrorWithSource:fname destination:nil];
      return NO;
    }
  }

  return YES;
}

@end /* SkyP4FileUploadData */
