// $Id$

#ifndef __Projects_SxDocument_H__
#define __Projects_SxDocument_H__

#include <Frontend/SxObject.h>

/*
  SxDocument
    
    parent-folder: SxDocumentFolder
*/

@class NSString, NSDictionary;
@class EOGlobalID;
@class SxProjectFolder;

@interface SxDocument : SxObject
{
  NSDictionary *attrCache;
}

- (id)initWithName:(NSString *)_key inContainer:(id)_folder;

/* accessors */

- (EOGlobalID *)projectGlobalIDInContext:(id)_ctx;
- (SxProjectFolder *)projectFolder;

- (id)fileManagerInContext:(id)_ctx;
- (id)fileManager;
- (NSString *)storagePath;

@end

#endif /* __Projects_SxDocument_H__ */
