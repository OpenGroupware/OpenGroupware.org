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

#include "TaskTemplate+Logic.h"
#include "MasterTask.h"
#include "SkyMasterApplication.h"
#include "DefaultEntry.h"
#include "common.h"
#include <XmlSchema/NSObject+XmlSchema.h>

@interface TaskTemplate(PrivateMethods)
- (void)_initIVarsWithDictionary:(NSDictionary *)_dict;
@end /* TaskTemplate(PrivateMethods) */

@implementation TaskTemplate(Logic)

static NSArray *toolPaths        = nil;
static NSArray *applicationPaths = nil;

/* initialization */

- (id)initWithContentsOfFile:(NSString *)_file {
  if ((self = [super initWithContentsOfFile:_file])) {
    SkyMasterApplication *application;

    if (self->autorestart == nil) {
      self->autorestart = [NSNumber numberWithBool:YES];
    }
    if (self->runcheck == nil)
      self->runcheck = [NSNumber numberWithBool:YES];
    
    application = (SkyMasterApplication *)[WOApplication application];
    
    if (self->restartdelay == nil) {
      [self setRestartdelay:
              [NSNumber numberWithInt:[application restartDelay]]];
    }
    if (self->startcount == nil)
      [self setStartcount:[NSNumber numberWithInt:[application startCount]]];
    if (self->startinterval == nil) {
      [self setStartinterval:
              [NSNumber numberWithInt:[application startInterval]]];
    }
  }
  return self;
}

- (NSDictionary *)parametersAsDictionary {
  NSMutableDictionary *result;
  NSEnumerator        *defaultEnum;
  DefaultEntry        *defaultEntry;

  result = [NSMutableDictionary dictionaryWithCapacity:
                                [self->parameters count]];
  defaultEnum = [self->parameters objectEnumerator];
  while((defaultEntry = [defaultEnum nextObject])) {
    [result setObject:[defaultEntry value] forKey:[defaultEntry name]];
  }
  return result;
}

- (NSString *)pathWithoutVariables:(NSString *)_path {
  NSDictionary *env;

  env = [[NSProcessInfo processInfo] environment];
  return [_path stringByReplacingVariablesWithBindings:env];
}

- (void)_initToolPathsArray {
  NSString *comboPath, *hostOSPath, *toolsPath;
  
  toolsPath =  @"$GNUSTEP_LOCAL_ROOT$";
  toolsPath = [toolsPath stringByAppendingPathComponent:@"Tools"];  
  
  hostOSPath = [toolsPath stringByAppendingPathComponent:
                           @"$GNUSTEP_HOST_CPU$"];
  hostOSPath = [hostOSPath stringByAppendingPathComponent:
                           @"$GNUSTEP_HOST_OS$"];
  comboPath  = [hostOSPath stringByAppendingPathComponent:@"$LIBRARY_COMBO$"];

  
  toolPaths = [[NSArray alloc] initWithObjects:
                              [self pathWithoutVariables:comboPath],
                              [self pathWithoutVariables:hostOSPath],
                              [self pathWithoutVariables:toolsPath],
                              nil];
}

- (void)_initApplicationPathsArray:(NSString *)_executable {
  NSString *appPath;

  appPath =  @"$GNUSTEP_LOCAL_ROOT$";
  appPath = [appPath stringByAppendingPathComponent:@"WOApps"];
  appPath = [appPath stringByAppendingPathComponent:_executable];
  appPath = [appPath stringByAppendingPathComponent:
                       @"$GNUSTEP_HOST_CPU$"];
  appPath = [appPath stringByAppendingPathComponent:
                       @"$GNUSTEP_HOST_OS$"];
  appPath = [appPath stringByAppendingPathComponent:@"$LIBRARY_COMBO$"];
  
  applicationPaths = [[NSArray alloc] initWithObjects:
                                      [self pathWithoutVariables:appPath],
                                      nil];
}

- (NSString *)pathForExecutable:(NSString *)_executable
  inDirectories:(NSArray *)_directories
{
  NSEnumerator  *dirEnum;
  NSString      *dir;
  NSFileManager *fm;

  fm = [NSFileManager defaultManager];
  
  dirEnum = [_directories objectEnumerator];
  while ((dir = [dirEnum nextObject])) {
    NSString *path;
    path = [dir stringByAppendingPathComponent:_executable];
    if ([fm fileExistsAtPath:path])
      return path;
  }
  return nil;
}
  
- (NSString *)applicationPathForExecutable:(NSString *)_executable {
  NSString *execFile;

  if (applicationPaths == nil)
    [self _initApplicationPathsArray:_executable];

  execFile = [_executable stringByDeletingPathExtension];
  return [self pathForExecutable:execFile inDirectories:applicationPaths];
}

- (NSString *)toolPathForExecutable:(NSString *)_executable {
  if (toolPaths == nil)
    [self _initToolPathsArray];

  return [self pathForExecutable:_executable inDirectories:toolPaths];
}

- (NSString *)executablePath {
  //[self logWithFormat:@"tool: %@", self->tool];
  if (self->app != nil)
    return [self applicationPathForExecutable:self->app];
  else if (self->tool != nil)
    return [self toolPathForExecutable:self->tool];
  else {
    NSDictionary *env;

    env = [[NSProcessInfo processInfo] environment];
    return [[[self executable]
                   stringByReplacingVariablesWithBindings:env]
                   stringByExpandingTildeInPath];
  }
}

- (id)taskFromTemplate {
  Class    clazz;
  NSString *taskClass;

  if((taskClass = self->taskclass) == nil)
    taskClass = @"MasterTask";
  
  clazz = NSClassFromString(taskClass);
  return [[(MasterTask *)[clazz alloc] initWithTemplate:self] autorelease];
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:@"<0x%08X[%@]: %@>",
                     self, NSStringFromClass([self class]),
                     [self taskclass]];
}

@end /* TaskTemplate(Logic) */
