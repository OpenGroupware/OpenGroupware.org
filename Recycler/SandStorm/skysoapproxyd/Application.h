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

#ifndef __SkySoapProxyDaemon__Application_H__
#define __SkySoapProxyDaemon__Application_H__

#include <NGObjWeb/WOApplication.h>

@class NSString, NSMutableDictionary;
@class NGSoapClient;

@interface Application : WOApplication
{
  NSMutableDictionary *clientCache;
  NSMutableDictionary *configs;
  NSArray             *methods;
}

- (void)removeClientForLocation:(NSString *)_location;
- (void)setClient:(NGSoapClient *)_client forLocation:(NSString *)_location;
- (NGSoapClient *)clientForLocation:(NSString *)_location;

- (void)removeConfigForKey:(NSString *)_key;
- (void)setConfig:(NSDictionary *)_config forKey:(NSString *)_key;
- (NSDictionary *)configForKey:(NSString *)_key;

- (NSArray *)keys;

- (void)setMethods:(NSArray *)_methods;
- (NSArray *)methods;

@end

#endif /* __SkySoapProxyDaemon__Application_H__ */
