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

#include "zOGITaskUpdateNotification.h"

@implementation zOGITaskUpdateNotification

-(id)initWithContext:(LSCommandContext *)_ctx
{
  self = [super initWithContext:_ctx];
  return self;
}

/* TODO: Make the template a default. */
- (void)send:(id)_task
{
  NSString       *subject;
  NSString       *body;
  NSString       *kind;
  NSMutableArray *recipients;
  id              account;

  recipients = [[NSMutableArray alloc] initWithCapacity:2];
  account = [[self ctx] valueForKey:LSAccountKey];
  if (![[account valueForKey:@"companyId"]
           isEqualTo:[_task valueForKey:@"ownerId"]])
    [recipients addObject:[_task valueForKey:@"ownerId"]];
  [recipients addObject:[_task valueForKey:@"executantId"]];
  subject = [[NSString alloc] initWithFormat:@"Task Modified: %@", [_task valueForKey:@"name"]];
  if ([[_task valueForKey:@"kind"] isNotNull])
    kind = [_task valueForKey:@"kind"];
  else kind = @"Generic";
  body = [[NSMutableString alloc] initWithFormat:
             @"Name:     %@\n"
             @"Start:    %@\n"
             @"Due:      %@\n"
             @"Owner:    %@\n"
             @"Executor: %@\n"
             @"Project:  %@\n"
             @"Kind:     %@\n"
             @"%@\n"
             @"---\n"
             @"This is an automated notification, do not reply to this message.\n"
             @"Feedback regarding this task should be performed via task commentary.\n",
               [_task valueForKey:@"name"],
               [[_task valueForKey:@"startDate"] descriptionWithCalendarFormat:DATEFORMAT],
               [[_task valueForKey:@"endDate"] descriptionWithCalendarFormat:DATEFORMAT],
               [self ownerName:_task],
               [self executorName:_task],
               [self projectName:_task],
               kind,
               [_task valueForKey:@"comment"]];
  [self send:body to:recipients
              subject:subject
            regarding:[_task valueForKey:@"jobId"]];
  [subject    release];
  [body       release];
  [recipients release];
}

@end /* zOGITaskUpdateNotification */
