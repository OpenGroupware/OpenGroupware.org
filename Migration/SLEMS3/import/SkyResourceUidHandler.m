// $Id$

#include "common.h"
#include "SkyResourceUidHandler.h"

@implementation SkyResourceUidHandler

- (NSString *)uidFile {
  return [self->path stringByAppendingPathComponent:@"resources.uid"];
}

- (NSString *)objectId:(id)_obj {
  return [_obj objectForKey:@"name"];
}

@end /* SkyResourceUidHandler */
