
#include "common.h"
#include "SkyResourceGroupExporter.h"

@implementation SkyResourceGroupExporter

static NSDictionary *AttrMapping = nil;

- (NSDictionary *)attributeMapping {
  if (AttrMapping == nil) {
    AttrMapping = [[NSDictionary alloc]
                               initWithObjectsAndKeys:
                               @"resourceGroupName",   @"resourceGroupName",
                               @"resourceGroupMember", @"resourceGroupMember",
                               nil];
  }
  return AttrMapping;
}

- (NSString *)primaryKeyForEntry:(NSDictionary *)_entry {
  return [_entry objectForKey:@"resourceGroupName"];
}


static NSArray *GroupAttrs = nil;

- (NSArray *)fetchAttributes {
  if (GroupAttrs == nil) {
    GroupAttrs = [[NSArray alloc]
                             initWithObjects:
                             @"resourceGroupName",
                             @"resourceGroupMember",
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
  return
    [EOQualifier qualifierWithQualifierFormat:
                 @"objectclass=SuSEResourceGroupObject"];
}

@end /* SkyResourceGroupExporter */
