
#include "common.h"
#include "SkyDBExporter.h"

@implementation SkyDBExporter

- (id)initWithAccountsPath:(NSString *)_accountPath {
  if ((self = [super init])) {
    self->accounts = [[self->fm directoryContentsAtPath:_accountPath] retain];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->dbConfig);
  RELEASE(self->dbAdaptor);
  RELEASE(self->adChannel);
  RELEASE(self->accounts);
  RELEASE(self->account);
  [super dealloc];
}

- (NSString *)dbAdaptor {
  if (self->dbAdaptor == nil) {
    self->dbAdaptor = [[[NSUserDefaults standardUserDefaults]
                                      stringForKey:@"DatabaseAdaptor"] retain];
    if (!self->dbAdaptor) {
      self->dbAdaptor = [@"PostgreSQL72" retain];
    }
  }
  return self->dbAdaptor;
}

- (NSDictionary *)dbConfig {
  if (self->dbConfig == nil) {
    self->dbConfig = [[[NSUserDefaults standardUserDefaults]
                                      dictionaryForKey:@"DatabaseConfig"] retain];

    if (!self->dbConfig) {
      self->dbConfig = [[NSDictionary alloc] initWithObjectsAndKeys:
                                             @"SkyDB",     @"databaseName",
                                             @"localhost", @"hostName",
                                             @"SkyUser",   @"userName",
                                             @"",          @"password",
                                             @"5432",      @"port",
                                             nil];
    }
  }
  return self->dbConfig;
}

- (BOOL)openConnection {
  BOOL result = YES;
  if (self->adChannel == nil) {
    EOAdaptor        *ad  = nil;
    EOAdaptorContext *ctx = nil;

    ad  = [EOAdaptor adaptorWithName:[self dbAdaptor]];
    [ad setConnectionDictionary:[self dbConfig]];

    ctx             = [ad createAdaptorContext];
    self->adChannel = [[ctx createAdaptorChannel] retain];
    if (![self->adChannel isOpen])
      [self->adChannel openChannel];

  }
  return result;
}

- (void)closeConnection {
  if ([self->adChannel isOpen]) {
    if ([[self->adChannel adaptorContext] transactionNestingLevel]) {
      [[self->adChannel adaptorContext] commitTransaction];
    }
    [self->adChannel closeChannel];
  }
  RELEASE(self->adChannel);
  self->adChannel = nil;
}

- (NSString *)entutyName {
  return [self subclassResponsibility:_cmd];
}

- (NSArray *)fetchAttributes {
  return [self->adChannel describeResults];
}

- (NSDictionary *)buildEntry:(NSDictionary *)_attrs {
  return [self subclassResponsibility:_cmd];
}

- (NSString *)searchExpression {
  return [self subclassResponsibility:_cmd];
}

- (BOOL)_exportEntries {
  if (![super exportEntries])
    return NO;

  if ([self openConnection]) {
    NSDictionary *dict;
    NSArray      *attrs;


    [[self->adChannel adaptorContext] beginTransaction];
    
    if (![self->adChannel evaluateExpression:[self searchExpression]]) {
      NSLog(@"%s: evaluateExpression %@ failed ", [self searchExpression],
            __PRETTY_FUNCTION__);
      return NO;
    }

    attrs = [self fetchAttributes];
    while ((dict = [self->adChannel fetchAttributes:attrs
                        withZone:nil])) {
      NSAutoreleasePool *pool;
      pool = [[NSAutoreleasePool alloc] init];
      dict = [self buildEntry:dict];
      
      if (![self writeEntry:dict]) {
        NSLog(@"%s: couldn`t write entry %@", __PRETTY_FUNCTION__,
              dict);
      }
      RELEASE(pool);
    }
    [self closeConnection];
    return YES;
  }
  return NO;
}

- (NSArray *)extractIdsFromString:(NSString *)_str {
  NSEnumerator   *enumerator;
  NSMutableArray *array;
  id             obj;

  array = [NSMutableArray arrayWithCapacity:10];
  enumerator = [[_str componentsSeparatedByString:@"|"] objectEnumerator];

  while ((obj = [enumerator nextObject])) {
    if ([obj isNotNull]) {
      if ([obj length]) {
        [array addObject:[[[[obj componentsSeparatedByString:@","]
                                 objectAtIndex:0]
                                 componentsSeparatedByString:@"="]
                                 lastObject]];
      }
    }
  }
  return array;
}


- (void)handleAttr:(NSMutableDictionary *)_attrs key:(NSString *)_key
{
  NSString *obj;
  id       res;

  obj = [_attrs objectForKey:_key];
  res = nil;

  if ([obj isNotNull]) {
    if ([obj length]) {
      res = [self extractIdsFromString:obj];
    }
  }
  if (!res) {
    res = [NSArray array];
  }
  [_attrs setObject:res forKey:_key];
}

- (NSString *)exportPath {
  return [[self->path stringByAppendingPathComponent:self->account]
                      stringByAppendingPathExtension:@"plist"];
}

- (BOOL)exportEntries {
  BOOL         overWriteEntries;
  NSEnumerator *enumerator;
  id           obj;

  self->writeSingleEntry = NO;

  obj = [[NSUserDefaults standardUserDefaults]
                         objectForKey:@"OverwriteEntries"];

  if (obj) {
    overWriteEntries = [obj boolValue];
  }
  else
    overWriteEntries = YES;
  
  enumerator = [self->accounts objectEnumerator];
  while ((self->account = [[enumerator nextObject]
                                       stringByDeletingPathExtension])) {
    NSString          *p;
    NSAutoreleasePool *pool;

    pool = [[NSAutoreleasePool alloc] init];
    p = [[self->path stringByAppendingPathComponent:self->account]
                     stringByAppendingPathExtension:@"plist"];

    if ([self->fm fileExistsAtPath:p]) {
      if (!overWriteEntries)
        continue;
      else {
        [self->fm removeFileAtPath:p handler:nil];
      }
    }
    if (![self _exportEntries]) {
      NSLog(@"%s: exportEntries for %@ failed ...",
            __PRETTY_FUNCTION__, self->account);
      [self->fm removeFileAtPath:p handler:nil];
    }
    else
      [self flush];

    self->account = nil;
    RELEASE(pool); pool = nil;
  }
  return YES;
}


@end /* SkyDBExporter */
