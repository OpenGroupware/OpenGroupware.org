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

#include "OWPasteboard.h"
#include "common.h"

@interface OWPasteboard(PrivateMethods)
- (void)setOwner:(id)_owner;
@end

@implementation OWPasteboard

- (id)initWithName:(NSString *)_name { // designated initializer
  if ((self = [super init])) {
    self->name         = [_name copy];
    self->owner        = nil;
    self->changeCount  = 0;
    self->type2content = [[NSMutableDictionary alloc] initWithCapacity:16];
  }
  return self;
}
- (id)init {
  NSString *uid;
  
  uid = [[NSProcessInfo processInfo] globallyUniqueString];
  return [self initWithName:uid];
}

- (void)dealloc {
  [self->type2content  release];
  [self->declaredTypes release];
  [self->owner         release];
  [self->name          release];
  [super dealloc];
}

- (void)clear { /* remove all contents */
  [self->type2content removeAllObjects];
  [self->declaredTypes release]; self->declaredTypes = nil;
  [self setOwner:nil];
}

/* accessors */

- (NSString *)name {
  return self->name;
}

- (void)setOwner:(id)_owner {
  id oldOwner = self->owner;
  
  if (self->owner == _owner)
    return;
    
  self->owner = [_owner retain];

  if ([oldOwner respondsToSelector:@selector(pasteboardChangedOwner:)])
    [oldOwner pasteboardChangedOwner:self];
  [oldOwner release];
}
- (id)owner {
  return self->owner;
}

- (int)changeCount {
  return self->changeCount;
}

/* types */

- (int)declareTypes:(NSArray *)_types owner:(id)_newOwner {
  if (self->declaredTypes != _types) {
    RELEASE(self->declaredTypes); self->declaredTypes = nil;
    self->declaredTypes = [_types copyWithZone:[self zone]];
  }
  self->changeCount++;
  [self setOwner:_newOwner];
  return self->changeCount;
}
- (int)addTypes:(NSArray *)_types owner:(id)_newOwner {
  NSMutableArray *tmp = [self->declaredTypes mutableCopy];
  
  [tmp addObjectsFromArray:_types];
  [self->declaredTypes release]; self->declaredTypes = nil;
  self->declaredTypes = [tmp copyWithZone:[self zone]];
  [tmp release]; tmp = nil;

  self->changeCount++;
  [self setOwner:_newOwner];
  return self->changeCount;
}

- (NGMimeType *)availableTypeFromArray:(NSArray *)_types {
  int i, tc;
  int j, dc;
  
  tc = [_types count];
  dc = [self->declaredTypes count];
  
  for (i = 0; i < tc; i++) {
    NGMimeType *t;
    
    t = [_types objectAtIndex:i];
    for (j = 0; j < dc; j++) {
      NGMimeType *dt;
      
      dt = [self->declaredTypes objectAtIndex:j];
      if ([t hasSameType:dt])
        return t;
    }
  }
  return nil;
}

- (NSArray *)types {
  return self->declaredTypes;
}

- (BOOL)isTypeDeclared:(NGMimeType *)_type {
  int i, count;

  for (i = 0, count = [self->declaredTypes count]; i < count; i++) {
    NGMimeType *type = [self->declaredTypes objectAtIndex:i];

    if ([type hasSameType:_type]) return YES;
  }
  return NO;
}

/* content */

- (BOOL)setObject:(id)_object forType:(NGMimeType *)_type {
  if (_type == nil) {
    [self logWithFormat:
            @"WARNING: missing type for pasteboard, object: %@",
            self];
    return NO;
  }
  if (![self isTypeDeclared:_type]) {
    [self logWithFormat:
            @"WARNING: type %@ is not declared for pasteboard %@: types=%@",
            _type, self, self->declaredTypes];
    return NO;
  }

  [self->type2content setObject:_object forKey:[_type stringValue]];

  return YES;
}
- (id)objectForType:(NGMimeType *)_type {
  id object;

  object = [self->type2content objectForKey:[_type stringValue]];
  if (object != nil) return object;
  
  if (_type == nil) {
    /* this can happen if called by OGoSession -removeTransferObject */
    [self debugWithFormat:
            @"WARNING: missing type argument for retrieving object from "
            @"the pasteboard: %@", self];
    return nil;
  }
  if (![self isTypeDeclared:_type]) {
    [self logWithFormat:
            @"WARNING: type %@ is not declared for pasteboard: %@",_type,self];
    return nil;
  }
  
  if (object == nil) {
    [self->owner pasteboard:self provideDataForType:_type];
    object = [self->type2content objectForKey:[_type stringValue]];
  }
  return object;
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return NO;
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:
                     @"<%@[0x%08X]: name=%@ owner=%@ changeCount=%i>",
                     NSStringFromClass([self class]), self,
                     [self name], [self owner], [self changeCount]];
}

@end /* OWPasteboard */
