/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id: SkyImapMailListState.h 1 2004-08-20 11:17:52Z znek $

#ifndef __LSWebInterface_LSWImapMails_SkyImapMailListState_H__
#define __LSWebInterface_LSWImapMails_SkyImapMailListState_H__

#import <Foundation/NSObject.h>

@class NSArray;
@class NGImap4Folder, NSUserDefaults;

@interface SkyImapMailListState : NSObject
{
@protected
  NSUserDefaults *defaults;
  NGImap4Folder  *folder;
  NSString       *name;
  unsigned       currentBatch;
  int            showAllMessages; // without writing defaults
}

- (id)initWithDefaults:(NSUserDefaults *)_ud;

- (void)setName:(NSString *)_name;
- (NSString *)name;

- (void)setFolder:(NGImap4Folder *)_folder;
- (NGImap4Folder *)folder;

// --- properties of SkyImapMailList -----------------------------

- (BOOL)showAll;
- (BOOL)showUnread;
- (BOOL)showFlagged;

- (BOOL)isShowFilterButtons;
- (BOOL)isShowMailButtons;
- (void)setCurrentBatch:(unsigned)_currentBatch;
- (unsigned)currentBatch;
- (void)setShowAllMessages:(int)_showAllMessages;
- (int)showAllMessages;

// --- values of preferences ---------------------------------------

- (void)setIsDescending:(BOOL)_flag;
- (BOOL)isDescending;

- (int)subjectLength;
- (int)senderLength;

- (NSString *)sortedKey;
- (void)setSortedKey:(NSString *)_sortedKey;

- (NSArray *)attributes;
- (void)attributes:(NSArray *)_shownAttributes;

- (void)setShowMessages:(NSString *)_showString;
- (NSString *)showMessages;

- (BOOL)doClientSideScroll;
- (int)clientSideScrollTreshold;

- (void)setBlockSize:(int)_blockSize;
- (int)blockSize;

// ---

- (void)synchronize;

@end

#endif /* __LSWebInterface_LSWFoundation_LSWTreeState_H__ */



