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

#import <LSFoundation/LSDBObjectBaseCommand.h>

@class NSArray;

@interface LSSetResourcesCommand : LSDBObjectBaseCommand
{
  NSArray *oldResources;
  NSArray *newResources;
}

@end /* LSSetResourcesCommand */

#import "common.h"

@implementation LSSetResourcesCommand

- (void)dealloc {
  [self->oldResources release];
  [self->newResources release];

  [super dealloc];
}

// command methods

- (void)_executeInContext:(id)_context {
  int            i, cnt = [self->oldResources count];
  NSMutableArray *c     = [NSMutableArray arrayWithCapacity:10];

  if (cnt > 0) {
    id <NSObject,LSCommand> cmd = nil;
    
    cmd = LSLookupCommand(@"appointmentresource", @"delete");
    
    for (i = 0; i < cnt; i++) {
      [cmd takeValue:[self->oldResources objectAtIndex:i] forKey:@"object"];
      [cmd runInContext:_context]; 
    }
  }

  cnt = [self->newResources count];

  if (cnt) {
    id <NSObject,LSCommand> cmd = nil;

    cmd = LSLookupCommand(@"appointmentresource", @"new");
    
    for (i = 0; i < cnt; i++) {
      [cmd takeValue:[self->newResources objectAtIndex:i] forKey:@"name"];
      [c addObject:[cmd runInContext:_context]];     
    }
  }
  [self setReturnValue:c];
}

// accessors

- (void)setOldResources:(NSArray *)_oldResources {
  ASSIGN(self->oldResources, _oldResources);
}
- (NSArray *)oldResources {
  return self->oldResources;
}

- (void)setNewResources:(NSArray *)_newResources {
  ASSIGN(self->newResources, _newResources);
}
- (NSArray *)newResources {
  return self->newResources;
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"oldResources"])
    [self setOldResources:_value];
  else if ([_key isEqualToString:@"newResources"])
    [self setNewResources:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"oldResources"])
    return [self oldResources];
  else if ([_key isEqualToString:@"newResources"])
    return [self newResources];

  return [super valueForKey:_key];
}

@end /* LSSetResourcesCommand */
