// $Id$

#include "common.h"
#include "SkyJobImport.h"
#include "SkyJobUidHandler.h"
#include "SkyGroupUidHandler.h"
#include "SkyAccountUidHandler.h"
#include <LSFoundation/LSFoundation.h>

@implementation SkyJobImport

- (id)initWithJobsPath:(NSString *)_path {
  if ((self = [super init])) {
    ASSIGN(self->path, _path);
    self->accountHandler = [[SkyAccountUidHandler alloc] init];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->path);
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
  return [SkyJobUidHandler class];
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

  [_obj setObject:[NSNumber numberWithInt:_id] forKey:@"jobId"];
  [_obj setObject:[self ownerId] forKey:@"executantId"];
  [_obj setObject:[self ownerId] forKey:@"creatorId"];

  if (![_obj objectForKey:@"name"])
    [_obj setObject:@"<imported>" forKey:@"name"];

  [_obj setObject:@"imported" forKey:@"keywords"];
  
  if ([[_obj objectForKey:@"done"] boolValue]) {
    [_obj setObject:@"25_done" forKey:@"jobStatus"];
  }
  else {
    [_obj setObject:@"20_processing" forKey:@"jobStatus"];
  }

  ctx = [self commandContext];

  [ctx runCommand:@"job::new" arguments:_obj];
  
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


@end /* SkyJobImport */
