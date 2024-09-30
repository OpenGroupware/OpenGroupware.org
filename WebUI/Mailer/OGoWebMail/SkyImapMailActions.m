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

#include <NGObjWeb/WODirectAction.h>

@interface SkyImapMailActions : WODirectAction
@end /* SkyImapMailActions */

#include "SkyImapMailDataSource.h"
#include "SkyImapContextHandler.h"
#include "SkyImapMailListState.h"
#include "LSWImapMailViewer.h"
#include "common.h"

@implementation SkyImapMailActions

static int NGImap4_messageWithURL = -1;

+ (void)initialize {
  NGImap4_messageWithURL =
    [NGImap4Context instancesRespondToSelector:@selector(messageWithURL:)] 
    ? 1 : 0;
  if (!NGImap4_messageWithURL)
    NSLog(@"WARNING: mail DA needs NGMime version v4.2.143 or higher!");
}

- (SkyImapContextHandler *)imapCtxHandler {
  return [SkyImapContextHandler imapContextHandlerForSession:
				  [self existingSession]];
}
- (NGImap4Context *)imapContext {
  return [[self imapCtxHandler] sessionImapContext:[self existingSession]];
}

- (WOResponse *)sessionExpiredResponse {
  // TODO: DUP code to OpenGroupware.m (should be handled by NGObjWeb?)
  // TODO: it would be great if we could login and then jump to the mail
  WOResponse *r;
  NSString   *jumpTo;
  
  jumpTo = [[[self context] applicationURL] absoluteString];
  jumpTo = [[[self request] adaptorPrefix] stringByAppendingString:jumpTo];
  if (![jumpTo hasSuffix:@"/"])
    jumpTo = [jumpTo stringByAppendingString:@"/"];
  
  r = [[self context] response];
  [r setStatus:302 /* redirect */];
  [r setHeader:jumpTo forKey:@"location"];
  return [[r retain] autorelease];
}

- (id<WOActionResults>)viewImapMailAction {
  // TODO: split up this huge method
  NSString              *str, *listName, *action;
  NSURL                 *url;
  NGImap4Context        *ctx;
  NGImap4Message        *msg;
  id                    page, defs;
  SkyImapMailListState  *state;
  SkyImapMailDataSource *ds;
  BOOL                  wasUnread;
  OGoNavigation         *nav;
  
  if ([self existingSession] == nil) {
    // TODO: create session and remember the invocation?
    [self logWithFormat:@"no session or session expired"];
    return [self sessionExpiredResponse];
  }
  if (!NGImap4_messageWithURL) {
    [self logWithFormat:@"DA unavailable, update your NGMime!"];
    return nil;
  }
  
  str      = [[self request] formValueForKey:@"url"];
  listName = [[self request] formValueForKey:@"listName"];

  action = [[self request] formValueForKey:@"action"];
  
  if ([listName length] == 0)
    listName = @"MailList";
  if ([str length] == 0)
    return nil;

  url = [NSURL URLWithString:str];
  
  if ((ctx = [self imapContext]) == nil) {
    [self logWithFormat:@"missing imapHandler"];
    return nil;
  }
  
  // TODO: interesting, document somehow ;-)
  if ((msg = [ctx messageWithURL:url]) == nil) {
    [self logWithFormat:@"missing message for url: '%@'", str];
    return nil;
  }
  
  if ([action length] > 0) {
    if ([action isEqualToString:@"markFlagged"])
      [msg markFlagged];
    else if ([action isEqualToString:@"markUnFlagged"])
      [msg markUnFlagged];
  }
  
  ds = [[SkyImapContextHandler sharedImapContextHandler]
	 mailDataSourceWithSession:[self session]
	 folder:[msg folder]];
  
  if (ds == nil)
    ds = [[[SkyImapMailDataSource alloc] init] autorelease];
  
  if (![[ds folder] isEqual:[msg folder]])
    [ds setFolder:[msg folder]];
  
  defs  = [[self session] userDefaults];
  state = [[[SkyImapMailListState  alloc] initWithDefaults:defs] autorelease];
  [state setName:listName];
  [state setFolder:[msg folder]];

  {
    EOSortOrdering *so;
    SEL            sel;

    sel     = ([state isDescending])
      ? EOCompareDescending : EOCompareAscending;
    so      = [EOSortOrdering sortOrderingWithKey:[state sortedKey]
                              selector:sel];

    if ([state sortedKey]) {
      EOFetchSpecification *fetchSpec;

      if ((fetchSpec = [ds fetchSpecification]) == nil) {
        fetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:nil
                                          qualifier:nil
                                          sortOrderings:
                                          [NSArray arrayWithObject:so]];
        [ds setFetchSpecification:fetchSpec];
      }
      else {
        NSArray *sos;

        sos = [NSArray arrayWithObject:so];
      
        if (![[fetchSpec sortOrderings] isEqual:sos]) {
          [fetchSpec setSortOrderings:[NSArray arrayWithObject:so]];
          [ds setFetchSpecification:fetchSpec];
        }
      }
#if 0 // TODO: why is that commented out?
      [(SkyImapMailDataSource *)self->dataSource
                                preFetchMessagesInRange:
                                NSMakeRange([self->state blockSize]
                                            * ([self->state currentBatch]-1),
                                            [self->state blockSize])];

#endif
    }
  }
  wasUnread = ![msg isRead];

  if (![msg isRead]) {
    [msg markRead];
    [[NSNotificationCenter defaultCenter]
                           postNotificationName:@"LSWImapMailFlagsChanged"
                           object:msg];
  }
  
  nav  = [[self session] navigation];
  
  if ([[nav activePage] isKindOfClass:[LSWImapMailViewer class]])
    [nav leavePage];
  
  page = [nav activateObject:msg withVerb:@"view"];
  
  if (state) [page takeValue:state forKey:@"state"];
  [page takeValue:[NSNumber numberWithBool:wasUnread] 
	forKey:@"messageWasUnread"];
  [page takeValue:ds forKey:@"mailDS"];
  
  return page;
}

@end /* SkyImapMailActions */
