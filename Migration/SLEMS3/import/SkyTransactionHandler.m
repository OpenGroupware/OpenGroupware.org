//$Id$

#include "common.h"
#include "SkyTransactionHandler.h"

@implementation SkyTransactionHandler

- (id)init {
  return [self initWithPath:
               [[NSUserDefaults standardUserDefaults]
                                stringForKey:@"SkyImportUidPath"]];
}

- (id)initWithPath:(NSString *)_path {
  if (![_path length]) {
    _path = @".";
  }
  if ((self = [super init])) {
    ASSIGN(self->path, _path);
    self->fm = [[NSFileManager defaultManager] retain];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->path);
  RELEASE(self->fm);
  [super dealloc];
}

- (NSString *)commitFile {
  return [self->path stringByAppendingPathComponent:@"commit.log"];
}

- (NSString *)transactionFile {
  return [self->path stringByAppendingPathComponent:@"transaction.log"];
}

- (BOOL)isObjectInserted:(int)_objId {
  NSArray *array;
  array = [NSArray arrayWithContentsOfFile:[self commitFile]];

  {
    unsigned int i, n;
    n = [array count];
    for (i = 0; i < n; i++) {
      id obj = [array objectAtIndex:i];
      if ([obj intValue] == _objId) {
        return YES;
      }
    }
  }
  return NO;
}

- (void)beginInsert:(int)_objId {
  NSMutableArray *array;

  array = [NSMutableArray arrayWithContentsOfFile:[self transactionFile]];
  if (!array)
    array = [NSMutableArray arrayWithCapacity:2];
  
  [array addObject:[NSNumber numberWithInt:_objId]];
  [array writeToFile:[self transactionFile] atomically:YES];
}

- (void)commitInsert:(int)_objId {
  NSMutableArray *array;

  array = [NSMutableArray arrayWithContentsOfFile:[self commitFile]];
  if (!array)
    array = [NSMutableArray arrayWithCapacity:2];
  
  [array addObject:[NSNumber numberWithInt:_objId]];
  if ([array writeToFile:[self commitFile] atomically:YES]) {

    array = [NSMutableArray arrayWithContentsOfFile:[self transactionFile]];

    {
      unsigned int i, n;
      n = [array count];
      for (i = 0; i < n; i++) {
	id obj = [array objectAtIndex:i];

	if ([obj intValue] == _objId) {
          [array removeObjectAtIndex:i];
          n--; i--;
	}
      }
    }

    [array writeToFile:[self transactionFile] atomically:YES];
  }
}

- (void)rollbackIds {
  [self->fm removeFileAtPath:[self transactionFile] handler:nil];
}

- (NSArray *)failedIds {
  return [NSArray arrayWithContentsOfFile:[self transactionFile]];
}

@end /* SkyTransactionHandler */
