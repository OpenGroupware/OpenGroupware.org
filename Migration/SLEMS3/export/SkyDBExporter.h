
#ifndef __SkyDBExporter_H__
#define __SkyDBExporter_H__

#include "SkyExporter.h"

@class NSDictionary, NSString, EOAdaptorChannel;

@interface SkyDBExporter : SkyExporter
{
  NSDictionary     *dbConfig;
  NSString         *dbAdaptor;
  EOAdaptorChannel *adChannel;
  NSArray  *accounts;
  NSString *account;
}

- (NSString *)dbAdaptor;
- (NSArray *)extractIdsFromString:(NSString *)_str;
- (void)handleAttr:(NSMutableDictionary *)_attrs key:(NSString *)_key;

@end /* SkyDBExporter */

#endif /* __SkyDBExporter_H__ */
