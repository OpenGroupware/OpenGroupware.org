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

#include <OGoFoundation/LSWContentPage.h>

@class NSArray, NSDictionary;

@interface SkyAptResourceList : LSWContentPage
{
@protected
  NSArray      *aptResources;
  id           aptResource;
  NSArray      *attributes;
  NSDictionary *selectedAttribute;
  unsigned     startIndex;
  BOOL         isDescending; 
}
@end

#include <OGoFoundation/LSWNotifications.h>
#include <OGoFoundation/OGoFoundation.h>
#include <LSFoundation/LSFoundation.h>
#include <NGObjWeb/NGObjWeb.h>
#include <NGMime/NGMimeType.h>
#include <NGExtensions/NSCalendarDate+misc.h>
#import <EOControl/EOControl.h>
#import <Foundation/Foundation.h>

@interface NSObject(Gid)
- (EOGlobalID *)globalID;
@end

@implementation SkyAptResourceList

- (void)dealloc {
  [self unregisterAsObserver];
  [self->attributes        release];
  [self->aptResources      release];
  [self->aptResource       release];
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

- (void)setAptResources:(NSArray *)_aptResources {
  ASSIGN(self->aptResources, _aptResources);
}
- (NSArray *)aptResources {
  return self->aptResources;
}

- (void)setAptResource:(id)_aptResource {
  ASSIGN(self->aptResource, _aptResource);
}
- (id)aptResource {
  return self->aptResource;
}

/* actions */

- (id)viewAptResource {
  return [[[self session] navigation]
                 activateObject:[self->aptResource valueForKey:@"globalID"]
                 withVerb:@"view"];
}

- (id)newAptResource {
  WOComponent *ct = nil;

  ct = [[self session] instantiateComponentForCommand:@"new"
                       type:[NGMimeType mimeType:@"eo/appointmentresource"]];
  return ct;
}

@end /* SkyAptResourceList */
