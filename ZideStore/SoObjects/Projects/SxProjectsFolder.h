// $Id: SxProjectsFolder.h 1 2004-08-20 11:17:52Z znek $

#ifndef __Projects_SxProjectsFolder_H__
#define __Projects_SxProjectsFolder_H__

#include <Frontend/SxFolder.h>

/*
  SxProjectsFolder
    
    parent-folder: *
    subobjects:    SxProjectFolder
*/

@class NSArray;
@class EODataSource;

@interface SxProjectsFolder : SxFolder
{
  NSArray *projectNames;
}

- (EODataSource *)rawContentDataSourceInContext:(id)_ctx;

@end

#endif /* __Projects_SxProjectsFolder_H__ */
