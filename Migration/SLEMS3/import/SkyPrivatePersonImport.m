
#include "common.h"
#include "SkyPrivatePersonImport.h"
#include "SkyPersonUidHandler.h"
#include "SkyAccountUidHandler.h"
#include <LSFoundation/LSFoundation.h>

@implementation SkyPrivatePersonImport

- (id)initWithPersonsPath:(NSString *)_path {
  if ((self = [super initWithPersonsPath:_path])) {
    self->accountHandler = [[SkyAccountUidHandler alloc] init];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->account);
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

- (NSNumber *)ownerId {
  return [NSNumber numberWithInt:
                   [self->accountHandler uidForObjectId:
                        [self->account stringByDeletingPathExtension]]];
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


@end /* SkyPrivatePersonImport */
