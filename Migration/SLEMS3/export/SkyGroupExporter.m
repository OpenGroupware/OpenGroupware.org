
#include "common.h"
#include "SkyGroupExporter.h"

@implementation SkyGroupExporter

- (NSString *)primaryKeyForEntry:(NSDictionary *)_entry {
  return [_entry objectForKey:@"cn"];
}

static NSDictionary *AttrMapping = nil;

- (NSDictionary *)attributeMapping {
  if (AttrMapping == nil) {
    AttrMapping = [[NSDictionary alloc]
                                 initWithObjectsAndKeys:
                                 @"description", @"cn",
                                 @"memberUid", @"memberUid",
                                 @"gidNumber", @"gidNumber",
                                 nil];
  }
  return AttrMapping;
}

static NSArray *GroupAttrs = nil;

- (NSArray *)fetchAttributes {
  if (GroupAttrs == nil) {
    GroupAttrs = [[NSArray alloc]
                             initWithObjects:
                             @"cn",
                             @"gidNumber",
                             @"givenName",
                             @"memberUid",
                             @"description",
                             nil];
  }
  return GroupAttrs;
}

- (BOOL)fetchDeep {
  return NO;
}

- (NSDictionary *)buildEntry:(NSDictionary *)_attrs {
  return _attrs;
}
/*
  objectclass=doof
*/
   
- (EOQualifier *)searchQualifier {
  return [EOQualifier qualifierWithQualifierFormat:@"objectclass=posixGroup"];
}


@end /* SkyGroupExporter */
