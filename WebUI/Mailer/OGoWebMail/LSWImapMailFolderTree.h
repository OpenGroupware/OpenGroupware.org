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

#ifndef __OGoWebMail_LSWImapMailFolderTree_H__
#define __OGoWebMail_LSWImapMailFolderTree_H__

#include <OGoFoundation/OGoComponent.h>

// TODO: is this still used?

@class NSNumber, NSArray, NSMutableArray; 

@interface LSWImapMailFolderTree : OGoComponent
{
@protected
  id folder;
  id subFolder;
  id compareObj;
  id rootFolder;
  
  unsigned navItemIndex;
  NSString *onClick;
  NSString *subFolderAction;
  NSString *subFolderTitleAction;
  NSString *folderTitleAction;
  NSString *parentFolderAction;
  NSString *moreInfosAction;      
  NSString *idName;      
  
  NSMutableArray *folderStack;
  NSNumber       *showRootFolder;
}

- (void)folderClicked;

/* accessors */

- (void)setCompareObj:(id)_obj;
- (id)compareObj;

@end

#endif /* __OGoWebMail_LSWImapMailFolderTree_H__ */
