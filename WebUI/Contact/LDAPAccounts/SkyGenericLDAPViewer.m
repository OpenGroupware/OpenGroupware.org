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

#include <OGoFoundation/LSWComponent.h>

@class NGLdapEntry, NGLdapURL, NGLdapAttribute;

@interface SkyGenericLDAPViewer : LSWComponent
{
  NGLdapURL       *url;
  NGLdapEntry     *entry;
  NGLdapAttribute *currentAttribute;
  NSString        *currentAttributeName;
  id              currentValue;
}

@end

#include <NGLdap/NGLdap.h>
#include <LSFoundation/LSCommandContext.h>
#include <NGObjWeb/WOResponse.h>
#include "common.h"

@implementation SkyGenericLDAPViewer

- (void)dealloc {
  [self->currentValue         release];
  [self->currentAttributeName release];
  [self->currentAttribute release];
  [self->url   release];
  [self->entry release];
  [super dealloc];
}

- (void)setLdapURL:(NGLdapURL *)_url {
  ASSIGN(self->url,_url);
}
- (NGLdapURL *)ldapURL {
  return self->url;
}
- (NSString *)ldapURLString {
  return [self->url urlString];
}

- (void)setLdapURLString:(NSString *)_url {
  id tmp = self->url;
  self->url = [[NGLdapURL alloc] initWithString:_url];  
  [tmp release];
}

- (NGLdapEntry *)entry {
  if (self->entry == nil)
    self->entry = [[self->url fetchEntry] retain];
  
  return self->entry;
}

- (BOOL)hasEntry {
  return [self entry] == nil ? NO : YES;
}

- (void)setCurrentValue:(id)_value {
  ASSIGN(self->currentValue, _value);
}
- (id)currentValue {
  return self->currentValue;
}

- (NSArray *)attributeNames {
  NSArray *names;

  if ((names = [[self entry] attributeNames]) == nil)
    return nil;

  return [names sortedArrayUsingSelector:@selector(compare:)];
}

- (void)setCurrentAttributeName:(NSString *)_name {
  if (![self->currentAttributeName isEqualToString:_name]) {
    ASSIGNCOPY(self->currentAttributeName, _name);
    [self->currentAttribute release]; self->currentAttribute = nil;
  }
}
- (NSString *)currentAttributeName {
  return self->currentAttributeName;
}
- (NGLdapAttribute *)currentAttribute {
  if (self->currentAttribute == nil) {
    self->currentAttribute =
      [[[self entry] attributeWithName:[self currentAttributeName]] retain];
  }
  return self->currentAttribute;
}

- (BOOL)isCurrentAttributeAnImage {
  return NO;
}

- (BOOL)isAttrsVisible {
  return YES;
}
- (BOOL)isLDIFVisible {
  return NO;
}

/* notifications */

- (void)sleep {
  [self->currentValue         release]; self->currentValue         = nil;
  [self->currentAttribute     release]; self->currentAttribute     = nil;
  [self->currentAttributeName release]; self->currentAttributeName = nil;
  [super sleep];
}

- (BOOL)isLDAPLicensed {
  // TODO: deprecated
  return YES;
}

@end /* SkyGenericLDAPViewer */
