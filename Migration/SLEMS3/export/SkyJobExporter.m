// $Id$

#include "common.h"
#include "SkyJobExporter.h"

@implementation SkyJobExporter

- (id)initWithAccountsPath:(NSString *)_accountPath {
  if ((self = [super init])) {
    self->accounts = [[self->fm directoryContentsAtPath:_accountPath] retain];
  }
  return self;
}

static NSDictionary *AttrMapping = nil;

- (NSDictionary *)attributeMapping {
  if (AttrMapping == nil) {
    AttrMapping = [[NSDictionary alloc]
                                 initWithObjectsAndKeys:
                                 @"startDate",   @"resubmissionDate",
                                 @"endDate",     @"endDate",
                                 @"category",    @"category",
                                 @"description", @"notice",
                                 @"owner_login", @"owner",
                                 @"priority",    @"priority",
                                 @"name",        @"todoTitle",
                                 @"done",        @"done",
                                 nil];
  }
  return AttrMapping;
}

- (NSString *)primaryKeyForEntry:(NSDictionary *)_entry {
  return [_entry objectForKey:@"todoId"];
}

- (NSDictionary *)buildEntry:(NSDictionary *)_attrs {
  NSMutableDictionary *attrs;

  attrs = [_attrs mutableCopy];

  [self handleAttr:attrs key:@"owner"];

  return [attrs autorelease];
}
/*
  objectclass=doof
*/
- (NSString *)searchExpression {
  return [NSString stringWithFormat:
                   @"select * from skymail_todo where owner like 'uid=%@,%@'",
                   self->account, @"%"];
}



@end /* SkyJobExporter */
