// $Id$

#ifndef __SkyAppImport_H__
#define __SkyAppImport_H__

#include  "SkyImport.h"

@class NSString, NSArray, SkyGroupUidHandler, SkyAccountUidHandler;

@interface SkyAppImport : SkyImport
{
  NSString             *path;
  NSString             *account;
  SkyGroupUidHandler   *groupHandler;
  SkyAccountUidHandler *accountHandler;
}

- (id)initWithAppsPath:(NSString *)_path;

@end /* SkyAppImport */

#endif /* __SkyAppImport_H__ */
