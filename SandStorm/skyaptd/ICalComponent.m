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

#include "ICalComponent.h"
#include "common.h"

@implementation ICalComponent

- (NSArray *)subComponents {
  return nil;
}

- (NSString *)externalName {
  return [self subclassResponsibility:_cmd];
}

/* description */

- (NSString *)icalStringForProperties {
  return @"";
}

- (NSString *)icalString {
  NSMutableString *ms;
  NSEnumerator  *e;
  ICalComponent *c;
  
  ms = [NSMutableString stringWithCapacity:256];

  /* open tag */
  [ms appendString:@"BEGIN:"];
  [ms appendString:[self externalName]];
  [ms appendString:@"\r\n"];

  /* add properties */
  [ms appendString:[self icalStringForProperties]];
  
  /* add subcomponents */
  e = [[self subComponents] objectEnumerator];
  while ((c = [e nextObject])) {
    NSString *s;

    s = [c icalString];
    if (s) [ms appendString:s];
  }
  
  /* close tag */
  [ms appendString:@"END:"];
  [ms appendString:[self externalName]];
  [ms appendString:@"\r\n"];
  
  return ms;
}

@end /* ICalComponent */
