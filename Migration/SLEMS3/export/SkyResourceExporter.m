// $Id$

#include "common.h"
#include "SkyResourceExporter.h"

@implementation SkyResourceExporter

static NSDictionary *AttrMapping = nil;

- (NSDictionary *)attributeMapping {
  if (AttrMapping == nil) {
    AttrMapping = [[NSDictionary alloc]
                               initWithObjectsAndKeys:
                               @"resourceName",   @"resourceName",
                               nil];
  }
  return AttrMapping;
}

- (NSString *)primaryKeyForEntry:(NSDictionary *)_entry {
  return [[_entry objectForKey:@"resourceName"] lowercaseString];
}


static NSArray *GroupAttrs = nil;

- (NSArray *)fetchAttributes {
  if (GroupAttrs == nil) {
    GroupAttrs = [[NSArray alloc]
                             initWithObjects:
                             @"resourceName",
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
                 @"objectclass=SuSEResourceObject"];
}

@end /* SkyResourceExporter */
