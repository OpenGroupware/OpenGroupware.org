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

#include <OGoFoundation/OGoContentPage.h>

@class NSArray;
@class NGImap4Message;

@interface LSWImapMail2Project : OGoContentPage
{
  NSArray        *messages;
  NGImap4Message *message;
  id             project;
}
@end

#include "common.h"
#include <OGoFoundation/LSWNotifications.h>

@implementation LSWImapMail2Project

- (void)dealloc {
  [self->messages release];
  [self->message  release];
  [self->project  release];
  [super dealloc];
}

/* accessors */

- (void)setMessages:(NSArray *)_mes {
  ASSIGN(self->messages, _mes);
}
- (NSArray *)messages {
  return self->messages;
}

- (void)setMessage:(id)_mes {
  ASSIGN(self->message, _mes);
}
- (id)message {
  return self->message;
}

- (void)setProject:(id)_pro {
  ASSIGN(self->project, _pro);
}
- (id)project {
  return self->project;
}

/* actions */

- (id)copy {
  if ((self->project == nil) || ![self->project isNotNull])
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
  return nil; // TODO: shouldn't we return the result of -leavePage?
}

@end /* LSWImapMail2Project */
