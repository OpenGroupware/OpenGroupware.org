#ifndef __SkyExporter_H__
#define __SkyExporter_H__

#import <Foundation/NSObject.h>

@class NSFileManager, NSString, NSMutableDictionary, NSDictionary;

@interface SkyExporter : NSObject
{
  NSFileManager       *fm;
  BOOL                writeSingleEntry;
  NSString            *path;
  NSMutableDictionary *entries;
}

/* create a file per entry (named unique_key.plist) */
- (BOOL)exportToPath:(NSString *)_path;

/* export all files in one dictionary with unique_key as key */
- (BOOL)exportToFile:(NSString *)_file;

- (BOOL)exportEntries;

- (BOOL)writeEntry:(NSDictionary *)_entry;

- (void)flush;
- (int)cacheSize;

/* subclasses */
- (id)primaryKeyForEntry:(NSDictionary *)_entry;

@end /* SkyExporter */

#endif /* __SkyExporter_H__ */
