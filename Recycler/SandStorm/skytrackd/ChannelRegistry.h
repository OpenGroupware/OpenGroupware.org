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

#ifndef __SkyTrackDaemon__ChannelRegistry_H__
#define __SkyTrackDaemon__ChannelRegistry_H__

#import <Foundation/NSObject.h>

@class NSObject, NSMutableDictionary, NSString, NSDictionary;
@class NSArray;

@interface ChannelRegistry : NSObject
{
  NSMutableDictionary *registry;
}

/* initialization */

- (void)initChannelRegistry:(NSString *)_userDir;


- (BOOL)isInRegistry:(NSString *)_channelID user:(NSString *)_user;

- (BOOL)addObjectToRegistry:(NSDictionary *)_object
                       type:(NSString *)_type
                       name:(NSString *)_name
                       user:(NSString *)_user;

- (NSDictionary *)updatesForCode:(NSString *)_name
                            user:(NSString *)_user;
 
- (NSArray *)registeredProjectsForUser:(NSString *)_user;

- (BOOL)deleteUpdatesForCode:(NSString *)_name
                        name:(NSString *)_element
                        user:(NSString *)_user;

- (NSDictionary *)infoForProject:(NSString *)_name
                            user:(NSString *)_user;

- (id)registerAction:(NSString *)_name
          forElement:(NSString *)_element
                type:(NSString *)_actionType
                args:(NSDictionary *)_args
                user:(NSString *)_user;

- (void)trackObjects;

@end /* ChannelRegistry */

#endif /* __SkyTrackDaemon__ChannelRegistry_H__ */
