/*
  Copyright (C) 2006 Helge Hess

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

#ifndef __ZideStore_GCalCalendar_H__
#define __ZideStore_GCalCalendar_H__

#import <Foundation/NSObject.h>

/*
  GCalCalendar

    parent-folder: GCalEntryPoint
    subobjects:    GCalEvent

  This maps to /calendar/feeds/$USERNAME.

  A complete URL:
    /calendar/feeds/$USER/private/full

  Schema:
    /calendar/feeds/$USER/visibility/projection
    /calendar/feeds/$USER/visibility/projection/$PKEY

  Visibility:
    public      => maps to /zidestore/dav/user/public/Calendar
    private     => maps to /zidestore/dav/user/Calendar
    [no support for private-magicCookie]

  Projection:
    full
    full-noattendees (no gd:who elements)
    composite
    attendees-only
    free-busy
    basic

  Notes:
  - would be best to map the projection to a renderer which is called
    automagically by SOPE?
*/

@interface GCalCalendar : NSObject
{
  NSString *visibility;
  NSString *projection;
  
  id       userFolder;
  id       calendarFolder; /* this is derived from the visibility */
}

- (id)initWithUserFolder:(id)_userFolder;

/* accessors */

- (NSString *)nameInContainer;

- (NSString *)visibility;
- (NSString *)projection;

- (id)userFolder;

@end

#endif /* __ZideStore_GCalCalendar_H__ */
