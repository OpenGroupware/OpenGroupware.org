// $Id$

#ifndef __SkyProjectServer__Session_H__
#define __SkyProjectServer__Session_H__

#include <NGObjWeb/WOSession.h>

@class SkyProjectFileManager;

@interface Session : WOSession
{
  id                    commandContext;
  SkyProjectFileManager *fileManager;
  NSMutableDictionary   *fileManagerCache;
}
- (void)setCommandContext:(id)_ctx;
- (id)commandContext;

- (void)setFileManager:(SkyProjectFileManager *)_fm;
- (SkyProjectFileManager *)fileManager;

- (id)fileManagerForCode:(NSString *)_code;

@end

#endif /* __SkyProjectServer__Session_H__ */
