/*
  Copyright (C) 2006-2009 Whitemice Consulting

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

#include <NGExtensions/NGHashMap.h>
#include <NGMail/NGMimeMessage.h>
#include "zOGIAction.h"
#include "zOGIAction+Object.h"
#include "zOGIAction+Contact.h"

@implementation zOGIAction(Mail)


-(void)_send:(NSString *)_body withSubject:(NSString *)_subject
                                        to:(NSArray *)_recipients
                                 regarding:(id)_regarding
{
  NGMimeMessage       *message;
  NGMutableHashMap    *header;
  NSArray             *recipients;

  if (recipients == nil)
    return;
  [self logWithFormat:@"_sendNotification has %d recipients", [recipients count]];
  if ([recipients count] > 0)
  {
    header = [[[NGMutableHashMap alloc] initWithCapacity:16] autorelease];
    [header addObject:_subject                  forKey:@"subject"];
    [header addObject:[NSCalendarDate date]     forKey:@"date"];
    [header addObject:@"1.0"                    forKey:@"MIME-Version"];
    [header addObject:@"OpenGroupware.org/zOGI" forKey:@"X-Mailer"];
    if ([_regarding isNotNull])
      [header addObject:_regarding forKey:@"X-OpenGroupware-Regarding"];

    message = [NGMimeMessage messageWithHeader:header];
    [message setBody:_body];
    [[self getCTX] runCommand:@"email::deliver",
                             @"copyToSentFolder", [NSNumber numberWithBool:YES],
                             @"addresses", _recipients,
                             @"mimePart", message, nil];
  }
} /* end _send */



@end /* End zOGIAction(Mail) */
