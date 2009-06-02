/*
  Copyright (C) 2009 Whitemice Consulting

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

#ifndef __zOGITaskActionNotification_H__
#define __zOGITaskActionNotification_H__

#include "zOGITaskNotification.h"

@interface zOGITaskActionNotification: zOGITaskNotification
{
  NSString    *comment;
}

- (void)send:(id)_task forAction:(id)_action withComment:(id)_comment;

@end /* zOGITaskActionNotification */

#endif /* __zOGITaskActionNotification_H__ */
