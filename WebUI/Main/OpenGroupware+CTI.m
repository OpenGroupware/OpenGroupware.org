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

#include "OpenGroupware.h"
#include "common.h"

@interface OpenGroupware(CTI)

- (id)createCTIDialer;

@end

@implementation OpenGroupware(CTI)

- (NSArray *)availableCTIDialers {
  NGBundleManager *bm;
  static NSArray *res = nil;

  if (res)
    return res;
  
  bm  = [NGBundleManager defaultBundleManager];
  res = [bm providedResourcesOfType:@"CTIDialers"];
  res = [res valueForKey:@"name"];
  
  if (res) {
    NSSet *set;
    set = [[NSSet alloc] initWithArray:res];
    res = [[set allObjects] copy];
    [set release];
  }
  else
    res = [[NSArray alloc] init];
  
  return res;
}

- (id)createCTIDialerWithName:(NSString *)_name {
  NGBundleManager *bm;
  NSBundle        *bundle;
  Class           readerClass;
  
  if (_name == nil)
    return [self createCTIDialer];
  
  if (![[self availableCTIDialers] containsObject:_name])
    return nil;
  
  bm     = [NGBundleManager defaultBundleManager];
  bundle = [bm bundleProvidingResource:_name ofType:@"CTIDialers"];
  
  if (bundle == nil)
    return nil;

  if (![bundle load]) {
    [self logWithFormat:@"WARNING: couldn't load CTI dialer bundle %@",bundle];
    return nil;
  }
  
  if ((readerClass = NSClassFromString(_name)))
    return [[[readerClass alloc] init] autorelease];
  
  [self logWithFormat:
          @"WARNING: couldn't find CTI dialer class %@ (CTI bundle=%@)",
          _name, bundle];
  
  return nil;
}

- (id)createCTIDialer {
  NSEnumerator *readers;
  NSString *readerName;
  NSString *defReader;
  id reader;

  defReader = 
    [[NSUserDefaults standardUserDefaults] stringForKey:@"CTIDialer"];
  
  if ([defReader length] > 0) {
    if ((reader = [self createCTIDialerWithName:defReader]))
      return reader;

    [self logWithFormat:
            @"could not create default CTIDialer '%@'!", defReader];
  }
  
  readers = [[self availableCTIDialers] objectEnumerator];
  
  while ((readerName = [readers nextObject])) {
    if ((reader = [self createCTIDialerWithName:readerName]))
      return reader;
  }
  return nil;
}

@end /* OpenGroupware(CTI) */
