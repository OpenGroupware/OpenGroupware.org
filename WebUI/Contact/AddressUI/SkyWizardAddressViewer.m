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

#include <OGoFoundation/SkyWizardViewer.h>

@interface SkyWizardAddressViewer : SkyWizardViewer
@end

#include "common.h"

@implementation SkyWizardAddressViewer

- (void)buildSnapshot {
  int                 i, cnt = 0;
  NSDictionary        *obj;
  NSMutableDictionary *snap;
  NSArray             *e;
  
  if (self->object == nil)
    return;
  
  obj  = [self object];
  snap = [[NSMutableDictionary alloc] initWithCapacity:64];
  e    = [obj allKeys];
  
  for (i = 0, cnt = [e count]; i < cnt; i++) {
    NSString *o;
    
    o = [e objectAtIndex:i];
    
    if ([o isEqualToString:@"telephones"]) {
      NSEnumerator *enumerator = nil;
      id           tel           = nil;
      
      enumerator = [[obj objectForKey:o] objectEnumerator];
      while ((tel = [enumerator nextObject])) {
        NSString *type, *number, *info;
        
        number = [tel valueForKey:@"number"];
        if (![number isNotNull])
          continue;

        type = [tel valueForKey:@"type"];
        info = [tel valueForKey:@"info"];        
        
        if (![info isNotNull]) info = @"";
        info = [info length] > 0
          ? [[NSString alloc] initWithFormat:@"%@; %@", number, info]
          : [number copy];
        [snap setObject:info forKey:type];
        [info release];
      }
    }
    else {
      [snap setObject:[obj objectForKey:o] forKey:o];
    }
  }
  [self setSnapshot:snap];
  [snap release];
}

@end /* SkyWizardAddressViewer */
