// $Id$

#ifndef __Projects_SxProjectFolder_H__
#define __Projects_SxProjectFolder_H__

#include <Frontend/SxFolder.h>

/*
  SxProjectFolder

    parent-folder: SxProjectsFolder
    subobjects:    SxDocumentFolder +...
*/

@class NSString, NSException;
@class EOGlobalID;

@interface SxProjectFolder : SxFolder
{
  EOGlobalID *projectGlobalID;
  id         fileManager;
}

/* project information */

- (NSString *)projectNameKey;
- (EOGlobalID *)projectGlobalIDInContext:(id)_ctx;
- (id)fileManagerInContext:(id)_ctx;

/* act as a common operation repository ... */

- (NSException *)moveObject:(id)_source toTarget:(id)_target
  newName:(NSString *)_name inContext:(id)_ctx;
- (NSException *)copyObject:(id)_source toTarget:(id)_target
  newName:(NSString *)_name inContext:(id)_ctx;

@end

#endif /* __Projects_SxProjectFolder_H__ */
