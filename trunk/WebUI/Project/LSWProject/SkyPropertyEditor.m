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

#include <OGoFoundation/LSWEditorPage.h>

@class EOGlobalID, NSString;

@interface SkyPropertyEditor : LSWEditorPage
{
@protected
  NSString   *namespace;
  NSString   *key;
  id         value;
  BOOL       isNew;
  EOGlobalID *gid;
  NSString   *propertyType;
}
@end

#include "common.h"

@interface NSObject(Private)
- (id)commandContext;
@end

@implementation SkyPropertyEditor

- (void)dealloc {
  RELEASE(self->namespace);
  RELEASE(self->key);
  RELEASE(self->value);
  RELEASE(self->gid);
  RELEASE(self->propertyType);
  [super dealloc];
}

/* activation */

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  if (![super prepareForActivationCommand:_command type:_type
              configuration:_cmdCfg])
    return NO;

  self->isNew = [_command isEqualToString:@"new"];
  NSAssert(self->isNew, @"SkyPropertyEditor handles only 'new' property");
  return YES;
}

- (NSNumber *)_coerceValueToNumber:(id)_value {
  return [NSNumber numberWithInt:[_value intValue]];
}
- (NSCalendarDate *)_coerceValueToCalendarDate:(id)_value {
  NSCalendarDate *tmp;
  
  if ((tmp = [NSCalendarDate dateWithString:_value]))
    return tmp;
  
  tmp = [NSCalendarDate dateWithString:_value 
			calendarFormat:@"%Y-%m-%d %H:%M"];
  if (tmp) return tmp;
  
  tmp = [NSCalendarDate dateWithString:_value calendarFormat:@"%Y-%m-%d"];
  return tmp;
}
- (id)_coerceValue:(id)_value toType:(NSString *)_type {
  if ([_type isEqualToString:@"number"])
    return [self _coerceValueToNumber:_value];
  if ([_type isEqualToString:@"date"])
    return [self _coerceValueToCalendarDate:_value];
  
  return _value;
}

- (NSString *)_propertyKey {
  if (self->namespace != nil) {
    return [[[@"{" stringByAppendingString:self->namespace]
                   stringByAppendingString:@"}"]
                   stringByAppendingString:self->key];
  }
  return self->key;
}

- (id)save {
  SkyObjectPropertyManager *objProp;
  NSException              *exc     = nil;
  NSString                 *k       = nil;
  NSDictionary *props;
  id           tmp;

  objProp = [[[self session] commandContext] propertyManager];

  if (self->value == nil || self->key == nil) {
    NSLog(@"return nil");
    return [self back];
  }
  
  k = [self _propertyKey];
  
  tmp = [self _coerceValue:self->value toType:self->propertyType];
  ASSIGN(self->value, tmp);
  
  if (self->value == nil) {
    // TODO: improve error message!
    [self logWithFormat:@"ERROR: did not find a value"];
    return nil;
  }
  
  props = [NSDictionary dictionaryWithObject:self->value forKey:k];
  if (self->isNew) {
    exc = [objProp addProperties:props
                   accessOID:[[[self session] activeAccount] globalID]
                   globalID:self->gid];
  }
  else
    exc = [objProp takeProperties:props globalID:self->gid];
  
  if (exc != nil)
    [self logWithFormat:@"WARNING save failed with exception: %@", exc];

  return [self back];
}

- (id)cancel {
  return [self back] ; 
}

- (BOOL)isDeleteDisabled {
  return self->isNew;
}

- (BOOL)isNew {
  return self->isNew;
}

- (void)takeValue:(id)_v forKey:(id)_k {
  if ([_k isEqualToString:@"gid"]) {
    ASSIGN(self->gid, _v);
    return;
  }
  if ([_k isEqualToString:@"namespace"]) {
    ASSIGNCOPY(self->namespace, _v);
    return;
  }
  if ([_k isEqualToString:@"key"]) {
    ASSIGNCOPY(self->key, _v);
  }
  if ([_k isEqualToString:@"value"]) {
    _v = [_v stringValue];
    ASSIGNCOPY(self->value, _v);
    return;
  }
  if ([_k isEqualToString:@"propertyType"]) {
    ASSIGNCOPY(self->propertyType, _v);
    return;
  }

  [super takeValue:_v forKey:_k];
}

- (id)valueForKey:(id)_k {
  if ([_k isEqualToString:@"gid"])
    return self->gid;
  if ([_k isEqualToString:@"namespace"])
    return self->namespace;
  if ([_k isEqualToString:@"key"])
    return self->key;
  if ([_k isEqualToString:@"value"])
    return self->value;
  if ([_k isEqualToString:@"propertyType"])
    return self->propertyType;
  
  return [super valueForKey:_k];
}

@end /* SkyPropertyEditor */
