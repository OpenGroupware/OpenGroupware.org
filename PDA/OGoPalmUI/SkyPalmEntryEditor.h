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

#ifndef __LSWebInterface_SkyPalm_SkyPalmEntryEditor_H__
#define __LSWebInterface_SkyPalm_SkyPalmEntryEditor_H__

#include <OGoFoundation/LSWEditorPage.h>
#include <OGoPalm/SkyPalmEntryDataSource.h>

@interface SkyPalmEntryEditor : LSWEditorPage
{
  SkyPalmEntryDataSource *ds;
  NSArray                *categories;
  NSArray                *devices;

  id                     item;
}

- (NSArray *)categories;
- (NSArray *)devices;
- (void)checkStringForKey:(NSString *)_key;

/* methods to overwrite
- (NSString *)palmDb;
- (NSString *)insertNotificationName;
- (NSString *)updateNotificationName;
 */

@end

#endif /* __LSWebInterface_SkyPalm_SkyPalmEntryEditor_H__ */
