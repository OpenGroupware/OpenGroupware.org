
#ifndef __SkyAccountImport_H__
#define __SkyAccountImport_H__

#include  "SkyImport.h"

@class NSString, NSArray, SkyGroupUidHandler;

@interface SkyAccountImport : SkyImport
{
  NSString           *path;
  SkyGroupUidHandler *groupHandler;
}

- (id)initWithAccountsPath:(NSString *)_path;

@end /* SkyAccountImport */

#endif /* __SkyAccountImport_H__ */
