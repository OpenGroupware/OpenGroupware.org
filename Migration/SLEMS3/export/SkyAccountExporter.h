// $Id$

#ifndef __SkyAccountExport_H__
#define __SkyAccountExport_H__

#include "SkyLDAPExporter.h"

@class NSString, NSDictionary;

@interface SkyAccountExporter : SkyLDAPExporter
{
  NSDictionary *accounts2Groups;
  NSDictionary *groups;
}

- (id)initWithGroupsPath:(NSString *)_path;

@end /* SkyAccountExporter */

#endif /* __SkyAccountExport_H__ */
