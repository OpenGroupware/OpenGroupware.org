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

#ifndef __LSWebInterface_LSWImapMail_SkyImapMailDataSource_H__
#define __LSWebInterface_LSWImapMail_SkyImapMailDataSource_H__

#import <NGExtensions/EODataSource+NGExtensions.h>
#import <Foundation/NSRange.h>

@class NSArray;
@class NGImap4Folder;
@class EOQualifier;

@interface SkyImapMailDataSource : EODataSource
{
@protected
  NSArray       *messages;
  NSArray       *sortOrderings;
  NGImap4Folder *folder;
  EOQualifier   *qualifier;
  int           oldExists; // remember the 'exists' flag of the folder
  int           oldUnseen; // remember the 'unseen' flag of the folder

  NSArray       *oldUnseenMessages;

  int maxCount;
  BOOL doSubFolders;
}

- (void)setFolder:(NGImap4Folder *)_folder;
- (NGImap4Folder *)folder;

- (void)setQualifier:(EOQualifier *)_qualifier;

- (int)oldExists;
- (int)oldUnseen;

- (void)preFetchMessagesInRange:(NSRange)_range;

- (void)setDoSubFolders:(BOOL)_flag;
- (BOOL)doSubFolders;

- (void)setMaxCount:(unsigned)_maxCount;
- (unsigned)maxCount;
- (BOOL)useServerSideSorting;
- (BOOL)useSSSortingForSOArray:(NSArray *)_array;

@end

#endif /* __LSWebInterface_LSWImapMail_SkyImapMailDataSource_H__ */
