/*
  Copyright (C) 2000-2005 SKYRIX Software AG

  This file is part of OpenGroupware.org.

  OGo is free software; you can redistribute it and/or modify it under
  the terms of the GNU Lesser General Public License as published by the
  Free Software Foundation; either version 2, or (at your option) any
  later version.

  OGo is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
  License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with OGo; see the file COPYING.  If not, write to the
  Free Software Foundation, 59 Temple Place - Suite 330, Boston, MA
  02111-1307, USA.
*/

#include <LSFoundation/LSCommandContext.h>
#include <LSFoundation/LSCommand.h>
#include <LSFoundation/LSBaseCommand.h>
#include <LSFoundation/LSTypeManager.h>
#include <LSFoundation/SkyAccessManager.h>
#include <LSFoundation/OGoContextManager.h>
#include <EOControl/EOControl.h>
#include "common.h"
#include <sys/time.h>
#include <unistd.h>

@interface NSObject(Misc)
- (id)initWithContext:(LSCommandContext *)_ctx;
@end

static id<LSCommand>
lookupCommand(LSCommandContext *self,
              NSString *_domain, NSString *_command,
              NSString *_arg1, va_list *va);

static inline id runCommand(LSCommandContext *self, id<LSCommand> _command);

static inline NSDate *now(void) {
  static Class NSDateClass = Nil;
  if (NSDateClass == Nil) NSDateClass = [NSDate class];
  return [NSDateClass date];
}

@interface LSCommandContext(PrivateMethods)
- (BOOL)_openChannel;
- (BOOL)handleException:(NSException *)_exception
  ofCommand:(id<LSCommand>)_command;
@end

static id openCtx = nil;

BOOL     ProfileCommands          = NO;
NSString *ProfileCommandsFileName = nil;

@interface LSCommandContext(TxPrivates)
- (BOOL)_beginTransaction;
- (BOOL)_isChannelOpen;
- (NSNotificationCenter *)notificationCenter;
@end

@implementation LSCommandContext

+ (int)version {
  return 2;
}

+ (void)initialize {
  NSUserDefaults *ns = [NSUserDefaults standardUserDefaults];
  static BOOL isInitialized = NO;
  if (isInitialized) return;
  isInitialized = YES;
  
  [ns registerDefaults:
        [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithInt:300], @"LSSessionChannelTimeOut",
                      nil]];
  ProfileCommands = [ns boolForKey:@"SkyCommandProfileEnabled"];
  if ((ProfileCommandsFileName =
       [ns stringForKey:@"SkyCommandProfileFilename"]) != nil) {
    FILE *f = NULL;
    if ((f = fopen([ProfileCommandsFileName cString], "a+")))
      fprintf(f, "\n############################### %d\n", getpid());
  }
}

+ (id)context {
  return [[[self alloc] init] autorelease];
}

- (NSNotificationCenter *)notificationCenter {
  static NSNotificationCenter *nc = nil;
  if (nc == nil)
    nc = [[NSNotificationCenter defaultCenter] retain];
  return nc;
}

- (id)_init {
  if ((self = [super init])) {
    NSNotificationCenter *nc;

    /* setup helper objects */
    
    self->typeManager = 
      [[NSClassFromString(@"LSTypeManager") alloc] initWithContext:self];
    
    self->objectPropertyManager =
      [[NSClassFromString(@"SkyObjectPropertyManager") alloc]
                                                       initWithContext:self];
    self->linkManager =
      [[NSClassFromString(@"OGoObjectLinkManager") alloc]
                                                   initWithContext:self];
    self->accessManager = [[SkyAccessManager alloc] initWithContext:self];
    
    if (self->typeManager == nil)
      [self logWithFormat:@"ERROR: LSTypeManager is missing!"];
    if (self->objectPropertyManager == nil)
      [self logWithFormat:@"ERROR: SkyObjectPropertyManager is missing!"];
    if (self->linkManager == nil)
      [self logWithFormat:@"ERROR: OGoObjectLinkManager is missing!"];
    if (self->accessManager == nil)
      [self logWithFormat:@"ERROR: SkyAccessManager is missing!"];

    /* ivars */
    
    self->extraVariables   = [[NSMutableDictionary alloc] initWithCapacity:32];
    self->wasLastCommandOk = YES;

    self->channelTimeOut =
      [[[NSUserDefaults standardUserDefaults]
                        objectForKey:@"LSSessionChannelTimeOut"]
                        doubleValue];
    
    nc = [self notificationCenter];
    
    [nc addObserver:self
        selector:@selector(_requireClassDescriptionForClass:)
        name:@"EOClassDescriptionNeededForClassNotification"
        object:nil];
    [nc addObserver:self
        selector:@selector(_requireClassDescriptionForEntityName:)
        name:@"EOClassDescriptionNeededForEntityNameNotification"
        object:nil];
  }
  return self;
}
- (id)init {
  return [self initWithManager:[OGoContextManager defaultManager]];
}

- (void)dealloc {
  if (self == openCtx)
    openCtx = nil;
  
  [[self notificationCenter] removeObserver:self];
  
  [self->channelCloseTimer invalidate];
  [(id)self->typeManager invalidate];
  
  if ([self isTransactionInProgress])
    [self rollback];
  if ([[self valueForKey:LSDatabaseChannelKey] isOpen])
    [[self valueForKey:LSDatabaseChannelKey] closeChannel];

  [self->typeManager           release];
  [self->objectPropertyManager release];
  [self->linkManager           release];
  [self->accessManager         release];
  [self->channelCloseTimer     release];
  [self->channelOpenTime       release];
  [self->txStartTime           release];
  [self->lastAccess            release];
  
  [self->extraVariables release];
  [self->commandFactory release];
  [super dealloc];
}

/* entity reflection */

- (void)_requireClassDescriptionForEntityName:(NSNotification *)_notification {
  EOClassDescription *d;
  EODatabase *db;
  NSString   *entityName;
  EOEntity   *entity;
  
  if ((db = [self valueForKey:LSDatabaseKey]) == nil)
    /* no model .. */
    return;
  
  entityName = [_notification object];
  entity     = [db entityNamed:entityName];
  
  if (entity == nil)
    return;
  
  d = [[EOEntityClassDescription alloc] initWithEntity:entity];
  [EOClassDescription registerClassDescription:(EOClassDescription *)d
                      forClass:NSClassFromString([entity className])];
  [d release]; d = nil;
}
- (void)_requireClassDescriptionForClass:(NSNotification *)_notification {
  EODatabase *db;
  Class      c;
  NSString   *className;
  NSString *entityName;
  EOEntity *entity;
  EOClassDescription *d;
  
  if ((db = [self valueForKey:LSDatabaseKey]) == nil)
    /* no model .. */
    return;
  
  c = [_notification object];
  className = NSStringFromClass(c);
  
  if (![className hasPrefix:@"LS"])
    return;

  entityName = [className substringFromIndex:2];
  entity     = [db entityNamed:entityName];
    
  if (entity == nil)
    return;

  d = [[EOEntityClassDescription alloc] initWithEntity:entity];
  [EOClassDescription registerClassDescription:d
                      forClass:NSClassFromString([entity className])];
  [d release]; d = nil;
}

/* database notifications */

#if 0
- (void)handleContextNotification:(NSNotification *)_n {
  [self logWithFormat:@"context notification %@ on object %@ userInfo %@",
          [_n name], [_n object], [_n userInfo]];
}
- (void)handleChannelNotification:(NSNotification *)_n {
  [self logWithFormat:@"channel notification %@ on object %@ userInfo %@",
          [_n name], [_n object], [_n userInfo]];
}
#endif

/* accessors */

- (BOOL)wasLastCommandOk {
  return self->wasLastCommandOk;
}

- (id<LSTypeManager>)typeManager {
  return self->typeManager;
}
- (id)propertyManager {
  return self->objectPropertyManager;
}
- (id)linkManager {
  return self->linkManager;
}

- (id)accessManager {
  return self->accessManager;
}

- (NSUserDefaults *)userDefaults {
  NSUserDefaults *ud;

  if ((ud = [self valueForKey:LSUserDefaultsKey]))
    return ud;
  
  return [NSUserDefaults standardUserDefaults];
}

- (void)setCommandFactory:(id<NSObject,LSCommandFactory>)_factory {
  ASSIGN(self->commandFactory, _factory);
}
- (id<NSObject,LSCommandFactory>)commandFactory {
  return self->commandFactory;
}

/* flushing caches */

- (void)flush {
  NSEnumerator   *evars;
  NSMutableArray *keys;
  NSString       *entry;
  int i, n;

  evars = [self->extraVariables keyEnumerator];
  keys  = [[NSMutableArray alloc] init];
  
  while ((entry = [evars nextObject])) {
    if ([entry hasPrefix:@"_cache"])
      [keys addObject:entry];
  }
  
  /* release cache keys */
  for (i = 0, n = [keys count]; i < n; i++)
    [self->extraVariables removeObjectForKey:[keys objectAtIndex:i]];
  
  [[self notificationCenter]
         postNotificationName:@"LSCommandContextFlush"
         object:self];
  [keys release]; keys = nil;
}

/* key-value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:LSCommandFactoryKey]) {
    ASSIGN(self->commandFactory, _value);
    return;
  }

  if ([_key isEqualToString:LSAccountKey]) {
    // it's not allowed to relogin
    BOOL allowed = NO;
    id oldVal = [self valueForKey:LSAccountKey];
    if (oldVal == nil) {
      // never logged in. -> allowed
      allowed = YES;
    }
    else if ([_value isKindOfClass:[NSNull class]]) {
      // invalidating context -> allowed
      allowed = YES;
    }
    if (allowed)
      [self->extraVariables setObject:_value forKey:_key];
    else {
      NSLog(@"%s: reassigning context account not allowed !!",
            __PRETTY_FUNCTION__);
    }
    return;
  }
  
  if (_value != nil)
    [self->extraVariables setObject:_value forKey:_key];
  else
    [self->extraVariables removeObjectForKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  return ([_key isEqualToString:LSCommandFactoryKey])
    ? self->commandFactory
    : [self->extraVariables objectForKey:_key];
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@[0x%08X]: login=%@ tx=%s>",
                     NSStringFromClass([self class]), self,
                     [[self valueForKey:LSAccountKey] valueForKey:@"login"],
                     [self isTransactionInProgress] ? "yes" : "no"];
}

@end /* LSCommandContext */

@implementation LSCommandContext(Logging)

- (void)logWithFormat:(NSString *)_format, ... {
  NSString *value = nil;
  va_list  ap;
  
  va_start(ap, _format);
  value = [[NSString alloc] initWithFormat:_format arguments:ap];
  va_end(ap);
  
  NSLog(@"CmdCtx[%@]: %@",
        [[self valueForKey:LSAccountKey] valueForKey:@"login"],
        value);
  [value release];
}

- (void)debugWithFormat:(NSString *)_format, ... {
  static char showDebug = 2;
  NSString *value = nil;
  va_list  ap;
  
  if (showDebug == 2) {
    showDebug = [[[NSUserDefaults standardUserDefaults]
                                  objectForKey:@"LSDebuggingEnabled"]
                                  boolValue] ? 1 : 0;
  }
  
  if (showDebug) {
    va_start(ap, _format);
    value = [[NSString alloc] initWithFormat:_format arguments:ap];
    va_end(ap);

    NSLog(@"CmdCtx[%@]D: %@",
          [[self valueForKey:LSAccountKey] valueForKey:@"login"],
          value);
    [value release];
  }
}

@end /* LSCommandContext(Logging) */

@implementation LSCommandContext(LookupCommands)

- (id<NSObject,LSCommandFactory>)commandFactory {
  id<NSObject,LSCommandFactory> factory;

  factory = [self valueForKey:LSCommandFactoryKey];
  NSAssert(factory, @"no factory set !");
  return factory;
}

- (id<LSCommand>)lookupCommand:(NSString *)_command inDomain:(NSString *)_do {
  return lookupCommand(self, _do, _command, nil, NULL);
}

- (id<LSCommand>)lookupCommand:(NSString *)_command
  inDomain:(NSString *)_domain
  args:(NSString *)_arg1,...
{
  va_list       va;
  id<LSCommand> command;

  va_start(va, _arg1);
  command = lookupCommand(self, _domain, _command, _arg1, &va);
  va_end(va);

  return command;
}

- (id<LSCommand>)lookupCommand:(NSString *)_command inDomain:(NSString *)_domain
  arg0:(id)_arg0 vargs:(va_list *)_va
{
  return lookupCommand(self, _domain, _command, _arg0, _va);
}

@end /* LSCommandContext(LookupCommands) */

@implementation LSCommandContext(RunningCommands)

- (BOOL)handleException:(NSException *)_exception
  ofCommand:(id<LSCommand>)_command
{
  return NO;
}

- (id)runCommand:(NSString *)_command
  fromDomain:(NSString *)_domain
  args:(NSString *)_arg1,...
{
  id<LSCommand> command = nil;
  va_list       va;

  va_start(va, _arg1);
  command = lookupCommand(self, _domain, _command, _arg1, &va);
  va_end(va);

  return runCommand(self, command);
}

- (id)runCommand:(NSString *)_command,... {
  id<LSCommand> command = nil;
  va_list       va;

  va_start(va, _command);
  command = lookupCommand(self, nil, _command, nil, &va);
  va_end(va);
  
  return runCommand(self, command);
}

- (id)runCommand:(NSString *)_command vargs:(va_list *)_va {
  id<LSCommand> command = nil;
  command = lookupCommand(self, nil, _command, nil, _va);
  return runCommand(self, command);
}

- (id)runCommand:(NSString *)_command arguments:(NSDictionary *)_args {
  id<LSCommand> command = nil;
  
  if ((command = lookupCommand(self, nil, _command, nil, NULL))) {
    [command takeValuesFromDictionary:_args];
    return runCommand(self, command);
  }
  else {
    return nil;
  }
}

- (id<LSCommand>)runCommand:(NSString *)_command inDomain:(NSString *)_domain
  arg0:(id)_arg0 vargs:(va_list *)_va
{
  id command;
  
  command = [self lookupCommand:_command inDomain:_domain
                  arg0:_arg0 vargs:_va];
  
  return runCommand(self, command);
}

@end /* LSCommandContext(RunningCommands) */

@implementation LSCommandContext(Channels)

static inline void _markAccessed(LSCommandContext *self) {
  [self->lastAccess release]; self->lastAccess = nil;
  self->lastAccess = [now() copy];
}

- (void)_resetChannelCloseTimer {
  [self->channelCloseTimer invalidate];
  [self->channelCloseTimer release]; 
  self->channelCloseTimer = nil;
}

- (void)_closeChannel {
  EODatabaseChannel *dbCh;
  
  if ([self isTransactionInProgress]) {
    [self logWithFormat:
            @"can't close channel, a transaction is in progress (started at %@)",
            self->txStartTime];
    return;
  }
  
  dbCh = [self valueForKey:LSDatabaseChannelKey];
  
  // check if session is open
  if (self->channelOpenTime == nil) {
    // ensure db channel is really closed
    if ([dbCh isOpen]) {
      [self logWithFormat:@"internal inconsistency (channel is still open)"];
      [dbCh closeChannel];
      [self _resetChannelCloseTimer];
    }
    return;
  }
  
  if (openCtx == self)
    openCtx = nil;
  
  /* session is open, but adaptor channel isn't ?! */
  if (![dbCh isOpen]) {
    [self logWithFormat:@"internal inconsistency (channel is not open)"];
    [self _resetChannelCloseTimer];
  }
  
  /* close channel */
  [dbCh closeChannel];
  [self _resetChannelCloseTimer];
  [self->channelOpenTime   release]; self->channelOpenTime = nil;
  [self->lastAccess        release]; self->lastAccess = nil;
}

- (BOOL)_isChannelOpen {
  EODatabaseChannel *dbCh;
  dbCh = [self valueForKey:LSDatabaseChannelKey];
  return [dbCh isOpen];
}

- (BOOL)_openChannel {
  EODatabaseChannel *dbCh;
  
  dbCh = [self valueForKey:LSDatabaseChannelKey];
  
  /* check whether session is already connected */
  if ([dbCh isOpen]) {
    [self debugWithFormat:@"tried to open channel twice !"];
    return YES;
  }
  
  /* try to open channel */
  if (![dbCh openChannel]) {
    [self logWithFormat:@"ERROR: couldn't open database channel !"];
    return NO;
  }
  
  /* mark open */
  self->channelOpenTime = [now() retain];
  _markAccessed(self);
  
  openCtx = self;
  
  self->channelCloseTimer =
    [[NSTimer scheduledTimerWithTimeInterval:self->channelTimeOut
              target:self selector:@selector(_channelTimeOut:)
              userInfo:nil repeats:YES]
              retain];
  
  return YES;
}

- (void)_channelTimeOut:(NSTimer *)_timer {
  static NSString *calFmt = @"%H:%M:%S";
  NSTimeInterval diff;
  id last, snow;
  
  if ([self->lastAccess timeIntervalSinceNow] >= (-(self->channelTimeOut)))
    return;

  last = self->lastAccess;
  snow = now();
  diff = [snow timeIntervalSinceDate:last];
    
  last = [last descriptionWithCalendarFormat:calFmt timeZone:nil locale:nil];
  snow = [snow descriptionWithCalendarFormat:calFmt timeZone:nil locale:nil];
  
  [self debugWithFormat:@"channel timed out (%.2gs, used=%@, now=%@)",
          diff, last, snow];
  [self _closeChannel];
  [_timer invalidate];
}

@end /* LSCommandContext(Channels) */

@implementation LSCommandContext(Transactions)

- (void)_ensureNoDatabaseTransactionInProgress {
  /* check whether dbContext has inconsistencies */
  EODatabaseContext *dbCtx;

  dbCtx = [self valueForKey:LSDatabaseContextKey];
  
  if ([dbCtx transactionNestingLevel] <= 0)
    return;
  
  [self logWithFormat:@"internal inconsistency (db tx is in progress)"];
  while ([dbCtx transactionNestingLevel] > 0) {
    if ([dbCtx commitTransaction]) 
      continue;
      
    [self logWithFormat:@"couldn't commit db transaction."];
    [dbCtx rollbackTransaction];
  }
}

- (BOOL)_beginTransaction {
  EODatabaseContext    *dbCtx = nil;
  NSNotificationCenter *nc    = nil; 
  
  dbCtx = [self valueForKey:LSDatabaseContextKey];
  nc    = [self notificationCenter];
  
  NSAssert(dbCtx, @"lost database context object ..");
  
  // check for nested transactions
  if (self->txStartTime) {
    [self logWithFormat:@"tried to start nested transaction !"];
    return YES;
  }
  
  [self _ensureNoDatabaseTransactionInProgress];
  
  // check for database channel
  if ((self->channelOpenTime == nil) || ![self _isChannelOpen]) {
    [self debugWithFormat:@"opening channel for transaction ..."];
    if (![self _openChannel]) {
      [self debugWithFormat:@"couldn't open channel for transaction."];
      return NO;
    }
    [nc postNotificationName:@"LSCommandContextOpenChannel"
        object:self];
  }

#if DEBUG
  {
    static int ask = -1;
    if (ask == -1) {
      ask = [[NSUserDefaults standardUserDefaults]
                             boolForKey:@"LSAskAtTxBegin"] ? 1 : 0;
    }
    if (ask) {
      fprintf(stdout, "%s: begin tx ... <enter>: ",
              [[self description] cString]);
      fflush(stdout);
      if (fgetc(stdin) == 'c')
        abort();
    }
  }
#endif
  
  /* begin tx */
  if (![dbCtx beginTransaction]) {
    [self logWithFormat:@"couldn't begin database transaction !"];
    _markAccessed(self);
    return NO;
  }
  [nc postNotificationName:@"LSCommandContextBeginTransaction"
      object:self];
  
  [self->txStartTime release]; self->txStartTime = nil;
  self->txStartTime = [now() retain];
  _markAccessed(self);
  return YES;
}

- (BOOL)begin {
  return [self _beginTransaction];
}

- (BOOL)commit {
  EODatabaseContext *dbCtx;
  
  if (self->txStartTime == nil) {
    [self debugWithFormat:@"Note: can't commit, no transaction in progress !"];
    return NO;
  }
  
  dbCtx = [self valueForKey:LSDatabaseContextKey];

  if (![dbCtx commitTransaction]) {
    [self logWithFormat:@"ERROR: couldn't commit database transaction !"];
    _markAccessed(self);
    return NO;
  }
  [[self notificationCenter]
         postNotificationName:@"LSCommandContextCommitTransaction"
         object:self];
  [self flush];

  [self debugWithFormat:
          @"Note: committed transaction started at %@ (duration=%5.3fs)",
          self->txStartTime, -[self->txStartTime timeIntervalSinceNow]];
  [self->txStartTime release]; self->txStartTime = nil;
  [self _ensureNoDatabaseTransactionInProgress];
  _markAccessed(self);
  return YES;
}

- (BOOL)rollback {
  EODatabaseContext *dbCtx;
  
  if (self->txStartTime == nil) {
    [self debugWithFormat:@"can't rollback: no transaction in progress !"];
    return NO;
  }

  dbCtx = [self valueForKey:LSDatabaseContextKey];

  if (![dbCtx rollbackTransaction]) {
    [self logWithFormat:@"couldn't rollback database transaction !"];
    [self->lastAccess release]; 
    self->lastAccess = [now() retain];
    return NO;
  }
  [[self notificationCenter]
         postNotificationName:@"LSCommandContextRollbackTransaction"
         object:self];
  
  [self debugWithFormat:@"canceled transaction started at %@",
          self->txStartTime];
  [self->txStartTime release]; self->txStartTime = nil;
  [self _ensureNoDatabaseTransactionInProgress];
  _markAccessed(self);
  return YES;
}

- (BOOL)isTransactionInProgress {
  return (self->txStartTime != nil) ? YES : NO;
}

@end /* LSCommandContext(Transactions) */

@implementation LSCommandContext(GlobalContext)

// MT
static NSMutableArray *ctxStack = nil;

- (void)pushContext {
  if (ctxStack == nil)
    ctxStack = [[NSMutableArray alloc] init];

  [ctxStack addObject:self];
}

- (void)popContext {
  unsigned count;
  id ctx;
  
  if (ctxStack == nil) {
    [self logWithFormat:@"WARNING(-popContext:): context stack is not setup."];
    return;
  }
  if ((count = [ctxStack count]) == 0) {
    [self logWithFormat:@"WARNING(-popContext:): context stack is empty."];
    return;
  }

  ctx = [ctxStack objectAtIndex:(count - 1)];
  if (ctx != self) {
    [self logWithFormat:
            @"WARNING(-popContext:): different ctx on top of stack."];
    return;
  }
  
  [ctxStack removeObjectAtIndex:(count - 1)];
}

+ (LSCommandContext *)activeContext {
  if ([ctxStack count] == 0)
    return nil;
  
  return [ctxStack lastObject];
}

@end /* LSCommandContext(GlobalContext) */

@implementation LSCommandContext(StaticMethods)

static NSNull *null = nil;

static id<LSCommand>
lookupCommand(LSCommandContext *self, NSString *_domain, NSString *_command,
              NSString *_arg1, va_list *va)
{
  id<LSCommand> command = nil;
  NSString *argName;
  id       argValue;

  if (null == nil) null = [[NSNull null] retain];

  if (_domain == nil) {
    // command in form 'domain::cmd'
    NSRange r;
    
    r = [_command rangeOfString:@"::"];
    if (r.length == 0)
      _domain = @"system";
    else {
      _domain  = [_command substringToIndex:r.location];
      _command = [_command substringFromIndex:(r.location + r.length)];
    }
  }
  
  command = LSCommandLookup([self commandFactory], _domain, _command);
  if (command == nil)
    return nil;

  argName  = _arg1 ? _arg1 : (va ? va_arg(*va, NSString *) : nil);
  argValue = va ? va_arg(*va, id) : nil;
    
  while (argName) {
    if (argValue == null) argValue = nil;
      
    LSCommandSet((LSBaseCommand *)command, argName, argValue);
      
    argName  = va_arg(*va, NSString *);
    argValue = va_arg(*va, id);
  }
  return command;
}

static id runCommand(LSCommandContext *self, id<LSCommand> _command) {
  volatile id result = nil;
  BOOL needsTx  = YES;
  BOOL needsCh  = YES;
  BOOL openedTx = NO;

  static int profileDeep = 0;

        
  
  needsCh = [_command requiresChannel];

  if (self->txStartTime == nil) {
    needsTx = [_command requiresTransaction];
    needsCh = YES;

    if (needsTx) {
      if (![self _beginTransaction]) {
        [self debugWithFormat:@"couldn't begin transaction"];
        return nil;
      }
      //[self debugWithFormat:@"started transaction for command %@.", _command];
      openedTx = YES;
    }
  }
  
  NS_DURING {
    struct timeval tv;
    double ti = 0.0, addTi;
    
    
    self->cmdNestingLevel++;

    if (ProfileCommands) {
      gettimeofday(&tv, NULL);
      ti = (double)tv.tv_sec + ((double)tv.tv_usec / 1000000.0);
      profileDeep++;
      if (ProfileCommandsFileName == nil) {
        fprintf(stderr, "###### { [%s] start timestamp \n",
                [[NSString stringWithFormat:@"%@:%@",
                          [(id)_command domain],
                           [(id)_command operation]] cString]);
      }
    }
    result = [_command runInContext:self];
    if (ProfileCommands) {
      NSString *cmdName = nil;
      FILE     *f      = NULL;
      NSNumber *oldInt = nil;
      gettimeofday(&tv, NULL);
      
      ti = (double)tv.tv_sec + ((double)tv.tv_usec / 1000000.0) - ti;
      profileDeep--;
      if (self->profileCmdDict == nil)
        self->profileCmdDict = [[NSMutableDictionary alloc] init];

      cmdName = [NSString stringWithFormat:@"%@:%@",
                          [(id)_command domain],
                          [(id)_command operation]];
      if (ProfileCommandsFileName == nil) {
        f = stderr;
      }
      else {
        if ((f = fopen([ProfileCommandsFileName cString], "a+")) == NULL)
          f = stderr;
      }
      if ((oldInt = [self->profileCmdDict objectForKey:cmdName]))
        addTi = [oldInt doubleValue] + ti;
      else
        addTi = ti;

      [self->profileCmdDict setObject:[NSNumber numberWithDouble:addTi]
                            forKey:cmdName];
                                                
      fprintf(f, "###### ");
      {
        int cnt = profileDeep;

        while (cnt != 0) {
          fprintf(f, "   ");
          cnt--;
        }
      }
      fprintf(f, "[%s] needed:%4.4fs added:%4.4fs }\n",
              [cmdName  cString], ti < 0.0 ? -1.0 : ti,
              addTi < 0.0 ? -1.0 : addTi);
      fflush(f);
      if (f != stderr)
        fclose(f);
    }
    self->cmdNestingLevel--;
    _markAccessed(self);
  }
  NS_HANDLER {
    self->cmdNestingLevel--;
    _markAccessed(self);
    
    if (![self handleException:localException ofCommand:_command]) {
      if (openedTx) [self rollback];
      [localException raise];
    }
  }
  NS_ENDHANDLER;
  //NSLog(@"return result self->txStartTime %@ %@", self->txStartTime, self);
  return result;
}

@end /* LSCommandContext(StaticMethods) */
