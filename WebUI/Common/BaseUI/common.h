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

#ifndef __LSWBase_common_H__
#define __LSWBase_common_H__

#import <Foundation/Foundation.h>

#if NeXT_Foundation_LIBRARY || COCOA_Foundation_LIBRARY
#  include <NGExtensions/NGObjectMacros.h>
#endif

#import <Foundation/NSFormatter.h>
#import <EOControl/EOControl.h>

#include <NGExtensions/NGExtensions.h>
#include <NGMime/NGMime.h>
#include <NGObjWeb/NGObjWeb.h>

#include <GDLAccess/GDLAccess.h>

#include <OGoFoundation/OGoSession.h>
#include <OGoFoundation/OGoNavigation.h>
#include <OGoFoundation/OGoContentPage.h>
#include <OGoFoundation/WOSession+LSO.h>

#endif /* __LSWBase_common_H__ */
