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

#ifndef __Contacts_SxUpdateContact_H__
#define __Contacts_SxUpdateContact_H__

#import <Foundation/NSObject.h>

@class NSString, NSDictionary, SxFetchContact, NSNumber, NSMutableDictionary;

@interface SxUpdateContact : NSObject
{
  id           cmdCtx;
  id           object;
  NSNumber     *pKey;
  NSDictionary *attrs;
  id           fetchObject;
  NSString     *type;
  BOOL         wasNew;
  BOOL         incVersion;
}
- (id)initWithContext:(id)_ctx primaryKey:(id)_pkey
  attributes:(NSDictionary *)_attrs;

- (NSString *)entityName;
- (NSString *)setCommand;
- (Class)fetchObjectClass;

- (void)updateObject:(NSDictionary *)_vars;
- (SxFetchContact *)fetchObject;
- (id)object;

- (void)updatePhone:(NSString *)_key value:(id)_value;
- (void)updateAddress:(NSString *)_type
  values:(NSDictionary *)_vars;
- (id)update;

- (BOOL)wasNew;
- (void)setType:(NSString *)_type;
- (NSString *)type;

- (NSMutableDictionary *)setObjectValues:(NSDictionary *)_vars;
- (NSMutableDictionary *)checkForObjectModifications:(id)_eo
  in:(NSMutableDictionary *)_dict;

- (NSMutableDictionary *)setObjectValues:(NSDictionary *)_vars;

@end /* SxUpdateContact */


#endif /* __Contacts_SxUpdateContact_H__ */
