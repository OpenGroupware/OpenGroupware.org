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
// $Id: LSCommand.h 1 2004-08-20 11:17:52Z znek $

#ifndef __LSLogic_LSFoundation_LSCommand_H__
#define __LSLogic_LSFoundation_LSCommand_H__

#import <Foundation/NSObject.h>

@class NSString, NSDictionary;

@protocol LSCommand <NSObject>

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain;

// tx&channel support

- (BOOL)requiresTransaction;
- (BOOL)requiresChannel;

// execute the command
- (id)runInContext:(id)_context;

// key value coding
- (void)takeValue:(id)_value forKey:(NSString *)_key;
- (id)valueForKey:(NSString *)_key;

- (void)takeValuesFromDictionary:(NSDictionary *)_dict;

// accessors
- (BOOL)isCommandOk;

@end

@protocol LSInitializableCommand

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain
  initDictionary:(NSDictionary *)_dict;

@end

#endif /* __LSLogic_LSFoundation_LSCommand_H__ */
