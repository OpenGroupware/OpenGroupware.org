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

#include "SkyTrackAction.h"
#include "Application.h"
#include "ChannelRegistry.h"
#include "common.h"

@implementation SkyTrackAction

- (NSString *)xmlrpcComponentName {
  return @"track";
}

- (NSString *)remoteUser {
  return [[[self request] headers] valueForKey:@"x-webobjects-remote-user"];
}

- (NSNumber *)trackObjectsAction {

  if ([[self remoteUser] isEqualToString:@"root"]) {
    ChannelRegistry *registry = nil;

    registry = [(Application *)[WOApplication application] channelRegistry];
    [registry trackObjects];
    NSLog(@"%s: user root triggered manual update", __PRETTY_FUNCTION__);
    return [NSNumber numberWithBool:YES];
  }

  NSLog(@"%s: unauthorized manual update requested by user %@",
        __PRETTY_FUNCTION__, [self remoteUser]);
  return [NSNumber numberWithBool:NO];
}

- (NSArray *)getChannelsAction {
  ChannelRegistry *registry = nil;

  registry = [(Application *)[WOApplication application] channelRegistry];
  return [registry registeredProjectsForUser:[self remoteUser]];
}

- (NSNumber *)registerAction:(NSString *)_name:
                   (NSString *)_type:(NSDictionary *)_args
{
  ChannelRegistry *registry = nil;

  registry = [(Application *)[WOApplication application] channelRegistry];

  if ([registry isInRegistry:_name user:[self remoteUser]] == NO) {

    [registry addObjectToRegistry:_args type:_type name:_name
              user:[self remoteUser]];
    return [NSNumber numberWithBool:YES];
  }
  else {
    return [NSNumber numberWithBool:NO];
  }
}

- (NSDictionary *)getInfoAction:(id)_project {
  ChannelRegistry *registry = nil;

  registry = [(Application *)[WOApplication application] channelRegistry];
  return [registry infoForProject:_project user:[self remoteUser]];
}

- (NSDictionary *)getChangesAction:(id)_object {
  ChannelRegistry *registry = nil;

  registry = [(Application *)[WOApplication application] channelRegistry];
  return [registry updatesForCode:_object user:[self remoteUser]];
}

- (NSNumber *)resetChangesAction:(id)_object:(NSString *)_element {
  ChannelRegistry *registry = nil;

  registry = [(Application *)[WOApplication application] channelRegistry];
  return [NSNumber numberWithBool:[registry deleteUpdatesForCode:_object
                                            name:_element
                                            user:[self remoteUser]]];
}

- (id)registerActionAction:(NSString *)_name:(NSString *)_element:
           (NSString *)_actionType:(NSDictionary *)_args
{
  ChannelRegistry *registry = nil;
  
  registry = [(Application *)[WOApplication application] channelRegistry];
  return [registry registerAction:(NSString *)_name
                       forElement:(NSString *)_element
                             type:(NSString *)_actionType
                             args:(NSDictionary *)_args
                      user:[self remoteUser]];
}

@end /* SkyTrackAction */
