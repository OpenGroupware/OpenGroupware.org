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

#ifndef __LSWImapMail_OGoMailFilterManager_H__
#define __LSWImapMail_OGoMailFilterManager_H__

#import <Foundation/NSObject.h>

@class NSArray, NSMutableArray, NSString;

// TODO: this API needs a lot of cleanup

@interface OGoMailFilterManager : NSObject

+ (id)sharedMailFilterManager;

/* operations */

- (NSMutableArray *)filterForUser:(id)_user;

- (BOOL)writeFilter:(NSArray *)_filter forUser:(id)_user;

- (NSString *)pathToFilterForUser:(id)_user;

- (void)exportFilterWithSession:(id)_session password:(NSString *)_pwd
  page:(id)_page;

- (NSMutableArray *)vacationForUser:(id)_user;
- (BOOL)writeVacation:(NSArray *)_filter forUser:(id)_user;

- (BOOL)writeAllFilters:(NSArray *)_filter forUser:(id)_user;
- (NSArray *)allFiltersForUser:(id)_user;

@end

#endif /* __LSWImapMail_OGoMailFilterManager_H__ */
