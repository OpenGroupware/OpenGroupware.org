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

#include "DirectAction.h"
#include "common.h"

@implementation DirectAction(Defaults)

- (id)_objectForDomain:(NSString *)_domain key:(NSString *)_key
  selector:(SEL)_selector
{
  NSDictionary   *dict;
  NSUserDefaults *ud;
  id             obj;

  ud   = [NSUserDefaults standardUserDefaults];
  [ud removePersistentDomainForName:_domain];
  dict = [ud persistentDomainForName:_domain];

  if (!dict) {
    [self logWithFormat:@"%s: Couldn`t find domain with name <%@>.",
          __PRETTY_FUNCTION__, _domain];
  }
  else {
    NSMutableArray *marray;
    
    marray = [[ud searchList] mutableCopy];
    [marray insertObject:_domain atIndex:0];
    [ud setSearchList:[[marray copy] autorelease]];
  }
  obj = [ud performSelector:_selector withObject:_key];
  [ud makeStandardDomainSearchList];
  return obj;
}

- (NSUserDefaults *)_defaults {
  return [NSUserDefaults standardUserDefaults];
}

- (id)defaults_arrayForKeyAction:(NSString *)_key {
  return [[self _defaults] arrayForKey:_key];
}
- (id)defaults_dictionaryForKeyAction:(NSString *)_key {
  return [[self _defaults] dictionaryForKey:_key];
}
- (id)defaults_objectForKeyAction:(NSString *)_key {
  return [[self _defaults] objectForKey:_key];
}
- (id)defaults_stringForKeyAction:(NSString *)_key {
  return [[self _defaults] stringForKey:_key];
}
- (id)defaults_dataForKeyAction:(NSString *)_key {
  return [[self _defaults] dataForKey:_key];
}

- (id)defaults_arrayForKeyAction:(NSString *)_key :(NSString *)_domain {
  return [self _objectForDomain:_domain key:_key
               selector:@selector(arrayForKey:)];
}
- (id)defaults_dictionaryForKeyAction:(NSString *)_key :(NSString *)_domain {
  return [self _objectForDomain:_domain key:_key
               selector:@selector(dictionaryForKey:)];
}
- (id)defaults_objectForKeyAction:(NSString *)_key :(NSString *)_domain {
  return [self _objectForDomain:_domain key:_key
               selector:@selector(objectForKey:)];
}
- (id)defaults_stringForKeyAction:(NSString *)_key :(NSString *)_domain {
  return [self _objectForDomain:_domain key:_key
               selector:@selector(stringForKey:)];
}
- (id)defaults_dataForKeyAction:(NSString *)_key :(NSString *)_domain {
  return [self _objectForDomain:_domain key:_key
               selector:@selector(dataForKey:)];
}

- (id)defaults_writeStringForKeyAction:(NSString *)_key :(NSString *)_val
                                      :(NSString *)_domain
{
  NSUserDefaults      *def;

  if (![self isCurrentUserRoot]) {
    return [self faultWithFaultCode:XMLRPC_MISSING_PERMISSIONS
                 reason:@"This function is only allowed to be used by 'root'"];
  }    
  def = [self _defaults];
  if ([_domain length] == 0) {
    [def setObject:_val forKey:_key];
    [def synchronize];
    return nil;
  }
  else {
    NSMutableDictionary *newDomain;

    newDomain  = [[def persistentDomainForName:_domain] mutableCopy];
    [newDomain setObject:_val forKey:_key];
    [def removePersistentDomainForName:_domain];
    [def setPersistentDomain:newDomain forName:_domain];
    [def synchronize];
  }
  return nil;
}
@end /* DirectAction(Defaults) */
