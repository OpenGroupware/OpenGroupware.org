/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

// TODO: find out, whether this is still used!

#include <OGoFoundation/SkyWizardViewer.h>

@interface SkyWizardPersonViewer : SkyWizardViewer
@end

#include "common.h"

@implementation SkyWizardPersonViewer

- (void)buildSnapshot {
  int                 i, cnt    = 0;
  id                  obj       = nil;
  NSMutableDictionary *snap = nil;
  NSArray             *e        = nil;

  if (self->object == nil) {
    return;
  }
  obj = [self object];

  snap = [[NSMutableDictionary allocWithZone:[self zone]]
                                         initWithCapacity:64];

  e = [obj allKeys];
  
  for (i = 0, cnt = [e count]; i < cnt; i++) {
    NSString *o;

    o = [e objectAtIndex:i];

    if ([o isEqualToString:@"categories"]) {
      NSMutableString *str        = nil;
      NSEnumerator    *enumerator = nil;
      id              cat         = nil;
      BOOL            isFirst     = YES;
      
      str = [NSMutableString stringWithCapacity:64];
      enumerator = [[(NSDictionary *)obj objectForKey:o] objectEnumerator];
      isFirst = YES;
      while ((cat = [enumerator nextObject])) {
        if ([cat length] > 0) {
          if (isFirst == NO) {
            [str appendString:@" ,"];
          }
          else {
            isFirst = NO;
          }
          [str appendString:cat];
        }
      }
      if ([str length] > 0)
        [snap setObject:str forKey:o];
    }
    else if ([o isEqualToString:@"telephones"]) {
      NSEnumerator *enumerator;
      id           tel;
      
      enumerator = [[(NSDictionary *)obj objectForKey:o] objectEnumerator];
      while ((tel = [enumerator nextObject])) {
        id type   = [tel valueForKey:@"type"];
        id number = [tel valueForKey:@"number"];
        id info   = [tel valueForKey:@"info"];        

        if ([number isNotNull]) {
          if (info == nil) info = @"";
          [snap setObject:[NSString stringWithFormat:@"%@; %@", number, info]
                    forKey:type];
        }
      }
    }
    else if ([o isEqualToString:@"contact"]) {
      [snap setObject:[[obj valueForKey:@"contact"] valueForKey:@"name"]
            forKey:o];
    }
    else {
      [snap setObject:[obj valueForKey:o] forKey:o];
    }
  }
  [self setSnapshot:snap];
  [snap release];
}

@end /* SkyWizardPersonViewer */
