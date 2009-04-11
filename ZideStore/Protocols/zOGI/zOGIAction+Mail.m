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

-(NSArray *)_recipientsFromId:(id)_recipientId;
{
  id              gid, tmp;
  NSString       *eN;
  NSMutableArray *r;

  gid = [self _getEOForPKey:_recipientId];
  if (gid == nil)
    return nil;
  eN = [gid entityName];
  r = [NSMutableArray arrayWithCapacity:16];
  if ([eN isEqualToString:@"Person"])
  {
    tmp = [self _getUnrenderedContactForKey:gid];
    tmp = [tmp valueForKey:@"email1"];
    if (tmp != nil)
      [r addObject:tmp];
  } else if ([eN isEqualToString:@"Team"])
    {
      id team, members, enumerator, member;

      team = [[[self getCTX] runCommand:@"team::get-by-globalid",
                                        @"gids", [NSArray arrayWithObject:gid],
                                        nil] lastObject];
      if ([team isNotNull]) {
        members = [[self getCTX] runCommand:@"team::members",
                                            @"team", team,
                                            nil];
        /* loop members */
        enumerator = [members objectEnumerator];
        while ((member = [enumerator nextObject]) != nil) 
        {
          if ([[member valueForKey:@"email1"] isNotNull])
            [r addObject:[member valueForKey:@"email1"]];
        }
      }
    }
  return r;
} /* end _recipientsFromId */

-(void)_sendNotification:(NSString *)_subject
                withBody:(NSString *)_body
                      to:(id)_recipientId
{
  NGMimeMessage       *message;
  NGMutableHashMap    *header;
  NSArray             *recipients;

  recipients = [self _recipientsFromId:_recipientId];
  if (recipients == nil)
    return;
  if ([recipients count] > 0)
  {
    header = [[[NGMutableHashMap alloc] initWithCapacity:16] autorelease];
    [header addObject:@""                   forKey:@"subject"];
    [header addObject:[NSCalendarDate date] forKey:@"date"];
    [header addObject:@"1.0"                forKey:@"MIME-Version"];
    [header addObject:@"zOGI"               forKey:@"X-Mailer"];

    message = [NGMimeMessage messageWithHeader:header];
    [message setBody:@"Yo!"];
    [[self getCTX] runCommand:@"email::deliver",
                             @"copyToSentFolder", [NSNumber numberWithBool:NO],
                             @"addresses", recipients,
                             @"mimePart", message, nil];
  }
} /* end _sendNotification */

@end /* End zOGIAction(Mail) */
