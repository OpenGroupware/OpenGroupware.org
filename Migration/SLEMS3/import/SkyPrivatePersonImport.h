// $Id$

#ifndef __SkyPrivatePersonImport_H__
#define __SkyPrivatePersonImport_H__

#include  "SkyPersonImport.h"

@class NSString, SkyAccountUidHandler;

@interface SkyPrivatePersonImport : SkyPersonImport
{
  NSString             *account;
  SkyAccountUidHandler *accountHandler;
}

@end /* SkyPrivatePersonImport */

#endif /* __SkyPrivatePersonImport_H__ */
