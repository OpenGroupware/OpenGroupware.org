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
// Created by Helge Hess on Sat Feb 02 2002.

#include "TaskComponent.h"
#include "TaskMethod.h"
#include "common.h"

@implementation TaskComponent

- (id)initWithName:(NSString *)_m config:(NSDictionary *)_dict {
  NSEnumerator *e;
  NSMutableDictionary *md;
  NSDictionary *d;
  NSString     *key;
  
  self->componentName = [_m copy];
  
  /* collect methods */
  md = [NSMutableDictionary dictionaryWithCapacity:64];
  e  = [(d = [_dict objectForKey:@"methods"]) keyEnumerator];
  while ((key = [e nextObject])) {
    TaskMethod *m;
    
    m = [[TaskMethod alloc] initWithMethodName:key
                            config:[d objectForKey:key]];
    if (m == nil)
      continue;

    [md setObject:m forKey:key];
    RELEASE(m);
  }
  self->methods = [md copy];
  
  return self;
}

- (void)dealloc {
  RELEASE(self->componentName);
  RELEASE(self->methods);
  [super dealloc];
}

/* accessors */

- (NSString *)componentName {
  return self->componentName;
}

/* dispatcher */

- (id)doesNotProvideMethodNamed:(NSString *)_name {
  NSLog(@"component %@: does not provide method %@", self, _name);
  return nil;
}

- (id)callMethodNamed:(NSString *)_method parameters:(NSArray *)_ps {
  TaskMethod *m;
  
  if ((m = [self->methods objectForKey:_method]) == nil)
    return [self doesNotProvideMethodNamed:_method];
  
  return [m callMethodNamed:_method parameters:_ps];
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:@"<0x%08X[%@]: %@>",
                     self, NSStringFromClass([self class]),
                     [self componentName]];
}

@end /* TaskComponent */
