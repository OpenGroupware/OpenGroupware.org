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

@interface NSObject(Private)
- (id)commandContext;
@end

@interface SkyPropertiesEditor : LSWEditorPage
{
@protected
  NSString            *namespace;
  EOGlobalID          *gid;
  id                  item;
  NSMutableDictionary *properties;
}
@end

#include "common.h"

@implementation SkyPropertiesEditor

- (id)init {
  if ((self = [super init])) {
    self->namespace  = nil;
    self->gid        = nil;
    self->item       = nil;
    self->properties = nil;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->namespace);
  RELEASE(self->gid);
  RELEASE(self->item);
  RELEASE(self->properties);
  [super dealloc];
}
#endif

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  if ([super prepareForActivationCommand:_command type:_type
             configuration:_cmdCfg]) {
  }
  return YES;
}

- (void)syncAwake {
  if (self->properties == nil) {
    SkyObjectPropertyManager *objProp    = nil;
    NSEnumerator             *enumerator = nil;
    id                       key         = nil;
    NSDictionary             *dict       = nil;

    objProp = [[[self session] commandContext] propertyManager];

    dict = [objProp propertiesForGlobalID:self->gid namespace:self->namespace];
    
    enumerator       = [dict keyEnumerator];
    self->properties = [[NSMutableDictionary alloc] init];
    
    while ((key = [enumerator nextObject])) {
      NSMutableDictionary *d         = nil;
      NSString            *className = nil;
      id                  v          = nil;

      v = [dict objectForKey:key];
      d = [[NSMutableDictionary alloc] init];
      [d setObject:v                            forKey:@"value"];
      [d setObject:[NSNumber numberWithBool:NO] forKey:@"delete"];
      
      if ([v isKindOfClass:[NSNumber class]]) {
        className = @"number";
      }
      else if ([v isKindOfClass:[NSDate class]]) {
        className = @"date";
      }
      else
        className = @"string";
      
      [d setObject:className forKey:@"className"];
      [self->properties setObject:d forKey:key];
      RELEASE(d); d = nil;
    }
  }
  [super syncAwake];
}

- (void)syncSleep {
  RELEASE(self->properties); self->properties = nil;
  RELEASE(self->item);       self->item       = nil;
  [super syncSleep];
}

- (id)new {
  id page = nil;

  page = [[self session] instantiateComponentForCommand:@"new"
                         type:[NGMimeType mimeType:@"gid" subType:@"property"]];
  [page takeValue:[[self object] globalID] forKey:@"gid"];
  [page takeValue:self->namespace          forKey:@"namespace"];
  [self enterPage:page];
  return nil;
}

- (id)save {
  SkyObjectPropertyManager *objProp    = nil;
  NSException              *exc        = nil;
  NSMutableDictionary      *prop       = nil;
  NSEnumerator             *enumerator = nil;
  id                       key         = nil;

  prop       = [[NSMutableDictionary alloc] init];
  objProp    = [[[self session] commandContext] propertyManager];
  enumerator = [self->properties keyEnumerator];
  while ((key = [enumerator nextObject])) {
    [prop setObject:[[self->properties objectForKey:key] objectForKey:@"value"]
          forKey:key];
  }
  exc = [objProp takeProperties:prop globalID:self->gid];
  if (exc != nil) {
    NSLog(@"WARNING save failed with exception %@", exc);
  }
  RELEASE(prop); prop = nil;
  return [self back];
}

- (id)deleteAction {
  SkyObjectPropertyManager *objProp;
  NSEnumerator             *enumerator;
  id                       key;
  NSMutableArray           *array;

  array = [[NSMutableArray alloc] initWithCapacity:4];

  enumerator = [self->properties keyEnumerator];
  while ((key = [enumerator nextObject])) {
    NSDictionary *p;
    
    p = [self->properties objectForKey:key];
    if (![[p objectForKey:@"delete"] boolValue])
      continue;
    
    [array addObject:key];
  }
  objProp = [[[self session] commandContext] propertyManager];
  [objProp removeProperties:array globalID:self->gid];
  [array release];
  return [self back]; 
}

- (id)cancel {
  return [self back] ; 
}

- (id)properties {
  return [self->properties allKeys];
}

- (id)item {
  return self->item;
}
- (void)setItem:(id)_id {
  ASSIGN(self->item, _id);
}

- (id)key {
  return [self->item substringFromIndex:[self->namespace length] + 2];
}

- (NSCalendarDate *)_coerceValueToCalendarDate:(id)_v {
  id tmp;

  if (![_v isNotNull]) return nil;
  _v = [_v stringValue];
  
  if ((tmp = [NSCalendarDate dateWithString:_v]))
    return tmp;

  tmp = [NSCalendarDate dateWithString:_v calendarFormat:@"%Y-%m-%d %H:%M"];
  if (tmp) return tmp;
  
  tmp = [NSCalendarDate dateWithString:_v calendarFormat:@"%Y-%m-%d"];
  return tmp;
}
- (NSNumber *)_coerceValueToNumber:(id)_v {
  return [NSNumber numberWithInt:[_v intValue]];
}
- (id)_coerceValue:(id)_v toType:(NSString *)_type {
  if ([_type isEqualToString:@"date"]) {
    id tmp;
    
    if ((tmp = [self _coerceValueToCalendarDate:_v]))
      _v = tmp;
    else {
      [self logWithFormat:@"could not convert string to date, using now."];
      _v = [NSCalendarDate date];
    }
    return _v;
  }
  if ([_type isEqualToString:@"number"])
    return [self _coerceValueToNumber:_v];
  return _v;
}

- (void)setValue:(id)_v {
  NSString *className;

  className = [[self->properties objectForKey:self->item]
                                 objectForKey:@"className"];
  
  _v = [self _coerceValue:_v toType:className];
  [[self->properties objectForKey:self->item] setObject:_v forKey:@"value"];
}
- (id)value {
  return [[self->properties objectForKey:self->item] objectForKey:@"value"];
}

- (BOOL)deleteFlag {
  return [[[self->properties objectForKey:self->item] objectForKey:@"delete"]
                             boolValue];
}

- (void)setDeleteFlag:(BOOL)_bool {
  [[self->properties objectForKey:self->item]
                     setObject:[NSNumber numberWithBool:_bool] 
                     forKey:@"delete"];
}

- (void)takeValue:(id)_v forKey:(id)_k {
  if ([_k isEqualToString:@"gid"]) {
    ASSIGN(self->gid, _v);
    return;
  }

  if ([_k isEqualToString:@"namespace"]) {
    ASSIGN(self->namespace, _v);
    return;
  }

  [super takeValue:_v forKey:_k];
}

- (id)valueForKey:(id)_k {
  if ([_k isEqualToString:@"gid"])
    return self->gid;
  
  if ([_k isEqualToString:@"namespace"])
    return self->namespace;

  return [super valueForKey:_k];
}

@end /* SkyPropertiesEditor */
