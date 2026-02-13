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

#ifndef NGFileManagerCopyTool_h
#define NGFileManagerCopyTool_h

#include <OGoProject/NGFileManagerProcessingTool.h>
#include <EOControl/EOQualifier.h>

/**
 * @class NGFileManagerCopyTool
 * @brief Copies files and directories between NGFileManager
 *        instances.
 *
 * A processing tool that copies file system trees from a
 * source NGFileManager to a target NGFileManager. Supports
 * recursive traversal, overwrite control, include/exclude
 * qualifier-based filtering, and optional save/restore of
 * file attributes (subject, MIME type, WebDAV properties).
 *
 * @see NGFileManagerProcessingTool
 * @see NGFileManagerCopyToolHandler
 */
@interface NGFileManagerCopyTool : NGFileManagerProcessingTool
{
  id<NSObject,NGFileManager> targetFileManager;
  BOOL                       recursive;
  BOOL                       saveAttributes;
  BOOL                       restoreAttributes;
  BOOL                       overwrite;
  EOQualifier               *excludeQualifier;
  EOQualifier               *includeQualifier;
  BOOL                       verbose;
}

/* accessors */

- (void)setSourceFileManager:(id<NSObject,NGFileManager>)_fm;
- (id<NSObject,NGFileManager>)sourceFileManager;
- (void)setTargetFileManager:(id<NSObject,NGFileManager>)_fm;
- (id<NSObject,NGFileManager>)targetFileManager;

- (void)setRecursive:(BOOL)_rec;
- (BOOL)recursive;
- (void)setSaveAttributes:(BOOL)_save;
- (BOOL)saveAttributes;
- (void)setRestoreAttributes:(BOOL)_restore;
- (BOOL)restoreAttributes;

- (void)setOverwrite:(BOOL)_overwrite;
- (BOOL)overwrite;

- (void)setExcludeQualifier:(EOQualifier *)_qual;
- (EOQualifier *)excludeQualifier;
- (void)setIncludeQualifier:(EOQualifier *)_qual;
- (EOQualifier *)includeQualifier;

- (void)setVerbose:(BOOL)_verbose;
- (BOOL)verbose;

/* operations */

- (NSException *)copyPath:(NSString *)_srcPath
  toPath:(NSString *)_toPath
  handler:(id)_handler;


@end /* NGFileManagerCopyTool */

/**
 * @class NGFileManagerCopyToolHandler
 * @brief Handler for NGFileManagerCopyTool processing
 *        callbacks.
 *
 * Implements the processing callbacks for directory, file,
 * and symlink operations during a copy. Manages the target
 * directory stack, applies include/exclude qualifiers, and
 * handles save/restore of file attributes and properties.
 *
 * @see NGFileManagerCopyTool
 */
@interface NGFileManagerCopyToolHandler : NSObject
{
  id<NSObject,NGFileManager> targetFileManager;
  NSString                   *targetDirectory;
  BOOL                       recursive;
  BOOL                       saveAttributes;
  BOOL                       restoreAttributes;
  BOOL                       overwrite;
  EOQualifier               *excludeQualifier;
  EOQualifier               *includeQualifier;

  NSMutableDictionary *fileAttributes;

  BOOL                       verbose;
}

/* accessors */

- (void)setTargetFileManager:(id<NSObject,NGFileManager>)_fm;
- (id<NSObject,NGFileManager>)targetFileManager;

- (void)setTargetDirectory:(NSString *)_target;
- (NSString *)targetDirectory;

- (void)setRecursive:(BOOL)_rec;
- (BOOL)recursive;
- (void)setSaveAttributes:(BOOL)_save;
- (BOOL)saveAttributes;
- (void)setRestoreAttributes:(BOOL)_restore;
- (BOOL)restoreAttributes;

- (void)setOverwrite:(BOOL)_overwrite;
- (BOOL)overwrite;

- (void)setExcludeQualifier:(EOQualifier *)_qual;
- (EOQualifier *)excludeQualifier;
- (void)setIncludeQualifier:(EOQualifier *)_qual;
- (EOQualifier *)includeQualifier;

- (void)setVerbose:(BOOL)_verbose;
- (BOOL)verbose;

/* operations */

- (NSException *)tool:(NGFileManagerProcessingTool *)_tool
  processDirectoryPath:(NSString *)_directoryPath;
- (NSException *)tool:(NGFileManagerProcessingTool *)_tool
  processFilePath:(NSString *)_filePath;
- (NSException *)tool:(NGFileManagerProcessingTool *)_tool
  processLinkPath:(NSString *)_linkPath;

/* misc */

- (NSException *)handleSaveRestoreAttributesForPath:(NSString *)_path
  newPath:(NSString *)_newPath
  tool:(NGFileManagerProcessingTool *)_tool;

- (NSData *)dataFromDictionary:(NSDictionary *)_dict;
- (NSDictionary *)dictionaryFromData:(NSData *)_data;
- (NSDictionary *)fileAttributesAtPath:(NSString *)_path
  tool:(NGFileManagerProcessingTool *)_tool;

@end /* NGFileManagerCopyToolHandler */

/**
 * @category NSObject(NGFileManagerCopyToolHandler)
 * @brief Default handler callbacks for file manager
 *        processing tools.
 *
 * Provides default implementations of the processing
 * callbacks invoked by NGFileManagerProcessingTool for
 * directories, files, and symbolic links.
 */
@interface NSObject(NGFileManagerCopyToolHandler)
- (NSException *)tool:(NGFileManagerProcessingTool *)_tool
  processDirectoryPath:(NSString *)_directoryPath;
- (NSException *)tool:(NGFileManagerProcessingTool *)_tool
  processFilePath:(NSString *)_filePath;
- (NSException *)tool:(NGFileManagerProcessingTool *)_tool
  processLinkPath:(NSString *)_linkPath;

#if 0
// hh: why is this commented out? - eg it is required by 
//     NGFileManagerProcessingTool
- (NSException *)tool:(NGFileManagerProcessingTool *)_tool
  processFiles:(NSArray *)_files atPath:(NSString *)_path;
#endif

@end /* NSObject(NGFileManagerCopyToolHandler) */

#endif /* NGFileManagerCopyTool_h */
