
#include "common.h"
#include "SkyGroupImport.h"
#include "SkyGroupUidHandler.h"
#include <LSFoundation/LSFoundation.h>

@implementation SkyGroupImport

- (id)initWithGroupsPath:(NSString *)_path {
  if ((self = [super init])) {
    ASSIGN(self->path, _path);
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->path);
  [super dealloc];
}

- (NSArray *)objects {
  NSArray        *array;
  NSEnumerator   *enumerator;
  id             obj;
  NSMutableArray *result;

  array = [self->fm directoryContentsAtPath:self->path];
  result = [NSMutableArray arrayWithCapacity:[array count]];
  enumerator = [array objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    NSDictionary *dict;
    dict = [NSDictionary dictionaryWithContentsOfFile:
                         [path stringByAppendingPathComponent:obj]];
    [result addObject:dict];
  }
  return result;
}

- (Class)uidHandlerClass {
  return [SkyGroupUidHandler class];
}


- (BOOL)importObject:(id)_obj withId:(int)_id {
  id ctx;
  ctx = [self commandContext];

  if (![_obj isKindOfClass:[NSMutableDictionary class]]) {
    _obj = [[_obj mutableCopy] autorelease];
  }
  [_obj setObject:[NSNumber numberWithInt:_id] forKey:@"companyId"];
  
  [ctx runCommand:@"team::new" arguments:_obj];
  return YES;
}

@end /* SkyGroupImport */
