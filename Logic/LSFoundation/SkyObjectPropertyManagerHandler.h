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

#ifndef __OGo_LSFoundation_SkyObjectPropertyManagerHandler__
#define __OGo_LSFoundation_SkyObjectPropertyManagerHandler__

#import <Foundation/NSObject.h>

@class NSMutableArray, NSNotification;
@class SkyObjectPropertyManager;

@interface SkyObjectPropertyManagerHandler : NSObject
{
  NSMutableArray *managers;
}

- (void)globalIDWasDeleted:(NSNotification *)_obj;
- (void)globalIDWasCopied:(NSNotification *)_obj;

- (void)addManager:(SkyObjectPropertyManager *)_ds;
- (void)removeManager:(SkyObjectPropertyManager *)_ds;

@end /* SkyObjectPropertyManagerHandler */

#endif /* __OGo_LSFoundation_SkyObjectPropertyManagerHandler__ */
