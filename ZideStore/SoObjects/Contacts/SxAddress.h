/*
  Copyright (C) 2002-2004 SKYRIX Software AG

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

#ifndef __sxdavd_SxAddress_H__
#define __sxdavd_SxAddress_H__

#include <ZSFrontend/SxObject.h>

@class NSMutableDictionary, NSDictionary, NSMutableArray;
@class EOFetchSpecification;
@class SxContactManager;

@interface SxAddress : SxObject
{
  BOOL isPrivate;
  BOOL isAccount;

  id company;
  id subCompany;
  NSMutableDictionary *addr;
  NSMutableDictionary *phones;
}

- (void)markAsPrivate;
- (void)markAsAccount;

- (BOOL)fillCompanyRecord:(NSMutableDictionary *)values
  from:(NSDictionary *)_setProps
  keySet:(NSMutableArray *)keys;

- (SxContactManager *)contactManagerInContext:(id)_ctx;
- (void)clearVars;

- (NSString *)baseURL;

@end /* SxAddress */

#endif /* __sxdavd_SxAddress_H__ */
