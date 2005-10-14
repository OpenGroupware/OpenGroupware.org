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

@class NSMutableDictionary;

@interface OGoRegPage : OGoContentPage
{
  NSMutableDictionary *private;
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
  [self->private release];
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
  return [[self session] userDefaults];
}

/* notifications */

- (void)sleep {
  [super sleep];
}

/* dock operations */

- (void)removeRegistrationFromDock {
  // TODO
}
- (id)firstPageInDock {
  // TODO
  return nil;
}

/* actions */

- (id)doRegister {
  // TODO: submit info, remove page from dock and jump to first page
  [self setErrorString:@"reg not yet enabled."];

  [self removeRegistrationFromDock];
  return [self firstPageInDock];
}

- (id)doRegisterLater {
  // TODO: move panel to last position in dock and jump to first page
  [self setErrorString:@"reg not yet enabled."];
  
  return [self firstPageInDock];
}

- (id)doNeverRegister {
  // TODO: remove panel from dock and jump to first page
  [self setErrorString:@"disable not yet implemented"];

  [self removeRegistrationFromDock];
  return [self firstPageInDock];
}

@end /* OGoRegPage */
