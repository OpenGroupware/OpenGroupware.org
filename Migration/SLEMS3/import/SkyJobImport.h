
#ifndef __SkyJobImport_H__
#define __SkyJobImport_H__

#include  "SkyImport.h"

@class NSString, NSArray, SkyAccountUidHandler;

@interface SkyJobImport : SkyImport
{
  NSString             *path;
  NSString             *account;
  SkyAccountUidHandler *accountHandler;
}

- (id)initWithJobsPath:(NSString *)_path;

@end /* SkyJobImport */

#endif /* __SkyJobImport_H__ */
