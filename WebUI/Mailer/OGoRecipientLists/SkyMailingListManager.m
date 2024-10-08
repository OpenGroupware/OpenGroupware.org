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

#include "common.h"
#include "SkyMailingListManager.h"

@implementation SkyMailingListManager

- (id)initWithContext:(id)_ctx {
  if ((self = [super init])) {
    self->context = [_ctx retain];
  }
  return self;
}

- (void)dealloc {
  [self->context release];
  [self->path    release];
  [super dealloc];
}

/* accessors */

- (NSString *)path {
  if (self->path == nil) {
    self->path = [[[[[self->context valueForKey:LSAccountKey]
                                    valueForKey:@"companyId"]
                                    stringValue]
                                    stringByAppendingPathExtension:
                                    @"mailingListManager"] copy];
  }
  return self->path;
}

- (NSArray *)mailingLists {
  NSFileManager *fm;

  fm = [NSFileManager defaultManager];

  if ([fm fileExistsAtPath:[self path]])
    return [NSArray arrayWithContentsOfFile:self->path];
  else
    return [NSArray array];
}

- (BOOL)writeMailingLists:(NSArray *)_lists {
  return [_lists writeToFile:[self path] atomically:YES];
}

@end /* SkyMailingListManager */
