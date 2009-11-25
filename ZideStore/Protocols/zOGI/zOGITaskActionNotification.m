/*
  Copyright (C) 2009 Whitemice Consulting

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

#include "zOGITaskActionNotification.h"

@implementation zOGITaskActionNotification

-(id)initWithContext:(LSCommandContext *)_ctx
{
  self = [super initWithContext:_ctx];
  return self;
}

/* TODO: Make the template a default. */
- (void)send:(id)_task forAction:(id)_action withComment:(id)_comment
{
  id              account;
  NSString       *body; 
  NSString       *subject;
  NSMutableArray *recipients;

  self->comment = _comment;
  if ([[_task valueForKey:@"notify"] isNotNull]) {
    if ([[_task valueForKey:@"notify"] intValue] == 1)
    {
      recipients = [[NSMutableArray alloc] initWithCapacity:2];
      account = [[self ctx] valueForKey:LSAccountKey];
      if (![[account valueForKey:@"companyId"] 
              isEqualTo:[_task valueForKey:@"ownerId"]])
        [recipients addObject:[_task valueForKey:@"ownerId"]];
      [recipients addObject:[_task valueForKey:@"executantId"]];
      subject = [[NSString alloc] initWithFormat:
                    @"Task: %@ (%@)", [_task valueForKey:@"name"],
                                      _action];
      body = [[NSString alloc] initWithFormat:
        @"User \"%@\" performed action \"%@\" on task \"%@\".\n"
        @"%@\n"
        @"---\n"
        @"This is an automated notification, do not reply to this message.\n"
        @"Feedback regarding this task should be performed via task commentary.\n",
          [account valueForKey:@"login"],
          _action,
          [_task valueForKey:@"name"],
          (self->comment == nil ? ((NSString *)@"") : self->comment)];
      [self send:body    to:recipients
                    subject:subject
                  regarding:[_task valueForKey:@"jobId"]];
      [subject    release];
      [body       release];
      [recipients release];
    }
  }
} /* End send */

@end /* zOGITaskUpdateNotification */
