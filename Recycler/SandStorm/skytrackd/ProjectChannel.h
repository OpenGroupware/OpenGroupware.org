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

#ifndef __SkyTrackDaemon__ProjectChannel_H__
#define __SkyTrackDaemon__ProjectChannel_H__

#include "Channel.h"

@class NSDictionary, NSString;
@class EOGlobalID;

@interface ProjectChannel : Channel
{
  NSString     *projectID;
  NSDictionary *changeInfo;
  EOGlobalID   *globalID;
}

/* initialization */

- (id)initWithDictionary:(NSDictionary *)_dict name:(NSString *)_name;

/* accessors */

- (NSDictionary *)channelInfo;
- (NSDictionary *)changeInfo;
- (void)setChangeInfo:(NSDictionary *)_info;
- (NSString *)projectID;

- (id)compareOldMD5:(id)_old withNewMD5:(id)_new;
- (void)resetChanges:(NSString *)_element;

- (void)registerAction:(id)_action forElement:(NSString *)_string;

@end /* ProjectChannel */

#endif /* __SkyTrackDaemon__ProjectChannel_H__ */
