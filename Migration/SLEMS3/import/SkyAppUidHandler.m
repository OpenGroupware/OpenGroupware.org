// $Id$

#include "common.h"
#include "SkyAppUidHandler.h"

@implementation SkyAppUidHandler

- (NSString *)uidFile {
  return [self->path stringByAppendingPathComponent:@"person.uid"];
}

- (NSString *)objectId:(id)_obj {
  return [_obj objectForKey:@"uid"];
}

@end /* SkyAppUidHandler */
