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

#include <OGoFoundation/OGoSession.h>
#include <OGoFoundation/LSWTreeState.h>
#import "common.h"

@implementation LSWTreeState

- (id)initWithObject:(id)_object pathKey:(NSString *)_pathKey {
  if ((self = [super init])) {
    NSAssert((_object  != nil), @"LSTreeState: No object set!");
    NSAssert((_pathKey != nil), @"LSTreeState: No pathKey set!");
    
    self->object = _object;
    ASSIGN(self->pathKey, _pathKey);
    
    self->map = [[NSMutableDictionary allocWithZone:[self zone]] init];
    
    self->defaultState = YES;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  // self->object is non retained
  RELEASE(self->map);
  RELEASE(self->pathKey);
  
  [super dealloc];
}
#endif

// --- accessors ----------------------------------------------------------

- (BOOL)defaultState {
  return self->defaultState;
}
- (void)setDefaultState:(BOOL)_flag {
  self->defaultState = _flag;
}

// ------------------------------------------------------------------------

- (BOOL)isExpanded {
  NSString *key   = [self currentPath];
  NSNumber *state = (key == nil) ? nil : [self->map objectForKey:key];

  return (state == nil) ? self->defaultState : [state boolValue];
}
 
- (void)setIsExpanded:(BOOL)_flag {
  NSString *key = [self currentPath];

  if (key == nil)
    NSLog(@"Warning: can not set treeState. keyPath is nil!");
  else
    [self->map setObject:[NSNumber numberWithBool:_flag] forKey:key];
}


- (NSString *)defaultName:(NSString *)_name {
  return [NSString stringWithFormat:@"%@%@", @"treeState_", _name];
}

- (NSString *)currentPath {
  return [self->object valueForKey:self->pathKey];
}

- (void)read:(NSString *)_name {
  NSString     *str;
  NSDictionary *tmp;
  
  str = [self defaultName:_name];
  tmp = [[(id)[self->object session] userDefaults] objectForKey:str];
  
  if ((tmp != nil) && [tmp isKindOfClass:[NSDictionary class]]) {
    [self->map removeAllObjects];
    [self->map addEntriesFromDictionary:tmp];
  }
}

- (void)write:(NSString *)_name {
  [self->object runCommand:@"userdefaults::write",
                  @"key",      [self defaultName:_name],
                  @"value",    self->map,
                  @"defaults", [(id)[self->object session] userDefaults], nil];
}

@end
