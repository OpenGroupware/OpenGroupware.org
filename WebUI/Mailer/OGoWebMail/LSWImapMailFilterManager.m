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
// $Id$

#include "LSWImapMailFilterManager.h"
#include "common.h"

// NOTE: DEPRECATED, use OGoMailFilterManager

@implementation LSWImapMailFilterManager

+ (NSArray *)allFilterForUser:(id)_user {
  return [[self sharedMailFilterManager] allFiltersForUser:_user];
}

+ (NSMutableArray *)filterForUser:(id)_user {
  return [[self sharedMailFilterManager] filterForUser:_user];
}

+ (NSMutableArray *)vacationForUser:(id)_user {
  return [[self sharedMailFilterManager] vacationForUser:_user];
}

+ (BOOL)writeAllFilter:(NSArray *)_filter forUser:(id)_user {
  return [[self sharedMailFilterManager] writeAllFilters:_filter 
					 forUser:_user];
}

+ (BOOL)writeFilter:(NSArray *)_filter forUser:(id)_user {
  return [[self sharedMailFilterManager] writeFilter:_filter forUser:_user];
}

+ (BOOL)writeVacation:(NSArray *)_filter forUser:(id)_user {
  return [[self sharedMailFilterManager] writeVacation:_filter forUser:_user];
}


+ (NSString *)pathToFilterForUser:(id)_user {
  return [[self sharedMailFilterManager] pathToFilterForUser:_user];
}

+ (void)exportFilterWithSession:(id)_session pwd:(NSString *)_pwd
  page:(id)_page
{
  [[self sharedMailFilterManager] exportFilterWithSession:_session
				  password:_pwd page:_page];
}

@end /* LSWImapMailFilterManager */
