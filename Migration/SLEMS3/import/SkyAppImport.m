// $Id$

#include "common.h"
#include "SkyAppImport.h"
#include "SkyAppUidHandler.h"
#include "SkyGroupUidHandler.h"
#include "SkyAccountUidHandler.h"
#include <LSFoundation/LSFoundation.h>

@implementation SkyAppImport

- (id)initWithAppsPath:(NSString *)_path {
  if ((self = [super init])) {
    ASSIGN(self->path, _path);
    self->groupHandler   = [[SkyGroupUidHandler alloc] init];
    self->accountHandler = [[SkyAccountUidHandler alloc] init];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->path);
  RELEASE(self->groupHandler);
  RELEASE(self->accountHandler);
  [super dealloc];
}

- (NSArray *)objects {
  NSDictionary   *dict;
  NSMutableArray *array;
  NSEnumerator   *keyEnum;
  id             number;

  dict = [NSDictionary dictionaryWithContentsOfFile:
                       [self->path stringByAppendingPathComponent:
                            self->account]];

  array = [NSMutableArray arrayWithCapacity:[dict count]];

  keyEnum = [dict keyEnumerator];
  while ((number = [keyEnum nextObject])) {
    NSMutableDictionary *d;

    d = [[[dict objectForKey:number] mutableCopy] autorelease];

    [d setObject:number forKey:@"uid"];
    [array addObject:d];
  }
  return array;
}

- (Class)uidHandlerClass {
  return [SkyAppUidHandler class];
}

- (NSNumber *)ownerId {
  return [NSNumber numberWithInt:
                   [self->accountHandler uidForObjectId:
                        [self->account stringByDeletingPathExtension]]];
}

- (BOOL)importObject:(id)_obj withId:(int)_id {
  id ctx;
  
  if (![_obj isKindOfClass:[NSMutableDictionary class]]) {
    _obj = [[_obj mutableCopy] autorelease];
  }

  [_obj setObject:[NSNumber numberWithInt:_id] forKey:@"dateId"];
  [_obj setObject:[self ownerId] forKey:@"ownerId"];

  {
    id      access;
    NSArray *array;

    array = [_obj objectForKey:@"accessTeam_name"];

    if ([array count]) {
      int i;
      
      access = [array lastObject];

      if ((i = [self->groupHandler uidForObjectId:access])) {
        [_obj setObject:[NSNumber numberWithInt:i]
                                  forKey:@"accessTeamId"];
      }
      else {
        NSLog(@"%s: missing id for group %@", __PRETTY_FUNCTION__, access);
      }
    }
  }
  {
    id      access;
    NSArray *array;
    NSMutableArray *writeAccessList;

    writeAccessList = [NSMutableArray arrayWithCapacity:4];
    array           = [_obj arrayForKey:@"writeAccessGroups_name"];

    if ([array count]) {
      int i;
      
      NSEnumerator *idEnum;

      idEnum = [array objectEnumerator];

      while ((access = [idEnum nextObject])) {

        if ((i = [self->groupHandler uidForObjectId:access])) {
          [writeAccessList addObject:[NSNumber numberWithInt:i]];
        }
        else {
          NSLog(@"%s: missing id for group %@", __PRETTY_FUNCTION__, access);
        }
      }
    }
    array           = [_obj arrayForKey:@"writeAccessList_login"];

    if ([array count]) {
      int i;
      NSEnumerator *idEnum;

      idEnum = [array objectEnumerator];

      while ((access = [idEnum nextObject])) {

        if ((i = [self->accountHandler uidForObjectId:access])) {
          [writeAccessList addObject:[NSNumber numberWithInt:i]];
        }
        else {
          NSLog(@"%s: missing id for group %@", __PRETTY_FUNCTION__, access);
        }
      }
    }
    if ([writeAccessList count]) {
      [_obj setObject:[writeAccessList componentsJoinedByString:@","]
            forKey:@"writeAccessList"];
    }
  }
  {
    id      access;
    NSArray *array;
    NSMutableArray *list;

    list  = [NSMutableArray arrayWithCapacity:4];
    array = [_obj arrayForKey:@"participants_group_names"];

    if ([array count]) {
      int i;
      NSEnumerator *idEnum;

      idEnum = [array objectEnumerator];

      while ((access = [idEnum nextObject])) {

        if ((i = [self->groupHandler uidForObjectId:access])) {
          [list addObject:
                [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:i], @"companyId", nil]];
        }
        else {
          NSLog(@"%s: missing id for group %@", __PRETTY_FUNCTION__, access);
        }
      }
    }
    array = [_obj arrayForKey:@"participants_login"];

    if ([array count]) {
      int i;
      NSEnumerator *idEnum;

      idEnum = [array objectEnumerator];

      while ((access = [idEnum nextObject])) {

        if ((i = [self->accountHandler uidForObjectId:access])) {
          [list addObject:
                [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:i], @"companyId", nil]];
        }
        else {
          NSLog(@"%s: missing id for group %@", __PRETTY_FUNCTION__, access);
        }
      }
    }
    if ([list count]) {
      [_obj setObject:list forKey:@"participants"];
    }
  }
  {
    NSArray *array;

    array = [_obj objectForKey:@"resources_names"];
    if ([array count]) {
      [_obj setObject:[array componentsJoinedByString:@", "]
            forKey:@"resourceNames"];
    }
  }

  ctx = [self commandContext];

  [_obj setObject:[NSNumber numberWithBool:YES]
        forKey:@"isWarningIgnored"];

  [ctx runCommand:@"appointment::new" arguments:_obj];
  
  return YES;
}


- (BOOL)import {
  NSArray        *array;
  NSEnumerator   *enumerator;
  id             obj;

  array = [self->fm directoryContentsAtPath:self->path];
  enumerator = [array objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    ASSIGN(self->account, obj);
    if (![super import])
      return NO;
  }
  return YES;

}


@end /* SkyAppImport */
