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

#import "common.h"
#import "SkyWizardChoicePage.h"
#import <OGoFoundation/SkyWizard.h>

@implementation SkyWizardChoicePage

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->wizard);
  RELEASE(self->posibilities);
  RELEASE(self->item);
  RELEASE(self->posibility);
  [super dealloc];
}
#endif

- (BOOL)isEditorPage {
  return YES;
}

- (id)finish {
  [self leavePage];
  return [self->wizard finish];
}
- (BOOL)isFinish {
  return [self->wizard isFinish];
}
- (id)cancel {
  [self leavePage];  
  return [(SkyWizard *)self->wizard cancel];
}

- (id)back {
  [self leavePage];  
  return [self->wizard back];
}
- (BOOL)isBack {
  return [self->wizard isBack];
}

- (id)forward {
  if (self->posibility != nil) {
    [self->wizard setChoosenPageName:[self->posibility valueForKey:@"page"]];
    [self->wizard addSnapshot:[NSNull null] page:self];
    [self leavePage];
    return [self->wizard valueForKey:@"forwardNotCached"];
  }
  return nil;
}

- (id)posibilities {
  return self->posibilities;
}
- (void)setPosibilities:(id)_pos {
  ASSIGN(self->posibilities, _pos);
}

- (id)wizard {
  return self->wizard;
}
- (void)setWizard:(id)_wiz {
  ASSIGN(self->wizard, _wiz);
}

- (id)item {
  return self->item;
}
- (void)setItem:(id)_it {
  ASSIGN(self->item, _it);
}

- (id)posibility {
  return self->posibility;
}
- (void)setPosibility:(id)_it {
  ASSIGN(self->posibility, _it);
}

- (NSString *)chooseLabel {
  NSString *l = [self->item valueForKey:@"label"]; 
  
  if (l != nil)
    l = [[self->wizard labels] valueForKey:l];
  else
    l = @"";
  return [l stringByAppendingString:@"</TD></TR>"];
}

- (NSString *)viewerPageName {
  return @"";
}

- (NSString *)wizardObjectType {
  return (id)[NSNull null];
}

@end /* SkyWizardChoicePage */
