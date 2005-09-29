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

#include "LSBundleCmdFactory.h"
#include "common.h"
#include <LSFoundation/LSCommand.h>
#include <NGExtensions/NGBundleManager.h>

@interface _LSBundleCommandInfo : NSObject
{
@public
  NSString     *command;
  NSString     *domain;
  NSString     *operation;
  NSString     *commandClassName;
  Class        commandClass;
  NSDictionary *config;
}

- (id)initWithName:(NSString *)_name className:(NSString *)_cname
  config:(NSDictionary *)_config;

@end

@implementation LSBundleCmdFactory

- (id)init {
  if ((self = [super init])) {
    self->nameToInfo = NSCreateMapTable(NSObjectMapKeyCallBacks,
                                        NSObjectMapValueCallBacks,
                                        512);
  }
  return self;
}

- (void)dealloc {
  [self->commandsProvidedByBundles release];
  [self->lastBundleQuery           release];
  if (self->nameToInfo) NSFreeMapTable(self->nameToInfo);
  [super dealloc];
}

/* parsing command model files */

- (void)processCommandDictionary:(NSDictionary *)_commands
  ofBundle:(NSBundle *)_bundle
{
  _LSBundleCommandInfo *info;
  NSDictionary *domainList;
  NSDictionary *domains;
  NSEnumerator *domainKeys;
  NSString     *domainKey;
  NSZone       *z;

  //NSLog(@"processing commands.plist of %@", [_bundle bundleName]);

  z = [self zone];
  domainList = [_commands objectForKey:@"domainList"];
  domains    = [_commands objectForKey:@"domains"];
  domainKeys = [domains keyEnumerator];
  
  /* for each domain */
  while ((domainKey = [domainKeys nextObject])) {
    NSDictionary *domainInfo;
    NSDictionary *domainOps;
    NSEnumerator *opKeys;
    NSString     *opKey;
    NSString     *cmdPrefix;

    cmdPrefix  = [domainKey  stringByAppendingString:@"::"];
    domainInfo = [domains    objectForKey:domainKey];
    domainOps  = [domainInfo objectForKey:@"operations"];
    opKeys     = [domainOps  keyEnumerator];

    /* for each operation in domain */
    while ((opKey = [opKeys nextObject])) {
      NSString     *commandName;
      NSString     *commandClassName;
      NSDictionary *commandInfo;

      commandName      = [cmdPrefix stringByAppendingString:opKey];
      commandInfo      = [domainOps objectForKey:opKey];
      commandClassName = [commandInfo objectForKey:@"class"];
      commandName      = [commandName lowercaseString];

      if ((info = NSMapGet(self->nameToInfo, commandName))) {
        NSLog(@"command %@ already registered.");
        continue;
      }

      info = [[_LSBundleCommandInfo alloc]
                  initWithName:commandName
                  className:commandClassName
                  config:[commandInfo objectForKey:@"init"]];
      NSMapInsertKnownAbsent(self->nameToInfo, commandName, info);
      [info release]; info = nil;
    }
  }
}

/* command info lookup */

- (_LSBundleCommandInfo *)lookupInfoForCommand:(NSString *)_command
  inBundle:(NSBundle *)_bundle
{
  NSString *path;
  
  //NSLog(@"lookup info for command %@ in %@", _command, _bundle);
  
  if ((path = [_bundle pathForResource:@"commands" ofType:@"plist"]) == nil) {
    [self warnWithFormat:@"did not find commands.plist in bundle %@ !",
          [_bundle bundlePath]];
  }
  else {
    NSDictionary *commands;
    
    if ((commands = [NSDictionary dictionaryWithContentsOfFile:path])) {
      [self processCommandDictionary:commands ofBundle:_bundle];
    }
    else
      [self warnWithFormat:@"could not load commands model: %@", path];
  }
  
  /* look into info cache (which got filled previously) */
  return NSMapGet(self->nameToInfo, _command);
}

- (_LSBundleCommandInfo *)lookupInfoForCommand:(NSString *)_command {
  _LSBundleCommandInfo *info;
  NGBundleManager *bm;
  
  if (_command == nil) return nil;
  
  /* look into info cache */
  if ((info = NSMapGet(self->nameToInfo, _command)))
    return info;
  
  bm = [NGBundleManager defaultBundleManager];
  
  /* look whether command is provided by a bundle */
  if ([self->commandsProvidedByBundles containsObject:_command]) {
    /* yes, it is -> load info */
    NSBundle *bundle;

    bundle = [bm bundleProvidingResource:_command ofType:@"LSCommands"];
    if ((info = [self lookupInfoForCommand:_command inBundle:bundle]))
      return info;
  }
  
  /* query bundle manager for available commands */
  if (self->lastBundleQuery == nil) {
    NSArray *cmds;

    [self->commandsProvidedByBundles release];
    self->commandsProvidedByBundles = nil;
    
    if ((cmds = [bm providedResourcesOfType:@"LSCommands"]) != nil) {
      NSMutableSet *s;
      int i, count;
      BOOL cmdAvailable = NO;
      
      s = [[NSMutableSet alloc] initWithCapacity:[cmds count]];
      for (i = 0, count = [cmds count]; i < count; i++) {
        NSDictionary *bundleInfo;
        NSString     *cmdName;

        bundleInfo = [cmds objectAtIndex:i];
        cmdName    = [bundleInfo objectForKey:@"name"];

        if (cmdName == nil)
          continue;
        
        [s addObject:cmdName];
        if (!cmdAvailable) cmdAvailable = [cmdName isEqualToString:_command];
      }
      
      self->commandsProvidedByBundles = [s copy];
      [s release]; s = nil;
      
      if (cmdAvailable) {
        NSBundle *bundle;

        bundle = [bm bundleProvidingResource:_command ofType:@"LSCommands"];
        if ((info = [self lookupInfoForCommand:_command inBundle:bundle]))
          return info;
      }
    }

    [self->lastBundleQuery release]; self->lastBundleQuery = nil;
    self->lastBundleQuery = [[NSDate alloc] init];
  }
  return nil;
}

/* command instantiation */

- (id<NSObject,LSCommand>)instantiateCommandUsingInfo:(_LSBundleCommandInfo *)_i
{
  id cmd;

  //NSLog(@"instantiate command %@", _i->command);
  
  if (_i->commandClass == Nil)
    _i->commandClass = NSClassFromString(_i->commandClassName);
  
  if (_i->commandClass == nil) {
    [self errorWithFormat:@"did not find class %@ for command %@",
          _i->commandClassName, _i->command];
    return nil;
  }

  cmd = [_i->commandClass alloc];
  if (_i->config) {
    cmd = [cmd initForOperation:_i->operation inDomain:_i->domain
               initDictionary:_i->config];
  }
  else {
    cmd = [cmd initForOperation:_i->operation inDomain:_i->domain];
  }
  return [cmd autorelease];
}

/* command lookup */

- (id)command:(NSString *)_operation inDomain:(NSString *)_domain {
  NSString *s;

  s = [[_domain stringByAppendingString:@"::"] 
	        stringByAppendingString:_operation];
  return [self lookupCommand:s];
}

- (id)lookupCommand:(NSString *)_command {
  _LSBundleCommandInfo   *info;
  id<NSObject,LSCommand> cmd;

  _command = [_command lowercaseString];
  //NSLog(@"lookup %@", _command);
  
  if ((info = [self lookupInfoForCommand:_command]) == nil) {
    NSLog(@"lookup of %@ failed, missing info", _command);
    return nil;
  }

  if ((cmd = [self instantiateCommandUsingInfo:info]) == nil) {
    NSLog(@"lookup of %@ failed, instantiation failed", _command);
    return nil;
  }
  return cmd;
}

@end /* LSBundleCmdFactory */

@implementation _LSBundleCommandInfo

- (id)initWithName:(NSString *)_name className:(NSString *)_cname
  config:(NSDictionary *)_config
{
  int     idx;
  NSRange r;
  
  self = [super init];

  self->command          = [_name   copy];
  self->commandClassName = [_cname  copy];
  self->config           = [_config copy];
  
  r = [_name rangeOfString:@"::"];
  idx = r.location;
  if (r.length > 0) {
    self->domain    = [[_name substringToIndex:r.location] copy];
    self->operation = 
      [[_name substringFromIndex:(r.location + r.length)] copy];
  }
  else {
    self->domain    = @"default";
    self->operation = [self->command retain];
  }
  return self;
}

- (void)dealloc {
  [self->operation release];
  [self->domain    release];
  [self->command   release];
  [self->commandClassName release];
  [self->config    release];
  [super dealloc];
}

@end /* _LSBundleCommandInfo */
