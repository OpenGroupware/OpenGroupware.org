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

#ifndef __ICal2_ICalVCalendar_H__
#define __ICal2_ICalVCalendar_H__

#include <ICalComponent.h>
#include <ical.h>

@class NSString, NSArray;

typedef icalproperty_method ICalVCalendarMethod;

@interface ICalVCalendar : ICalComponent
{
  ICalVCalendarMethod method;
  NSString *methodString;
  NSString *productId;
  int      majorVersion;
  int      minorVersion;
  
  NSArray  *subComponents;
}

- (id)initWithMethod:(ICalVCalendarMethod)_method
  productId:(NSString *)_pid
  version:(int)_major:(int)_minor
  subComponents:(NSArray *)_subcomponents;

/* accessors */

- (int)majorVersion;
- (int)minorVersion;

- (NSString *)productId;
- (BOOL)isOutlook;
- (BOOL)isGnomeCalendar;
- (BOOL)isAppleiCal;

@end

#endif /* __ICal2_ICalVCalendar_H__ */
