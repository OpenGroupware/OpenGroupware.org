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

#include <OGoFoundation/OGoComponent.h>

/*
  OGoObjPropInlineEditor

  Bindings
  - globalID - EOGlobalID - object

  TODO: document
*/

#warning TODO: implement me

@class NSArray, NSMutableSet;
@class EOGlobalID;
@class SkyObjectPropertyManager;

@interface OGoObjPropInlineEditor : OGoComponent
{
  EOGlobalID          *gid;
  NSArray             *namespaces;
  NSString            *defaultNamespace;
  
  NSString            *newAttributeNamespace;
  NSString            *newAttributeName;
  NSString            *newAttributeValue;
  NSString            *newAttributeType;
  
  NSArray             *displayNamespaces;
  NSMutableDictionary *props;
  BOOL                didFetch;
  NSString            *currentPropertyName;
  id                  currentPropertyValue;
  
  id                  labels;
}

- (EOGlobalID *)globalID;
- (SkyObjectPropertyManager *)propertyManager;

@end

#include <LSFoundation/SkyObjectPropertyManager.h>
#include <LSFoundation/LSCommandContext.h>
#include <OGoFoundation/OGoSession.h>
#include <OGoFoundation/OGoNavigation.h>
#include <OGoFoundation/OGoContentPage.h>
#include <NGObjWeb/WOContext.h>
#include "common.h"

@implementation OGoObjPropInlineEditor

static NSArray *calFormats = nil;

+ (void)initialize {
  // TODO: check superclass version
  if (calFormats == nil) {
    // TODO: fetch from bundle defaults
    calFormats = [[NSArray alloc] initWithObjects:
                    @"%Y-%m-%d %H:%M:%S",
                    @"%Y-%m-%d %H:%M",
                    @"%Y-%m-%d",
                    @"%H:%M:%S",
                    @"%H:%M",
                    nil];
  }
}

- (void)dealloc {
  [self->currentPropertyValue release];
  [self->currentPropertyName  release];
  [self->displayNamespaces    release];
  [self->props                release];
  
  [self->newAttributeType  release];
  [self->newAttributeValue release];
  [self->newAttributeName  release];
  [self->newAttributeNamespace release];
  
  [self->defaultNamespace release];
  [self->namespaces       release];
  [self->gid              release];
  [self->labels           release];
  [super dealloc];
}

/* fetching */

- (void)_ensureProps {
  NSDictionary *oprops;
  
  if (self->didFetch && (self->props != nil))
    return;

  self->props = [[NSMutableDictionary alloc] initWithCapacity:16];
  
  oprops = [[self propertyManager] propertiesForGlobalID:[self globalID]];
  [self->props takeValuesFromDictionary:oprops];

  self->didFetch = YES;
}

/* accessors */

- (void)setGlobalID:(EOGlobalID *)_gid {
  if ([self->gid isEqual:_gid])
    return;

  ASSIGNCOPY(self->gid, _gid);
  self->didFetch = NO;
  [self->props             release]; self->props             = nil;
  [self->displayNamespaces release]; self->displayNamespaces = nil;
}
- (EOGlobalID *)globalID {
  return self->gid;
}

- (void)setNamespaces:(NSArray *)_ns {
  ASSIGN(self->namespaces, _ns);
}
- (NSArray *)namespaces {
  return self->namespaces;
}

- (void)setDefaultNamespace:(NSString *)_defNS {
  ASSIGNCOPY(self->defaultNamespace, _defNS);
}
- (NSString *)defaultNamespace {
  return self->defaultNamespace
    ? self->defaultNamespace
    : @"http://www.skyrix.com/custom-attribute";
}

/* new property */

- (void)setNewAttributeNamespace:(NSString *)_value {
  ASSIGNCOPY(self->newAttributeNamespace, _value);
}
- (NSString *)newAttributeNamespace {
  return self->newAttributeNamespace
    ? self->newAttributeNamespace
    : [self defaultNamespace];
}

- (void)setNewAttributeType:(NSString *)_value {
  ASSIGNCOPY(self->newAttributeType, _value);
}
- (NSString *)newAttributeType {
  return self->newAttributeType;
}

- (void)setNewAttributeName:(NSString *)_value {
  ASSIGNCOPY(self->newAttributeName, _value);
}
- (NSString *)newAttributeName {
  return self->newAttributeName;
}

- (void)setNewAttributeValue:(NSString *)_value {
  ASSIGNCOPY(self->newAttributeValue, _value);
}
- (NSString *)newAttributeValue {
  return self->newAttributeValue;
}

/* namespaces */

- (NSArray *)displayNamespaces {
  if (self->displayNamespaces != nil)
    return self->displayNamespaces;
  if (self->namespaces != nil)
    return self->namespaces;
  
  [self _ensureProps];
  return nil;
}

- (NSArray *)propertyNames {
  [self _ensureProps];
  return [self->props allKeys];
}
- (BOOL)hasProperties {
  [self _ensureProps];
  return [self->props count] > 0 ? YES : NO;
}

- (void)setCurrentPropertyName:(NSString *)_key {
  ASSIGNCOPY(self->currentPropertyName, _key);
}
- (NSString *)currentPropertyName {
  return self->currentPropertyName;
}

- (NSString *)currentPropertyNamespace {
  NSRange range;
  
  range = [self->currentPropertyName rangeOfString:@"}"];
  
  if (range.length == 0)
    return nil;

  range.length   = (range.location - 1);
  range.location = 1;
  
  return [self->currentPropertyName substringWithRange:range];
}
- (NSString *)currentPropertyLocalName {
  NSRange r;
  
  r = [self->currentPropertyName rangeOfString:@"}"];
  return r.length == 0
    ? self->currentPropertyName
    : [self->currentPropertyName substringFromIndex:(r.location + r.length)];
}

- (void)setCurrentPropertyValue:(id)_value {
  [self->props setObject:_value forKey:self->currentPropertyName];
}
- (NSString *)currentPropertyValue {
  return [self->props objectForKey:self->currentPropertyName];
}

- (void)setLabels:(id)_labels {
  ASSIGN(self->labels, _labels);
}
- (id)labels {
  return self->labels;
}

/* operational */

- (SkyObjectPropertyManager *)propertyManager {
  return [[(OGoSession *)[self session] commandContext] propertyManager];
}

/* actions */

- (id)save {
  NSException *exc;
  
  exc = [[self propertyManager]
               takeProperties:self->props globalID:[self globalID]];

  if (exc != nil) {
    [(OGoContentPage *)[[self context] page] setErrorString:[exc description]];
    return nil;
  }
  
  return [[(OGoSession *)[self session] navigation] leavePage];
}

- (NSArray *)calendarFormats {
  return calFormats;
}

- (id)_valueForNewAttribute {
  if ([self->newAttributeType isEqualToString:@"int"])
    return [NSNumber numberWithInt:[self->newAttributeValue intValue]];
  
  if ([self->newAttributeType isEqualToString:@"double"])
    return [NSNumber numberWithDouble:[self->newAttributeValue doubleValue]];
  
  if ([self->newAttributeType isEqualToString:@"url"])
    return [NSURL URLWithString:self->newAttributeValue];
  
  if ([self->newAttributeType isEqualToString:@"date"]) {
    NSEnumerator *cfs;
    NSString *cf;
    id value = nil;
    
    cfs = [[self calendarFormats] objectEnumerator];
    while ((cf = [cfs nextObject]) && (value == nil)) {
      value = [NSCalendarDate dateWithString:self->newAttributeValue
                              calendarFormat:cf];
    }
    if (value == nil) {
      value = [NSCalendarDate dateWithString:self->newAttributeValue
                              calendarFormat:nil];
    }
    return value;
  }

  return self->newAttributeValue;
}

@end /* OGoObjPropInlineEditor */
