// $Id$

#ifndef __SkyPersonImport_H__
#define __SkyPersonImport_H__

#include  "SkyImport.h"

@class NSString, NSArray, SkyGroupUidHandler;

@interface SkyPersonImport : SkyImport
{
  NSString           *path;
}

- (id)initWithPersonsPath:(NSString *)_path;

@end /* SkyPersonImport */

#endif /* __SkyPersonImport_H__ */
