/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
  SkyDefaultsElementViewer
  
  TODO: explain what it does.
*/

@class SkyDefaultsElement;

@interface SkyDefaultsElementViewer : OGoComponent
{
  SkyDefaultsElement *element;
  BOOL                showInfo;
}

@end

#include "common.h"
#include "SkyDefaultsDomain.h"
#include "SkyDefaultsElement.h"
#include "SkyDefaultsEditor.h"

@implementation SkyDefaultsElementViewer

- (void)dealloc {
  [self->element release];
  [super dealloc];
}

/* accessors */

- (void)setShowInfo:(BOOL)_b {
  self->showInfo = _b;
}
- (BOOL)showInfo {
  return self->showInfo;
}

- (void)setElement:(id)_obj {
  ASSIGN(self->element, _obj);
}
- (id)element {
  return self->element;
}

- (NSString *)currentValue {
  id value;
  
  if ((value = [self->element value]) != nil)
    return [value stringValue];
  
  return [[self labels] valueForKey:@"valueNotSet"];
}

@end /* SkyDefaultsElementViewer */
