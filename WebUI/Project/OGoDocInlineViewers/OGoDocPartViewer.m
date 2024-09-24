/*
  Copyright (C) 2005 Helge Hess

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

#include "OGoDocPartViewer.h"
#include <OGoDatabaseProject/SkyDocumentHistoryDataSource.h>
#include <OGoDatabaseProject/SkyProjectDocument.h>
#include <OGoDatabaseProject/SkyProjectFileManager.h>
#include "common.h"

@implementation OGoDocPartViewer

+ (int)version {
  return [super version] + 0 /* v2 */;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (void)dealloc {
  [self->historyDataSource release];
  [self->path        release];
  [self->fsinfo      release];
  [self->documentGID release];
  [self->fileManager release];
  [self->document    release];
  [super dealloc];
}

/* enable/disable */

+ (BOOL)canShowInDocumentViewer:(OGoComponent *)_viewer {
  return YES;
}

/* notifications */

- (void)resetDocCaches {
  [self->document          release]; self->document          = nil;
  [self->documentGID       release]; self->documentGID       = nil;
  [self->historyDataSource release]; self->historyDataSource = nil;
}
- (void)reset {
  [self->fileManager release]; self->fileManager = nil;
  [self->fsinfo      release]; self->fsinfo      = nil;
  [self resetDocCaches];
  [super reset];
}

- (void)syncSleep {
  [self reset];
  [super syncSleep];
}

/* accessors */

#if USE_PASSIVE_SYNC
- (BOOL)synchronizesVariablesWithBindings {
  return NO;
}
#endif

- (void)setFileManager:(id<NSObject,SkyDocumentFileManager>)_fm {
  ASSIGN(self->fileManager, _fm);
}
- (id<NSObject,SkyDocumentFileManager>)fileManager {
#if USE_PASSIVE_SYNC
  if (self->fileManager == nil)
    self->fileManager = [[self valueForBinding:@"fileManager"] retain];
#endif
  return self->fileManager;
}

- (void)setDocumentGlobalID:(EOGlobalID *)_gid {
  ASSIGN(self->documentGID, _gid);
}
- (EOGlobalID *)documentGlobalID {
#if USE_PASSIVE_SYNC
  if (self->documentGID == nil)
    self->documentGID = [[self valueForBinding:@"documentGlobalID"] retain];
#endif
  return self->documentGID;
}

- (void)setDocument:(id)_doc {
  ASSIGN(self->document, _doc);
}
- (id)document {
#if USE_PASSIVE_SYNC
  if (self->document == nil)
    self->document = [[self valueForBinding:@"document"] retain];
#endif
  return self->document;
}

- (Class)historyDataSourceClass {
  return NGClassFromString(@"SkyDocumentHistoryDataSource");
}
- (EODataSource *)historyDataSource {
  // TODO: use a generic capability query, not a method
  if (![(id)[self fileManager] supportsHistoryDataSource])
    return nil;
  
  if (self->historyDataSource != nil)
    return self->historyDataSource;
    
  self->historyDataSource =
    [[[self historyDataSourceClass] alloc]
      initWithFileManager:(id)[self fileManager]
      documentGlobalID:[self documentGlobalID]];
  return self->historyDataSource;
}

- (void)setDocumentPath:(NSString *)_value {
  ASSIGNCOPY(self->path, _value);
}
- (NSString *)documentPath {
#if USE_PASSIVE_SYNC
  return [self valueForBinding:@"documentPath"];
#else
  return self->path;
#endif
}

- (NSString *)_documentPath {
  id tmp;
  
  if ([(tmp = [self document]) isNotNull])
    return [tmp path];
  
  if ([(tmp = [self documentGlobalID]) isNotNull])
    return [[self fileManager] pathForGlobalID:tmp];
  
  return [self documentPath];
}

- (BOOL)canReadFile {
  return [[self fileManager] isReadableFileAtPath:[self _documentPath]];
}

- (NSDictionary *)fileSystemInfo {
  if (self->fsinfo != nil)
    return self->fsinfo;
  
  self->fsinfo = [[[self fileManager]
                         fileSystemAttributesAtPath:[self _documentPath]]
                         copy];
  return self->fsinfo;
}

- (NSString *)documentName {
  return [[self _documentPath] lastPathComponent];
}
// TODO: no such method in the viewer?! - (NSString *)versionString 

- (NSDictionary *)documentAttributes {
  return [[self fileManager]
                fileAttributesAtPath:[self _documentPath]
                traverseLink:YES];
}

- (NSString *)documentMimeType {
  NSString *mimeType;
  
  if ((mimeType = [[self documentAttributes] objectForKey:@"NSFileMimeType"]))
    return [mimeType stringValue];
  
  return @"application/octet-stream";
}

/* actions */

- (id)editStandardAttrs {
  WOComponent *page;
  
  page = [self pageWithName:@"SkyDocumentAttributeEditor"];
  [page takeValue:[self document]  forKey:@"doc"];
  
#warning TODO: clear page cache?
  // TODO: the SkyProject4DocumentViewer does reset all its info?
  //       => might need a notification for that
  
  return page;
}

- (id)editProperties {
  WOComponent *page;
  
  if ((page = [self pageWithName:@"SkyObjectPropertyEditor"]) == nil) {
    [[[self context] page] setErrorString:@"Could not find property editor!"];
    return nil;
  }
  
  [page takeValue:[self documentGlobalID]          forKey:@"globalID"];
  [page takeValue:[(id)[self fileManager] defaultProjectDocumentNamespace]
        forKey:@"defaultNamespace"];
  [page takeValue:[self labels] forKey:@"labels"];
  return page;
}

@end /* OGoDocPartViewer */
