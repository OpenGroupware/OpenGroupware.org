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

#ifndef __LSWebInterface_LSWFoundation_common_H__
#define __LSWebInterface_LSWFoundation_common_H__

#include <objc/objc-api.h>

#import <Foundation/Foundation.h>
#import <Foundation/NSDateFormatter.h>
#include <NGExtensions/NGExtensions.h>
#include <NGStreams/NGStreams.h>

#include <GDLAccess/GDLAccess.h>

#include <NGMime/NGMime.h>
#include <NGHttp/NGHttp.h>
#include <NGObjWeb/NGObjWeb.h>

#include <LSFoundation/LSFoundation.h>

#if PROFILE
#  define BEGIN_PROFILE \
     { NSTimeInterval __ti = [[NSDate date] timeIntervalSince1970];

#  define END_PROFILE \
     __ti = [[NSDate date] timeIntervalSince1970] - __ti;\
     if (__ti > 0.05) \
       printf("***PROF[%s]: %0.3fs\n", __PRETTY_FUNCTION__, __ti);\
     else if (__ti > 0.005) \
       printf("PROF[%s]: %0.3fs\n", __PRETTY_FUNCTION__, __ti);\
     }

#  define PROFILE_CHECKPOINT(__key__) \
     { NSTimeInterval diff = [[NSDate date] timeIntervalSince1970] - __ti;\
       if (diff > 0.002) {\
         printf("---PROF[%s] CP %s: %0.3fs\n", __PRETTY_FUNCTION__, __key__,\
                diff);\
       }\
     }

#else
#  define BEGIN_PROFILE {
#  define END_PROFILE   }
#  define PROFILE_CHECKPOINT(__key__)
#endif

#endif /* __LSWebInterface_LSWFoundation_common_H__ */
