// $Id$

#ifndef __SkyUidHandler_H__
#define __SkyUidHandler_H__

#import <Foundation/NSObject.h>

@class NSString, NSFileManager;

@interface SkyUidHandler : NSObject
{
  NSString      *path;
  NSFileManager *fm;
}

- (id)init;
- (id)initWithPath:(NSString *)_path;
- (void)dealloc;
- (NSString *)nextUidFile;
- (NSString *)uidFile;
- (NSString *)objectId:(id)_obj;
- (int)uidForObject:(id)_obj;
- (int)nextUid;
- (int)uidForObjectId:(id)_id;

@end /* SkyUidHandler */


#endif /* __SkyUidHandler_H__ */
