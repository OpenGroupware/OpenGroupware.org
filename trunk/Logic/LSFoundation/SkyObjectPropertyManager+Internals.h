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

#ifndef __SkyObjectPropertyManager_Internals_H__
#define __SkyObjectPropertyManager_Internals_H__

#import <Foundation/NSString.h>
#include <LSFoundation/SkyObjectPropertyManager.h>

@class NSString, NSNumber, NSCalendarDate, NSData;

typedef struct {
  NSString       *pType;
  NSString       *vString;
  NSNumber       *vInt;
  NSNumber       *vFloat;
  NSCalendarDate *vDate;
  NSNumber       *vOID;
  NSNumber       *bSize;
  NSData         *vBlob;
} SkyPropValues;

@interface NSObject(SkyPropValues)

- (NSString *)_skyPropValueKind;
- (void)_buildSkyPropValues:(SkyPropValues *)_vals;

@end

@interface NSString(SkyPropNamespaces)

- (void)_extractSkyPropNamespace:(NSString **)namespace_
  andLocalKey:(NSString **)key_
  withDefaultNamespace:(NSString *)_defns;

@end

@class NSTimeZone, NSMutableString;
@class EOAttribute;

@interface SkyObjectPropertyManager(Internals)

+ (void)__initialize__Internals__;
- (NSTimeZone *)_defaultTimeZone;
- (NSString *)_qualifierInStringForGIDs:(NSArray *)_gids;
- (void)_objectId:(id)_obj
  objectId:(id *)objectId_
  objectType:(id *)objectType_;

- (BOOL)_keyAlreadyExist:(NSString *)_key
  namespace:(NSString *)_namespace
  objectId:(NSNumber *)_oid;

- (NSString *)_buildKeyQualifier:(NSArray *)_keys
  objectId:(NSNumber *)_objId;

- (BOOL)_operation:(NSString *)_operation allowedOnProperties:(NSArray *)_prop;
- (void)_disassembleContainerQualifer:(EOQualifier *)_qualifier
  kvQuals:(NSMutableArray *)kvQualifiers_
  notQuals:(NSMutableArray *)notQualifiers_
  orQuals:(NSMutableArray *)orQualifiers_
  andQuals:(NSMutableArray *)andQualifiers_;

- (NSMutableString *)_buildSQLWithPropQual:(EOQualifier *)_qualifier
  objType:(NSString *)_objType identifier:(NSString *)_ident;
- (NSException *)_updateProperties:(NSDictionary *)_properties 
  globalID:(id)_gid checkExist:(BOOL)_check;
- (NSException *)_addProperties:(NSDictionary *)_properties 
  accessOID:(EOGlobalID *)_access globalID:(id)_gid checkExist:(BOOL)_check;
- (NSDictionary *)_accessOIDsForGIDs:(NSArray *)_gids;
- (void)_postChangeNotificationForGID:(EOGlobalID *)_gid;
- (NSString *)value:(id)_value forAttr:(EOAttribute *)_attr;
- (NSDictionary *)mapOIDsWithGIDs:(NSArray *)_gids;

@end

#endif /* __SkyObjectPropertyManager_Internals_H__ */
