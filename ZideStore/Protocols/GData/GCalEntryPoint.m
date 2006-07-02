/*
  Copyright (C) 2006 Helge Hess

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

#import <Foundation/NSObject.h>

/*
  GCalEntryPoint

    parent-folder: ZideStore
    subobjects:    one GCalCalendar

  This maps to /calendar and /calendar/feeds.

  A complete URL:
    /calendar/feeds/$USER/private/full
*/

@class GCalCalendar;

@interface GCalEntryPoint : NSObject
{
  NSString     *userName;
  GCalCalendar *calendar;
}

@end

#include "GCalCalendar.h"
#include "common.h"

@implementation GCalEntryPoint

- (void)dealloc {
  [self->calendar release];
  [self->userName release];
  [super dealloc];
}

/* lookup */

- (id)lookupName:(NSString *)_name inContext:(id)_ctx acquire:(BOOL)_flag {
  id tmp;

  if ([_name isEqualToString:@"feeds"]) {
    /* set a marker in the context to let other lookup objects know ... */
    [_ctx takeValue:[NSNumber numberWithBool:YES] forKey:@"GCalFeedLookup"];
    return self;
  }
  
  if ((tmp = [super lookupName:_name inContext:_ctx acquire:NO]) != nil)
    return tmp;

  /* lookup user */

  if (self->userName != nil) {
    if ([_name isEqual:self->userName])
      return self->calendar;

    return nil;
  }

  self->userName = [_name copy];
  [self debugWithFormat:@"tied to user: %@", self->userName];
  
  tmp = [[_ctx application] lookupName:_name inContext:_ctx acquire:NO];
  [self debugWithFormat:@"user folder: %@", tmp];
  
  if ([tmp isNotNull] && ![tmp isKindOfClass:[NSException class]]) {
    self->calendar = [[GCalCalendar alloc] initWithUserFolder:tmp];
    [self debugWithFormat:@"calendar: %@", self->calendar];
  }
  else
    self->calendar = [tmp retain];
  
  return self->calendar;
}

@end /* GCalEntryPoint */
