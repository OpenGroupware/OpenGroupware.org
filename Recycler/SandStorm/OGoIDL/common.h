/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

#ifndef __SkyIDL_common_H__
#define __SkyIDL_common_H__

#import <Foundation/Foundation.h>

#if LIB_FOUNDATION_LIBRARY
#  import <Foundation/exceptions/GeneralExceptions.h>
#elif NeXT_Foundation_LIBRARY || COCOA_Foundation_LIBRARY
#  import <FoundationExt/NSObjectMacros.h>
#  import <FoundationExt/NSString+Ext.h>
#  import <FoundationExt/GeneralExceptions.h>
#endif

#include <SaxObjC/SaxObjC.h>
#include <NGExtensions/NGExtensions.h>

static inline BOOL isSkyIdlNamespace(NSString *_namespace) {
  static NSString *SkyIdlSchemaNS = @"http://www.skyrix.com/skyrix-idl";
  
  if ([_namespace isEqualToString:SkyIdlSchemaNS])
    return YES;
  else
    return NO;
}

#endif /* __SkyIDL_common_H__ */
