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

#include <LSFoundation/LSDBObjectSetCommand.h>

@class NSArray;

@interface LSSetResourceCommand : LSDBObjectSetCommand
{
  NSArray *subResources;
}

@end

#include "common.h"

@implementation LSSetResourceCommand

- (void)dealloc {
  [self->subResources release];
  [super dealloc];
}

/* operation */

- (void)_prepareForExecutionInContext:(id)_context {
  [self assert:([self valueForKey:@"resourceName"] != nil)
        reason:@"No resourceName set!"];
  [self assert:([self valueForKey:@"type"] != nil)
        reason:@"No type set!"];
  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {
  id obj;
  
  obj = [self object];
  [self assert:(obj != nil) reason:@"no resource to act on!"];

  [super _executeInContext:_context];

   // if resource unit or group
  if ([[obj valueForKey:@"type"] intValue] > 1 && self->subResources != nil) {
    LSRunCommandV(_context, @"resource", @"set-subresources",
                  @"subResources", self->subResources,
                  @"object", [self object],
                  nil);
  }
}

- (NSString*)entityName {
  return @"Resource";
}

/* accessors */

- (void)setSubResources:(NSArray *)_subResources {
  ASSIGN(self->subResources, _subResources);
}
- (NSArray *)subResources {
  return self->subResources;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"subResources"]) {
    [self setSubResources:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"subResources"])
    return [self subResources];
  return [super valueForKey:_key];
}

@end /* LSSetResourceCommand */
