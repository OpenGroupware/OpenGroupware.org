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

#ifndef __SkyAppointmentDaemon_Common_H__
#define __SkyAppointmentDaemon_Common_H__

#import <Foundation/Foundation.h>

#if NeXT_Foundation_LIBRARY || APPLE_Foundation_LIBRARY
#  import <FoundationExt/objc-api.h>
#  import <FoundationExt/objc-runtime.h>
#  import <FoundationExt/NSException.h>
#  import <FoundationExt/GeneralExceptions.h>
#  import <FoundationExt/MissingMethods.h>
#  import <FoundationExt/NSObjectMacros.h>
#endif

#include <EOControl/EOControl.h>
#include <EOControl/EOQualifier.h>
#include <NGExtensions/NGExtensions.h>
#include <GDLAccess/GDLAccess.h>
#include <NGObjWeb/NGObjWeb.h>

#include <LSFoundation/LSFoundation.h>
#include <OGoDocuments/SkyDocuments.h>

#endif /* __SkyAppointmentDaemon_Common_H__ */
