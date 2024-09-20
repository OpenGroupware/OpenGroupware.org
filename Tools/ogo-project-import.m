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
#include "common.h"

@interface SkyProjectImporter : NGFileManagerCopyTool
{
}
- (id)initWithLogin:(NSString *)_login password:(NSString *)_pwd
  project:(NSString *)_projectKey;
@end

#include <OGoDatabaseProject/SkyProjectFileManager.h>
#include <LSFoundation/LSCommandContext.h>

static void usage(int exitCode);

@implementation SkyProjectImporter

- (id)initWithLogin:(NSString *)_login
  password:(NSString *)_pwd
  project:(NSString *)_projectKey
{
  if ([_login length] == 0 || [_projectKey length] == 0) {
    [self release];
    return nil;
  }
  
  if ((self = [self init])) {
    LSCommandContext *cc;
    id fm;
    
    if ((cc = [[LSCommandContext alloc] init]) == nil) {
      NSLog(@"couldn't create command context ..");
      [self release];
      return nil;
    }
    if (![cc login:_login password:_pwd]) {
      NSLog(@"couldn't login '%@' user ..", _login);
      [self release];
      return nil;
    }

    fm =
      [[SkyProjectFileManager alloc] initWithContext:cc
                                     projectCode:_projectKey];
    if (fm == nil) {
      NSLog(@"couldn't create filemanager for project %@ ..", _projectKey);
      [self release];
      return nil;
    }
    [self setSourceFileManager:[NSFileManager defaultManager]];
    [self setTargetFileManager:fm];
    [fm release]; fm = nil;
    [cc release]; cc = nil;
  }
  return self;
}

+ (int)run {
  NSUserDefaults     *ud;
  NSString           *projectKey, *login, *pwd, *path, *dpath;
  NSString           *include, *exclude;
  BOOL               attribs, overwrt, vArg;
  SkyProjectImporter *skyProjectImporter;
  EOQualifier        *argIncQual = nil;
  EOQualifier        *argExcQual = nil;

  ud = [NSUserDefaults standardUserDefaults];

  if ([ud boolForKey:@"verbose"])
    NSLog(@"%s: starting import", __PRETTY_FUNCTION__);
    
  login      = [ud stringForKey:@"login"];
  pwd        = [ud stringForKey:@"password"];
  projectKey = [ud stringForKey:@"project"];
  path       = [ud stringForKey:@"source"];
  dpath      = [ud stringForKey:@"target"];
  include    = [ud stringForKey:@"include"];
  exclude    = [ud stringForKey:@"exclude"];
  attribs    = [ud boolForKey:  @"attributes"];
  overwrt    = [ud boolForKey:  @"overwrite"];
  vArg    = [ud boolForKey:  @"verbose"];
    
  if ([login      length] == 0) usage(1);
  if ([pwd        length] == 0) pwd = @"";//usage(2);
  if ([projectKey length] == 0) usage(3);
  if ([path       length] == 0) path  = @"*";
  if ([dpath      length] == 0) dpath = @"/";
  
  if ([include length] != 0)
    argIncQual = [EOQualifier qualifierWithQualifierFormat:include];
  if ([exclude length] != 0)
    argExcQual = [EOQualifier qualifierWithQualifierFormat:exclude];

  skyProjectImporter = [[SkyProjectImporter alloc] initWithLogin:login
						   password:pwd
						   project:projectKey];
  [skyProjectImporter setRestoreAttributes:attribs];
  [skyProjectImporter setOverwrite:        overwrt];
  [skyProjectImporter setVerbose:          vArg];
  [skyProjectImporter setIncludeQualifier:argIncQual];
  [skyProjectImporter setExcludeQualifier:argExcQual];

  [skyProjectImporter copyPath:path toPath:dpath handler:nil];
  [[(id)[skyProjectImporter targetFileManager] context] commit];

  if ([ud boolForKey:@"verbose"]) {
    NSLog(@"%s: import was successful", __PRETTY_FUNCTION__);
  }
  
#if 0
  /* OS will clean up for us (and do this faster ;-) ... */
  [skyProjectImporter release];
#endif
  return 0;
}

@end /* SkyProjectImporter */

void usage(int exitCode) {
  printf("usage: skyprojectimporter\n"
         "  -login <login>\n"
         "  [-password <pwd>]\n"
         "  -project <project-num>         SKYRiX project code\n"
         "  [-source <source-path>]        (default: '.')\n"
         "  [-target <destination-path>]   (default: '/')\n"
         "  [-attributes NO]               restore attributes\n"
         "  [-overwrite NO]                overwrite existing files\n"
         "  [-verbose NO]                  verbose mode\n"
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
  
  pool = [[NSAutoreleasePool alloc] init];
  [SkyProjectImporter run];
  // [pool release]; // we are cleaned up by the kernel in just a second ...
  
  exit(0);
  [pool release]; // please the compiler
  return 0;
}
