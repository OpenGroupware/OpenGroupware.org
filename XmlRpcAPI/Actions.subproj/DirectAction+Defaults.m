/*
  Copyright (C) 2000-2004 SKYRIX Software AG

  This file is part of OpenGroupware.org

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

#include "DirectAction.h"
#include "common.h"

@implementation DirectAction(Defaults)

- (NSUserDefaults *)_defaults {
#if 0 /* old behaviour */
  return [NSUserDefaults standardUserDefaults];
#else
  return [[self commandContext] userDefaults];
#endif
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

@end /* DirectAction(Defaults) */
