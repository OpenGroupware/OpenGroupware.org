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

#include "SkyImapMailListState.h"
#import "common.h"

@interface SkyImapMailListState(PrivateMethodes)
- (NSString *)_:(NSString *)_key;
@end;

/* self->name should be
     "SearchMailList",
     "SentMailList",
     "MailList" or
     "PanelMailList"
*/

static NSString *MailList             = @"MailList";
static NSString *SearchMailList       = @"SearchMailList";
static NSString *PanelMailList        = @"PanelMailList";

static NSString *BlockSize            = @"BlockSize";
static NSString *ShowMessages         = @"ShowMessages";
static NSString *SortHeader           = @"SortHeader";
static NSString *SortOrder            = @"SortOrder";
static NSString *Attributes           = @"Attributes";
static NSString *MailSubjectLength    = @"mail_subjectLength";
static NSString *MailSenderLength     = @"mail_senderLength";
static NSString *DoClientScroll       = @"MailListDoClientSideScroll";
static NSString *ClientScrollTreshold = @"MailListClientSideScrollTreshold";

@implementation SkyImapMailListState

- (id)initWithDefaults:(NSUserDefaults *)_ud {
  if ((self = [super init])) {
    NSAssert((_ud != nil), @"SkyImapMailListState: no userDefaults set!");

    ASSIGN(self->defaults, _ud);
    self->currentBatch    = 1;
    self->showAllMessages = 0;
  }
  return self;
}

- (id)init {
  NSLog(@"SkyImapMailListState: use -initWithDefaults: instead!");
  return [self initWithDefaults:nil];
}

- (void)dealloc {
  [self->defaults release];
  [self->folder   release];
  [self->name     release];
  [super dealloc];
}

/* accessors */

- (void)setName:(NSString *)_name {
  ASSIGN(self->name, _name);
}
- (NSString *)name {
  return self->name;
}

- (void)setFolder:(NGImap4Folder *)_folder {
  ASSIGN(self->folder, _folder);
}
- (NGImap4Folder *)folder {
  return self->folder;
}

/* properties of SkyImapMailList */

- (BOOL)showAll {
  if (self->showAllMessages == 1)
    return YES;
  if (self->showAllMessages == -1)
    return NO;

  return [[self showMessages] isEqualToString:@"all"];
}

- (BOOL)showUnread {
  if (self->showAllMessages == -1)
    return YES;
  if (self->showAllMessages == 1)
    return NO;

  return [[self showMessages] isEqualToString:@"unread"];
}

- (BOOL)showFlagged {
  if (self->showAllMessages == 0)
    return [[self showMessages] isEqualToString:@"flagged"];

  return NO;
}

- (BOOL)isShowFilterButtons {
  if ([self->name isEqualToString:SearchMailList])
    return NO;
  if ([self->name isEqualToString:PanelMailList])
    return NO;

  return YES;
}

- (BOOL)isShowMailButtons {
  return (![self->name isEqualToString:PanelMailList]);
}

- (void)setCurrentBatch:(unsigned)_currentBatch {
  self->currentBatch = _currentBatch;
}
- (unsigned)currentBatch {
  return self->currentBatch;
}

// show all messages without writing defaults
- (int)showAllMessages {
  return self->showAllMessages;
}
- (void)setShowAllMessages:(int)_showAllMessages {
  self->showAllMessages = _showAllMessages;
}

/* values of preferences */

- (NSString *)_sortOrderKey {
  if ([self->name isEqualToString:SearchMailList])
    return [SearchMailList stringByAppendingString:SortOrder];
  if ([self->name isEqualToString:PanelMailList])
    return [PanelMailList stringByAppendingString:SortOrder];

  return [[MailList stringByAppendingString:SortOrder]
                    stringByAppendingString:[self->folder absoluteName]];
}

- (NSString *)_sortHeaderKey {
  if ([self->name isEqualToString:SearchMailList])
    return [SearchMailList stringByAppendingString:SortHeader];
  if ([self->name isEqualToString:PanelMailList])
    return [PanelMailList stringByAppendingString:SortHeader];

  return  [[MailList stringByAppendingString:SortHeader]
                     stringByAppendingString:[self->folder absoluteName]];
}

- (void)setIsDescending:(BOOL)_flag {
  [self->defaults setBool:_flag forKey:[self _sortOrderKey]];
}
- (BOOL)isDescending {
  NSString *key;

  key = [self _sortOrderKey];
  if ([self->defaults objectForKey:key] == nil) {
    [self->defaults setBool:YES forKey:key];
    return YES;
  }
  return [self->defaults boolForKey:key];
}

- (void)setSortedKey:(NSString *)_sortedKey {
  [self->defaults setObject:_sortedKey forKey:[self _sortHeaderKey]];
}
- (NSString *)sortedKey {
  NSString *tmp;

  if ((tmp = [self->defaults stringForKey:[self _sortHeaderKey]]))
    return tmp;
  
  if ([[self attributes] containsObject:@"sendDate"])
    return @"sendDate";
  
  return nil;
}

- (int)subjectLength {
  return [self->defaults integerForKey:MailSubjectLength];
}
- (int)senderLength {
  return [self->defaults integerForKey:MailSenderLength];
}

- (NSArray *)attributes {
  NSString *key = [self->name stringByAppendingString:Attributes];
  return [self->defaults stringArrayForKey:key];
}
- (void)attributes:(NSArray *)_shownAttributes {
  NSString *key = [self->name stringByAppendingString:Attributes];
  [self->defaults setObject:_shownAttributes forKey:key];
}

- (void)setShowMessages:(NSString *)_showString {
  NSString *key = [self->name stringByAppendingString:ShowMessages];
  key = [key stringByAppendingString:[self->folder absoluteName]];

  [self->defaults setObject:_showString forKey:key];
}
- (NSString *)showMessages {
  NSString *key = [self->name stringByAppendingString:ShowMessages];
  NSString *tmp;
  key = [key stringByAppendingString:[self->folder absoluteName]];

  tmp = [self->defaults stringForKey:key];

  return (tmp) ? tmp : @"all";
}

- (BOOL)doClientSideScroll {
  return [self->defaults boolForKey:DoClientScroll];
}
- (int)clientSideScrollTreshold {
  return [self->defaults integerForKey:ClientScrollTreshold];
}

- (int)blockSize {
  NSString *key = [self->name stringByAppendingString:BlockSize];
  return [self->defaults integerForKey:key];
}
- (void)setBlockSize:(int)_blockSize {
  NSString *key = [self->name stringByAppendingString:BlockSize];
  [self->defaults setInteger:_blockSize forKey:key];
}

- (void)synchronize {
  [self->defaults synchronize];
}

@end /* SkyImapMailListState */
