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

#ifndef __SkyMasterDaemon__Common_H__
#define __SkyMasterDaemon__Common_H__

#define STATUS_FLAG_FAILED 0
#define STATUS_FLAG_TERM   1
#define STATUS_FLAG_ZOMBIE 2
#define STATUS_FLAG_FORKED 3

#define RETURN_CODE_ERROR  -127

#import <Foundation/Foundation.h>

#if LIB_FOUNDATION_LIBRARY
#  import <Foundation/UnixSignalHandler.h>
#elif NeXT_Foundation_LIBRARY || COCOA_Foundation_LIBRARY
#  import <FoundationExt/NSObjectMacros.h>
#  import <FoundationExt/NSString+Ext.h>
#  import <FoundationExt/UnixSignalHandler.h>
#endif

#include <NGExtensions/NGExtensions.h>
#include <NGObjWeb/NGObjWeb.h>

#endif /* __SkyMasterDaemon__Common_H__ */
