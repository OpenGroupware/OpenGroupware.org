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

#include "ShellAction.h"
#include "common.h"

@implementation ShellAction

- (id)init {
  if ((self = [super init])) {
    self->commandString = @"";
    self->commandArgs   = [[NSArray alloc] init];
  }
  return self;
}

+ (ShellAction *)actionWithArguments:(NSDictionary *)_args {
  ShellAction*   action                = nil;
  NSUserDefaults *ud                   = nil;
  BOOL           allowUnmappedCommands = NO;
  
  ud = [NSUserDefaults standardUserDefaults];
  allowUnmappedCommands = [ud boolForKey:@"SkyTrackAllowUnmappedCommands"];
  action = [[self alloc] init];
  
  if (allowUnmappedCommands == NO) {
    NSDictionary *commands;
    NSString     *command;
    
    commands = [ud dictionaryForKey:@"SkyTrackShellActionCommands"];
    if ((command = [commands valueForKey:[_args valueForKey:@"cmd"]]) == nil) {
      NSLog(@"%s: creation of ShellAction failed, unmapped command %@",
            __PRETTY_FUNCTION__, [_args valueForKey:@"cmd"]);
      return nil;
    }
    [action setCommandString:command];
  }
  else {
    [action setCommandString:[_args valueForKey:@"cmd"]];
  }
    
  [action setArguments:_args];
  [action setCommandArgs:[_args valueForKey:@"args"]];
  
  return AUTORELEASE(action);
}

- (void)dealloc {
  RELEASE(self->commandString);
  RELEASE(self->commandArgs);
  
  [super dealloc];
}

/* accessors */

- (NSString *)commandString {
  return self->commandString;
}
- (void)setCommandString:(NSString *)_string {
  ASSIGNCOPY(self->commandString, _string);
}

- (NSArray *)commandArgs {
  return self->commandArgs;
}
- (void)setCommandArgs:(NSArray *)_string {
  ASSIGN(self->commandArgs, _string);
}

- (id)run {
  NSTask   *task   = nil;
  NSPipe   *pipe   = nil;
  NSData   *data   = nil;
  NSString *result = nil;
  
  task = [[NSTask alloc] init];
  pipe = [NSPipe pipe];

  [task setStandardOutput:pipe];

  [task setLaunchPath:[self commandString]];
  [task setArguments:[self commandArgs]];

  [task launch];

  data = [[pipe fileHandleForReading] availableData];

  RELEASE(task); task = nil;

  result = [[NSString alloc] initWithData:data
                             encoding:[NSString defaultCStringEncoding]];

  return AUTORELEASE(result);
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@[0x%p]: cmd: %@>",
                   NSStringFromClass([self class]), self,
                   self->commandString];
}

@end /* ShellAction */
