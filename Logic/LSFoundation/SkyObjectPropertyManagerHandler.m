/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include "SkyObjectPropertyManagerHandler.h"
#include "SkyObjectPropertyManager+Internals.h"
#include "common.h"
#include <LSFoundation/SkyObjectPropertyManager.h>

@implementation SkyObjectPropertyManagerHandler

- (id)init {
  if ((self = [super init])) {
#if !ENABLE_NC_REGISTRATION
    NSNotificationCenter *nc = nil;
#endif
    
    self->managers = [[NSMutableArray alloc] initWithCapacity:16];
#if !ENABLE_NC_REGISTRATION
    // hh asks: why commented out?
    nc             = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(globalIDWasCopied:)
	name:SkyGlobalIDWasCopied object:nil];
    [nc addObserver:self selector:@selector(globalIDWasDeleted:)
	name:SkyGlobalIDWasDeleted object:nil];
#endif
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->managers release];
  [super dealloc];
}

/* notifications */

- (void)globalIDWasDeleted:(NSNotification *)_obj {
  if ([self->managers count] == 0)
    return;
  
  [[self->managers lastObject] removeAllPropertiesForGlobalID:[_obj object]];
}

- (void)globalIDWasCopied:(NSNotification *)_obj {
  SkyObjectPropertyManager *manager;
  NSMutableDictionary      *keys, *mdict;
  NGHashMap                *access;
  id                       source, dest, obj;
  NSEnumerator             *enumerator;
  
  if ([self->managers count] == 0)
    return;
  
  source     = [(NSDictionary *)[_obj object] objectForKey:@"source"];
  dest       = [(NSDictionary *)[_obj object] objectForKey:@"destination"];
  manager    = [self->managers lastObject];
  keys       = [[manager propertiesForGlobalID:source] mutableCopy];
  access     = [[[manager _accessOIDsForGIDs:[NSArray arrayWithObject:source]]
                          objectEnumerator] nextObject];
  enumerator = [access keyEnumerator];
  mdict      = nil;
    
  while ((obj = [enumerator nextObject])) {
      NSEnumerator *props;
      NSDictionary *dict;
      id           prop;

      if (mdict == nil)
        mdict = [[NSMutableDictionary alloc] init];
      else
        [mdict removeAllObjects];
      
      props = [[access objectsForKey:obj] objectEnumerator];
      
      while ((prop = [props nextObject])) {
        [mdict setObject:[keys objectForKey:prop] forKey:prop];
        [keys removeObjectForKey:prop];
      }
      dict = [mdict copy];
      [manager addProperties:dict accessOID:obj globalID:dest];
      [dict release]; dict = nil;
  }
  if ([keys count] > 0)
    [manager addProperties:keys accessOID:nil globalID:dest];
    
  [keys  release]; keys  = nil;
  [mdict release]; mdict = nil;
}

- (void)addManager:(SkyObjectPropertyManager *)_ds {
  [self->managers addObject:_ds];
}
- (void)removeManager:(SkyObjectPropertyManager *)_ds {
  [self->managers removeObject:_ds];
}

@end /* SkyObjectPropertyManagerHandler */
