
#include "common.h"
#include "SkyPrivatePersonExporter.h"

@implementation SkyPrivatePersonExporter

- (id)initWithAccountsPath:(NSString *)_accountPath {
  if ((self = [super init])) {
    self->accounts = [[self->fm directoryContentsAtPath:_accountPath] retain];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->accounts);
  [super dealloc];
}

- (NSString *)searchBase {
  return [NSString stringWithFormat:@"ou=addr,uid=%@,%@",
                   self->account, [super searchBase]];
}


/*
  objectclass=doof
*/

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
    if (![super exportEntries]) {
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

@end /* SkyPersonExporter */
