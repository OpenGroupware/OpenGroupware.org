/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#include "SkyMasterAction.h"
#include "common.h"
#include "SkyMasterApplication.h"
#include "MasterTask.h"
#include "TaskTemplate.h"
#include "AutostartInstance+Logic.h"
#include <XmlRpc/XmlRpcMethodCall.h>
#include <OGoIDL/NGXmlRpcAction+Introspection.h>

#include <crypt.h>
#include <stdio.h>

int getline(FILE *f, char s[], int lim)
{
  int c, i;

  for (i = 0; i < lim - 1 && (c = fgetc(f)) != EOF && c != '\n'; i++)
    s[i] = c;
  if (c == '\n')
    s[i++] = c;
  s[i] = '\0';
  return i;
}

char *dupstr(const char *s)
{
  char *p = malloc(strlen(s) + 1);

  if (p)
    strcpy(p, s);
  return p;
}

@implementation SkyMasterAction

- (id)initWithContext:(WOContext *)_ctx {
  if ((self = [super initWithContext:_ctx])) {
    NSString *path;
    NSBundle *bundle;

    bundle = [NSBundle bundleForClass:[self class]];
    
    path = [bundle pathForResource:@"INTERFACE" ofType:@"xml"];
    if (path != nil)
      [self registerInterfaceAtPath:path forComponentName:
            [self xmlrpcComponentName]];
    else
      [self logWithFormat:@"INTERFACE.xml not found in bundle path"];
  }
  return self;
}

- (SkyMasterApplication *)application {
  return (SkyMasterApplication *)[WOApplication application];
}

- (NSString *)xmlrpcComponentName {
  return @"master";
}

- (NSString *)processIdPrefix {
  return @"PID.";
}

- (int)defaultLogFileResultLines {
  return 10;
}

- (NSString *)userName {
  NSString *user;

  user = [[NSUserDefaults standardUserDefaults]
                          valueForKey:@"SMAuthenticationUser"];
  if (user == nil)
    [self logWithFormat:@"Default 'SMAuthenticationUser' is not set"];

  return user;
}

- (NSString *)password {
  NSString *pass;

  pass = [[NSUserDefaults standardUserDefaults]
                          valueForKey:@"SMAuthenticationPassword"];
  if (pass == nil)
    [self logWithFormat:@"Default 'SMAuthenticationPassword' is not set"];

  return pass;
}

- (MasterTask *)taskForProcessId:(NSString *)_processId {
  return [[self application] taskForProcessId:_processId];
}

- (AutostartInstance *)instanceForName:(NSString *)_name {
  return [[[self application] instances] objectForKey:_name];
}

- (TaskTemplate *)templateForName:(NSString *)_name {
  return [[[self application] taskTemplates] objectForKey:_name];
}

- (NSArray *)runningInstancesForTaskClassNamed:(NSString *)_taskClass {
  NSEnumerator *taskEnum;
  MasterTask   *task;
  NSMutableArray *result;

  result = [NSMutableArray arrayWithCapacity:8];
  
  taskEnum = [[[self application] tasks] objectEnumerator];
  while ((task = [taskEnum nextObject])) {
    if ([[task templateClass] isEqualToString:_taskClass]) {
      [result addObject:[task taskName]];
    }
  }
  return result;  
}

- (BOOL)isValidPassword:(NSString *)_password {
  char *result;
  int ok;

  if ((_password != nil) && ([self password] != nil)) {
    result = crypt([_password cString], [[self password] cString]);
    ok = strcmp (result, [[self password] cString]) == 0;
    return ok ? YES : NO;
  }
  else {
    [self logWithFormat:@"invalid password"];
    return NO;
  }
}

- (BOOL)checkAuthorization {
  NSString *cryptedCredentials;
  NSArray  *credentials;

  if ((cryptedCredentials = [self credentials]) != nil) {
    credentials =  [[cryptedCredentials stringByDecodingBase64]
                                        componentsSeparatedByString:@":"];

    if ([credentials count] == 2) {
      if ([[credentials objectAtIndex:0] isEqualToString:[self userName]]) {
        if ([self isValidPassword:[credentials objectAtIndex:1]])
          return YES;
      }
    }
    else
      [self logWithFormat:@"invalid credentials"];
  }
  return NO;
}

- (NSArray *)logFileContent:(NSString *)_logFileName count:(NSNumber *)_count {
  FILE *f;
  NSMutableArray *result;
  int num_lines;
  char **line_ptrs;
  char buffer[1000];
  int i;
  unsigned j, current_line;

  num_lines = (_count != nil)
    ? [_count intValue]
    : [self defaultLogFileResultLines];
  
  result = [NSMutableArray arrayWithCapacity:num_lines];

  f = fopen([_logFileName cString],"r");
  if (!f) {
    [self logWithFormat:@"logfile '%@' not found", _logFileName];
    return nil;
  }
  
  line_ptrs = malloc(sizeof *line_ptrs * num_lines);
  if (!line_ptrs) {
    [self logWithFormat:@"reading logfile - out of memory"];
    return nil;
  }

  for (i = 0; i < num_lines; i++)
    line_ptrs[i] = NULL;

  current_line = 0;
  do {
    getline(f, buffer, sizeof buffer);
    if (!feof(f)) {
      if (line_ptrs[current_line]) {
        free(line_ptrs[current_line]);
      }
      line_ptrs[current_line] = dupstr(buffer);
      if (!line_ptrs[current_line]) {
        [self logWithFormat:@"reading logfile - out of memory"];
        return nil;
      }
      current_line = (current_line + 1) % num_lines;
    }
  } while (!feof(f));

  for (i = 0; i < num_lines; i++) {
    j = (current_line + i) % num_lines;
    if (line_ptrs[j]) {
      NSString *line;

      line = [NSString stringWithCString:line_ptrs[j]];
      line = [line substringToIndex:[line length] -1];
 
      [result addObject:line];
      free(line_ptrs[j]);
    }
  }
  fclose(f);
  return result;
}

/* actions */

- (id)startAction:(NSString *)_task:(NSDictionary *)_arguments {
  id result;
  AutostartInstance *instance;
  TaskTemplate      *template;
  
  if ((instance = [self instanceForName:_task]) != nil) {
    template = [self templateForName:[instance templateclass]];

    if (template != nil) {
      result = [[self application] startNewTask:[instance instanceName]
                                   withTemplate:template
                                   arguments:[instance parametersAsDictionary]
                                   asRequiredTask:NO];
    }
    else {
      [self logWithFormat:
            @"ERROR: invalid template class '%@' for instance '%@'",
            [instance templateclass], _task];
    }
  }
  else {
    template = [self templateForName:_task];

    if (template != nil) {    
      result = [[self application] startNewTask:_task
                                   withTemplate:template
                                   arguments:_arguments
                                   asRequiredTask:NO];
    }
    else {
      [self logWithFormat:
            @"ERROR: invalid template class '%@'", _task];
            
    }
  }
  if (result != nil)
    return result;
  return [NSNumber numberWithBool:NO];
}

- (NSNumber *)stopAction:(NSString *)_task {
  MasterTask *task;

  if ([_task hasPrefix:[self processIdPrefix]]) {
    if ((task = [self taskForProcessId:_task]) == nil) {
      [self logWithFormat:@"no task for process ID %@",_task];
      return [NSNumber numberWithInt:-1];
    }

    if([task statusFlag] == STATUS_FLAG_ZOMBIE) {
      int result;
      result = [task terminationStatus];
      [[self application] removeTask:_task];
      return [NSNumber numberWithInt:result];
    }
    return [NSNumber numberWithInt:[task stop]];    
  }
  else {
    return [[self application] stopTasksWithTaskClass:_task];
  }
} 

- (NSNumber *)isRunningAction:(NSString *)_task {
  MasterTask *task;

  if([_task hasPrefix:[self processIdPrefix]]) {
    if ((task = [self taskForProcessId:_task]) == nil) {
      [self logWithFormat:@"no task for process ID %@",_task];
      return [NSNumber numberWithBool:NO];
    }
    return [NSNumber numberWithBool:[task status]];
  }
  else {
    NSEnumerator   *taskEnum;
    MasterTask     *task;
  
    taskEnum = [[[self application] tasks] objectEnumerator];
  
    while ((task = [taskEnum nextObject])) {
      if ([[task taskName] isEqualToString:_task] &&
          [task statusFlag] != STATUS_FLAG_ZOMBIE)
        return [NSNumber numberWithBool:YES];
    }
  }
  return [NSNumber numberWithBool:NO];
}

- (id)restartAction:(NSString *)_task {
  MasterTask *task;

  if ([_task hasPrefix:[self processIdPrefix]]) {  
    if ((task = [self taskForProcessId:_task]) == nil) {
      [self logWithFormat:@"no task for pid '%@'", _task];
      return [NSNumber numberWithBool:NO];
    }
    return [task restart];
  }
  else {
    return [[self application] restartTasksWithTaskClass:_task];
  }
}

- (id)stdoutLogAction:(NSString *)_task:(NSNumber *)_count {
  MasterTask *task;
  NSString   *fileName;

  if ((task = [self taskForProcessId:_task]) == nil) {
    [self logWithFormat:@"no such pid '%@'", _task];
    return [NSNumber numberWithBool:NO];
  }

  fileName = [task stdoutLogFileName];
  return [self logFileContent:fileName count:_count];
}

- (id)stderrLogAction:(NSString *)_task:(NSNumber *)_count {
  MasterTask *task;
  NSString   *fileName;

  if ((task = [self taskForProcessId:_task]) == nil) {
    [self logWithFormat:@"no such pid '%@'", _task];
    return [NSNumber numberWithBool:NO];
  }

  fileName = [task stderrLogFileName];
  return [self logFileContent:fileName count:_count];
}

- (id)statusAction:(NSString *)_task {
  MasterTask *task;
  NSMutableDictionary *result;
  NSString *statusFlags;
  
  if ((task = [self taskForProcessId:_task]) == nil) {
    [self logWithFormat:@"no such pid '%@'", _task];
    return [NSNumber numberWithBool:NO];
  }

  result = [NSMutableDictionary dictionaryWithCapacity:3];
  [result setObject:[task taskName]      forKey:@"uid"];
  [result setObject:[task templateClass] forKey:@"template"];

  statusFlags = @"";
  
  switch([task statusFlag]) {
    case STATUS_FLAG_FORKED: {
      statusFlags = [statusFlags stringByAppendingString:@"F"];
      break;
    }
    case STATUS_FLAG_ZOMBIE: {
      statusFlags = [statusFlags stringByAppendingString:@"Z"];
      break;
    }
    [result setObject:statusFlags forKey:@"status"];
  }
  return result;
}

- (NSArray *)templatesAction {
  return [[[[self application] taskTemplates] allKeys]
                  sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)tasksAction {
  return [[[[self application] tasks] allKeys]
                  sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)instancesAction:(NSString *)_taskClass {
  if (_taskClass == nil) {
    return [[[[self application] instances] allKeys]
                    sortedArrayUsingSelector:@selector(compare:)];
  }
  else {
    return [self runningInstancesForTaskClassNamed:_taskClass];
  }
}

- (NSNumber *)reloadAction {
  return [[self application] reloadTaskTemplates];
}

- (NSString *)serverStatusAction {
  return [[self application] serverStatus];
}

- (BOOL)requiresCommandContextForMethodCall:(NSString *)_method {
  static NSArray *methodNames = nil;
  NSString *methodName;
  NSRange range;

  range = [_method rangeOfString:[self xmlrpcComponentName]
                   options:NSBackwardsSearch];
  
  if (range.location != 0) {
    int index;

    index = range.location + [[self xmlrpcComponentName] cStringLength] + 1;
    methodName = [_method substringFromIndex:index];
  }
  else
    methodName = _method;
  
  if (methodNames == nil) {
    methodNames = [[NSArray alloc] initWithObjects:
                            @"isRunning",
                            @"tasks",
                            @"instances",
                            @"templates",
                            @"status",
                            @"system.listMethods",
                            @"system.methodSignature",
                            @"system.methodHelp",
                            nil];
  }
  
  if ([methodNames containsObject:methodName])
    return NO;
  
  return YES;
}

- (id<WOActionResults>)performMethodCall:(XmlRpcMethodCall *)_call {
  if ([self requiresCommandContextForMethodCall:[_call methodName]]) {
    if (![self checkAuthorization])
      return [self accessDeniedAction];
  }
  return [super performMethodCall:_call];
}

@end /* SkyMasterAction */
