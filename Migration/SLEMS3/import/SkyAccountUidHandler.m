
#include "common.h"
#include "SkyAccountUidHandler.h"

@implementation SkyAccountUidHandler

- (NSString *)uidFile {
  return [self->path stringByAppendingPathComponent:@"accounts.uid"];
}

- (NSString *)objectId:(id)_obj {
  return [_obj objectForKey:@"login"];
}

@end /* SkyAccountUidHandler */
