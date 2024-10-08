/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#ifndef __ZideStore_OLSxTask_H__
#define __ZideStore_OLSxTask_H__

#import <ZSFrontend/SxObject.h>

@class SxTaskFolder;

@interface SxTask : SxObject
{
  NSString *group; /* group or nil */
}

- (NSString *)group;

/* simplified command execution */

- (id)createWithChanges:(NSMutableDictionary *)_dict log:(NSString *)_log
  inContext:(id)_ctx;

@end


#endif /* __ZideStore_OLSxTask_H__ */
