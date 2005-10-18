/*
  Copyright (C) 2005 SKYRIX Software AG

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

#include <OGoFoundation/OGoContentPage.h>

@class NSMutableDictionary, NSUserDefaults;

@interface OGoRegPage : OGoContentPage
{
  NSMutableDictionary *private;
  NSUserDefaults *defaults;
}

@end

#include "common.h"

@implementation OGoRegPage

+ (void)initialize {
  // NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
}

- (id)init {
  id p;

  /* this component is a session-singleton */
  if ((p = [self persistentInstance]) != nil) {
    [self release];
    return [p retain];
  }
  
  if ((self = [super init]) != nil) {
    [self registerAsPersistentInstance];
  }
  return self;
}

- (void)dealloc {
  [self->defaults release];
  [self->private  release];
  [super dealloc];
}

/* mark as editor page (to avoid refreshes) */

- (BOOL)isEditorPage {
  return YES;
}

/* load data */

- (id)firstValueForKey:(NSString *)_key inArray:(NSArray *)_array {
  unsigned i, count;

  for (i = 0, count = [_array count]; i < count; i++) {
    id v;
    
    v = [[_array objectAtIndex:i] valueForKey:_key];
    if ([v isNotEmpty]) return v;
  }
  return nil;
}

- (void)_loadData {
  NSArray *addrs;
  id account;
  id tmp;

  /* fetch account data from database */
  
  account = [[self session] activeAccount];
  account = [self runCommand:@"person::get",
                    @"companyId",  [account valueForKey:@"companyId"],
                  nil];
  if ([account isKindOfClass:[NSArray class]])
    account = [account isNotEmpty] ? [account lastObject] : nil;

  /* setup private data dict */
  
  self->private = [[NSMutableDictionary alloc] initWithCapacity:16];
  
  if ([(tmp = [account valueForKey:@"name"]) isNotEmpty])
    [self->private setObject:tmp forKey:@"lastname"];
  if ([(tmp = [account valueForKey:@"firstname"]) isNotEmpty])
    [self->private setObject:tmp forKey:@"firstname"];
  
  if ([(tmp = [account valueForKey:@"email"]) isNotEmpty])
    [self->private setObject:tmp forKey:@"email"];
  else if ([(tmp = [account valueForKey:@"email1"]) isNotEmpty])
    [self->private setObject:tmp forKey:@"email"];
  
  addrs = [self runCommand:@"address::get",
                @"companyId",  [account valueForKey:@"companyId"],
                @"returnType", intObj(LSDBReturnType_ManyObjects),
             nil];
  
  if ((tmp = [self firstValueForKey:@"city" inArray:addrs]) != nil)
    [self->private setObject:tmp forKey:@"city"];
  if ((tmp = [self firstValueForKey:@"zip" inArray:addrs]) != nil)
    [self->private setObject:tmp forKey:@"zip"];
  if ((tmp = [self firstValueForKey:@"state" inArray:addrs]) != nil)
    [self->private setObject:tmp forKey:@"state"];
  if ((tmp = [self firstValueForKey:@"country" inArray:addrs]) != nil)
    [self->private setObject:tmp forKey:@"country"];
}

/* accessors */

- (void)setPrivate:(id)_data {
  // noop
}
- (NSMutableDictionary *)private {
  if (self->private == nil)
    [self _loadData];
  return self->private;
}

- (NSUserDefaults *)userDefaults {
  if (self->defaults == nil)
    self->defaults = [[[self session] userDefaults] retain];
  return self->defaults;
}
- (NSUserDefaults *)systemUserDefaults {
  return [NSUserDefaults standardUserDefaults];
}

/* notifications */

- (void)sleep {
  [super sleep];
  [self->defaults release]; self->defaults = nil;
}

/* defaults operations */

- (void)postDockReloadNotification {
  [[NSNotificationCenter defaultCenter]
                         postNotificationName:@"SkyDockReload"
                         object:[self userDefaults]];
}

- (void)_writeDefault:(NSString *)_key value:(id)_value {
  [self runCommand:@"userdefaults::write",
	  @"key",      _key,
          @"value",    _value,
          @"defaults", [self userDefaults],
          @"userId", [[[self session] activeAccount] valueForKey:@"companyId"],
	nil];
}

/* dock operations */

- (BOOL)removeOrRepositionRegistrationInDock:(BOOL)_doRemove {
  NSArray *dockKeys;
  NSMutableArray *tmp;
  
  dockKeys = [[self userDefaults] arrayForKey:@"SkyDockablePagesOrdering"];
  if (![dockKeys containsObject:@"Registration"]) {
    [self warnWithFormat:@"Registration page is not in dock ..."];
    return NO;
  }
  if (![dockKeys isNotEmpty])
    return NO;
  
  tmp = [dockKeys mutableCopy];
  [tmp removeObject:@"Registration"];
  if (!_doRemove) [tmp addObject:@"Registration"];
  
  [self _writeDefault:@"SkyDockablePagesOrdering" value:tmp];
  [tmp release]; tmp = nil;
  
  [self postDockReloadNotification];

  return YES;
}

- (NSDictionary *)bundleInfoForDockKey:(NSString *)_key {
  NGBundleManager *bm;
  NSBundle *bundle;
  
  if (![_key isNotEmpty]) return nil;
  
  bm     = [NGBundleManager defaultBundleManager];
  bundle = [bm bundleProvidingResource:_key ofType:@"DockablePages"];
  if (bundle == nil) {
    [self warnWithFormat:@"did not find bundle for dockable page: '%@'", _key];
    return nil;
  }
  
  return [bundle configForResource:_key ofType:@"DockablePages"];
}

- (id)firstPageInDock {
  NSDictionary *dockInfo;
  NSArray  *dockKeys;
  NSString *dockKey;
  
  dockKeys = [[self userDefaults] arrayForKey:@"SkyDockablePagesOrdering"];
  dockKey  = [dockKeys isNotEmpty] ? [dockKeys objectAtIndex:0] : nil;
  dockInfo = [self bundleInfoForDockKey:dockKey];
  return [self pageWithName:[dockInfo valueForKey:@"component"]];
}

/* actions */

- (id)doRegister {
  // TODO: submit info, remove page from dock and jump to first page
  [self setErrorString:@"reg not yet enabled."];

  // [self removeOrRepositionRegistrationInDock:YES];
  return [self firstPageInDock];
}

- (id)doRegisterLater {
  [self logWithFormat:@"account has choosen to register later: %@",
        [[[self session] activeAccount] valueForKey:@"login"]];
  [self removeOrRepositionRegistrationInDock:NO];
  return [self firstPageInDock];
}

- (id)doNeverRegister {
  /* remove panel from dock and jump to first page */
  [self logWithFormat:@"account has choosen not to register: %@",
        [[[self session] activeAccount] valueForKey:@"login"]];
  [self removeOrRepositionRegistrationInDock:YES];
  return [self firstPageInDock];
}

@end /* OGoRegPage */
