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

#ifndef __OGoProject_common_H__
#define __OGoProject_common_H__

#import <Foundation/Foundation.h>

#include <EOControl/EOControl.h>

#include <NGExtensions/NGObjectMacros.h>
#include <NGExtensions/EOCacheDataSource.h>
#include <NGExtensions/EOFilterDataSource.h>
#include <NGExtensions/EODataSource+NGExtensions.h>
#include <NGExtensions/NSFileManager+Extensions.h>
#include <NGExtensions/NGFileFolderInfoDataSource.h>

#include <NGObjWeb/NGObjWeb.h>

#include <WEExtensions/WEClientCapabilities.h>

#include <LSFoundation/LSCommandContext.h>
#include <OGoFoundation/OGoFoundation.h>
#include <OGoFoundation/LSWSession.h>
#include <OGoFoundation/LSWNavigation.h>
#include <OGoFoundation/WOComponent+Navigation.h>
#include <EOAccess/EOAccess.h>


#include <OGoProject/SkyProject.h>
#include <OGoProject/SkyProjectDataSource.h>
#include <OGoProject/OGoFileManagerFactory.h>
#include <OGoProject/SkyProjectHistoryDocument.h>

#include <OGoDatabaseProject/SkyProjectDocument.h>
#include <OGoDatabaseProject/SkyProjectDocument.h>
#include <OGoDatabaseProject/SkyProjectFileManager.h>

#include <OGoFileSystemProject/SkyFSFileManager.h>
#include <OGoFileSystemProject/SkyFSDataSource.h>
#include <OGoFileSystemProject/SkyFSDocument.h>

#include <OGoDocuments/SkyDocuments.h>

#include <OGoBase/SkyLogDataSource.h>
#include <OGoBase/LSCommandContext+Doc.h>

#endif /* __OGoProject_common_H__ */
