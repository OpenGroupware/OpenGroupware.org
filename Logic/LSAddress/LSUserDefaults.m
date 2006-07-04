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

#include "LSUserDefaults.h"
#include <LSFoundation/LSCommandContext.h>
#include "common.h"

static NSString *LSUserDefaults_object = @"LSUserDefaults_object";
static NSString *LSUserDefaults_bool   = @"LSUserDefaults_bool";
static NSString *LSUserDefaults_int    = @"LSUserDefaults_int";
static NSString *LSUserDefaults_float  = @"LSUserDefaults_float";
static NSString *LSUserDefaults_remove = @"LSUserDefaults_remove";

@interface LSUserDefaults(PrivateMethodes)
- (BOOL)writeDefaultForKey:(NSString *)_key;
@end

@implementation LSUserDefaults

static BOOL debugOn = NO;

// designated initializer:
- (id)initWithUserDefaults:(NSUserDefaults *)_ud
  andContext:(LSCommandContext *)_ctx
{
  if ((self = [super init])) {
    self->context = _ctx;  // non retained !!!
    self->standardUserDefaults = [_ud retain];
    self->map    = [[NSMutableDictionary alloc] initWithCapacity:32];
    self->values = [[NSMutableDictionary alloc] initWithCapacity:32];
  }
  return self;
}

- (id)initWithUserDefaults:(NSUserDefaults *)_ud {
  return [self initWithUserDefaults:_ud andContext:nil];
}

- (id)init {
  return [self initWithUserDefaults:[NSUserDefaults standardUserDefaults]
               andContext:nil];
}

- (void)dealloc {
  // self->context is non retained !!!
  [self->standardUserDefaults release];
  [self->map                  release];
  [self->values               release];
  [self->account              release];
  [super dealloc];
}

/* methods */
- (void)willChange {
  self->isChanged = YES;
}

- (NSArray *)arrayForKey:(NSString *)_key {
  NSArray *v;

  if ((v = [self->values objectForKey:_key]))
    return v;
  if ((v = [super arrayForKey:_key]))
    return v;

  return [self->standardUserDefaults arrayForKey:_key];
}

- (NSDictionary *)dictionaryForKey:(NSString *)_key {
  NSDictionary *v;

  if ((v = [self->values objectForKey:_key]))
    return v;
  if ((v = [super dictionaryForKey:_key]))
    return v;

  return [self->standardUserDefaults dictionaryForKey:_key];
}

- (NSData *)dataForKey:(NSString *)_key {
  NSData *v;

  if ((v = [self->values objectForKey:_key]))
    return v;
  if ((v = [super dataForKey:_key]))
    return v;

  return [self->standardUserDefaults dataForKey:_key];
}

- (NSArray *)stringArrayForKey:(NSString *)_key {
  NSArray *v;

  if ((v = [self->values objectForKey:_key]))
    return v;
  if ((v = [super stringArrayForKey:_key]))
    return v;

  return [self->standardUserDefaults stringArrayForKey:_key];
}

- (NSString *)stringForKey:(NSString *)_key {
  NSString *v;

  if ((v = [self->values objectForKey:_key]))
    return v;
  if ((v = [super stringForKey:_key]))
    return v;

  return [self->standardUserDefaults stringForKey:_key];
}

- (BOOL)boolForKey:(NSString *)_key {
  id obj;

  if ((obj = [self objectForKey:_key])) {
    if ([obj isKindOfClass:[NSString class]]) {
      if ([obj compare:@"YES" options:NSCaseInsensitiveSearch] == NSOrderedSame)
        return YES;
    }
    if ([obj respondsToSelector:@selector(intValue)])
      return [obj intValue] ? YES : NO;
  }
  return NO;
}
- (void)setBool:(BOOL)_bool forKey:(NSString *)_key {
  if ([self boolForKey:_key] != _bool) {
    [self willChange];
    [self->map setObject:LSUserDefaults_bool forKey:_key];
    [self->values setObject:[NSNumber numberWithBool:_bool] forKey:_key];
  }
}

- (float)floatForKey:(NSString*)_key {
  id obj;
  
  if ((obj = [self stringForKey:_key])) 
    return [obj floatValue];
  return 0;
}
- (void)setFloat:(float)_flt forKey:(NSString *)_key {
  if ([self floatForKey:_key] != _flt) {
    [self willChange];
    [self->map    setObject:LSUserDefaults_float forKey:_key];
    [self->values setObject:[NSNumber numberWithFloat:_flt] forKey:_key];
  }
}

- (int)integerForKey:(NSString*)_key {
  id obj;
  
  if ((obj = [self stringForKey:_key]))
    return [obj intValue];
  return 0;
}
- (void)setInteger:(int)_integer forKey:(NSString *)_key {
  if ([self integerForKey:_key] != _integer) {
    [self willChange];
    [self->map setObject:LSUserDefaults_int forKey:_key];
    [self->values setObject:[NSNumber numberWithInt:_integer] forKey:_key];
  }
}

- (id)objectForKey:(NSString *)_key {
  id v;

  if ((v = [self->values objectForKey:_key]) == nil)
    if (!(v = [super objectForKey:_key]))
      v = [self->standardUserDefaults objectForKey:_key];
  
  if (([v isKindOfClass:[NSMutableDictionary class]]) ||
      ([v isKindOfClass:[NSMutableArray class]]) ||
      ([v isKindOfClass:[NSMutableString class]])) {
    v = [[v copy] autorelease];
  }
  return v;
}

- (void)setObject:(id)_obj forKey:(NSString *)_key {
  id old;

  if (_key == nil) {
    [self warnWithFormat:
            @"LSUserDefaults: called -setObject:forKey: without key"];
    return;
  }
  if (_obj == nil) {
    [self warnWithFormat:
            @"LSUserDefaults: tried to save nil for key: '%@'", _key];
    return;
  }
  
  old = [[self objectForKey:_key] description];
  
  if ([old isEqual:_obj])
    return;
  
  if (![old isEqualToString:[_obj description]]) {
    [self willChange];
    [self->map    setObject:LSUserDefaults_object forKey:_key];

    if (([_obj isKindOfClass:[NSMutableDictionary class]]) ||
        ([_obj isKindOfClass:[NSMutableArray class]]) ||
        ([_obj isKindOfClass:[NSMutableString class]]))
      _obj = [[_obj copy] autorelease];
    
    [self->values setObject:_obj forKey:_key];
  }
}

- (NSNumber *)boolNumberForKey:(NSString *)_key {
  return [NSNumber numberWithBool:[self boolForKey:_key]];
}

- (NSNumber *)floatNumberForKey:(NSString *)_key {
  return [NSNumber numberWithFloat:[self floatForKey:_key]];
}

- (NSNumber *)intNumberForKey:(NSString *)_key {
  return [NSNumber numberWithInt:[self integerForKey:_key]];
}

- (void)removeObjectForKey:(NSString *)_key {
  if (_key == nil)
    return;
  
  if ([self objectForKey:_key] == nil) 
    return;
  
  [self willChange];
  [super removeObjectForKey:_key];
  [self->map    setObject:LSUserDefaults_remove forKey:_key];
  [self->values removeObjectForKey:_key];
}

/* synchronization */

- (BOOL)synchronize {
  NSEnumerator      *enumerator;
  NSString          *key;
  NSAutoreleasePool *pool;
  BOOL allOk;

  allOk = YES;
  
  if (self->context == nil)
    return NO;

  if (!self->isChanged)
    return YES;

  pool       = [[NSAutoreleasePool alloc] init];
  enumerator = [self->map keyEnumerator];

  while ((key = [enumerator nextObject]))
    allOk = allOk && [self writeDefaultForKey:key];
    
  if (debugOn && [[self->values allKeys] isNotEmpty]) {
      [self debugWithFormat:
              @"Warning!!! LSUserDefaults could not handle values: %@",
              self->values];
  }
  [self->map    removeAllObjects];
  [self->values removeAllObjects];

  self->isChanged = NO;

  if (self->account != nil) {
    [self->context runCommand:@"userdefaults::register",
           @"defaults", self,
           @"account", self->account, nil];
  }
  else {
    [self->context runCommand:@"userdefaults::register",
           @"defaults", self, nil];
  }
  [pool release];
  
  return allOk;
}

/* private */

- (BOOL)writeDefaultForKey:(NSString *)_key {
  id       obj;
  NSString *type;
  SEL      sel;

  type = [self->map objectForKey:_key];
  
  if (type == nil) {
    [self logWithFormat:@"%s: missing type for %@", __PRETTY_FUNCTION__, _key];
    return NO;
  }

  if ([type isEqualToString:LSUserDefaults_remove]) {
    if (self->account != nil) {
      [self->context runCommand:@"userdefaults::delete",
           @"key",      _key,
           @"defaults", self,
           @"userId", [self->account valueForKey:@"companyId"], nil];
    }
    else {
      [self->context runCommand:@"userdefaults::delete",
           @"key",      _key,
           @"defaults", self, nil];
    }
  }
  else {
    if ([type isEqualToString:LSUserDefaults_int])
      sel = @selector(intNumberForKey:);
    else if ([type isEqualToString:LSUserDefaults_bool])
      sel = @selector(boolNumberForKey:);
    else if ([type isEqualToString:LSUserDefaults_float])
      sel = @selector(floatNumberForKey:);
    else 
      sel = @selector(objectForKey:);

    obj = [self performSelector:sel withObject:_key];
    if (self->account != nil) {
      [self->context runCommand:@"userdefaults::write",
           @"key",      _key,
           @"value",    obj,
           @"defaults", self,
           @"userId",   [self->account valueForKey:@"companyId"], nil];
    }
    else {
      [self->context runCommand:@"userdefaults::write",
           @"key",      _key,
           @"value",    obj,
           @"defaults", self, nil];
    }
  }
  [self->values removeObjectForKey:_key];
  
  return YES;
}

- (void)setAccount:(id)_account {
  ASSIGN(self->account, _account);
}
- (id)account {
  return self->account;
}

/* debug */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

@end /* LSUserDefaults */
