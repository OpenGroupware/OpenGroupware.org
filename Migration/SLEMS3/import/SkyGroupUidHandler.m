
#include "common.h"
#include "SkyGroupUidHandler.h"

@implementation SkyGroupUidHandler

- (NSString *)uidFile {
  return [self->path stringByAppendingPathComponent:@"groups.uid"];
}

- (NSString *)objectId:(id)_obj {
  return [_obj objectForKey:@"description"];
}

@end
