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

#include "common.h"
#import  "SkyTool.h"

/*
  Exit codes:
  5 - database failed
*/

@interface SkyGetLoginNames : SkyTool
@end /* SkyGetLoginNames */

@implementation SkyGetLoginNames

- (BOOL)onlyRoot {
  return YES;
}


- (NSString *)additionalSwitches {
  return @"\t-attributes\tThe account attributes. Default is 'login'.";
}

- (NSString *)toolName {
  return @"sky_get_login_names";
}

- (NSString *)versionInformation {
  return @"1.0.0";
}

- (NSString *)toolDescription {
  return @"This tool returns the login names of all SKYRiX accounts.";
}

- (NSArray *)attributes {
  NSUserDefaults *ud;
  id             attrs;

  ud = [NSUserDefaults standardUserDefaults];

  if (!(attrs = [ud objectForKey:@"attributes"])) {
    attrs = @"login";
  }
  return [attrs componentsSeparatedByString:@","];
}

- (NSArray *)attributesForEntity:(EOEntity *)_entity {
  id             attrs;
  NSMutableArray *res;
  NSEnumerator   *enumerator;

  attrs      = [self attributes];
  res        = [NSMutableArray arrayWithCapacity:[attrs count]];
  enumerator = [attrs objectEnumerator];

  while ((attrs = [enumerator nextObject])) {
    id r;

    if ((r = [_entity attributeNamed:attrs])) {
      [res addObject:r];
    }
  }
  return res;
}

- (int)runWithArguments:(NSArray *)_args {
  if (![super runWithArguments:_args]) {
    LSCommandContext *ctx;
    EOSQLQualifier *qualifier;
    NSArray        *attributes;
    BOOL           isOk;
    EOAdaptorChannel *channel;
    EODatabaseContext *context;
    EOModel           *model;
    EOEntity          *entity;
    NSMutableArray    *result;

    ctx     = [self commandContext];
    result  = nil;
    model   = [[[ctx valueForKey:LSDatabaseKey] adaptor] model];
    channel = [[ctx valueForKey:LSDatabaseChannelKey] adaptorChannel];
    context = [ctx valueForKey:LSDatabaseContextKey];

    NSAssert(context, @"no adaptor context available");
    NSAssert(channel, @"no adaptor channel available");

    entity    = [model entityNamed:@"Person"];
    qualifier = [[EOSQLQualifier alloc]
                                 initWithEntity:entity
                                 qualifierFormat:
                                 @"(isAccount=1) AND NOT (companyId=10000) "
                                 @"AND NOT (dbStatus='archived') "
                                 @"AND (isTemplateUser IS NULL "
                                 @"OR isTemplateUser=0)"];
    AUTORELEASE(qualifier);

    attributes = [self attributesForEntity:entity];

    if (![channel isOpen]) {
      if (![channel openChannel]) {
        NSLog(@"couldn't open adaptor channel");
        exit(5);
      }
    }  

    if ([context beginTransaction]) {
      isOk = [channel selectAttributes:attributes
                  describedByQualifier:qualifier
                  fetchOrder:nil
                  lock:NO];
      if (isOk) {
        id obj;
        result = [NSMutableArray arrayWithCapacity:64];
        while ((obj = [channel fetchAttributes:attributes
                           withZone:NULL])) {
          [result addObject:obj];
        }
      }
      if (!(isOk = [context commitTransaction])) 
        [context rollbackTransaction];
    }
    else {
      [context rollbackTransaction];
    }
    [channel closeChannel];

    if (!isOk) {
      NSLog(@"couldn't fetch root login ..");
      exit(5);
    }
    if (result) {
      NSArray      *attrs;
      NSEnumerator *enumerator;
      id           obj;

      enumerator = [result objectEnumerator];
      attrs      = [self attributes];

      while ((obj = [enumerator nextObject])) {
        NSEnumerator *e;
        id           k;
        BOOL         isFirst;

        if ([attrs count] > 1) {
          e       = [attrs objectEnumerator];
          isFirst = YES;

          while ((k = [e nextObject])) {
            NSString *str;
          
            if (isFirst)
              isFirst = NO;
            else
              printf("|");

            str = [[obj valueForKey:k] stringValue];

            str = [[str componentsSeparatedByString:@"|"]
                        componentsJoinedByString:@"\\|"];
            printf("%s", [str cString]);
          }
          printf("\n");
        }
        else {
          printf("%s\n", [[obj valueForKey:
                              [[obj keyEnumerator] nextObject]] cString]);
        }
      }
    }
  }
  return 0;
}

@end /* SkyGetAccountLoginNames */

int main(int argc, char **argv, char **env) {
  NSAutoreleasePool *pool;
  SkyGetLoginNames  *tool;
  int res;
  
  pool = [[NSAutoreleasePool alloc] init];
#if LIB_FOUNDATION_LIBRARY  
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif
  
  tool = [[SkyGetLoginNames alloc] init];
  res = [tool runWithArguments:[[NSProcessInfo processInfo] arguments]];
  [tool release];
  
  [pool release];
  exit(0);
  /* static linking */
  [NGExtensions class];
  return 0;
}
