
#include "common.h"
#include "SkyAccountExporter.h"

@implementation SkyAccountExporter

- (id)initWithGroupsPath:(NSString *)_path {
  if ((self = [super init])) {
    NSAutoreleasePool   *pool;
    NSEnumerator        *directoryContents;
    NSString            *fn;
    NSMutableDictionary *dict, *grps;

    dict  = [[NSMutableDictionary alloc] initWithCapacity:512];
    grps  = [[NSMutableDictionary alloc] initWithCapacity:64];

    directoryContents = [[self->fm directoryContentsAtPath:_path]
                                   objectEnumerator];
    
    while ((fn = [directoryContents nextObject])) {
      NSDictionary *group;

      pool  = [[NSAutoreleasePool alloc] init];
      group = [NSDictionary dictionaryWithContentsOfFile:
                            [_path stringByAppendingPathComponent:fn]];

      if (!group) {
        NSLog(@"%s: couldn`t initialize dictionary with file %@",
              __PRETTY_FUNCTION__, fn);
      }
      else {
        NSString     *groupName;
        id           member;
        NSEnumerator *enumerator;
        
        [grps  setObject:[group objectForKey:@"description"]
               forKey:[group objectForKey:@"gidNumber"]];
        groupName = [group objectForKey:@"description"];
        member    = [group objectForKey:@"memberUid"];

        if ([member isKindOfClass:[NSString class]]) {
          if ([member length]) {
            member = [NSArray arrayWithObject:member];
          }
          else {
            member = [NSArray array];
          }
        }
        enumerator = [member objectEnumerator];

        while ((member = [enumerator nextObject])) {
          NSMutableArray *marray;

          
          if (!(marray = [dict objectForKey:member])) {
            marray = [[NSMutableArray alloc] initWithCapacity:8];
            [dict setObject:marray forKey:member];
          }
          [marray addObject:groupName];
        }
      }
      RELEASE(pool);
    }
    self->accounts2Groups = [dict copy];
    self->groups          = [grps copy];
    RELEASE(dict); dict = nil;
    RELEASE(grps); grps = nil;
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->accounts2Groups);
  RELEASE(self->groups);
  [super dealloc];
}

static NSDictionary *AttrMapping = nil;

- (NSDictionary *)attributeMapping {
  if (AttrMapping == nil) {
    AttrMapping = [[NSDictionary alloc]
                                 initWithObjectsAndKeys:
                                 @"password",           @"userPassword",
                                 @"login",              @"uid",
                                 @"writeGlobalAddress", @"writeGlobalAddress",
                                 @"group_description",  @"groups",
                                 @"name",               @"sn",
                                 @"firstname",          @"givenName",
                                 @"dontCryptPassword",  @"dontCryptPassword",
                                 @"email1",             @"mail",
                                 nil];
  }
  return AttrMapping;
}

- (NSDictionary *)groups {
  return self->groups;
}

- (NSDictionary *)accounts2Groups {
  return self->accounts2Groups;
}

- (NSString *)primaryKeyForEntry:(NSDictionary *)_entry {
  return [_entry objectForKey:@"uid"];
}


static NSArray *AccountAttrs = nil;

- (NSArray *)fetchAttributes {
  if (AccountAttrs == nil) {
    AccountAttrs = [[NSArray alloc]
                             initWithObjects:
                             @"cn",
                             @"gidNumber",
                             @"givenName",
                             @"mail",
                             @"preferredLanguage",
                             @"sn",
                             @"uid",
                             @"uidNumber",
                             @"userPassword",
                             @"writeGlobalAddress",
                             nil];
  }
  return AccountAttrs;
}

- (BOOL)fetchDeep {
  return NO;
}

- (NSDictionary *)buildEntry:(NSDictionary *)_attrs {
  NSMutableDictionary *dict;
  NSMutableArray      *g;

  dict = [_attrs mutableCopy];

  g = [self->accounts2Groups objectForKey:[_attrs objectForKey:@"uid"]];

  if (!g) {
    g = [NSMutableArray arrayWithCapacity:1];
  }
  
  [g addObject:[self->groups objectForKey:
                         [_attrs objectForKey:@"gidNumber"]]];
  [dict setObject:g forKey:@"groups"];

  { /* password */
    NSString *pwd;

    pwd = [_attrs objectForKey:@"userPassword"];
    if ([pwd length]) {
      if ([pwd hasPrefix:@"{crypt}"]) {
        pwd = [pwd substringFromIndex:7];
      }
      else {
        NSString *l;

        l = @"";
        
        if ([pwd length] > 4)
          l = [pwd substringToIndex:4];
          
        NSLog(@"WARNING[%s]: found account password with unsupported crypt "
              @"method %@... (%@)", __PRETTY_FUNCTION__, l,
              [_attrs objectForKey:@"dn"]);
        pwd = @"";
      }
      [dict setObject:pwd forKey:@"userPassword"];
    }
  }
  
  [dict setObject:[NSNumber numberWithBool:YES] forKey:@"dontCryptPassword"];
  return [dict autorelease]; 
}
/*
  objectclass=doof
*/

- (EOQualifier *)searchQualifier {
  return [EOQualifier qualifierWithQualifierFormat:@"objectclass=posixAccount"];
}


@end /* SkyAccountExporter */
