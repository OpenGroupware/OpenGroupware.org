// $Id$

#ifndef __Projects_SxDocumentFolder_H__
#define __Projects_SxDocumentFolder_H__

#include <Frontend/SxFolder.h>

/*
  SxDocumentFolder
    
    parent-folder: SxDocumentFolder || SxProjectFolder
    subobjects:    SxDocumentFolder || SxDocument
*/

@class NSString, NSDictionary;
@class EODataSource, EOGlobalID;
@class SxProjectFolder;

@interface SxDocumentFolder : SxFolder
{
  NSString     *projectPath;
  EODataSource *folderDataSource;
  NSDictionary *attrCache;
}

/* folder navigation */

- (BOOL)isProjectRootFolder;
- (NSString *)storagePath;

- (EOGlobalID *)projectGlobalIDInContext:(id)_ctx;
- (SxProjectFolder *)projectFolder;
- (id)fileManagerInContext:(id)_ctx;

- (EODataSource *)folderDataSourceInContext:(id)_ctx;

/* error handling */

- (id)internalError:(NSString *)_reason;

@end

#endif /* __Projects_SxDocumentFolder_H__ */
