// $Id$

#ifndef __SkyAppExport_H__
#define __SkyAppExport_H__

#include "SkyDBExporter.h"

@interface SkyAppExporter : SkyDBExporter
{
  NSCalendarDate *exportDate;
}

- (void)setExportDate:(NSCalendarDate *)_date;
@end /* SkyAppExporter */

#endif /* __SkyAppExport_H__ */
