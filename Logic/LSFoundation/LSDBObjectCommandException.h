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
// $Id: LSDBObjectCommandException.h 1 2004-08-20 11:17:52Z znek $

#ifndef __LSLogic_LSFoundation_LSDBObjectCommandException_H__
#define __LSLogic_LSFoundation_LSDBObjectCommandException_H__

#import <Foundation/NSException.h>

@interface LSDBObjectCommandException : NSException
{
@protected
  id   object;
  BOOL status;
}

+ (id)raiseOnFail:(BOOL)_status
  object:(id)_object
  reason:(NSString *)_reason;

+ (id)raiseOnFail:(BOOL)_status
  object:(id)_object
  reason:(NSString *)_reason
  userInfo:(NSDictionary *)_userInfo;

+ (id)exceptionWithStatus:(BOOL)_status
  object:(id)_object
  reason:(NSString *)_reason
  userInfo:(NSDictionary *)_userInfo;

- (id)initWithStatus:(BOOL)_status
  object:(id)_object
  reason:(NSString *)_reason
  userInfo:(NSDictionary *)_userInfo;

// accessors

- (id)object;
- (BOOL)status;

@end

#endif /* __LSLogic_LSFoundation_LSDBObjectCommandException_H__ */
