// $Id$

#include "Session.h"
#include "common.h"

@implementation Session

- (id)init {
  if ((self = [super init])) {
    [[self application] refuseNewSessions:YES];
  }
  return self;
}

- (void)dealloc {
  [self->commandContext   release];
  [self->fileManager      release];
  [self->fileManagerCache release];
  [super dealloc];
}

/* accessors */

- (void)setCommandContext:(id)_ctx {
  ASSIGN(self->commandContext, _ctx);
}
- (id)commandContext {
  return self->commandContext;
}

- (Class)fileManagerClass {
  return NSClassFromString(@"SkyProjectFileManager");
}
- (Class)dataSourceClass {
  return NSClassFromString(@"SkyProjectDataSource");
}

- (void)setFileManager:(id)_fm {
  ASSIGN(self->fileManager, _fm);
}

- (EOFetchSpecification *)fetchSpecForProjectWithNumber:(id)_pid {
  static NSDictionary  *hints = nil;
  EOQualifier          *qualifier;
  EOFetchSpecification *fspec;
  
  if (hints == nil) {
    hints = [[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                           forKey:@"SearchAllProjects"] copy];
  }

  qualifier = [EOQualifier qualifierWithQualifierFormat:@"number=%@", _pid];
  fspec = [[EOFetchSpecification alloc] initWithEntityName:nil
                                        qualifier:qualifier
                                        sortOrderings:nil
                                        usesDistinct:YES];
  [fspec setHints:hints];
  return [fspec autorelease];
}

- (id)fileManagerForCode:(NSString *)_code {
  EOGlobalID *gid       = nil;
  id         pds        = nil;
  id         project    = nil;
  NSArray    *projects  = nil;
  NSString   *pid       = nil;
  id fm;
  
  if (self->fileManagerCache == nil)
    self->fileManagerCache = [[NSMutableDictionary alloc] initWithCapacity:64];
  
  if ((fm = [self->fileManagerCache objectForKey:_code]))
    return fm;

  if (self->commandContext == nil) {
    NSLog(@"ERROR[%@] missing commandContext, return nil", self);
    return nil;
  }

  pid = _code;
  if (pid == nil || [pid length] == 0) {
    NSLog(@"missing project number !");
    return nil;
  }

  /* create datasource for searching projects */
  
  pds = [[[self dataSourceClass] alloc] initWithContext:self->commandContext];
  
  [pds setFetchSpecification:[self fetchSpecForProjectWithNumber:pid]];
  projects = [pds fetchObjects];
  
  if ([projects count] == 0) {
    NSLog(@"ERROR[%s] missing project", __PRETTY_FUNCTION__);
    return nil;
  }
  if ([projects count] > 1) {
    NSLog(@"WARNING[%s] more than one project for given number (%i) !", 
          __PRETTY_FUNCTION__, [projects count]);
  }
  
  project = [projects objectAtIndex:0];
  [pds release]; pds = nil;
  
  if ((gid = [project valueForKey:@"globalID"]) == nil) {
    NSLog(@"ERROR[%s] missing gid", __PRETTY_FUNCTION__);
    return nil;
  }
    
  fm = [[[self fileManagerClass] alloc] 
         initWithContext:self->commandContext
         projectGlobalID:gid];
  [self->fileManagerCache setObject:fm forKey:_code];

  return [fm autorelease];
}

- (id)fileManager {
  NSString *pid;
  
  if (self->fileManager)
    return self->fileManager;
    
  if (self->commandContext == nil) {
    [self logWithFormat:@"ERROR: missing commandContext."];
    return nil;
  }
  
  pid = [[NSUserDefaults standardUserDefaults] stringForKey:@"project"];
  if ([pid length] == 0) {
    [self logWithFormat:@"missing number of project to host !"];
    return nil;
  }
  
  self->fileManager = [[self fileManagerForCode:pid] retain];
  return self->fileManager;
}

- (void)sleep {
  if ([self->commandContext isTransactionInProgress])
    [self->commandContext commit];
  [super sleep];
  
  [[NSNotificationCenter defaultCenter]
                         postNotificationName:@"LSWSessionSleep"
                         object:nil];
  
}

- (void)awake {
  [[NSNotificationCenter defaultCenter]
                         postNotificationName:@"LSWSessionAwake"
                         object:nil];
  [super awake];
}

@end /* Session */
