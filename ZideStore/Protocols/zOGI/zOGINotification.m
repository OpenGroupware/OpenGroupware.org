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

#include <NGExtensions/NGHashMap.h>
#include <NGMail/NGMimeMessage.h>
#include "zOGINotification.h"

@implementation zOGINotification

-(id)initWithContext:(LSCommandContext *)_context 
{
  [super init];
  self->ctx = _context;
  return self;
}

-(LSCommandContext *)ctx
{
  return self->ctx;
}

-(NSArray *)_recipientsFromId:(id)_recipientId;
{
  id              gid, tmp;
  NSMutableArray *r;

  if ([self ctx] == nil)
    [self logWithFormat:@"NULL Command Context!!!"];
  gid = [[[self ctx] typeManager] globalIDForPrimaryKey:_recipientId];
  if (gid == nil)
  {
    [self logWithFormat:@"Got no EOGlobalID for key: %@", _recipientId];
    return nil;
  }
  r = [NSMutableArray arrayWithCapacity:16];
  if ([[gid entityName] isEqualToString:@"Person"])
  {
    tmp = [[[self ctx] runCommand:@"person::get-by-globalid",
                                 @"gids", [NSArray arrayWithObject:gid],
                                 nil] lastObject];
    tmp = [tmp valueForKey:@"email1"];
    if (tmp != nil)
      [r addObject:tmp];
  } else if ([[gid entityName] isEqualToString:@"Team"])
    {
      id team, members, enumerator, member;

      team = [[[self ctx] runCommand:@"team::get-by-globalid",
                                    @"gids", [NSArray arrayWithObject:gid],
                                    nil] lastObject];
      if ([team isNotNull]) {
        members = [[self ctx] runCommand:@"team::members",
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

-(NSArray *)_recipientsFromIds:(id)_recipients
{
  NSMutableArray *r;
  id            tmp;

  r = nil;
  if ([_recipients isNotNull])
  {
    r = [NSMutableArray arrayWithCapacity:16];
    if ([_recipients isKindOfClass:[NSArray class]])
    {
      NSEnumerator *enumerator;

      enumerator = [_recipients objectEnumerator];
      while ((tmp = [enumerator nextObject]) != nil)
        if ([tmp isNotNull])
          [r addObjectsFromArray:[self _recipientsFromId:tmp]];
    } else
      {
        tmp = [self _recipientsFromId:_recipients];
        if ([tmp isNotNull])
          [r addObjectsFromArray:tmp];
      }
  }
  return r;
}

/* accessors */

- (NSString *)dateFormat { return @"%Y-%m-%d %H:%M (%Z)"; }
- (NSString *)timeFormat { return @"%Y-%m-%d"; }

- (NSString *)actorName 
{
   id account;
   NSString *label;

   account = [self->ctx valueForKey:LSAccountKey];
   if ([[account valueForKey:@"email1"] isNotNull])
   {
     label = [NSString stringWithFormat:@"%@, %@ <%@>",
                         [account valueForKey:@"name"],
                         [account valueForKey:@"firstname"],
                         [account valueForKey:@"email1"]];
   } else label = [account valueForKey:@"login"];
   return label;
}

- (void)send:(NSString *)_body to:(NSArray *)_recipients 
                          subject:(NSString *)_subject 
                        regarding:(id)_regarding
{
  NGMimeMessage       *message;
  NGMutableHashMap    *header;
  NSArray             *recipients;

  recipients = [self _recipientsFromIds:_recipients];
  if (recipients == nil)
    return;
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
    [self->ctx runCommand:@"email::deliver",
                           @"copyToSentFolder", [NSNumber numberWithBool:YES],
                           @"addresses", recipients,
                           @"mimePart", message, nil];
  }
}

@end /* zOGINotification */

