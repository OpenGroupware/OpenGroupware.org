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

#include <OGoProject/NGFileManagerCopyTool.h>
#include <LSFoundation/LSCommandContext.h>
#include "common.h"

@interface SkyProjectExporter : NGFileManagerCopyTool
{
}

- (id)initWithLogin:(NSString *)_login password:(NSString *)_pwd
  project:(NSString *)_projectKey;

@end

#import <OGoDatabaseProject/SkyProjectFileManager.h>

@implementation SkyProjectExporter

- (id)initWithLogin:(NSString *)_login
  password:(NSString *)_pwd
  project:(NSString *)_projectKey
{
  if ([_login length] == 0 || [_projectKey length] == 0) {
    RELEASE(self);
    return nil;
  }
  
  if ((self = [self init])) {
    LSCommandContext *cc;
    id fm;
    
    if ((cc = [[LSCommandContext alloc] init]) == nil) {
      NSLog(@"couldn't create command context ..");
      RELEASE(self);
      return nil;
    }
    if (![cc login:_login password:_pwd]) {
      NSLog(@"couldn't login '%@' user ..", _login);
      RELEASE(self);
      return nil;
    }

    fm =
      [[SkyProjectFileManager alloc] initWithContext:cc
                                     projectCode:_projectKey];
    if (fm == nil) {
      NSLog(@"couldn't create filemanager for project %@ ..", _projectKey);
      RELEASE(self);
      return nil;
    }
    [self setSourceFileManager:fm];
    [self setTargetFileManager:[NSFileManager defaultManager]];
    RELEASE(fm); fm = nil;
    RELEASE(cc); cc = nil;
  }
  return self;
}

@end

void usage(int exitCode) {
  printf("usage: skyprojectexport\n"
         "  -login <login>\n"
         "  [-password <pwd>]\n"
         "  -project <project-num>       SKYRiX project code\n"
         "  -target <destination-path>   export destination\n"
         "  [-source <source-path>]      (default: '/')\n"
         "  [-attributes NO]             save attributes\n"
         "  [-overwrite NO]              overwrite existing files\n"
         "  [-verbose NO]                verbose mode\n"
         "  [-include <qualifier>]\n"
         "  [-exclude <qualifier>]\n"
         );
  exit(exitCode);
}

int main(int argc, char **argv, char **env) {
  NSAutoreleasePool *pool;
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif

  pool = [NSAutoreleasePool new];
  {
    NSUserDefaults     *ud;
    NSString           *projectKey, *login, *pwd, *path, *dpath;
    NSString           *include, *exclude;
    BOOL               attribs, overwrt, verbose;
    SkyProjectExporter *skyProjectExporter;
    EOQualifier         *includeQualifier = nil;
    EOQualifier         *excludeQualifier = nil;

    ud         = [NSUserDefaults standardUserDefaults];
    login      = [ud stringForKey:@"login"];
    pwd        = [ud stringForKey:@"password"];
    projectKey = [ud stringForKey:@"project"];
    path       = [ud stringForKey:@"source"];
    dpath      = [ud stringForKey:@"target"];
    include    = [ud stringForKey:@"include"];
    exclude    = [ud stringForKey:@"exclude"];
    attribs    = [ud boolForKey:  @"attributes"];
    overwrt    = [ud boolForKey:  @"overwrite"];
    verbose    = [ud boolForKey:  @"verbose"];
    
    if ([login      length] == 0) usage(1);
    if ([pwd        length] == 0) pwd = @"";//usage(2);
    if ([projectKey length] == 0) usage(3);
    if ([dpath      length] == 0) usage(4);
    if ([path       length] == 0) path = @"/";
    if ([include    length] != 0)
      includeQualifier = [EOQualifier qualifierWithQualifierFormat:include];
    if ([exclude    length] != 0)
      excludeQualifier = [EOQualifier qualifierWithQualifierFormat:exclude];

    skyProjectExporter = [[SkyProjectExporter alloc] initWithLogin:login
                                                     password:pwd
                                                     project:projectKey];

    [skyProjectExporter setSaveAttributes:  attribs];
    [skyProjectExporter setOverwrite:       overwrt];
    [skyProjectExporter setVerbose:         verbose];
    [skyProjectExporter setIncludeQualifier:includeQualifier];
    [skyProjectExporter setExcludeQualifier:excludeQualifier];

    [skyProjectExporter copyPath:path toPath:dpath handler:nil];

    RELEASE(skyProjectExporter);
  }
  RELEASE(pool);
  
  exit(0);
  return 0;
}
