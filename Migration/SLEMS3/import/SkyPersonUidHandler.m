// $Id$

#include "common.h"
#include "SkyPersonUidHandler.h"

@implementation SkyPersonUidHandler

- (NSString *)uidFile {
  return [self->path stringByAppendingPathComponent:@"person.uid"];
}

- (NSString *)objectId:(id)_obj {
  return [_obj objectForKey:@"uid"];
}

@end /* SkyPersonUidHandler */
