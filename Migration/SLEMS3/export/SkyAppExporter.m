// $Id$

#include "common.h"
#include "SkyAppExporter.h"

@implementation SkyAppExporter

- (void)dealloc {
  RELEASE(self->exportDate);
  [super dealloc];
}


static NSDictionary *AttrMapping = nil;

- (NSDictionary *)attributeMapping {
  if (AttrMapping == nil) {
    AttrMapping = [[NSDictionary alloc]
                                 initWithObjectsAndKeys:
                                 @"startDate",               @"startDate",
                                 @"endDate",                 @"endDate",
                                 @"comment",                 @"comment",
                                 @"title",                   @"title",
                                 @"owner_login",             @"owner",
                                 @"location",                @"location",
                                 @"participants_login",      @"participants",
                                 @"participants_group_names",@"groups",
                                 @"resources_names",         @"resourceNames",
                                 @"accessTeam_name",         @"readAccessGroup",
                                 @"writeAcessList_login",    @"writeAccessAccounts",
                                 @"writeAccessGroups_name",  @"writeAccessGroups",
                                 nil];
  }
  return AttrMapping;
}

- (NSString *)primaryKeyForEntry:(NSDictionary *)_entry {
  return [_entry objectForKey:@"dateId"];
}

- (NSDictionary *)buildEntry:(NSDictionary *)_attrs {
  NSMutableDictionary *attrs;

  attrs = [_attrs mutableCopy];

  [self handleAttr:attrs key:@"participants"];
  [self handleAttr:attrs key:@"readAccessGroup"];
  [self handleAttr:attrs key:@"groups"];
  [self handleAttr:attrs key:@"resourceNames"];
  [self handleAttr:attrs key:@"writeAccessAccounts"];
  [self handleAttr:attrs key:@"writeAccessGroups"];

  {
    NSArray      *array;

    array = [attrs objectForKey:@"resourceNames"];

    if ([array count]) {
      NSString       *name;
      NSEnumerator   *enumerator;
      NSMutableArray *res;

      res        = [NSMutableArray array];
      enumerator = [array objectEnumerator];

      while ((name = [enumerator nextObject])) {
        NSDictionary *dict;
        NSString     *p;
        NSString     *rn;

        rn   = nil;
        p    = [[@"resources" stringByAppendingPathComponent:name]
                              stringByAppendingPathExtension:@"plist"];
        if ([self->fm fileExistsAtPath:path]) {
          dict = [NSDictionary dictionaryWithContentsOfFile:p];

          if (dict) {
            rn = [dict objectForKey:@"resourceName"];
          }
        }
        if (![rn length])
          rn = name;

        [res addObject:rn];
      }
      [attrs setObject:res forKey:@"resourceNames"];
    }
  }
  return attrs;
}
/*
  objectclass=doof
*/
- (NSString *)searchExpression {
  NSString *str;
  static EOAttribute *DateAttr = nil;

  if (DateAttr == nil) {
    DateAttr = [[EOAttribute alloc] init];
    [DateAttr setServerTimeZone:[NSTimeZone defaultTimeZone]];
  }
  
  if (self->exportDate) {
    str = [NSString stringWithFormat:
                   @"select * from skymail_date where owner='%@' AND start_date > %@",
                    self->account,
                    [[EOAdaptor adaptorWithName:[self dbAdaptor]]
                                formatValue:self->exportDate
                                forAttribute:DateAttr]];
  }
  else {
    str = [NSString stringWithFormat:
                   @"select * from skymail_date where owner='%@'",
                   self->account];
  }
  return str;
}

- (void)setExportDate:(NSCalendarDate *)_date {
  ASSIGN(self->exportDate, _date);
}

- (NSCalendarDate *)exportDate {
  return self->exportDate;
}
@end /* SkyAppExporter */
