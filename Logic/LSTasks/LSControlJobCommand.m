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

#import <LSFoundation/LSDBObjectSetCommand.h>

// TODO: document
//       I think this is used for delegate jobs

@interface LSControlJobCommand : LSDBObjectSetCommand
{
  id project;
  id executant;
  id jobName;
}

@end

#import "common.h"

@implementation LSControlJobCommand

- (void)dealloc {
  [self->project   release];
  [self->executant release];
  [self->jobName   release];
  [super dealloc];
}

- (void)_validateKeysForContext:(id)_context {
  if ([self object] == nil) {
    [LSDBObjectCommandException raiseOnFail:NO object:self
                                reason:@"LSControlJobCommand: no job set!"];
  }
}  

- (void)_buildControlJobInContext:(id)_context {
  id<LSCommand> nCmd, jCmd;
  NSNumber      *userId;
  id controlJob;
  id obj;
  
  obj     = [self object];
  nCmd   = LSLookupCommand(@"Job", @"new");
  userId = [[_context valueForKey:LSAccountKey] valueForKey:@"companyId"];
  
  [nCmd takeValue:LSJobProcessing                forKey:@"jobStatus"];
  [nCmd takeValue:[obj valueForKey:@"startDate"] forKey:@"startDate"];
  [nCmd takeValue:[obj valueForKey:@"endDate"]   forKey:@"endDate"];
  [nCmd takeValue:userId                         forKey:@"creatorId"];
  [nCmd takeValue:userId                         forKey:@"executantId"];
  [nCmd takeValue:[NSNumber numberWithBool:YES]  forKey:@"isControlJob"];
  [nCmd takeValue:self->project                  forKey:@"toProject"];  

  if (![self->jobName isNotNull]) { //JobName
    NSMutableString *string;
    
    string = [[NSMutableString alloc] initWithString:@"Job for "];
    [string appendString:[self->executant valueForKey:@"login"]];
    [nCmd takeValue:string forKey:@"name"];
    [string release]; string = nil;
  }
  else
    [nCmd takeValue:self->jobName forKey:@"name"];    
  
  controlJob = [nCmd runInContext:_context];
  
  [obj takeValue:[controlJob valueForKey:@"jobId"] forKey:@"parentJobId"];
  
  jCmd = LSLookupCommand(@"Job", @"jobAction");
  [jCmd takeValue:@"accept"  forKey:@"action"];
  [jCmd takeValue:controlJob forKey:@"object"];
  [jCmd runInContext:_context];
  
  [self setReturnValue:controlJob];
}

/* accessors */

- (void)setProject:(id)_project {
  ASSIGN(self->project, _project);
}
- (id)project {
  return self->project;
}

- (void)setExecutant:(id)_executant {
  ASSIGN(self->executant, _executant);
}
- (id)executant {
  return self->executant;
}

- (void)setName:(id)_name {
  ASSIGN(self->jobName, _name);
}
- (id)name {
  return self->jobName;
}

/* execute */

- (void)_executeInContext:(id)_context {
  [self _buildControlJobInContext:_context];
  //  [super _executeInContext:_context];
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"project"])
    [self setProject:_value];
  else if ([_key isEqualToString:@"executant"])
    [self setExecutant:_value];
  else if ([_key isEqualToString:@"name"])
    [self setName:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"project"])
    return [self project];
  if ([_key isEqualToString:@"executant"])
    return [self executant];
  if ([_key isEqualToString:@"name"])
    return [self name];

  return [super valueForKey:_key];
}

@end /* LSControlJobCommand */
