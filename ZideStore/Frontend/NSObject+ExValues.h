/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#ifndef __sxdavd_NSObject_ExValues_H__
#define __sxdavd_NSObject_ExValues_H__

#import <Foundation/NSObject.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>
#include <NGObjWeb/SoWebDAVValue.h>

@interface NSObject(ExValues)

- (id)exDavFloatValue;
- (id)exDavIntValue;
- (id)exDavBase64Value;

- (NSString *)asExUID;

@end

@interface NSDate(ExValues)

+ (id)dateWithExDavString:(NSString *)_s;
- (id)exDavDateValue;

@end

@interface NSString(ExValues)

// this is used for Folder-URLs in OL 2000
- (NSString *)asEncodedHomePageURL:(BOOL)_show;

// this is used in AB queries (and in recipients table ?)
- (NSString *)asEncodedEmailStruct;

@end

@interface NSData(Base64)
- (NSData *)dataByEncodingBase64LineWidth:(unsigned int)_width;
@end /* NSData(Base64) */

#if !LIB_FOUNDATION_LIBRARY
#  import <Foundation/NSTimeZone.h>
#endif

@interface NSTimeZone(ExTimeZoneID)

- (id)exTimeZoneID;

@end
    
#endif /* __sxdavd_NSObject_ExValues_H__ */
