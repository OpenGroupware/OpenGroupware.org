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

#include "OGoJobStatus.h"
#include "common.h"

@implementation OGoJobStatus

+ (id)jobStatusWithString:(NSString *)_status {
  return [[[self alloc] initWithString:_status] autorelease];
}
- (id)initWithString:(NSString *)_status {
  if ((self = [super init])) {
    self->status = [_status copy];
  }
  return self;
}
- (id)init {
  return [self initWithString:nil];
}

- (void)dealloc {
  [self->status release];
  [super dealloc];
}

/* accessors */

- (NSString *)statusString {
  return self->status;
}

/* current status */

- (BOOL)isArchived {
  return [self->status isEqualToString:LSJobArchived];
}
- (BOOL)isCreated {
  return [self->status isEqualToString:LSJobCreated];
}
- (BOOL)isRejected {
  return [self->status isEqualToString:LSJobRejected];
}
- (BOOL)isDone {
  return [self->status isEqualToString:LSJobDone];
}

/* possible operations */

- (BOOL)allowAcceptTransition {
  if ([self isArchived])
    return NO;
  if ([self isCreated])
    return YES;
  if ([self isRejected])
    return YES;
  
  return NO;
}

- (BOOL)allowDoneTransition {
  if ([self isArchived])
    return NO;
  if ([self isDone])
    return NO;
  
  return YES;
}

- (BOOL)allowArchiveTransition {
  return [self isArchived] ? NO : YES;
}
- (BOOL)allowAnnotateTransition {
  return [self isArchived] ? NO : YES;
}

- (BOOL)allowRejectTransition {
  if ([self isArchived])
    return NO;
  if ([self isRejected])
    return NO;
  if ([self isDone]) /* can't reject if done, right? */
    return NO;
  
  return YES;
}

- (BOOL)allowDeleteTransition {
  return [self isArchived];
}

@end /* OGoJobStatus */
