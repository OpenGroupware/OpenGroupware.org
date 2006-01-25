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

#include <NGObjWeb/WOComponent.h>

/*
  SkyObjectPropertyViewer

  Bindings:
    globalID         - EOGlobalID - used to query the attributes
    defaultNamespace - string     - show those w/o namespace
    omitTable        - bool       - do not render <table> tag
    attributes       - NSArray    - OGo ext-attribute specification
  
  TODO: document
  
  TODO: fix namespaces
  TODO: implement attribute specs
*/

@class EOGlobalID;

@interface SkyObjectPropertyViewer : WOComponent
{
  EOGlobalID   *gid;
  NSArray      *namespaces;
  NSString     *defaultNamespace;

  NSDictionary *properties;
  
  BOOL    omitTable;
  NSArray *attributes;
  
  /* transient */
  NSString *currentPropertyName;
  id       currentPropertyValue;
}

@end

#include <LSFoundation/SkyObjectPropertyManager.h>
#include <LSFoundation/LSCommandContext.h>
#include <OGoFoundation/OGoSession.h>
#include "common.h"

@implementation SkyObjectPropertyViewer

- (void)dealloc {
  [self->defaultNamespace release];
  [self->properties       release];
  [self->namespaces       release];
  [self->attributes       release];
  [self->gid              release];
  [super dealloc];
}

/* accessors */

- (void)setGlobalID:(EOGlobalID *)_gid {
  if ([self->gid isEqual:_gid])
    return;
  
  ASSIGNCOPY(self->gid, _gid);
}
- (EOGlobalID *)globalID {
  return self->gid;
}

- (void)setDefaultNamespace:(NSString *)_ns {
  ASSIGNCOPY(self->defaultNamespace, _ns);
}
- (NSString *)defaultNamespace {
  return self->defaultNamespace;
}

- (void)setOmitTable:(BOOL)_flag {
  self->omitTable = _flag;
}
- (BOOL)omitTable {
  return self->omitTable;
}

- (void)setCurrentPropertyName:(NSString *)_propName {
  ASSIGNCOPY(self->currentPropertyName, _propName);
}
- (NSString *)currentPropertyName {
  return self->currentPropertyName;
}

- (NSString *)currentPropertyLabel {
  NSString *k;
  unsigned nslen;
  NSRange  r;
  
  if (![(k = [self currentPropertyName]) isNotEmpty])
    return k;
  
  nslen = [self->defaultNamespace length];
#if DEBUG && 0
  NSLog(@"key: %@", k);
  NSLog(@"idx: %d", [k indexOfString:self->defaultNamespace]);
  NSLog(@"ns:  %@", self->defaultNamespace);
#endif
  
  r = [k rangeOfString:self->defaultNamespace];
  if (r.length > 0 && r.location == 1)
    k = [k substringFromIndex:(nslen + 2)];
  
  return k;
}

- (void)setCurrentPropertyValue:(id)_value {
  ASSIGN(self->currentPropertyValue, _value);
}
- (id)currentPropertyValue {
  return self->currentPropertyValue;
}

- (void)setAttributes:(NSArray *)_ns {
  ASSIGN(self->attributes, _ns);
}
- (NSArray *)attributes {
  return self->attributes;
}

- (void)setNamespaces:(NSArray *)_ns {
  ASSIGN(self->namespaces, _ns);
}
- (NSArray *)namespaces {
  return self->namespaces;
}

- (BOOL)useNamespaces {
  return self->namespaces ? YES : NO;
}

- (SkyObjectPropertyManager *)propertyManager {
  return [[(OGoSession *)[self session] commandContext] propertyManager];
}

- (NSDictionary *)properties {
  if (self->properties != nil)
    return self->properties;
  
  if (![self useNamespaces]) {
    self->properties =
      [[[self propertyManager] propertiesForGlobalID:[self globalID]] retain];
  }
  else {
    NSMutableDictionary *md;
    NSEnumerator        *nse;
    NSString            *ns;
    
    md = [[NSMutableDictionary alloc] 
	   initWithCapacity:[self->namespaces count]];
    
    nse = [self->namespaces objectEnumerator];
    while ((ns = [nse nextObject]) != nil) {
      NSDictionary *props;
      
      props = [[self propertyManager]
                     propertiesForGlobalID:[self globalID]
                     namespace:ns];
      if (props)
        [md setObject:props forKey:ns];
    }
    
    self->properties = [md copy];
    [md release];
  }
  return self->properties;
}

/* notifications */

- (void)sleep {
  [super sleep];

  [self->currentPropertyValue release]; self->currentPropertyValue = nil;
  [self->currentPropertyName  release]; self->currentPropertyName  = nil;
  [self->properties           release]; self->properties           = nil;
}

@end /* SkyObjectPropertyViewer */

#if 0 // hh asks: what's that?
- (NSString *)keyLabel {
  NSString *k;
  unsigned nslen;
  
  if ((k = [self key]) == nil) return nil;
  if ([k length] == 0) return k;

  nslen = [XMLNS_PROJECT_DOCUMENT length];
  NSLog(@"key: %@", k);
  NSLog(@"idx: %d", [k indexOfString:XMLNS_PROJECT_DOCUMENT]);
  NSLog(@"ns:  %@", XMLNS_PROJECT_DOCUMENT);
  
  if ([k indexOfString:XMLNS_PROJECT_DOCUMENT] == 1)
    k = [k substringFromIndex:(nslen + 2)];
  
  return k;
}
#endif
