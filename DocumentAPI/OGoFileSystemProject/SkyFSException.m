
#include "SkyFSFileManager.h"
#include "common.h"

@implementation SkyFSException

+ (id)reason:(NSString *)_reason {
  return [SkyFSException exceptionWithName:@"SkyFSException"
                         reason:_reason
                         userInfo:nil];
}

+ (id)reason:(NSString *)_reason userInfo:(NSDictionary *)_info {
  return [SkyFSException exceptionWithName:@"SkyFSException"
                         reason:_reason
                         userInfo:_info];
}

- (id)initWithReason:(NSString *)_reason
  userInfo:(NSDictionary *)_info
{
  return [self initWithName:@"SkyFSException" reason:_reason
               userInfo:_info];
}

@end /* SkyFSException : NSException */
