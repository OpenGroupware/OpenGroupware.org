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

#ifndef __ICal2_ICalFreeBusy_H__
#define __ICal2_ICalFreeBusy_H__

#include "ICalProperty.h"
#import <Foundation/NSCalendarDate.h>
#include <ical.h>

@class NSString, NSArray, NSCalendarDate;

/*
  ---snip---
   Property Name: FREEBUSY

   Purpose: The property defines one or more free or busy time
   intervals.

   Value Type: PERIOD. The date and time values MUST be in an UTC time
   format.
  ---snap---
*/

typedef icalparameter_fbtype ICalFreeBusyType;

@interface ICalFreeBusy : ICalProperty
{
  NSCalendarDate   *startDate;
  NSCalendarDate   *endDate;
  ICalFreeBusyType fbType;
}

- (id)initWithTimeRange:(NSCalendarDate *)_from:(NSCalendarDate *)_to
  fbType:(ICalFreeBusyType)_fbtype;

/* parameters */

- (BOOL)isFree;
- (BOOL)isBusy;
- (BOOL)isBusyUnavailable;
- (BOOL)isBusyTentative;

/* value */

- (NSCalendarDate *)startDate;
- (NSCalendarDate *)endDate;

/* comparing */

- (int)compare:(id)_other;

@end

#endif /* __ICal2_ICalFreeBusy_H__ */
