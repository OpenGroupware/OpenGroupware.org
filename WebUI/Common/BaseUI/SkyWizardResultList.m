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

#import "common.h"
#import "SkyWizardResultList.h"
#import <OGoFoundation/SkyWizard.h>

@implementation SkyWizardResultList

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->wizard);
  RELEASE(self->item);
  [super dealloc];
}
#endif

- (BOOL)isEditorPage {
  return YES;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (void)setWizard:(id)_wizard {
  ASSIGN(self->wizard, _wizard);
}
- (id)wizard {
  return self->wizard;
}

- (id)resultList {
  return [self->wizard objects];
}

- (BOOL)hasViewer {
  return ([[self->item valueForKey:@"objectType"] isNotNull] == NO) ? NO : YES;
}

- (id)resultViewer {
  id       page  = nil;
  NSString *objT = nil;

  if ([(objT = [self->item valueForKey:@"objectType"]) isNotNull] == NO) {
    NSLog(@"WARNING: objectType is nil");
    return nil;
  }
  [[self session] transferObject:[self->item valueForKey:@"object"]
                  owner:self];
  page = [[self session] instantiateComponentForCommand:@"wizard-view"
                         type:[NGMimeType mimeType:@"eo" subType:objT]
                         object:[self->item valueForKey:@"object"]];
  return page;
}

- (BOOL)isBack {
  return YES;
}

- (id)back {
  [self leavePage];  
  [self->wizard back];
  return nil;
}

- (id)cancel {
  [self leavePage];  
  [self->wizard cancel];
  return nil;
}

- (id)save {
  [self leavePage];
  [self->wizard save];
  return nil;
}

@end

