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

#ifndef __OGoProject_LSWProject_common_H__
#define __OGoProject_LSWProject_common_H__

#import <Foundation/Foundation.h>

#include <NGExtensions/NGExtensions.h>

#import <EOControl/EOControl.h>
#import <GDLAccess/GDLAccess.h>

#include <NGMime/NGMimeType.h>
#include <NGObjWeb/NGObjWeb.h>

#include <LSFoundation/LSFoundation.h>
#include <OGoFoundation/OGoFoundation.h>
#include <OGoDatabaseProject/SkyDocumentDataSource.h>
#include <OGoProject/OGoFileManagerFactory.h>
#include <OGoProject/SkyProjectDataSource.h>

#define LSJobCreated    @"00_created"
#define LSJobAccepted   @"05_accepted"
#define LSJobCommented  @"10_commented"
#define LSJobDivided    @"15_divided"
#define LSJobProcessing @"20_processing"
#define LSJobDone       @"25_done"
#define LSJobArchived   @"30_archived"
#define LSJobReactivate @"27_reactivated"
#define LSJobRejected   @"02_rejected"

#endif /* __OGoProject_LSWProject_common_H__ */
