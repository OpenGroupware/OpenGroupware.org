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

#include <OGoFoundation/OGoComponent.h>

@interface SkyImapMailPopUp : OGoComponent
{
  id       p;                  // LSWImapMails page
  int      count;              // count of new messages
  BOOL     refetchNewMessages;
  NSString *parentWindowName;
}

@end /* SkyImapMailPopUp */

#include "common.h"
#include <NGObjWeb/NGObjWeb.h>

@implementation SkyImapMailPopUp

- (id)init {
  id pa;

  if ((pa = [self persistentInstance])) {
    RELEASE(self);
    return RETAIN(pa);
  }
  
  if ((self = [super init])) {
    [self registerAsPersistentInstance];

    self->p                  = nil;
    self->count              = -1;
    self->refetchNewMessages = YES;
    self->parentWindowName   = nil;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  NSLog(@"%s dealloc of persistent instance", __PRETTY_FUNCTION__);
  RELEASE(self->p);
  RELEASE(self->parentWindowName);
  [super dealloc];
}
#endif

- (void)awake {
  self->refetchNewMessages = YES;
  [super awake];
}

- (NGImap4Context *)imapContext {
  if (self->p == nil) {
    self->p = [self pageWithName:@"LSWImapMails"];
    RETAIN(self->p);
  }
  return [self->p imapContext];
}

- (int)count {
  if (self->refetchNewMessages) {
    self->count = [[[self imapContext] inboxFolder] unseen];
    self->refetchNewMessages = NO;
  }
  return self->count;
}

- (BOOL)hasNewMessages {
  return ([self count] > 0);
}

- (NSString *)newMessagesString {
  int cnt = [self count];
  if (cnt == 0) 
    return [[self labels] valueForKey:@"label_newMail_no"];
  if (cnt == 1)
    return [[self labels] valueForKey:@"label_newMail_single"];
  return [NSString stringWithFormat:
                   [[self labels] valueForKey:@"label_newMail_multi"],
                   cnt];
}

- (NSString *)parentWindowName {
  return self->parentWindowName;
}

- (NSString *)mailDockLink {
  NSDictionary *dict;

  dict = [NSDictionary dictionaryWithObjectsAndKeys:
                       @"LSWImapMails",            @"page",
                       [[self session] sessionID], @"wosid", 
                       [[self context] contextID], @"cid",
                       nil];
  return [[self context] directActionURLForActionNamed:@"dock"
                         queryDictionary:dict];
}

/*
  - (NSString *)refreshLink {
  NSDictionary *dict =
  [NSDictionary dictionaryWithObject:[[self context] contextID]
                  forKey:@"cid"];
  return [[self context] directActionURLForActionNamed:@"viewMailsPopUp"
                         queryDictionary:dict];
}
*/

- (void)takeValue:(id)_val forKey:(id)_key {
  if ([_key isEqual:@"parentWindowName"]) {
    ASSIGN(self->parentWindowName,_val);
  }
  else
    [super takeValue:_val forKey:_key];
}

@end /* SkyImapMailPopUp */
