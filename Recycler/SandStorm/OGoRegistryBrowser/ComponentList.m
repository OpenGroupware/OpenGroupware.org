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

#include "common.h"
#include "ComponentList.h"
#include "ComponentElement.h"

@implementation ComponentList

/* initialization */

- (id)init {
  return [self initWithArray:nil];
}

- (id)initWithArray:(NSArray *)_array {
  if ((self = [super init])) {
    NSEnumerator *arrayEnum;
    id           arrayEntry;
    
    self->components = [[NSMutableArray arrayWithCapacity:[_array count]]
                                        retain];
    self->componentNamespaces = [[NSMutableArray arrayWithCapacity:16] retain];
    arrayEnum = [_array objectEnumerator];

    while ((arrayEntry = [arrayEnum nextObject])) {
      [self addElement:arrayEntry];
    }
  }
  return self;
}


- (void)dealloc {
  RELEASE(self->components);
  [super dealloc];
}

/* accessors */

- (NSArray *)components {
  return self->components;
}

- (NSArray *)componentNamespaces {
  return self->componentNamespaces;
}

/* functions */

- (void)addElement:(NSString *)_entry {
  NSArray  *entryElements  = nil;
  NSString *entrySubstring = nil;
  int i;
  
  entrySubstring = @"";
  
  entryElements = [_entry componentsSeparatedByString:@"."];

  for(i = 0; i < [entryElements count]; i++) {
    if(i != 0) {
      entrySubstring = [[entrySubstring stringByAppendingString:@"."]
                                        stringByAppendingString:
                                        [entryElements objectAtIndex:i]];
    }
    else {
      entrySubstring = [entryElements objectAtIndex:0];
    }
    if (![self hasElement:entrySubstring]) {
      [self addObjectToList:entrySubstring];
    }
  }
}

- (ComponentElement *)getComponentElement:(NSString *)_element
                                fromArray:(NSArray *)_array
{
  NSEnumerator *compEnum;
  id           compObject;

  compEnum = [_array objectEnumerator];
  
  while ((compObject = [compEnum nextObject])) {
    if ([_element isEqualToString:[compObject key]]) {
      return compObject;
    }
    else if([_element hasPrefix:[compObject key]]) {
      return [self getComponentElement:_element
                   fromArray:[compObject subComponents]];
    }
  }
  return nil;
}

- (void)addObjectToList:(NSString *)_entry {
  NSMutableArray   *entryElements;
  NSString         *parent;
  NSString         *keyName;
  ComponentElement *element;
  ComponentElement *subElement;
  NSEnumerator     *namespaceEnum;
  id               namespace;
  
  entryElements = [[_entry componentsSeparatedByString:@"."] mutableCopy];
  keyName       = [entryElements objectAtIndex:[entryElements count] -1];

  [entryElements removeObjectAtIndex:[entryElements count] -1];

  parent = @"";
  namespaceEnum = [self->componentNamespaces objectEnumerator];

  while((namespace = [namespaceEnum nextObject])) {
    if ([_entry hasPrefix:namespace]) {
      if([namespace length] > [parent length]) {
        parent = namespace;
      }
    }
  }

  
  element = [[ComponentElement alloc] initWithKey:_entry name:keyName];
  
  /* add namespace to lookup list */
  [self->componentNamespaces addObject:_entry];
  
  if ((subElement = [self getComponentElement:parent
                          fromArray:self->components]) != nil) {
    [[subElement subComponents] addObject:element];
  }
  else {
    [self->components addObject:element];
  }
  RELEASE(element);
}

- (BOOL)hasElement:(NSString *)_entry {
  NSEnumerator *compEnum;
  id           compObject;
  BOOL         result;

  result = NO;
  
  compEnum = [self->componentNamespaces objectEnumerator];

  while ((compObject = [compEnum nextObject])) {
    if ([compObject isEqualToString:_entry]) {
      result = YES;
      break;
    }
  }
  return result;
}

@end /* ComponentList */
