/*
  Copyright (C) 2005 SKYRIX Software AG

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

#ifndef __OGoScheduler_NSCalendarDate_OGoScheduler_H__
#define __OGoScheduler_NSCalendarDate_OGoScheduler_H__

#import <Foundation/NSCalendarDate.h>

@interface NSCalendarDate(OGoScheduler)

/*
  Those two methods are only relevant for the first week of a year. In all
  other cases they return the month/year as set in the date.

  For transition weeks, the methods will return the "new year", even for old
  dates, eg if the view displays:
    Mon/30. | Tue/30. | Wed/31. | Thu/01. | Fri/02.
  the method will return the year of Thu/01. even for Tue/30.
  
  This is intended for improved navigation.
*/
- (int)bestMonthForWeekView:(NSCalendarDate *)_weekStart;
- (int)bestYearForWeekView:(NSCalendarDate *)_weekStart;

- (int)bestWeekForWeekView;

@end

#endif /* __OGoScheduler_NSCalendarDate_OGoScheduler_H__ */
