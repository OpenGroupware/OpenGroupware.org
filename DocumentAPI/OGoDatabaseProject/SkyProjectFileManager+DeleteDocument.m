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

#include <OGoDatabaseProject/SkyProjectFileManager.h>
#include <OGoDatabaseProject/SkyProjectFileManagerCache.h>

@class NSString, NSMutableArray, NSArray, EOGenericRecord, NGHashMap;
@class EOAdaptorChannel;

@interface SkyProjectFileManager(ErrorHandling_Internals)
- (void)_initializeErrorDict;
- (BOOL)_buildErrorWithSource:(NSString *)_src dest:(NSString *)_dest
  msg:(int)_msgId handler:(id)_handler cmd:(SEL)_sel;
- (NSDictionary *)errorDict;
- (BOOL)_buildErrorWithSource:(NSString *)_src dest:(NSString *)_dest
  msg:(int)_msgId handler:(id)_handler cmd:(SEL)_sel doFlush:(BOOL)_cache
  doRollback:(BOOL)_doRollback;
@end /* SkyProjectFileManager(ErrorHandling+Internals) */

@interface SkyProjectFileManager(Locking_Internals)
- (NSArray *)allVersionAttributesAtPath:(NSString *)_path;
@end /* SkyProjectFileManager(Locking_Internals) */

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
  handler:(id)_handler;

- (BOOL)moveDir:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_dirName
  extension:(NSString *)_dirExt
  handler:(id)_handler
  doFlush:(BOOL)_doFlush;

- (BOOL)moveLink:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_linkName
  extension:(NSString *)_linkExt
  handler:(id)_handler;

- (BOOL)moveLink:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_linkName
  extension:(NSString *)_linkExt
  handler:(id)_handler
  doFlush:(BOOL)_doFlush;

- (BOOL)moveFile:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_fileName
  extension:(NSString *)_fileExt
  handler:(id)_handler;

- (BOOL)moveFile:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_fileName
  extension:(NSString *)_fileExt
  handler:(id)_handler
  doFlush:(BOOL)_doFlush;

@end /* SkyProjectFileManager(Internals) */

@interface SkyProjectFileManagerCache(Internals)
- (NGHashMap *)parent2ChildDirectoriesCache;
- (EOAdaptorChannel *)beginTransaction;
- (void)commitTransaction;
- (void)rollbackTransaction;
@end /* SkyProjectFileManagerCache(Internals) */

@interface SkyProjectFileManager(Removing)
- (BOOL)_removeFileAttrs:(NSArray *)_paths handler:(id)_handler
  failed:(BOOL*)failed_;
- (BOOL)_removeFiles:(NSArray *)_fileAttrs handler:(id)_handler
  failed:(BOOL*)failed_;
- (BOOL)_removeDirs:(NSArray *)_dirAttr handler:(id)_handler failed:(BOOL*)failed_;
@end

#include <OGoDatabaseProject/SkyProjectFileManagerCache.h>
#include "common.h"

@interface SkyProjectFileManager(DeleteDocument)
- (BOOL)prepareDeletionOf:(NSDictionary *)_dict;
- (BOOL)deleteVersions:(NSDictionary *)_attrs
  filesToRemove:(NSMutableArray *)_array;
- (BOOL)deleteDocumentEditing:(NSDictionary *)_attrs
  filesToRemove:(NSMutableArray *)_array;
- (BOOL)deleteDoc:(NSDictionary *)_attrs filesToRemove:(NSMutableArray *)_array;
- (BOOL)reallyDeleteFile:(NSDictionary *)_attrs;
- (void)removeAllFiles:(NSArray *)_files;
@end

@implementation SkyProjectFileManager(DeleteDocument)

- (BOOL)prepareDeletionOf:(NSDictionary *)_dict {
  EOEntity         *entity;
  NSMutableString  *str;
  NSNumber         *number;
  EOAdaptorChannel *channel;
  
  if (![[_dict objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
    return YES;

  entity = [[[[[self->cache context] valueForKey:LSDatabaseKey] adaptor] model]
                            entityNamed:@"Doc"];

  str = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE %@ = %@",
                    [entity externalName],
                    [[entity attributeNamed:@"parentDocumentId"] columnName],
                    [[[_dict valueForKey:@"globalID"] keyValuesArray] 
		             lastObject]];

  channel = [self->cache beginTransaction];
  if (![channel evaluateExpression:str]) {
      NSLog(@"ERROR[%s]: select failed for expression %@ attrs %@ ",
            __PRETTY_FUNCTION__, str, _dict);
      [self->cache rollbackTransaction];
      return NO;
  }
  number = [[[channel fetchAttributes:[channel describeResults] 
		      withZone:NULL]
                      allValues] lastObject];
  [channel cancelFetch];
    
  if ([number intValue]) {
    [self _buildErrorWithSource:[_dict objectForKey:NSFilePath]
	  dest:nil msg:22 handler:nil cmd:_cmd];
    return NO;
  }
  return YES;
}

- (BOOL)deleteVersions:(NSDictionary *)_attrs
  filesToRemove:(NSMutableArray *)_array
{
  NSArray         *versions;
  NSEnumerator    *enumerator;
  id              obj;
  EOEntity        *entity;
  NSMutableString *str;

  entity = [[[[[self->cache context] valueForKey:LSDatabaseKey] adaptor] model]
                            entityNamed:@"DocumentVersion"];

  versions   = [self allVersionAttributesAtPath:
		       [_attrs objectForKey:NSFilePath]];
  enumerator = [versions objectEnumerator];

  
  str = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = %@",
                  [entity externalName], [[entity attributeNamed:@"documentId"]
                                                  columnName],
                  [[[_attrs valueForKey:@"globalID"] 
		            keyValuesArray] lastObject]];
  
  if (![[self->cache beginTransaction] evaluateExpression:str]) {
    NSLog(@"ERROR[%s]: select failed for expression %@ attrs %@ ",
          __PRETTY_FUNCTION__, str, versions);
    [self->cache rollbackTransaction];
    return NO;
  }
  while ((obj = [enumerator nextObject])) {
    [_array addObject:[obj objectForKey:@"SkyBlobPath"]];
  }

  return YES;
}

- (BOOL)deleteDocumentEditing:(NSDictionary *)_attrs
  filesToRemove:(NSMutableArray *)_array
{
  NSArray         *versions = nil;
  EOEntity        *entity;
  NSMutableString *str;

  entity = [[[[[self->cache context] valueForKey:LSDatabaseKey] adaptor] model]
                            entityNamed:@"DocumentEditing"];

  str = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = %@",
                  [entity externalName], [[entity attributeNamed:@"documentId"]
                                                  columnName],
                  [[[_attrs valueForKey:@"globalID"] 
		            keyValuesArray] lastObject]];
  
  if (![[self->cache beginTransaction] evaluateExpression:str]) {
    NSLog(@"ERROR[%s]: select failed for expression %@ attrs %@ ",
          __PRETTY_FUNCTION__, str, versions);
    [self->cache rollbackTransaction];
    return NO;
  }
  {
    id tmp;

    if ((tmp = [_attrs objectForKey:@"__editBlobPath__"]))
      [_array addObject:tmp];
  }
  return YES;
}

- (BOOL)deleteDoc:(NSDictionary *)_attrs filesToRemove:(NSMutableArray *)_fs {
  // TODO: fix method name "filesToRemove" is "files successfully removed"?
  EOEntity        *entity;
  NSMutableString *str;
  id tmp;
  
  entity = [[[[[self->cache context] valueForKey:LSDatabaseKey] adaptor] model]
                             entityNamed:@"Doc"];

  str = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = %@",
                  [entity externalName], [[entity attributeNamed:@"documentId"]
                                                  columnName],
                  [[[_attrs valueForKey:@"globalID"] 
		            keyValuesArray] lastObject]];
  
  if (![[self->cache beginTransaction] evaluateExpression:str]) {
    NSLog(@"ERROR[%s]: select failed for expression %@ attrs %@ ",
          __PRETTY_FUNCTION__, str, _attrs);
    [self->cache rollbackTransaction];
    return NO;
  }
    
  if ((tmp = [_attrs objectForKey:@"__docBlobPath__"]))
    [_fs addObject:tmp];
  
  return YES;
}

- (BOOL)reallyDeleteFile:(NSDictionary *)_attrs {
  NSMutableArray *filesToRemove;
  NSString       *ft;

  if ([_attrs count] == 0)
    return YES;
  
  if (![self prepareDeletionOf:_attrs])
    return NO;
  
  filesToRemove = [NSMutableArray arrayWithCapacity:10];

  ft = [_attrs objectForKey:NSFileType];
  if ([ft isEqual:NSFileTypeRegular] || [ft isEqual:NSFileTypeUnknown]) {
    if (![self deleteVersions:_attrs filesToRemove:filesToRemove])
      return NO;
    
    if (![self deleteDocumentEditing:_attrs filesToRemove:filesToRemove])
      return NO;
  }
  if (![self deleteDoc:_attrs filesToRemove:filesToRemove])
    return NO;
  
  [self removeAllFiles:filesToRemove];
  return YES;
}

- (void)removeAllFiles:(NSArray *)_files {
  NSEnumerator  *enumerator;
  NSString      *fileName;
  NSFileManager *manager;

  manager    = [NSFileManager defaultManager];
  enumerator = [_files objectEnumerator];

  while ((fileName = [enumerator nextObject])) {
    if (![manager fileExistsAtPath:fileName])
      continue;
    
    if (![manager removeFileAtPath:fileName handler:nil]) {
      [self logWithFormat:@"WARNING(%s): couldn`t delete file %@",
	      __PRETTY_FUNCTION__, fileName];
    }
  }
}


@end /* SkyProjectFileManager(DeleteDocument) */
