/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include "LSDBObjectCommandException.h"
#include "common.h"

@implementation LSDBObjectCommandException

+ (id)raiseOnFail:(BOOL)_status object:(id)_object reason:(NSString *)_reason {
  if (_status)
    return nil;
  
  [[self exceptionWithStatus:_status object:_object reason:_reason 
         userInfo:nil]
         raise];

  return nil;
}

+ (id)raiseOnFail:(BOOL)_status object:(id)_object reason:(NSString *)_reason
  userInfo:(NSDictionary *)_userInfo 
{
  if (_status)
    return nil;
  
  [[self exceptionWithStatus:_status object:_object reason:_reason
         userInfo:_userInfo] raise];

  return nil;
}

+ (id)exceptionWithStatus:(BOOL)_status object:(id)_object
  reason:(NSString *)_reason userInfo:(NSDictionary *)_userInfo
{
  return [[self alloc] initWithStatus:_status object:_object reason:_reason
                       userInfo:_userInfo];
}

- (id)initWithStatus:(BOOL)_status object:(id)_object 
  reason:(NSString *)_reason userInfo:(NSDictionary *)_userInfo 
{
  self = [super initWithName:@"LSDBObjectCommandException" reason:_reason
		userInfo:_userInfo];
  if (self) {
    self->object = [_object retain];
    self->status = _status;
  }
  return self;
}

/* accessors */

- (id)object {
  return self->object;
}

- (BOOL)status {
  return self->status;
}

@end /* LSDBObjectCommandException */
