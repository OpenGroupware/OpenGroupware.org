// $Id$

#include "SkyImport.h"
#include "SkyTransactionHandler.h"
#include "SkyUidHandler.h"
#include <LSFoundation/LSFoundation.h>
#include <LSFoundation/LSCommandKeys.h>
#include "common.h"

#include <sys/types.h>
#include <unistd.h>
#include <sys/wait.h>

@implementation NSDictionary(SkyImport)
- (NSArray *)arrayForKey:(id)_key {
  static Class NSArrayClass = nil;
  id obj;

  if (!NSArrayClass) {
    NSArrayClass = [NSArray class];
  }
  
  if ((obj = [self objectForKey:_key])) {
    if (![obj isKindOfClass:NSArrayClass])
        obj = [NSArray arrayWithObject:obj];
  }
  return obj;
}

@end /* NSDictionary(SkyImport) */

@implementation SkyImport

- (id)init {
  NSUserDefaults *ud;
    
  ud = [NSUserDefaults standardUserDefaults];

  return [self initWithLogin:[ud stringForKey:@"SkyImportLogin"]
               pwd:[ud stringForKey:@"SkyImportPwd"]];
}

- (id)initWithLogin:(NSString *)_login pwd:(NSString *)_pwd {
  if ((self = [super init])) {
    ASSIGN(self->login, _login);
    ASSIGN(self->pwd, _pwd);
    self->isChild = NO;
    self->fm = [[NSFileManager defaultManager] retain];
    self->transactionHandler = [[SkyTransactionHandler alloc] init];
    self->uidHandler         = [[[self uidHandlerClass] alloc] init];
    
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->commandContext);
  RELEASE(self->login);
  RELEASE(self->pwd);
  RELEASE(self->fm);
  RELEASE(self->transactionHandler);
  RELEASE(self->uidHandler);
  [super dealloc];
}

- (id)commandContext {
  if (self->isChild == NO) {
    NSLog(@"ERROR[%s] commandContext should only be called during "
          @"child-processes", __PRETTY_FUNCTION__);
    return nil;
  }
  if (self->commandContext)
    return self->commandContext;
  
  self->commandContext = [[LSCommandContext alloc] 
                           initWithManager:[OGoContextManager defaultManager]];
  if (![self->commandContext login:self->login password:self->pwd]) {
    NSLog(@"ERROR[%s]: couldn`t login for user %@",
          __PRETTY_FUNCTION__, self->login);
    [self->commandContext release]; self->commandContext = nil;
    return nil;
  }
    
  if ([[[self->commandContext valueForKey:LSAccountKey]
                              valueForKey:@"companyId"] intValue] != 10000) {
    NSLog(@"ERROR[%s] only root is allowed to import objects, got %@",
          __PRETTY_FUNCTION__, [self->commandContext valueForKey:
                                      LSAccountKey]);
    [self->commandContext release]; self->commandContext = nil;
    return nil;
  }
  return self->commandContext;
}

- (Class)uidHandlerClass {
  return [self subclassResponsibility:_cmd];
}


- (NSArray *)objects {
  return [self subclassResponsibility:_cmd];
}

static int InsertObjectInterval = -1;

- (int)insertObjectInterval {
  if (InsertObjectInterval == -1) {
    InsertObjectInterval = [[NSUserDefaults standardUserDefaults]
                                            integerForKey:
                                            @"SkyImportObjectInterval"];
    if (InsertObjectInterval == 0)
      InsertObjectInterval = 20;
  }
  return InsertObjectInterval;
}

- (BOOL)importObject:(id)_obj withId:(int)_id {
  [self subclassResponsibility:_cmd];
  return NO;
}

- (int)verifyObject:(id)_obj {
  return 0;
}

- (BOOL)handleObjectImport:(id)_obj {
  int objId;

  if (!(objId = [self verifyObject:_obj])) {
    objId = [self->uidHandler uidForObject:_obj];
  }
  else {
    [self->uidHandler writeUid:objId forObject:
         [self->uidHandler objectId:_obj]];
    return YES;
  }

  if ([self->transactionHandler isObjectInserted:objId]) {
    return YES;
  }

  [self->transactionHandler beginInsert:objId];
  
  if (![self importObject:_obj withId:objId]) { /* store id */
    return NO;
  }
  [self->transactionHandler commitInsert:objId];

  return YES;
}

- (BOOL)handleObjectIntervalImport:(NSArray *)_objs {
  NSEnumerator *enumerator;
  id           obj;

  enumerator = [_objs objectEnumerator];
  
  while ((obj = [enumerator nextObject])) {
    if (![self handleObjectImport:obj])
      return NO;
  }
  return YES;
}

- (void)checkTransaction {
  NSArray *array;
  
  if ([(array = [self->transactionHandler failedIds]) count]) {
    NSEnumerator  *enumerator;
    id            number;
    id            tm;
    BOOL          failed;

    failed     = NO;
    tm         = [[self commandContext] typeManager];
    enumerator = [array objectEnumerator];
    while ((number = [enumerator nextObject])) {
      EOGlobalID *gid;

      if ((gid = [tm globalIDForPrimaryKey:number])) {
        id obj;

        NSLog(@"%s: got gid for not completly inserted object %@",
              __PRETTY_FUNCTION__, gid);
        obj = [[self commandContext]
                     runCommand:@"object::get-by-globalid"
                     arguments:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSArray arrayWithObject:gid], @"gids",
                                        nil]];
        NSLog(@"please remove this object from the database %@",
              obj);
        failed = YES;
      }
    }
    if (failed)
      exit(1);

    [self->transactionHandler rollbackIds];
  }
}

- (BOOL)importObjects:(NSArray *)_objs {
  pid_t pid;

  pid = fork();

  if (pid == -1) { /* error */
    NSLog(@"ERROR[%s]: fork failed with %d ", __PRETTY_FUNCTION__, pid);
    return NO;
  }
  else  if (pid == 0) { /* child */
    self->isChild = YES;

    if ([self commandContext] == nil) {
      NSLog(@"ERROR[%s] couldn`t login ", __PRETTY_FUNCTION__);
      exit(3);
    }
    [self checkTransaction];
    
    if (![self handleObjectIntervalImport:_objs]) {
      NSLog(@"%s: handleObjectImport returns NO", __PRETTY_FUNCTION__);
      [self->commandContext rollback];
      exit(1);
    }
    if ([[self->commandContext valueForKey:LSDatabaseContextKey]
                               transactionNestingLevel] > 0) {
      if (![self->commandContext commit]) {
        NSLog(@"%s: couldn`t commit ", __PRETTY_FUNCTION__);
        exit(2);
      }
    }
    exit(0);
  }
  else { /* parent */
    int status;
    
    if (wait(&status) == pid) {
      if (status == 0)
        return YES;
      else {
        NSLog(@"ERROR[%s] client returned with status %d",
              __PRETTY_FUNCTION__, status);
        return NO;
      }
    }
    else {
      NSLog(@"ERROR[%s] unexpected returned child ", __PRETTY_FUNCTION__);
      return NO;
    }
  }
  return YES;
}

- (BOOL)import {
  NSArray *array;
  int     interval, cnt, objCnt;

  array    = [self objects];
  cnt      = 0;
  objCnt   = [array count];
  interval = [self insertObjectInterval];

  for (cnt=0; cnt < objCnt; cnt+=interval) {
    NSArray *range;

    range = [array subarrayWithRange:
                   NSMakeRange(cnt,
                               (interval<objCnt-cnt)?interval:objCnt-cnt)];
    if (![self importObjects:range]) {
      NSLog(@"ERROR[%s] import failed for objects %@",
            __PRETTY_FUNCTION__, range);
      return NO;
    }
  }
  return YES;
}

@end /* SkyImport */
