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
  [self->project release];
  [self->executant release];
  [self->jobName release];
  [super dealloc];
}

- (void)_validateKeysForContext:(id)_context {
  if ([self object] == nil) {
    [LSDBObjectCommandException raiseOnFail:NO object:self
                                reason:@"LSControlJobCommand: no job set!"];
  }
}  

- (void)_buildControlJobInContext:(id)_context {
  id controlJob    = nil;
  id obj           = [self object];
  id nCmd          = LSLookupCommand(@"Job", @"new");
  NSNumber *userId = [[_context valueForKey:LSAccountKey]
                                valueForKey:@"companyId"];
  
  [nCmd takeValue:LSJobProcessing                forKey:@"jobStatus"];
  [nCmd takeValue:[obj valueForKey:@"startDate"] forKey:@"startDate"];
  [nCmd takeValue:[obj valueForKey:@"endDate"]   forKey:@"endDate"];
  [nCmd takeValue:userId                         forKey:@"creatorId"];
  [nCmd takeValue:userId                         forKey:@"executantId"];
  [nCmd takeValue:[NSNumber numberWithBool:YES]  forKey:@"isControlJob"];
  [nCmd takeValue:self->project                  forKey:@"toProject"];  

  if (self->jobName == nil) { //JobName
    NSMutableString *string = [[NSMutableString allocWithZone:[self zone]]
                                                initWithString:@"Job for "];
    [string appendString:[self->executant valueForKey:@"login"]];
    [nCmd takeValue:string forKey:@"name"];
    RELEASE(string); string = nil;
  }
  else {
    [nCmd takeValue:self->jobName forKey:@"name"];    
  }

  controlJob = [nCmd runInContext:_context];

  [obj takeValue:[controlJob valueForKey:@"jobId"] forKey:@"parentJobId"];
  {
    id jCmd = LSLookupCommand(@"Job", @"jobAction");

    [jCmd takeValue:@"accept"  forKey:@"action"];
    [jCmd takeValue:controlJob forKey:@"object"];
    [jCmd runInContext:_context];
  }
  [self setReturnValue:controlJob];
}

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

- (void)_executeInContext:(id)_context {
  [self _buildControlJobInContext:_context];
  //  [super _executeInContext:_context];
}

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"project"]) {
    [self setProject:_value];
  }
  else if ([_key isEqualToString:@"executant"]) {
    [self setExecutant:_value];
  }
  else if ([_key isEqualToString:@"name"]) {
    [self setName:_value];
  }
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"project"])
    return [self project];
  else if ([_key isEqualToString:@"executant"])
    return [self executant];
  else if ([_key isEqualToString:@"name"])
    return [self name];
  else
    return [super valueForKey:_key];
}


@end
