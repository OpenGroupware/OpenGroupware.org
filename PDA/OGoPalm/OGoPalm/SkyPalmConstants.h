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

#ifndef __SkyPalmConstants_H__
#define __SkyPalmConstants_H__

// Sync Type of PalmRecord-SkyricRecord - Assignment
#define SYNC_TYPE_DO_NOTHING    0
// skyrix record is master
#define SYNC_TYPE_SKY_OVER_PALM 1
// palm record is master
#define SYNC_TYPE_PALM_OVER_SKY 2
// modified record is master, if both -> conflict
#define SYNC_TYPE_TWO_WAY       3

// State of Palm-Skyrix Assignment
#define SYNC_STATE_NOTHING_CHANGED 100
#define SYNC_STATE_PALM_CHANGED    101
#define SYNC_STATE_SKYRIX_CHANGED  102
#define SYNC_STATE_BOTH_CHANGED    103
#define SYNC_STATE_NEVER_SYNCED    104

#define SYNC_SKYRIX_CONFLICT_DO_NOTHING       0
#define SYNC_SKYRIX_CONFLICT_CREATE_NEW_OGO   1
#define SYNC_SKYRIX_CONFLICT_FORCEPALMOVEROGO 2
#define SYNC_SKYRIX_CONFLICT_FORCEOGOOVERPALM 3

#define SYNC_SKYRIX_CONFLICT_NOTIFY_TASK 5

// PalmAddress Phone Label Ids
#define PALM_ADDRESS_PHONE_WORK   0
#define PALM_ADDRESS_PHONE_HOME   1
#define PALM_ADDRESS_PHONE_FAX    2
#define PALM_ADDRESS_PHONE_OTHER  3
#define PALM_ADDRESS_PHONE_EMAIL  4
#define PALM_ADDRESS_PHONE_MAIN   5
#define PALM_ADDRESS_PHONE_PAGER  6
#define PALM_ADDRESS_PHONE_MOBILE 7

// Notification Names
#define SkyDeletedPalmAddressNotification @"SkyDeletedPalmAddressNotification"
#define SkyUpdatedPalmAddressNotification @"SkyUpdatedPalmAddressNotification"
#define SkyNewPalmAddressNotification     @"SkyNewPalmAddressNotification"

#define SkyDeletedPalmDateNotification @"SkyDeletedPalmDateNotification"
#define SkyUpdatedPalmDateNotification @"SkyUpdatedPalmDateNotification"
#define SkyNewPalmDateNotification     @"SkyNewPalmDateNotification"

#define SkyDeletedPalmMemoNotification @"SkyDeletedPalmMemoNotification"
#define SkyUpdatedPalmMemoNotification @"SkyUpdatedPalmMemoNotification"
#define SkyNewPalmMemoNotification     @"SkyNewPalmMemoNotification"

#define SkyDeletedPalmJobNotification @"SkyDeletedPalmJobNotification"
#define SkyUpdatedPalmJobNotification @"SkyUpdatedPalmJobNotification"
#define SkyNewPalmJobNotification     @"SkyNewPalmJobNotification"

#endif /* __SkyPalmConstants_H__ */
