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

#include "common.h"
#include <OGoFoundation/LSWNotifications.h>

@interface LSWImapMail2Project : LSWContentPage
{
  NSArray        *messages;
  NGImap4Message *message;
  id             project;
}
@end


@implementation LSWImapMail2Project

- (id)init {
  if ((self = [super init])) {
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  [super dealloc];
}
#endif

- (NSArray *)messages {
  return self->messages;
}
- (void)setMessages:(NSArray *)_mes {
  ASSIGN(self->messages, _mes);
}

- (id)message {
  return self->message;
}
- (void)setMessage:(id)_mes {
  ASSIGN(self->message, _mes);
}

- (id)project {
  return self->project;
}
- (void)setProject:(id)_pro {
  ASSIGN(self->project, _pro);
}

- (id)copy {
  if ((self->project == nil) || ([EONull null] == self->project))
    return nil;

  [self runCommand:@"email::new",
        @"mimePart", [self->message message],
        @"projectId", [self->project valueForKey:@"projectId"],
        @"owner", [[self session] activeAccount],
        nil];
  [self leavePage];
  return nil;
}

- (id)cancel {
  [self leavePage];
  return nil;
};

@end

