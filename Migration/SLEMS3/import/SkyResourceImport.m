// $Id$

#include "common.h"
#include "SkyResourceImport.h"
#include "SkyResourceUidHandler.h"
#include "SkyGroupUidHandler.h"
#include <LSFoundation/LSFoundation.h>

@implementation SkyResourceImport

- (id)initWithResourcesPath:(NSString *)_path
  groupsPath:(NSString *)_groups
{
  if ((self = [super init])) {
    ASSIGN(self->path, _path);
    ASSIGN(self->groupsPath, _groups);
  }
  return self;
}

- (void)dealloc {
  [self->path       release];
  [self->groupsPath release];
  [super dealloc];
}

- (NSArray *)objects {
  NSArray        *array;
  NSEnumerator   *enumerator;
  id             obj;
  NSMutableArray *result, *insNames;

  array    = [self->fm directoryContentsAtPath:self->groupsPath];
  result   = [NSMutableArray arrayWithCapacity:[array count]];
  insNames = [NSMutableArray arrayWithCapacity:64];
  
  enumerator = [array objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    NSEnumerator *keyEnum;
    NSDictionary *dict;
    NSString     *grName;
    id           o;

    dict = [NSDictionary dictionaryWithContentsOfFile:
                         [self->groupsPath stringByAppendingPathComponent:obj]];

    grName  = [dict objectForKey:@"resourceGroupName"];
    keyEnum = [[dict arrayForKey:@"resourceGroupMember"] objectEnumerator];

    while ((o = [keyEnum nextObject])) {
      [insNames addObject:o];
      o = [NSDictionary dictionaryWithObjectsAndKeys:
                        o, @"name",
                        grName, @"category", nil];
      [result addObject:o];
    }
  }
  
  array    = [self->fm directoryContentsAtPath:self->path];
  enumerator = [array objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    NSDictionary *dict;
    NSString     *name;

    dict = [NSDictionary dictionaryWithContentsOfFile:
                         [self->path stringByAppendingPathComponent:obj]];

    if ((name  = [dict objectForKey:@"resourceName"])) {
      if ([insNames containsObject:name])
        continue;

      [result addObject:[NSDictionary dictionaryWithObject:name
                                      forKey:@"name"]];
    }
  }
  return result;
}

- (Class)uidHandlerClass {
  return [SkyResourceUidHandler class];
}


- (BOOL)importObject:(id)_obj withId:(int)_id {
  id ctx;

  ctx = [self commandContext];

  if (![_obj isKindOfClass:[NSMutableDictionary class]]) {
    _obj = [[_obj mutableCopy] autorelease];
  }
  [_obj setObject:[NSNumber numberWithInt:_id]
        forKey:@"appointment_resource_id"];

  NS_DURING {
    [ctx runCommand:@"appointmentresource::new" arguments:_obj];
  }
  NS_HANDLER {
    printf("importObject %s failed with %s\n",
           [[_obj description] cString],
           [[localException description] cString]);
  }
  NS_ENDHANDLER;

  return YES;
}

@end /* SkyResourceImport */
