// $Id$

#ifndef __SkyPrivatePersonExport_H__
#define __SkyPrivatePersonExport_H__

#include "SkyPersonExporter.h"

@class NSString, NSArray;

@interface SkyPrivatePersonExporter : SkyPersonExporter
{
  NSArray  *accounts;
  NSString *account;
}

- (id)initWithAccountsPath:(NSString *)_accountPath;

@end /* SkyPrivatePersonExporter */

#endif /* __SkyPrivatePersonExport_H__ */
