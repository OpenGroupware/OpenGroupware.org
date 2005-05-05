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

@interface LSSetCategoriesCommand : LSDBObjectBaseCommand
{
  NSArray *oldCategories;
  NSArray *newCategories;
}

@end /* LSSetCategoriesCommand */

#import "common.h"

@implementation LSSetCategoriesCommand

- (void)dealloc {
  [self->oldCategories release];
  [self->newCategories release];

  [super dealloc];
}

// command methods

- (void)_executeInContext:(id)_context {
  int            i, cnt = [self->oldCategories count];
  NSMutableArray *c     = [NSMutableArray arrayWithCapacity:10];

  if (cnt) {
    id <NSObject,LSCommand> cmd;

    cmd = LSLookupCommand(@"companycategory", @"delete");
    
    for (i = 0; i < cnt; i++) {
      [cmd takeValue:[self->oldCategories objectAtIndex:i] forKey:@"object"];
      [cmd runInContext:_context]; 
    }
  }

  cnt = [self->newCategories count];

  if (cnt) {
    id <NSObject,LSCommand> cmd;

    cmd = LSLookupCommand(@"companycategory", @"new");
    
    for (i = 0; i < cnt; i++) {
      [cmd takeValue:[self->newCategories objectAtIndex:i] forKey:@"category"];
      [c addObject:[cmd runInContext:_context]];     
    }
  }
  [self setReturnValue:c];
}

// accessors

- (void)setOldCategories:(NSArray *)_oldCategories {
  ASSIGN(self->oldCategories, _oldCategories);
}
- (NSArray *)oldCategories {
  return self->oldCategories;
}

- (void)setNewCategories:(NSArray *)_newCategories {
  ASSIGN(self->newCategories, _newCategories);
}
- (NSArray *)newCategories {
  return self->newCategories;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"oldCategories"])
    [self setOldCategories:_value];
  else if ([_key isEqualToString:@"newCategories"])
    [self setNewCategories:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"oldCategories"])
    return [self oldCategories];
  if ([_key isEqualToString:@"newCategories"])
    return [self newCategories];

  return [super valueForKey:_key];
}

@end /* LSSetCategoriesCommand */
