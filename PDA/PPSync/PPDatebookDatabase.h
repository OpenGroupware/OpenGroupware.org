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
// $Id$

#ifndef __PPSync_PPDatebookDatabase_H__
#define __PPSync_PPDatebookDatabase_H__

#import <Foundation/NSDate.h>
#include "PPRecordDatabase.h"

@class NSCalendarDate, NSDate, NSString;

@interface PPDatebookDatabase : PPRecordDatabase
{
  BOOL     hasAppInfo;
  BOOL     startOfWeek;
}

@end

@interface PPDatebookRecord : PPRecord
{
  BOOL           isEvent;
  NSCalendarDate *startDate;
  NSCalendarDate *endDate;
  BOOL           hasAlarm;
  NSTimeInterval alarmAdvance;
  int            alarmAdvanceUnit;
  int            cycleType;
  BOOL           cycleEndIsDistantFuture;
  NSCalendarDate *cycleEndDate;
  int            cycleFrequency;
  int            dayCycle;
  BOOL           cycleDays[7];
  int            cycleWeekstart;
  int            cycleExceptions;
  NSString       *title;
  NSString       *note;

  NSArray        *cycleExceptionsArray;
}

@end

#endif /* __PPSync_PPDatebookDatabase_H__ */
