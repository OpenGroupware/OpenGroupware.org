// $Id$

#ifndef __SkyResourceImport_H__
#define __SkyResourceImport_H__

#include  "SkyImport.h"

@class NSString, NSArray, SkyGroupUidHandler;

@interface SkyResourceImport : SkyImport
{
  NSString *path;
  NSString *groupsPath;
}

- (id)initWithResourcesPath:(NSString *)_path groupsPath:(NSString *)_groups;

@end /* SkyResourceImport */

#endif /* __SkyResourceImport_H__ */
