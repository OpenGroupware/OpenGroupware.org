/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$


#ifndef	__UIxComponent_H_
#define	__UIxComponent_H_

#include <NGObjWeb/SoComponent.h>

@class NSCalendarDate, NSTimeZone, NSMutableDictionary, SoUser;


@interface UIxComponent : SoComponent
{
  NSMutableDictionary *queryParameters;
}

- (NSString *)queryParameterForKey:(NSString *)_key;
- (NSDictionary *)queryParameters;

/* use this to set 'sticky' query parameters */
- (void)setQueryParameter:(NSString *)_param forKey:(NSString *)_key;

/* date related query parameters */
- (NSDictionary *)queryParametersBySettingSelectedDate:(NSCalendarDate *)_date;
- (void)setSelectedDateQueryParameter:(NSCalendarDate *)_newDate
        inDictionary:(NSMutableDictionary *)_qp;

/* appends queryParameters to _method if any are set */
- (NSString *)completeHrefForMethod:(NSString *)_method;

- (NSString *)ownMethodName;

- (NSString *)userFolderPath;
- (NSString *)ownPath;
- (NSString *)relativePathToUserFolderSubPath:(NSString *)_sub;

/* date selection */
- (NSTimeZone *)viewTimeZone;
- (NSTimeZone *)backendTimeZone;
- (NSCalendarDate *)selectedDate;
- (NSString *)dateStringForDate:(NSCalendarDate *)_date;
- (NSCalendarDate *)dateForDateString:(NSString *)_dateString;

/* SoUser */
- (SoUser *)user;
- (NSString *)shortUserNameForDisplay;

/* labels */
- (NSString *)labelForKey:(NSString *)_key;

- (NSString *)localizedNameForDayOfWeek:(unsigned)_dayOfWeek;
- (NSString *)localizedAbbreviatedNameForDayOfWeek:(unsigned)_dayOfWeek;
- (NSString *)localizedNameForMonthOfYear:(unsigned)_monthOfYear;
- (NSString *)localizedAbbreviatedNameForMonthOfYear:(unsigned)_monthOfYear;
    
/* locale */
- (NSDictionary *)locale;

/* Debugging */
- (BOOL)isUIxDebugEnabled;

@end

#endif	/* __UIxComponent_H_ */
