/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include <OGoFoundation/LSWEditorPage.h>

@class NSString, NGImap4Context, NSMutableDictionary, NSMutableArray;

@interface SkyVacationEditor : LSWEditorPage
{
  NSMutableArray      *filters;
  NSMutableDictionary *vacation;
  NSMutableDictionary *forward;
  NSString            *password;
  NSString            *storedPwd;
  NSString            *newMail;
  NSString            *newForward;
  NSMutableArray      *removedEmails;
  NSMutableArray      *removedForwards;
  id                  item;
}
- (void)_updateEmailsList;
- (void)exportFilter;
@end /* SkyVacationEditor */

#include "LSWImapMails.h"
#include "LSWImapMailFilterManager.h"
#include "common.h"
#include <NGExtensions/NSString+Ext.h>

@implementation SkyVacationEditor

- (id)init {
  if ((self = [super init])) {
    NSDictionary *account;
    
    // TODO: not such a good idea to acess the session in -init
    account = [[self session] activeAccount];
    
    [self setIsInNewMode:NO];
    self->filters     =
      [[LSWImapMailFilterManager vacationForUser:account] mutableCopy];
    self->removedEmails   = [[NSMutableArray alloc] initWithCapacity:16];
    self->removedForwards = [[NSMutableArray alloc] initWithCapacity:16];
  }
  return self;
}

- (void)dealloc {
  [self->storedPwd       release];
  [self->item            release];
  [self->filters         release];
  [self->vacation        release];
  [self->forward         release];
  [self->password        release];
  [self->newMail         release];
  [self->removedEmails   release];
  [self->newForward      release];
  [self->removedForwards release];
  [super dealloc];
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];
  [self setErrorString:nil];

  [self _updateEmailsList];
  [self->removedEmails removeAllObjects];
  
  // TODO: whats that?
  if ([[NSUserDefaults standardUserDefaults]
                       boolForKey:@"UseSkyrixLoginForImap"]) {
    self->password = [[[[self session] commandContext]
                              valueForKey:@"LSUser_P_W_D_Key"] copy];
  }
  else {
    if (self->password == nil || [self->password length] == 0) {
      self->password = [[[[self session] userDefaults]
                                stringForKey:@"imap_passwd"] copy];
    }
  }
}

- (void)syncSleep {
  [self->removedEmails removeAllObjects];
  ASSIGN(self->password, nil);
  [super syncSleep];
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  NSMutableArray      *emails;
  NSEnumerator        *enumerator;
  NSMutableDictionary *entry;
  
  ASSIGN(self->vacation, nil);
  ASSIGN(self->forward,  nil);

  enumerator = [self->filters objectEnumerator];

  while ((entry = [enumerator nextObject])) {
    if ([[entry objectForKey:@"kind"] isEqual:@"vacation"]) {
      self->vacation = entry;
    }
    else if ([[entry objectForKey:@"kind"] isEqual:@"forward"]) {
      self->forward = entry;
    }
    if (self->forward && self->vacation)
      break;
  }
  if (!self->forward) {
    self->forward = [[NSMutableDictionary alloc] initWithCapacity:1];
    [self->forward setObject:@"forward" forKey:@"kind"];
  } 
  else {
    id tmp;

    tmp = self->forward;
    self->forward = [tmp mutableCopy];
    [self->filters removeObject:tmp];
  }
  [self->filters addObject:self->forward];
  
  if (!self->vacation) {
    [self setIsInNewMode:YES];
    self->vacation    = [[NSMutableDictionary alloc] initWithCapacity:8];
    [self->vacation setObject:@"vacation" forKey:@"kind"];
  }
  else {
    id tmp;

    tmp = self->vacation;
    self->vacation = [tmp mutableCopy];
    [self->filters removeObject:tmp];
  }
  [self->filters addObject:self->vacation];


  emails = [self->forward objectForKey:@"emails"];
  if (emails)
    emails = [emails mutableCopy];
  else
    emails = [[NSMutableArray alloc] initWithCapacity:8];

  [emails autorelease];
  [self->forward setObject:emails forKey:@"emails"];
  
  emails = [self->vacation objectForKey:@"emails"];
  if (emails)
    emails = [emails mutableCopy];
  else
    emails = [[NSMutableArray alloc] initWithCapacity:8];

  [emails autorelease];
  [self->vacation setObject:emails forKey:@"emails"];
  
  if ([self isInNewMode]) {
    NSString *str;
    id       account;

    account = [[self session] activeAccount];

    str = [account valueForKey:@"email1"];

    if ([str isNotNull])
      if ([str length])
        [emails addObject:str];

    str = [account valueForKey:@"email2"];

    if ([str isNotNull])
      if ([str length])
        [emails addObject:str];

    [self->vacation setObject:@"7" forKey:@"repeatInterval"];
    [self->forward setObject:[NSNumber numberWithBool:NO]
                   forKey:@"keepMails"];
  }
  
  return YES;
}

- (BOOL)isSaveDisabled {
  return NO;
}

- (BOOL)isDeleteDisabled {
  return [self isInNewMode];
}

- (id)save {
  id l;

  l = [self labels];

  if ([self->password length] > 0) {
    ASSIGNCOPY(self->storedPwd, self->password);
  }
  ASSIGN(self->password, nil);
  
  if ([self->storedPwd length] == 0)  {
    [self setErrorString:[l valueForKey:@"missing password"]];
    return nil;
  }
  
  if (self->vacation) {
    if (![[self->vacation objectForKey:@"emails"] count]) {
      [self setErrorString:[l valueForKey:@"missing email(s)"]];
      return nil;
    }
    if ([[self->vacation objectForKey:@"repeatInterval"] intValue] < 1) {
      NSString *es;
      
      es = [l valueForKey:@"interval has to be greater then 0"];
      [self setErrorString:es];
      return nil;
    }
  }
  if (![[self->forward objectForKey:@"emails"] count]) {
    [self->filters removeObject:self->forward];
  }
  [self exportFilter];
  return nil;
}

- (id)delete {
  if ([self->password length] > 0) {
    ASSIGNCOPY(self->storedPwd, self->password);
  }
  ASSIGN(self->password, nil);
  if ([self->storedPwd length] == 0)  {
    [self setErrorString:[[self labels] valueForKey:@"missing password"]];
    return nil;
  }
  [self->filters removeObject:self->vacation];
  [self->filters removeObject:self->forward];

  [self exportFilter];
  return nil;
}

- (id)cancel {
  [self leavePage];
  return nil;
}

- (BOOL)isEditorPage {
  return YES;
}

- (void)exportFilter {
  [self setErrorString:nil];
  [LSWImapMailFilterManager writeVacation:self->filters
                            forUser:[[self session] activeAccount]];

  [LSWImapMailFilterManager exportFilterWithSession:[self session]
                            pwd:self->storedPwd page:self];
  if ([[self errorString] length] == 0) {
    [self postChange:@"LSWImapFilterChanged" onObject:nil];
    [self leavePage];
  }
}

- (NSString *)password {
  return self->password;
}
- (void)setPassword:(NSString *)_pwd {
  ASSIGN(self->password, _pwd);
}

- (BOOL)hasPassword {
  return (self->password == nil || [self->password length] == 0) ? NO : YES;
}


- (void)_updateEmailsList {
  NSMutableArray *mails;

  mails = [self->vacation objectForKey:@"emails"];

  [mails removeObjectsInArray:self->removedEmails];

  if ([self->newMail length]) {
    NSEnumerator *enumerator;
    NSString     *m;
    
    
    if ([self->newMail rangeOfString:@","].length == 0) {
      enumerator = [[NSArray arrayWithObject:self->newMail] objectEnumerator];
    }
    else {
      enumerator = [[self->newMail componentsSeparatedByString:@","]
                                   objectEnumerator];
    }
    while ((m = [enumerator nextObject])) {
      m = [m stringByTrimmingSpaces];
      
      if ([m length] == 0)
        continue;

      if (![mails containsObject:m])
        [mails addObject:m];
    }
  }
  [self->newMail release]; self->newMail = nil;
}

- (void)_updateForwardList {
  NSMutableArray *mails;

  mails = [self->forward objectForKey:@"emails"];

  [mails removeObjectsInArray:self->removedForwards];

  if ([self->newForward length] > 0) {
    NSEnumerator *enumerator;
    NSString     *m;
    
    if ([self->newForward rangeOfString:@","].length == 0) {
      enumerator = [[NSArray arrayWithObject:self->newForward]
                             objectEnumerator];
    }
    else {
      enumerator = [[self->newForward componentsSeparatedByString:@","]
                                      objectEnumerator];
    }
    while ((m = [enumerator nextObject])) {
      m = [m stringByTrimmingSpaces];
      
      if (![m length])
        continue;
      
      if (![mails containsObject:m])
        [mails addObject:m];
    }
  }
  ASSIGN(self->newForward, nil);
}


- (id)invokeActionForRequest:(WORequest *)_request inContext:(WOContext *)_ctx {
  [self _ensureSyncAwake];
  [self _updateEmailsList];
  [self _updateForwardList];

  return [super invokeActionForRequest:_request inContext:_ctx];
}


- (NSString *)newMail {
  return self->newMail;
}
- (void)setNewMail:(NSString *)_str {
  ASSIGN(self->newMail, _str);
}

- (NSString *)newForward {
  return self->newForward;
}
- (void)setNewForward:(NSString *)_str {
  ASSIGN(self->newForward, _str);
}

- (NSMutableArray *)removedEmails {
  return self->removedEmails;
}
- (void)setRemovedEmails:(NSMutableArray *)_rem {
  ASSIGN(self->removedEmails, _rem);
}
- (NSMutableArray *)removedForwards {
  return self->removedForwards;
}
- (void)setRemovedForwards:(NSMutableArray *)_rem {
  ASSIGN(self->removedForwards, _rem);
}

- (id)add {
  return nil;
}

- (id)vacation {
  return self->vacation;
}
- (id)item {
  return self->item;
}
- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}

- (id)forward {
  return self->forward;
}

@end /* SkyVacationEditor */


