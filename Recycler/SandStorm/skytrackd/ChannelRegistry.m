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

#include "ChannelRegistry.h"
#include "Channel.h"
#include "ProjectChannel.h"
#include "Change.h"
#include "Action.h"
#include "ShellAction.h"
#include "common.h"

@implementation ChannelRegistry

- (id) init {
  if ((self = [super init])) {
    self->registry = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->registry);

  [super dealloc];
}

- (void)initChannelRegistry:(NSString *)_userDir {
  NSFileManager *fileManager  = nil;
  NSEnumerator  *pathEnum     = nil;
  NSString      *userFile     = nil;
  id            subdir        = nil;
  
  fileManager = [NSFileManager defaultManager];

  pathEnum = [[fileManager directoryContentsAtPath:_userDir] objectEnumerator];

  while ((subdir = [pathEnum nextObject])) {

    BOOL         isDir      = NO;
    NSArray      *entries   = nil;
    NSEnumerator *entryEnum = nil;
    id           entry      = nil;

    if (!([fileManager fileExistsAtPath:
                     [_userDir stringByAppendingPathComponent:subdir]
                      isDirectory:&isDir]) || !isDir) {
      continue;
    }

    userFile = [[_userDir stringByAppendingPathComponent:subdir]
                          stringByAppendingPathComponent:@"Channels.plist"];

    NSLog(@"loading userfile %@", userFile);
    
    entries = [NSArray arrayWithContentsOfFile:userFile];

    entryEnum = [entries objectEnumerator];

    while((entry = [entryEnum nextObject])) {
      Class    classType   = Nil;
      Channel  *channel    = nil;
      NSString *changeFile = nil;
 
      classType = NSClassFromString([entry objectForKey:@"type"]);
      channel = [[classType alloc] init];
      [channel initWithDictionary:entry name:[entry objectForKey:@"name"]];

      changeFile = [_userDir stringByAppendingPathComponent:
                             [entry objectForKey:@"name"]];
      changeFile = [changeFile stringByAppendingString:@".log"];

      if ([fileManager fileExistsAtPath:changeFile]) {
        NSMutableDictionary *dict       = nil; 
        NSDictionary        *changeInfo = nil;
        NSEnumerator        *dictEnum   = nil;
        id                  dictEntry   = nil;

        changeInfo = [NSDictionary dictionaryWithContentsOfFile:changeFile];
        dict = [NSMutableDictionary dictionaryWithCapacity:[changeInfo count]];
        
        dictEnum = [changeInfo keyEnumerator];
        
        while ((dictEntry = [dictEnum nextObject])) {
          Change  *change = nil;
          NSArray *actions = nil;
          NSEnumerator *actionEnum = nil;
          id           action = nil;
          
          change = [Change changeWithChangeType:
                           [[changeInfo valueForKey:dictEntry]
                                  valueForKey:@"type"]];

          actions = [[changeInfo valueForKey:dictEntry]
                                 valueForKey:@"actions"];

          actionEnum = [actions objectEnumerator];

          while((action = [actionEnum nextObject])) {
            Class actionClass = Nil;
            id actionObject;
            
            actionClass = NSClassFromString([action valueForKey:@"type"]);
            actionObject = [actionClass actionWithArguments:
                                        [action valueForKey:@"arguments"]];
            if (actionObject != nil) {
              [change addAction:actionObject];
            }
          }
          [dict setObject:change forKey:dictEntry];
        }

        [channel setChangeInfo:dict];
      }
      if ([self->registry valueForKey:subdir] == nil) {
        NSMutableArray *array = nil;

        array = [NSMutableArray arrayWithObject:channel];
        [self->registry setObject:array forKey:subdir];
      }
      else {
        [[self->registry objectForKey:subdir] addObject:channel];
      }
    }
  }
}

- (BOOL)isInRegistry:(NSString *)_key user:(NSString *)_user{
  NSEnumerator *registryEnum = nil;
  id           registryEntry = nil;
  
  registryEnum = [[self->registry objectForKey:_user] objectEnumerator];

  if (registryEnum != nil) {
    while((registryEntry = [registryEnum nextObject])) {
      if ([[registryEntry channelID] isEqualToString:_key]) {
        return YES;
      }
    }
  }
  return NO;
}

- (BOOL)addObjectToRegistry:(NSDictionary *)_object
                       type:(NSString *)_type
                       name:(NSString *)_name
                       user:(NSString *)_user
{
  Class classType = Nil;

  classType = NSClassFromString(_type);

  if (classType != nil) {
    Channel *chan = nil;

    chan = [[classType alloc] initWithDictionary:_object name:_name];
    [chan saveToUserFile:_user];

    if ([self->registry valueForKey:_user] == nil) {
      NSMutableArray *array = nil;

      array = [NSMutableArray arrayWithObject:chan];
      [self->registry setObject:array forKey:_user];
    }
    else {
      [[self->registry objectForKey:_user] addObject:chan];
    }
    return YES;
  }
  return NO;
}

- (NSDictionary *)updatesForCode:(NSString *)_key user:_user {
  NSEnumerator *registryEnum = nil;
  id           registryEntry = nil;
  
  registryEnum = [[self->registry objectForKey:_user] objectEnumerator];

  if (registryEnum != nil) {
    while((registryEntry = [registryEnum nextObject])) {
      if ([[registryEntry channelID] isEqualToString:_key]) {
        NSMutableDictionary *dict       = nil;
        NSDictionary        *changeInfo = nil;
        NSEnumerator        *dictEnum   = nil;
        id                  dictEntry   = nil;
        
        dict = [NSMutableDictionary dictionaryWithCapacity:16];
        changeInfo = [registryEntry changeInfo];
        
        dictEnum = [changeInfo keyEnumerator];

        while ((dictEntry = [dictEnum nextObject])) {
          [dict takeValue:[[changeInfo objectForKey:dictEntry] dictionary]
                forKey:dictEntry];
        }
        return dict;
      }
    }
  }
  return [NSDictionary dictionary];
}

- (NSArray *)registeredProjectsForUser:(NSString *)_user {
  NSEnumerator   *registryEnum = nil;
  id             registryEntry = nil;
  NSMutableArray *returnVal    = nil;
  
  registryEnum = [[self->registry objectForKey:_user] objectEnumerator];
  returnVal    = [NSMutableArray arrayWithCapacity:1];

  if (registryEnum != nil) {
    while((registryEntry = [registryEnum nextObject])) {
      [returnVal addObject:[registryEntry channelID]];
    }
  }
  return returnVal;
}

- (BOOL)deleteUpdatesForCode:(NSString *)_code
                        name:(NSString *)_element
                        user:(NSString *)_user
{
  NSEnumerator *registryEnum = nil;
  id           registryEntry = nil;

  registryEnum = [[self->registry objectForKey:_user] objectEnumerator];

  if(registryEnum != nil) {
    while((registryEntry = [registryEnum nextObject])) {
      if ([[registryEntry channelID] isEqualToString:_code]) {
        [(ProjectChannel*)registryEntry resetChanges:_element];
        return YES;
      }
    }
  }
  return NO;
}

- (NSDictionary *)infoForProject:(NSString *)_code
                     user:(NSString *)_user
{
  NSEnumerator *registryEnum = nil;
  id           registryEntry = nil;

  registryEnum = [[self->registry objectForKey:_user] objectEnumerator];

  if (registryEnum != nil) {
    while((registryEntry = [registryEnum nextObject])) {
      if ([[registryEntry channelID] isEqualToString:_code]) {
        return [registryEntry channelInfo];
      }
    }
  }
  return nil;
}

- (id)registerAction:(NSString *)_name
          forElement:(NSString *)_element
                type:(NSString *)_actionType
                args:(NSDictionary *)_args
                user:(NSString *)_user
{
  NSEnumerator *registryEnum = nil;
  id           registryEntry = nil;

  registryEnum = [[self->registry objectForKey:_user] objectEnumerator];

  if (registryEnum != nil) {
    while((registryEntry = [registryEnum nextObject])) {
      if ([[registryEntry channelID] isEqualToString:_name]) {
        Class regClass = Nil;
        id    action   = nil;
  
        regClass = NSClassFromString(_actionType);
        action = [regClass actionWithArguments:_args];

        [registryEntry registerAction:action forElement:_element];
        
        return nil;
      }
    }
  }
  return nil;
}

- (void)trackObjects {
  NSEnumerator *keyEnum;
  id           key;

  keyEnum = [self->registry keyEnumerator];

  while ((key = [keyEnum nextObject])) {
    [[self->registry objectForKey:key]
                     makeObjectsPerformSelector:@selector(trackChannel)];
  }
}

@end /* ChannelRegistry */
