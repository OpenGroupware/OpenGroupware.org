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

#ifndef __LSWebInterface_SkyPalm_SkyPalmPage_H__
#define __LSWebInterface_SkyPalm_SkyPalmPage_H__

#include <OGoFoundation/LSWContentPage.h>
#include <OGoPalm/SkyPalmEntryDataSource.h>
// #include <OGoPalmUI/SkyPalmDateWeekOverviewState.h>
#include <NGExtensions/EOCacheDataSource.h>

@interface SkyPalmPage : LSWContentPage
{
  id                     item;          // for iteration
  EOCacheDataSource      *addresses;
  EOCacheDataSource      *dates;
  SkyPalmEntryDataSource *memos;
  SkyPalmEntryDataSource *jobs;
}

- (void)setSelectedTab:(NSString *)_tab;

@end

#endif /* __LSWebInterface_SkyPalm_SkyPalmPage_H__ */
