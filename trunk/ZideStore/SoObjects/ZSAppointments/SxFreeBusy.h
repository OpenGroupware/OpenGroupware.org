/*
  Copyright (C) 2000-2005 SKYRIX Software AG

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

#ifndef __Appointments_SxFreeBusy_H__
#define __Appointments_SxFreeBusy_H__

#include <ZSFrontend/SxObject.h>

@interface SxFreeBusy : SxObject
{
  NSString *user;
  NSString *format;
}

// may be TEAM:<team>, SMTP:<email> or <login>
- (void)setUser:(NSString *)_user;
- (NSString *)user;

// xml, vfb, iCal, ics
- (void)setFormat:(NSString *)_format;
- (NSString *)format;

- (id)GETAction:(id)_ctx;

@end /* SxFreeBusy */


#endif /* __Appointments_SxFreeBusy_H__ */
