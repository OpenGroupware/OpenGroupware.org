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

#ifndef __LSUserDefaults_H__
#define __LSUserDefaults_H__

#if 0
# import <Foundation/NSUserDefaults.h>
# define _NSUserDefaults NSUserDefaults
#else
# include "_NSUserDefaults.h"
# define _NSUserDefaults lfNSUserDefaults
#endif

@class LSCommandContext;
@class NSUserDefaults;

@interface LSUserDefaults : _NSUserDefaults
{
@protected
  NSUserDefaults      *standardUserDefaults;
  NSMutableDictionary *map;
  NSMutableDictionary *values;
  LSCommandContext    *context;
  BOOL                isChanged;
  id                  account;
}

- (id)init;
- (id)initWithUserDefaults:(NSUserDefaults *)_ud;

// designated initializer:
- (id)initWithUserDefaults:(NSUserDefaults *)_ud
  andContext:(LSCommandContext *)_ctx;

- (void)setAccount:(id)_account;
- (id)account;

@end

#endif /* __LSUserDefaults_H__ */
