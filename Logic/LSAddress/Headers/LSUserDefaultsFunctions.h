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

#ifndef __LSLogic_LSAddress_LSUserDefaultsFunctions_H__
#define __LSLogic_LSAddress_LSUserDefaultsFunctions_H__

#import <Foundation/NSObject.h>

@class NSString, NSNumber;
@class NSDictionary, NSMutableDictionary;
@class NSUserDefaults;

NSString *__getUserDefaultsPath_LSLogic_LSAddress(id self, id _context,
                                                  NSNumber *_uid);

NSMutableDictionary *__getUserDefaults_LSLogic_LSAddress(id self,id _context,
                                                         NSNumber *_uid);

void __writeUserDefaults_LSLogic_LSAddress(id self,id _context,
                                           NSMutableDictionary *_defaults,
                                           NSNumber *_uid);

void __registerVolatileLoginDomain_LSLogic_LSAddress(id self, id _context,
                                                     NSUserDefaults *_defaults,
                                                     NSDictionary *_domain,
                                                     NSNumber *_uid);

#endif /* __LSLogic_LSAddress_LSUserDefaultsFunctions_H__ */
