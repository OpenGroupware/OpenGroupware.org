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

#include "LSWImapDockView.h"
#include "common.h"

#include <NGObjWeb/WOContext.h>

//#warning includes other bundle header - to be fixed !!!
//#include "../LSWImapMail/Headers/SkyImapMailListState.h"

@interface NSObject(LSWImapDockView_PRIVATE)
- (void)initializeImap;
- (id)initWithDefaults:(id)_defs;
- (NGImap4Folder *)selectedFolder;
+ (NGImap4Context *)sessionImapContext:(id)_ses;
- (void)setName:(id)_n;
@end

@interface SkyImapMailPanelDataSource : EODataSource
{
  NSArray *messages;
  NSArray *sortOrderings;
}
- (void)setMessages:(NSArray *)_messages;
@end

@implementation LSWImapDockView

+ (int)version {
  return 1;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (id)init {
  id pa;

  /* this component is a session-singleton */
  
  if ((pa = [self persistentInstance])) {
    [self release];
    return [pa retain];
  }

  if ((self = [super init])) {
    NSUserDefaults *d = (NSUserDefaults *)[[self session] userDefaults];
    NSZone         *z = [self zone];
    
    /* register as persistent component */
    [self registerAsPersistentInstance];

    self->dataSource  = [[SkyImapMailPanelDataSource allocWithZone:z] init];
    self->state       = [[NSClassFromString(@"SkyImapMailListState")
                                           allocWithZone:z]
 initWithDefaults:d];
    [(NSObject *)self->state setName:@"PanelMailList"];
    self->newMessages = NO;
    self->showPopUp   = NO;
    self->popUpShown  = NO;
    self->count       = 0;
    self->hideLink    = NO;
    self->hideAll     = NO;

    self->initializeImap = YES;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->state);
  RELEASE(self->dataSource);
  [super dealloc];
}
#endif

- (void)awake {
  self->refetchNewMessages = YES;
  [super awake];
}
- (void)sleep {
  [super sleep];
  self->popUpShown  = self->showPopUp;
}

- (void)setHideLink:(BOOL)_flag {
  self->hideLink = _flag;
}
- (BOOL)hideLink {
  return self->hideLink;
}
- (void)setHideAll:(BOOL)_flag {
  self->hideAll = _flag;
}
- (BOOL)hideAll {
  return self->hideAll;
}

- (NGImap4Context *)imapContext {
  if (self->initializeImap) {
    [[self pageWithName:@"LSWImapMails"] initializeImap];
    self->initializeImap = NO;
  }
  
  return [NSClassFromString(@"SkyImapContextHandler")
                           sessionImapContext:[self session]];
}


- (BOOL)hasNewMessages {
  if (self->refetchNewMessages == YES) {
    BOOL    mainMailPageShowsInbox = NO;
    id      imapCtx;

    BOOL panelIfNewMails;
    BOOL popupIfNewMails;

    imapCtx         = [self imapContext];
    panelIfNewMails = [[[self session] userDefaults]
                              boolForKey:@"panelIfNewMails"];
    popupIfNewMails = [[[self session] userDefaults]
                              boolForKey:@"popupIfNewMails"];
  

    if (imapCtx != nil) self->refetchNewMessages = NO;

    if (panelIfNewMails) {
      NSArray *mails;
      int cnt;

      mails       = [imapCtx newMessages];
      cnt         = [mails count];
      if (cnt > self->count)
        // force popup if new message received
        self->popUpShown = NO;
      self->count = cnt;
        
      if ([[[self pageWithName:@"LSWImapMails"] selectedFolder]
                  isEqual:[imapCtx inboxFolder]])
        mainMailPageShowsInbox = YES;
      
      self->newMessages = ([mails count] > 0);
      if (self->newMessages && !mainMailPageShowsInbox) {
        self->showPanel = YES;
        [self->dataSource setMessages:mails];
      }

      self->showPopUp = (popupIfNewMails
                         && self->newMessages
                         && (self->count > 0));
    }
    else {
      int cnt;
      self->newMessages = [imapCtx hasNewMessages];
      self->showPanel   = NO;
      
      cnt = [[imapCtx inboxFolder] unseen];
      if (cnt > self->count)
        // force popup if new message received
        self->popUpShown = NO;
      self->count       = cnt;
      
      self->showPopUp = (popupIfNewMails
                         && self->newMessages
                         && (self->count > 0));
    }
  }
  return self->newMessages;
}

- (BOOL)isInactive {
  return ([self imapContext] == nil) ? YES : NO;
}

- (int)imageBorder {
  return [self hasNewMessages] ? 1 : 0;
}

- (SkyImapMailPanelDataSource *)dataSource {
  return self->dataSource;
}
- (id /*SkyImapMailListState * */)state {
  return self->state;
}

- (void)setShowPanel:(BOOL)_showPanel {
  self->showPanel = _showPanel;
}
- (BOOL)showPanel {
  [self hasNewMessages];
  return self->showPanel;
}

- (BOOL)showPopUp {
  [self hasNewMessages];
  if (self->popUpShown) return NO;
  return self->showPopUp;
}

- (NSString *)popupLink {
  NSDictionary *dict;

  dict = [NSDictionary dictionaryWithObjectsAndKeys:
                       [[self context] contextID], @"cid",
                       [[self session] sessionID], @"wosid", nil];

  /* warning: 'viewMailsPopUp' const also used in Skyrix.m */
  return [[self context] directActionURLForActionNamed:@"viewMailsPopUp"
                         queryDictionary:dict];
}

- (int)newMailsCount {
  return self->count;
}

- (NSString *)newMailLabel {
  NSString *l;

  l = ([self newMailsCount] == 1)
    ? [[self labels] valueForKey:@"label_newMail_single"]
    : [[self labels] valueForKey:@"label_newMail_multi"];

  if ([self newMailsCount] != 1)
    l = [NSString stringWithFormat:l, [self newMailsCount]];
  
  if ([l rangeOfString:@"\n"].length > 0) {
    l = [[l componentsSeparatedByString:@"\n"]
            componentsJoinedByString:@"\\n"];
  }
  if ([l rangeOfString:@"\""].length > 0) {
    l = [[l componentsSeparatedByString:@"\""]
            componentsJoinedByString:@"'"];
  }
  return l;
}

@end /* LSWImapDockView */

@implementation SkyImapMailPanelDataSource

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->messages);
  RELEASE(self->sortOrderings);
  [super dealloc];
}
#endif

- (NSArray *)fetchObjects {
  return self->messages;
}

- (void)setMessages:(NSArray *)_messages {
  ASSIGN(self->messages, _messages);

  [[NSNotificationCenter defaultCenter]
                         postNotificationName:EODataSourceDidChangeNotification
                         object:self];
}

- (void)setFetchSpecification:(EOFetchSpecification *)_fetchSpec {
  NSArray *so;

  so = [_fetchSpec sortOrderings];
  ASSIGN(self->sortOrderings, so);
}

- (EOFetchSpecification *)fetchSpecification {
  EOFetchSpecification *fetchSpec;

  fetchSpec = [[EOFetchSpecification alloc] init];
  [fetchSpec setSortOrderings:self->sortOrderings];

  return AUTORELEASE(fetchSpec);
}

@end
