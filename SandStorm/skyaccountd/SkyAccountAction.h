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

#ifndef __skyaccountd_DirectAction_H__
#define __skyaccountd_DirectAction_H__

#include <OGoDaemon/SDXmlRpcAction.h>

@interface SkyAccountAction : SDXmlRpcAction
{
  int      loginId;
  NSString *login;
}

- (BOOL)isRoot;
- (int)loginId;
- (NSString *)login;
- (NSException *)buildExceptonWithNumber:(int)_number
  reason:(NSString *)_reason command:(char *)_funtction;
- (id)application;

- (NSArray *)groupKeys;
- (NSArray *)accountKeys;
- (NSArray *)dbKeys;


@end /* DirectAction */

#endif /* __skyaccountd_DirectAction_H__ */
