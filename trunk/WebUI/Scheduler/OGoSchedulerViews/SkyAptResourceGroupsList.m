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

#include <OGoFoundation/OGoContentPage.h>

/*
  SkyAptResourceGroupsList
  
  Bindings:
    aptResourceGroups - NSArray of ??? - input parameter
  
  TODO: what does it display, where is it used?
  TODO: apparently this is not used anywhere!
*/

@class NSArray, NSDictionary;

@interface SkyAptResourceGroupsList : OGoContentPage
{
@protected
  NSArray      *aptResourceGroups;
  id           aptResourceGroup;
  NSArray      *attributes;
  NSDictionary *selectedAttribute;
  unsigned     startIndex;
  BOOL         isDescending; 
}
@end

#include <LSFoundation/LSFoundation.h>
#include <NGMime/NGMimeType.h>
#include "common.h"

@interface NSObject(Gid)
- (EOGlobalID *)globalID;
@end

@implementation SkyAptResourceGroupsList

- (void)dealloc {
  [self unregisterAsObserver];
  [self->attributes        release];
  [self->aptResourceGroups release];
  [self->aptResourceGroup  release];
  [self->selectedAttribute release];
  [super dealloc];
}

/* accessors */

- (void)setStart:(unsigned)_startIndex {
  self->startIndex = _startIndex;
}
- (unsigned)start {
  return self->startIndex;    
}

- (void)setIsDescending:(BOOL)_isDescending {
  self->isDescending = _isDescending;
}
- (BOOL)isDescending {
  return self->isDescending;    
}

- (void)setSelectedAttribute:(NSDictionary *)_selectedAttribute {
  ASSIGN(self->selectedAttribute, _selectedAttribute);
}
- (NSDictionary *)selectedAttribute {
  return self->selectedAttribute;    
}

- (void)setAttributes:(NSArray *)_attributes {
  ASSIGN(self->attributes, _attributes);
}
- (NSArray *)attributes {
  return self->attributes;
}

- (void)setAptResourceGroups:(NSArray *)_aptResources {
  ASSIGN(self->aptResourceGroups, _aptResources);
}
- (NSArray *)aptResourceGroups {
  return self->aptResourceGroups;
}

- (void)setAptResourceGroup:(id)_aptResource {
  ASSIGN(self->aptResourceGroup, _aptResource);
}
- (id)aptResourceGroup {
  return self->aptResourceGroup;
}

/* actions */

- (id)viewAptResourceGroup {
  id p;

  p = [self pageWithName:@"SkyAptResourceGroupEditor"];
  [p setObject:self->aptResourceGroup];
  return p;
}

- (id)newAptResourceGroup {
  return [self pageWithName:@"SkyAptResourceGroupEditor"];
}

@end /* SkyAptResourceGroupsList */
