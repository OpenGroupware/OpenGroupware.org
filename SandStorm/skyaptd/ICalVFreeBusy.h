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

#ifndef __ICal2_ICalVFreeBusy_H__
#define __ICal2_ICalVFreeBusy_H__

#include "ICalComponent.h"
#import <Foundation/NSCalendarDate.h>

@class NSString, NSArray, NSCalendarDate, NSURL;

/*
  --snip--
   Description: A "VFREEBUSY" calendar component is a grouping of
   component properties that represents either a request for, a reply to
   a request for free or busy time information or a published set of
   busy time information.
  --snap--
*/

@interface ICalVFreeBusy : ICalComponent
{
  id             organizer;
  NSCalendarDate *startDate;
  NSCalendarDate *endDate;
  NSTimeInterval timeStamp;
  NSURL          *url;
  NSString       *uid;
  NSArray        *freeBusyProps;
  NSArray        *attendees;
  NSArray        *comments;
  NSArray        *rstatus;
}

- (id)initWithOrganizer:(id)_organizer
  timeRange:(NSCalendarDate *)_from:(NSCalendarDate *)_to
  timeStamp:(NSTimeInterval)_ts
  freeBusyProperties:(NSArray *)_fb;

/* accessors */

- (NSTimeInterval)timeStamp;
- (NSCalendarDate *)timeStampAsDate;

- (NSCalendarDate *)startDate;
- (NSCalendarDate *)endDate;

- (id)organizer;

- (NSArray *)freeBusyProperties;

@end

#endif /* __ICal2_ICalVFreeBusy_H__ */
