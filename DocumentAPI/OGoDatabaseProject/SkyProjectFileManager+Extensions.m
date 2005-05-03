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

#include <OGoDatabaseProject/SkyProjectFileManager.h>

@class NSString, EOQualifier, EOGenericRecord, NSArray, NSMutableArray;

@interface SkyProjectFileManager(ErrorHandling_Internals)
- (void)_initializeErrorDict;
- (BOOL)_buildErrorWithSource:(NSString *)_src dest:(NSString *)_dest
  msg:(int)_msgId handler:(id)_handler cmd:(SEL)_sel;
- (NSDictionary *)errorDict;
@end /* SkyProjectFileManager(ErrorHandling+Internals) */
  
@interface SkyProjectFileManager(Extensions_Internals)
- (NSArray *)searchChildsForFolder:(NSString *)_path
  deep:(BOOL)_deep
  qualifier:(EOQualifier *)_qualifier;
+ (void)setProjectID:(NSNumber *)_pid forDocID:(NSNumber *)_did
  context:(id)_cxt;
+ (NSNumber *)pidForDocId:(NSNumber *)_did context:(id)_ctx;
+ (NSDictionary *)projectIdsForDocsInContext:(id)_ctx;
+ (void)setProjectIdsForDocs:(NSDictionary *)_dict inContext:(id)_ctx;
@end /* SkyProjectFileManager(Extensions_Internals) */

@interface SkyProjectFileManager(Internals)

- (void)_checkCWDFor:(NSString *)_source;
- (id)_project;
- (NSString *)_defaultCompleteProjectDocumentNamespace;
- (NSArray *)subDirectoryNamesForPath:(NSString *)_path;
- (NSString *)_makeAbsolute:(NSString *)_path;
- (void)_subpathsAtPath:(NSString *)_path array:(NSMutableArray *)_array;
- (BOOL)_copyPath:(NSString*)_src toPath:(NSString*)_dest handler:(id)_handler;

- (BOOL)moveDir:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_dirName
  extension:(NSString *)_dirExt
  handler:(id)_handleru;

- (BOOL)moveLink:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_linkName
  extension:(NSString *)_linkExt
  handler:(id)_handler;

- (BOOL)moveFile:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_fileName
  extension:(NSString *)_fileExt
 handler:(id)_handler;

- (BOOL)writeContents:(NSData *)_content atPath:(NSString *)_path
  handler:(id)_handler flush:(BOOL)_doFlush;
@end /* SkyProjectFileManager(Internals) */


#include <OGoDatabaseProject/SkyProjectFileManagerCache.h>
#include <OGoDatabaseProject/SkyProjectFolderDataSource.h>
#include <OGoDatabaseProject/SkyDocumentIdHandler.h>
#include "common.h"

@implementation SkyProjectFileManager(ExtendedFileManagerImp)

// TODO: this stuff belongs into a separate class ...

+ (EOKeyGlobalID *)baseGlobalIDForEditingGlobalID:(EOKeyGlobalID *)dgid 
  context:(LSCommandContext *)_ctx
{
  // TODO: move to SkyDocumentIdHandler?
  EOKeyGlobalID *gid;
  id did;
    
  did = [_ctx runCommand:@"documentediting::get-by-globalid",
		@"noAccessCheck", [NSNumber numberWithBool:YES],
                @"gid", dgid,
                @"attributes", [NSArray arrayWithObject:@"documentId"], nil];
    
  if ([did isKindOfClass:[NSArray class]])
    did = [did count] > 0 ? [did lastObject] : nil;
    
  if (![(did = [did valueForKey:@"documentId"]) isNotNull]) {
      NSLog(@"ERROR[%s]: missing documentId for documentEditingId %@",
            __PRETTY_FUNCTION__, dgid);
      return nil;
  }
  gid = [EOKeyGlobalID globalIDWithEntityName:@"Doc"
		       keys:&did keyCount:1 zone:NULL];
  return gid;
}

+ (EOKeyGlobalID *)baseGlobalIDForVersionGlobalID:(EOKeyGlobalID *)dgid 
  context:(LSCommandContext *)_ctx
{
  // TODO: move to SkyDocumentIdHandler?
  EOKeyGlobalID *gid;
  NSNumber      *key;
  id            doc;
  
  doc = [_ctx runCommand:@"documentversion::get",
                @"documentVersionId", [dgid keyValues][0], nil];
  key = [doc valueForKey:@"documentId"];
  if (![key isNotNull])
    return nil;
    
  gid = [EOKeyGlobalID globalIDWithEntityName:@"Doc"
		       keys:&key keyCount:1 zone:NULL];
  return gid;
}

+ (EOKeyGlobalID *)baseGlobalIDForDocumentGlobalID:(EOGlobalID *)_dgid 
  context:(LSCommandContext *)_ctx
{
  // TODO: move to SkyDocumentIdHandler?
  EOKeyGlobalID *dgid;
  
  /* ensure a EOKeyGlobalID */
  
  if (![_dgid isKindOfClass:[EOKeyGlobalID class]]) {
    NSLog(@"WARNING(%s): wrong global id for method", __PRETTY_FUNCTION__, 
	  _dgid);
    return nil;
  }
  dgid = (EOKeyGlobalID *)_dgid;

  if ([[dgid entityName] isEqualToString:@"Doc"])
    return dgid;
  
  if ([[dgid entityName] isEqualToString:@"DocumentEditing"])
    return [self baseGlobalIDForEditingGlobalID:dgid context:_ctx];
  
  if ([[dgid entityName] isEqualToString:@"DocumentVersion"])
    return [self baseGlobalIDForVersionGlobalID:dgid context:_ctx];
  
  [self logWithFormat:@"WARNING: unknown document GID: %@", dgid];
  return nil;
}

+ (EOGlobalID *)projectGlobalIDForDocumentGlobalID:(EOGlobalID *)_dgid
  context:(id)_ctx
{
  // TODO: cleanup code
  NSNumber      *pid;
  EOKeyGlobalID *dgid;
  EOGlobalID    *gid;
  id  handler;
  
  if (![_dgid isNotNull] || _ctx == nil) {
    NSLog(@"ERROR[%s]: missing globalID or context", __PRETTY_FUNCTION__);
    return nil;
  }

  if (![_dgid isKindOfClass:[EOKeyGlobalID class]]) {
    NSLog(@"WARNING(%s): wrong global id for method", __PRETTY_FUNCTION__, 
	  _dgid);
    return nil;
  }
  
  pid = (id)[SkyProjectFileManager pidForDocId:[(id)_dgid keyValues][0]
				   context:_ctx];
  if ([pid isNotNull]) {
    gid = [EOKeyGlobalID globalIDWithEntityName:@"Project"
			 keys:&pid keyCount:1 zone:NULL];
    return gid;
  }
  
  dgid = [self baseGlobalIDForDocumentGlobalID:_dgid context:_ctx];
  
  handler = [SkyDocumentIdHandler handlerWithContext:_ctx];
  
  if ((gid = [handler projectGIDForDocumentGID:dgid context:_ctx]) == nil)
    return nil;
  
  [SkyProjectFileManager setProjectID:[(EOKeyGlobalID *)gid keyValues][0]
			 forDocID:[(EOKeyGlobalID *)dgid keyValues][0]
                         context:_ctx];
  return gid;
}

/* global ids */

- (BOOL)writeContents:(NSData *)_content atPath:(NSString *)_path
  handler:(id)_handler
{
  return [self writeContents:_content atPath:_path handler:_handler flush:YES];
}

- (BOOL)writeContents:(NSData *)_content atPath:(NSString *)_path
  handler:(id)_handler flush:(BOOL)_doFlush 
{
  NSDictionary *attrs;
  BOOL         release;
  NSString     *status;
  int          ec;

  if ((_path = [self _makeAbsolute:_path]) == nil) {
    return [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil
                 cmd:_cmd];
  }
  if (!(attrs = [self fileAttributesAtPath:_path traverseLink:NO])) {
    /* new document */
    return [self createFileAtPath:_path contents:_content attributes:nil];
  }

  if (![self isWritableFileAtPath:_path])
    return NO;
  
  if (_content == nil)
    _content = [NSData data];
  
  status  = [attrs objectForKey:@"SkyStatus"];
  release = NO;
  
  if (![status isEqualToString:@"edited"]) {
    if (![self checkoutFileAtPath:_path handler:_handler]) {
      return NO;
    }
    attrs   = [self fileAttributesAtPath:_path traverseLink:NO];    
    release = YES;
  }
  NS_DURING {
    id d;
    ec = 0;
    if ((d = [self->cache genericRecordForAttrs:attrs manager:self])) {
      [[self context] runCommand:@"doc::set",
                      @"object", d,
                      @"data", _content,
                      @"fileSize", [NSNumber numberWithInt:[_content length]],
                      nil];
    }
    else
      ec = 4;
  }
  NS_HANDLER {
    ec = 17;
    [self setLastException:localException];
  }
  NS_ENDHANDLER;
  if (ec) {
    if (release) {
      if (![self rejectFileAtPath:_path handler:_handler])
        ec = 57;
    }
    return [self _buildErrorWithSource:_path dest:nil msg:ec handler:_handler
                 cmd:_cmd];
  }
  if (release) {
    if (![self releaseFileAtPath:_path handler:_handler]) {
      return NO;
    }
  }
  [self postChangeNotificationForPath:
	  [_path stringByDeletingLastPathComponent]];
  [self flush];
  return YES;
}

- (BOOL)writeContents:(NSData *)_content atPath:(NSString *)_path {
  return [self writeContents:_content atPath:_path handler:nil];
}

/* locking */

- (BOOL)lockFileAtPath:(NSString *)_path handler:(id)_handler {
  return [self checkoutFileAtPath:_path handler:_handler];
}
- (BOOL)unlockFileAtPath:(NSString *)_path handler:(id)_handler {
  return [self releaseFileAtPath:_path handler:_handler];
}
- (BOOL)isFileLockedAtPath:(NSString *)_path {
  FMVersioningStatus stat;
  
  stat = [self versioningStatusAtPath:_path];
  
  return (stat != FMVersioningStatus_RELEASED) ? YES : NO;
}

- (BOOL)isLockableFileAtPath:(NSString *)_path {
  if ([self isFileLockedAtPath:_path])
    return NO;
  
  return [self isWritableFileAtPath:_path];
}

- (BOOL)isUnlockableFileAtPath:(NSString *)_path {
  return [self->cache isUnlockableFileAtPath:_path manager:self];
}

/* global-id's */

- (NSString *)pathForGlobalId:(EOGlobalID *)_pgid {
  NSLog(@"ERROR[%s] deprecated.", __PRETTY_FUNCTION__);
  return [self pathForGlobalID:_pgid];
}

- (NSString *)pathForGlobalID:(EOGlobalID *)_pgid {
  if (!_pgid)
    return nil;
  
  if (![_pgid isKindOfClass:[EOKeyGlobalID class]]) {
    [self logWithFormat:
	    @"WARNING(%s): cannot process GID %@, expected EOKeyGlobalID",
            __PRETTY_FUNCTION__, _pgid];
    return nil;
  }
  if ([[(EOKeyGlobalID *)_pgid entityName] isEqualToString:@"Doc"] ||
      [[(EOKeyGlobalID *)_pgid entityName] isEqualToString:@"DocumentEditing"])
    return [self->cache pathForGID:_pgid manager:self];

  return nil;
}

- (EOGlobalID *)globalIDForPath:(NSString *)_path {
  if (!(_path = [self _makeAbsolute:_path])) {
    [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil cmd:_cmd];
    return nil;
  }
  [self->lastException release]; self->lastException = nil;
  self->lastErrorCode = 0;
  return [self->cache gidForPath:_path manager:self];
}

/* trash */

- (BOOL)supportsTrashFolderAtPath:(NSString *)_path {
  return YES;
}
- (NSString *)trashFolderForPath:(NSString *)_path {
  static NSString *trashFolderPath = nil;
  if (trashFolderPath == nil) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    trashFolderPath = [[ud stringForKey:@"OGoProjectTrashFolderPath"] copy];
    if (trashFolderPath == nil) trashFolderPath = @"/trash";
  }
  return trashFolderPath;
}

- (id)context {
  return [self->cache context];
}

- (NSArray *)readOnlyDocumentKeys {
  static NSArray *readOnlyDocumentKeys = nil;

  if (readOnlyDocumentKeys == nil) {
    readOnlyDocumentKeys = [[NSArray alloc]
                                     initWithObjects:
                                     @"NSFileMimeType",
                                     @"NSFileModificationDate",
                                     @"NSFileName",
                                     @"NSFileOwnerAccountName",
                                     @"NSFileOwnerAccountNumber",
                                     @"NSFilePath",
                                     @"NSFileSize",
                                     @"NSFileType",
                                     @"SkyCreationDate",
                                     @"SkyFileName",
                                     @"SkyFilePath",
                                     @"SkyFirstOwnerId",
                                     @"SkyIsVersion",
                                     @"SkyLastModifiedDate",
                                     @"SkyOwnerId",
                                     @"SkyStatus",
                                     @"SkyVersionCount",
                                     @"creationDate",
                                     @"fileSize",
                                     @"fileType",
                                     @"filename",
                                     @"globalID",
                                     @"lastmodifiedDate",
                                     @"status",
                                     @"versionCount", nil];
  }
  return readOnlyDocumentKeys;
}

@end /* SkyProjectFileManager(ExtendedFileManagerImp) */

@implementation SkyProjectFileManager(Datasources)

- (EODataSource *)dataSourceAtPath:(NSString *)_path {
  SkyProjectFolderDataSource *ds;
  id                         fgid;
  
  if (_path == nil)
    return nil;
  
  if ((_path = [self _makeAbsolute:_path]) == nil) {
    [self _buildErrorWithSource:_path dest:nil msg:20 handler:nil cmd:_cmd];
    return nil;
  }
  fgid  = [self->cache gidForPath:_path manager:self];
  
  if (fgid == nil)
    return nil;
  
  ds = [[SkyProjectFolderDataSource alloc]
                                    initWithContext:[self->cache context]
                                    folderGID:fgid
                                    projectGID:[[self->cache project] globalID]
                                    path:_path fileManager:self];
  return [ds autorelease];
}

- (EODataSource *)dataSource {
  return [self dataSourceAtPath:[self currentDirectoryPath]];
}

@end /* SkyProjectFolder(Datasources) */

@implementation SkyProjectFileManager(CustomRights)

- (BOOL)isOperation:(NSString *)_op allowedOnPath:(NSString *)_path {
  return [self->cache isOperation:_op allowedOnPath:_path manager:self];
}
- (NSString *)filePermissionsAtPath:(NSString *)_path {
  return [self->cache filePermissionsAtPath:_path manager:self];
}
@end /* SkyProjectFileManager(CustomRights) */

@implementation SkyProjectFileManager(Extensions_Internals)

+ (void)setProjectID:(NSNumber *)_pid forDocID:(NSNumber *)_did
  context:(id)_cxt
{
  NSMutableDictionary *dict;

  if (!(dict = [_cxt valueForKey:@"docToProjectCache"])) {
    dict = [NSMutableDictionary dictionaryWithCapacity:256];
    [_cxt takeValue:dict forKey:@"docToProjectCache"];
  }
  [dict setObject:_pid forKey:_did];
}

+ (NSNumber *)pidForDocId:(NSNumber *)_did context:(id)_ctx {
  return [(NSDictionary *)[_ctx valueForKey:@"docToProjectCache"] 
			  objectForKey:_did];
}

+ (NSDictionary *)projectIdsForDocsInContext:(id)_ctx {
  return [(NSDictionary *)[_ctx valueForKey:@"docToProjectCache"]
                objectForKey:@"projectIdsForDocs"];
}

+ (void)setProjectIdsForDocs:(NSDictionary *)_dict inContext:(id)_ctx {
  [(NSMutableDictionary *)[_ctx valueForKey:@"docToProjectCache"]
			  setObject:_dict forKey:@"projectIdsForDocs"];
}

- (NSArray *)searchChildsForFolder:(NSString *)_path
  deep:(BOOL)_deep
  qualifier:(EOQualifier *)_qualifier
{
  return [self->cache searchChildsForFolder:_path deep:_deep
                      qualifier:_qualifier manager:self]; 
}

- (BOOL)supportQualifier:(EOQualifier *)_qual {
  return [SkyProjectFileManager supportQualifier:_qual];
}

@end /* SkyProjectFileManager(ExtendedFileManager) */

@implementation SkyProjectFileManager(Cache)

- (BOOL)useSessionCache {
  return [self->cache useSessionCache];
}

- (void)setUseSessionCache:(BOOL)_cache {
  [self->cache setUseSessionCache:_cache];
}

- (void)flush {
  [self->cache flushWithManager:self];
}

- (NSTimeInterval)flushTimeout {
  return [self->cache flushTimeout];
}
- (void)setFlushTimeout:(NSTimeInterval)_timeInt {
  [self->cache setFlushTimeout:_timeInt];
}

@end /* SkyProjectFileManager(Cache) */


@implementation SkyProjectFileManager(ErrorHandling)

static NSNumber *num(int _i) {
  return [NSNumber numberWithInt:_i];
}

- (void)setLastException:(NSException *)_exc {
  ASSIGN(self->lastException, _exc);
}
- (NSException *)lastException {
  return self->lastException;
}

- (BOOL)supportsExternalErrorDescription {
  return NO;
}

- (int)lastErrorCode {
  return self->lastErrorCode;
}

- (NSString *)lastErrorDescription {
  return [[self errorDict] objectForKey:num([self lastErrorCode])];
}

- (NSString *)errorDescriptionForCode:(int)_code {
  return [[self errorDict]  objectForKey:num(_code)];
}

- (NSDictionary *)errorUserInfo {
  return self->errorUserInfo;
}

@end

@implementation SkyProjectFileManager(GenericRecordGeneration)

- (EOGenericRecord *)genericRecordForDocGID:(EOGlobalID *)_dgig {
  return [self->cache genericRecordForGID:_dgig manager:self];
}

@end /* SkyProjectFileManager(GenericRecordGeneration) */
