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

#include "Session.h"
#include <SxComponents/SxComponentRegistry.h>
#include "common.h"

@implementation Session

- (id)init {
  if ((self = [super init])) {
    /* do not use default registry, since credentials are shared ! */
    self->registry = [[SxComponentRegistry alloc] init];
    
    self->relatedMethodCache =
      [[NSMutableDictionary alloc] initWithCapacity:64];
  }
  return self;
}
- (void)dealloc {
  RELEASE(self->relatedMethodCache);
  RELEASE(self->registry);
  [super dealloc];
}

/* accessors */

- (SxComponentRegistry *)registry {
  return self->registry;
}

/* related method cache */

- (NSArray *)cachedRelatedMethodsForComponent:(SxComponent *)_component
  valueType:(NSString *)_vtype
{
  NSString *key;
  
  if (_component == nil) return nil;
  if ([_vtype length] == 0) return nil;
  
  key = [NSString stringWithFormat:@"%@\n%@",
                    [_component componentName],
                    _vtype];
  return [self->relatedMethodCache objectForKey:key];
}

- (void)cacheRelatedMethods:(NSArray *)_methods
  forComponent:(SxComponent *)_component
  andType:(NSString *)_vtype
{
  NSString *key;
  
  if (_methods   == nil) return;
  if (_component == nil) return;
  if (_vtype     == nil) return;
  
  key = [NSString stringWithFormat:@"%@\n%@",
                    [_component componentName],
                    _vtype];
  [self->relatedMethodCache setObject:_methods forKey:key];
}

@end /* Session */
