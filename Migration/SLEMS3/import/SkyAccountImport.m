// $Id$

#include "common.h"
#include "SkyAccountImport.h"
#include "SkyAccountUidHandler.h"
#include "SkyGroupUidHandler.h"
#include <LSFoundation/LSFoundation.h>

@implementation SkyAccountImport

- (id)initWithAccountsPath:(NSString *)_path {
  if ((self = [super init])) {
    ASSIGN(self->path, _path);
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->path);
  RELEASE(self->groupHandler);
  [super dealloc];
}

- (SkyGroupUidHandler *)groupHandler {
  if (self->groupHandler == nil) {
    self->groupHandler = [[SkyGroupUidHandler alloc] init];
  }
  return self->groupHandler;
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
  return [SkyAccountUidHandler class];
}

- (int)verifyObject:(id)_obj {
  id account;

  account = [[self commandContext]
                   runCommand:@"account::get-by-login", @"login",
                 [_obj valueForKey:@"login"], nil];

  if (!account) {
    return 0;
  }
  NSLog(@"%s: account \n%@\n already exist in database \n%@\n",
        __PRETTY_FUNCTION__, _obj, account);
  [_obj setObject:[NSNumber numberWithBool:YES] forKey:@"alreadyExist"];
  return [[account valueForKey:@"companyId"] intValue];
}


- (BOOL)importObject:(id)_obj withId:(int)_id {
  id ctx, account;
  int templateUserId = 9999;

  if ([[_obj objectForKey:@"alreadyExist"] boolValue])
    return YES;
  
  ctx = [self commandContext];

  if (![_obj isKindOfClass:[NSMutableDictionary class]]) {
    _obj = [[_obj mutableCopy] autorelease];
  }
  [_obj setObject:[NSNumber numberWithInt:_id] forKey:@"companyId"];
  [_obj setObject:[NSNumber numberWithInt:templateUserId]
        forKey:@"templateUserId"];
  
  account = [ctx runCommand:@"account::new" arguments:_obj];

  {
    NSArray            *groupNames;
    NSMutableArray     *groups;
    NSEnumerator       *enumerator;
    id                 obj;
    SkyGroupUidHandler *handler;
    BOOL               hasAllIntranet;
    int                allIntranetGrpNumber = 10003;
    
    handler        = [self groupHandler];
    groupNames     = [_obj arrayForKey:@"group_description"];
    groups         = [NSMutableArray arrayWithCapacity:[groupNames count]];
    enumerator     = [groupNames objectEnumerator];
    hasAllIntranet = NO;
    while ((obj = [enumerator nextObject])) {
      int grpNr;

      grpNr = [handler uidForObjectId:obj];

      if (grpNr == allIntranetGrpNumber)
        hasAllIntranet = YES;
      
      [groups addObject:
              [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:grpNr],
                            @"companyId", nil]];
    }
    if (!hasAllIntranet) {
      [groups addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:
                                                allIntranetGrpNumber],
                                      @"companyId", nil]];
    }
    [ctx runCommand:@"account::setgroups"
         arguments:[NSDictionary dictionaryWithObjectsAndKeys:
                             account, @"member",
                            groups, @"groups", nil]];
  }
  return YES;
}

@end /* SkyAccountImport */
