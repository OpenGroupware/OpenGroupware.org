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
// $Id$

#include <OGoFoundation/LSWEditorPage+Wizard.h>
#include <OGoFoundation/SkyWizard.h>
#import "common.h"

@implementation OGoEditorPage(Wizard)

- (id)wizard {
  if (self->isInWizardMode == NO) {
    [self logWithFormat:@"aks a non-wizard page for a wizard"];
  }
  return self->wizard;
}
- (void)setWizard:(id)_wiz {
  if (self->isInWizardMode == NO) {
    [self logWithFormat:@"set a wizard in for a non-wizard page"];
  }
  ASSIGN(self->wizard, _wiz);
}

- (id)wizardForward {
  if (self->isInWizardMode == YES) {
    if ([self isWizardForward] == YES) {
      if ([self checkConstraintsForSave] == YES) {
        [self->wizard addSnapshot:[self snapshot] page:self];
        [self leavePage];
        return [self->wizard forward];
      }
    }
    else {
      [self logWithFormat:@"forward not allowed"];
    }
  }
  else {
    [self logWithFormat:@"do wizard-operation with a non-wizard page"];    
  }
  return nil;
}

- (id)wizardBack {
  if (self->isInWizardMode == YES) {
    if ([self isWizardBack] == YES) {
      [self leavePage];
      return [self->wizard back];
    }
    else {
      [self logWithFormat:@"back not allowed"];
    }
  }
  else {
    [self logWithFormat:@"do wizard-operation with a non-wizard page"];    
  }
  return nil;
}

- (id)wizardFinish {
  if (self->isInWizardMode == YES) {
    if ([self isWizardFinish] == YES) {
      [self->wizard addSnapshot:[self snapshot] page:self];
      [self leavePage];
      return [self->wizard finish];
    }
    else {
      [self logWithFormat:@"finish not allowed"];
    }
  }
  else {
    [self logWithFormat:@"do wizard-operation with a non-wizard page"];    
  }
  return nil;
}

- (id)wizardCancel {
  if (!self->isInWizardMode) {
    [self logWithFormat:@"do wizard-operation with a non-wizard page"];    
    return nil;
  }
  
  [self leavePage];
  return [(OGoEditorPage *)self->wizard cancel];
}

- (BOOL)isWizardForward {
  if (self->isInWizardMode == YES) {
    if ([self->wizard isForward] == YES)
      return YES;
  }
  return NO;
}
- (BOOL)isWizardBack {
  if (self->isInWizardMode == YES) {
    if ([self->wizard isBack] == YES)
      return YES;
  }
  return NO;
}
- (BOOL)isWizardFinish {
  if (self->isInWizardMode == YES) {
    if ([self->wizard isFinish] == YES)
      return YES;
  }
  return NO;
}

- (NSString *)wizardObjectType {
  [self logWithFormat:@"ERROR(%s): subclass should override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

- (void)setWizardObjectParent:(id)_obj {
  ASSIGN(self->wizardObjectParent, _obj);
}

- (id)wizardObjectParent {
  return self->wizardObjectParent;
}

- (id)wizardSave {
  [self logWithFormat:@"ERROR(%s): subclasses need to override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

@end /* OGoEditorPage(Wizard) */
