
#include "common.h"
#include "SkyUidHandler.h"

@implementation SkyUidHandler
	
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

- (NSString *)nextUidFile {
  return [self->path stringByAppendingPathComponent:@"SkyImportUid.txt"];
}

- (NSString *)uidFile {
  return [self subclassResponsibility:_cmd];
}

- (NSString *)objectId:(id)_obj {
  return [self subclassResponsibility:_cmd];
}

- (void)writeUid:(int)_uid forObject:(id)_objId {
  id           uid;
  NSMutableDictionary *d;

  d  = [[NSDictionary dictionaryWithContentsOfFile:[self uidFile]] mutableCopy];

  if (!d)
    d = [[NSMutableDictionary alloc] initWithCapacity:2];
    
  uid = [NSNumber numberWithInt:_uid];
  [d setObject:uid forKey:_objId];

  if (![d writeToFile:[self uidFile] atomically:YES]) {
    NSLog(@"%s: couldn`t write uid-file %@", __PRETTY_FUNCTION__,
          [self uidFile]);
    abort();
  }
  [d release]; d = nil;
}

- (int)uidForObjectId:(id)_id {
  NSDictionary *uids;
  id           uid;
  id           objId;

  NSLog(@"[self uidFile] <%@> objId <%@>", [self uidFile], _id);
  
  uids  = [NSDictionary dictionaryWithContentsOfFile:[self uidFile]];
  objId = _id;
    
  if (!(uid = [uids objectForKey:objId])) {
    int i;

    i = [self nextUid];
    
    [self writeUid:i forObject:_id];
    return i;
  }
  return [uid intValue];
}


- (int)uidForObject:(id)_obj {
  return [self uidForObjectId:[self objectId:_obj]];
}

- (int)nextUid {
  int uidCnt;
  
  if ([self->fm fileExistsAtPath:[self nextUidFile] isDirectory:NULL]) {
    uidCnt = [[NSString stringWithContentsOfFile:[self nextUidFile]]
                              intValue];
  }
  else {
    uidCnt = [[NSUserDefaults standardUserDefaults]
                              integerForKey:@"SkyImportUidStart"];
    if (uidCnt == 0) {
      uidCnt = 60200;
    }
  }
  uidCnt += 2;

  if (![[NSString stringWithFormat:@"%d", uidCnt]
                  writeToFile:[self nextUidFile]
                  atomically:YES]) {
    NSLog(@"%s: couldn`t write uid file %@", __PRETTY_FUNCTION__,
          [self nextUidFile]);
    abort();
  }
  return uidCnt;
}



@end /* SkyUidHandler */
