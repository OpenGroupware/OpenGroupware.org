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

#ifndef __LSWebInterface_SkyPalm_SkyPalmDateChartViews_H__
#define __LSWebInterface_SkyPalm_SkyPalmDateChartViews_H__

#include <OGoFoundation/LSWContentPage.h>

@class NSTimeZone, SkyPalmDateDataSource, NSCalendarDate;

@interface SkyPalmDateChartViews : LSWContentPage
{
  NSTimeZone            *tz;
  SkyPalmDateDataSource *ds;
  // week overview
  NSCalendarDate        *weekStart;  // weekstart of week overview
  // month/year overview
  int                   month;
  int                   year;
  // day overview
  NSCalendarDate        *day;
  
  NSString              *mode;       // selected chart
  NSString              *weekSubkey; // subchart of week chart
  NSString              *daySybkey;  // subchart of day chart
  
}

@end


#endif /* __LSWebInterface_SkyPalm_SkyPalmDateChartViews_H__ */
