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

#include <NGObjWeb/WOComponent.h>

@class SxXmlRpcComponent;

@interface RelatedMethods : WOComponent
{
  id                value;
  SxXmlRpcComponent *sxComponent;
  NSArray           *relatedMethodNames;
  NSString          *relatedMethodName;
  id                item; /* transient */
}

/* accessors */

- (void)setSxComponent:(SxXmlRpcComponent *)_component;
- (SxXmlRpcComponent *)sxComponent;

- (NSArray *)relatedMethodNames;

@end

#include "common.h"
#include "RunMethod.h"
#include "Session.h"
#include <SxComponents/SxXmlRpcComponent.h>
#include <SxComponents/SxComponentMethodSignature.h>

@interface RelatedMethods(PrivateMethods)
- (NSArray *)initialRelatedMethodNames;
@end /* RelatedMethods(PrivateMethods) */

@implementation RelatedMethods

- (void)dealloc {
  RELEASE(self->item);
  RELEASE(self->value);
  RELEASE(self->sxComponent);
  RELEASE(self->relatedMethodNames);
  RELEASE(self->relatedMethodName);
  [super dealloc];
}

/* notifications */

/* accessors */

- (void)setValue:(id)_val {
  if (![_val isEqual:self->value]) {
    ASSIGN(self->value, _val);
    ASSIGN(self->relatedMethodNames, nil);
    ASSIGN(self->relatedMethodName,  nil);
  }
}
- (id)value {
  return self->value;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (BOOL)isSimpleType {
  if ([self->value isKindOfClass:[NSArray class]])
    return NO;
  if ([self->value isKindOfClass:[NSDictionary class]])
    return NO;
  if ([self->value isKindOfClass:[NSException class]])
    return NO;
  return YES;
}
- (NSString *)valueType {
  if ([self->value isKindOfClass:[NSString class]])
    return @"string";
  if ([self->value isKindOfClass:[NSArray class]])
    return @"array";
  if ([self->value isKindOfClass:[NSDictionary class]])
    return @"struct";
  if ([self->value isKindOfClass:[NSNumber class]])
    return @"i4";
  if ([self->value isKindOfClass:[NSDate class]])
    return @"dateTime.iso8601";
  if ([self->value isKindOfClass:[NSException class]])
    return @"fault";

  return nil;
}

/* accessors */

- (void)setSxComponent:(SxXmlRpcComponent *)_component {
  ASSIGN(self->sxComponent, _component);
}
- (SxXmlRpcComponent *)sxComponent {
  return self->sxComponent;
} 

- (void)setRelatedMethodName:(NSString *)_methodName {
  ASSIGN(self->relatedMethodName, _methodName);
}
- (NSString *)relatedMethodName {
  return self->relatedMethodName;
}

- (NSString *)itemString {
  NSString *s;
  
  s = [self item];
  if ([s length] <= 10) return s;
  
  s = [s substringToIndex:8];
  s = [s stringByAppendingString:@".."];
  return s;
}

- (NSArray *)relatedMethodNames {
  if (self->relatedMethodNames == nil)
    self->relatedMethodNames = [[self initialRelatedMethodNames] retain];
  return self->relatedMethodNames;
}
- (BOOL)hasRelatedMethodNames {
  return [[self relatedMethodNames] count] > 0 ? YES : NO;
}

- (NSArray *)initialRelatedMethodNames {
  NSArray        *methodNames;
  NSEnumerator   *nameEnum;
  NSString       *methodName;
  NSMutableArray *result;
  NSString       *vtype;
  
  if (self->sxComponent == nil) {
    [self logWithFormat:@"%s: No SandStorm component set",__PRETTY_FUNCTION__];
    return nil;
  }
  if ((vtype = [self valueType]) == nil) {
    [self logWithFormat:@"no value type is set !"];
    return nil;
  }
  
  /* check related methods cache */
  
  result = (id)[[self session]
                      cachedRelatedMethodsForComponent:[self sxComponent]
                      valueType:[self valueType]];
  if ([result isNotNull])
    return result;
  
  /* calculate related methods */
  
  methodNames = [[self sxComponent] listMethods];
  
  result = [NSMutableArray arrayWithCapacity:[methodNames count]];
  
  nameEnum = [methodNames objectEnumerator];
  while((methodName = [nameEnum nextObject])) {
    NSArray      *signatures;
    NSEnumerator *sigEnum;
    SxComponentMethodSignature *signature;
    
    //[self logWithFormat:@"check method: %@", methodName];
    signatures = [[self sxComponent] methodSignature:methodName];
    
    sigEnum = [signatures objectEnumerator];
    while ((signature = [sigEnum nextObject])) {
      NSString *sigRpcType;
      
      if ([signature numberOfArguments] == 0) continue;
      
      sigRpcType = [[signature xmlRpcTypes] objectAtIndex:1];
      if ([sigRpcType isEqualToString:vtype]) {
        [result addObject:methodName];
        break; /* a single match is sufficient ... */
      }
    }
  }
  //[self debugWithFormat:@"related methods: %@", result];

  /* store in cache */
  
  if (result) {
    result = (id)[result sortedArrayUsingSelector:@selector(compare:)];
    [[self session] cacheRelatedMethods:result
                    forComponent:[self sxComponent]
                    andType:vtype];
  }
  
  if ([result count] == 0) return nil;
  return result;
}

/* actions */

- (id)runMethodPage {
  NSString  *relatedMethod;
  RunMethod *page;
  
  relatedMethod = [self relatedMethodName];
  if ([relatedMethod length] == 0) {
    [self logWithFormat:@"no related method is set ?!"];
    return nil;
  }
  
  page = [self pageWithName:@"RunMethod"];
  [page setComponent:[self sxComponent]];
  [page setMethodName:relatedMethod];
  [page setDefaultValues:[NSArray arrayWithObject:[self value]]];
  
  return page;
}

@end /* RelatedMethods */
