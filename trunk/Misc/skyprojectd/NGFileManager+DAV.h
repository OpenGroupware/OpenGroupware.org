
#ifndef __SkyProjectServer__SkyProjectFileManager_WebDAV_H__
#define __SkyProjectServer__SkyProjectFileManager_WebDAV_H__

#include <NGExtensions/NGFileManager.h>

@interface NGFileManager(WebDAV)
- (BOOL)lockFileAtPath:(NSString *)_path timeout:(NSTimeInterval)_time;
@end

#endif /* __SkyProjectServer__SkyProjectFileManager+WebDAV_H__ */
