// $Id$

#include "common.h"
#include "SkyJobUidHandler.h"

@implementation SkyJobUidHandler

- (NSString *)uidFile {
  return [self->path stringByAppendingPathComponent:@"person.uid"];
}

- (NSString *)objectId:(id)_obj {
  return [_obj objectForKey:@"uid"];
}

@end /* SkyJobUidHandler */
