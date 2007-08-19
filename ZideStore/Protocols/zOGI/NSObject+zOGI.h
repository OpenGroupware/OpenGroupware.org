/*
  Copyright (C) 2006-2007 Whitemice Consulting

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

#ifndef __zOGI_NSObject_zOGI_H__
#define __zOGI_NSObject_zOGI_H__

#import <Foundation/NSObject.h>
#include <NGObjWeb/SoObjects.h>

/*
  Category for zOGI API.
*/

@class NSString, NSArray, NSDictionary, NSCalendarDate;

@interface NSObject(zOGI)

@end

@interface NSObject(zOGIObject)

@end

@interface NSObject(PostObject)

/*- (NSString *)ogiContentInContext:(id)_ctx;
- (NSDictionary *)zOgiPostInfoInContext:(id)_ctx; */

@end

#endif /* __zOGI_NSObject_zOGI_H__ */
