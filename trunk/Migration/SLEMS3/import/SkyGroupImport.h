
#ifndef __SkyGroupImport_H__
#define __SkyGroupImport_H__

#include  "SkyImport.h"

@class NSString, NSArray;

@interface SkyGroupImport : SkyImport
{
  NSString *path;
}

- (id)initWithGroupsPath:(NSString *)_path;

@end /* SkyGroupImport */

#endif /* __SkyGroupImport_H__ */
