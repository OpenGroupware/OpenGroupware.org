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

// TODO: find out whether this is still used!

#include <OGoFoundation/SkyWizard.h>
#include "common.h"
#include <NGMime/NGMimeType.h>

@interface SkyPersonWizard : SkyWizard 
@end

@interface NSObject(PRIVATE)
- (void)setAddressType:(NSString *)_type;
- (void)setPosibilities:(id)_pos;
@end

@implementation SkyPersonWizard

- (int)maxSteps {
  return 5;
}

- (NSString *)wizardName {
  return @"person";
}

- (BOOL)isFinish {
  return YES;
}

- (NSString *)labelPage {
  return @"LSWPersonEditor";
}

- (BOOL)pageCouldChangeForStep:(int)_step {
  if (_step == 4)
    return YES;
  return NO;
}

- (id)enterPersonData:(id)_obj {
  OGoEditorPage *page;
  
  [self->session transferObject:self owner:nil];
  page = (id)[self->session
                  instantiateComponentForCommand:@"wizard"
                  type:[NGMimeType mimeType:@"eo" subType:@"person"]];
  [page setWizard:self];  
  [page setWindowTitle:
        [[self labels] valueForKey:@"personeditor_wizard_title"]];
  if (_obj != nil)
    [page setSnapshot:_obj];
  
  return page;
}

- (id)enterAddress:(id)_obj type:(NSString *)_type {
  OGoEditorPage *page;
  NSString *str;

  page = (id)[self->session 
                  instantiateComponentForCommand:@"wizard"
                  type:[NGMimeType mimeType:@"eo" subType:@"address"]];
  str = [NSString stringWithFormat:@"%@addresseditor_wizard_title", _type];
  if (_obj != nil) [page setSnapshot:_obj];
  [page setWizard:self];
  [page setWindowTitle:[[self labels] valueForKey:str]];
  [page setAddressType:_type];
  return page;
}

- (id)chooseEnterpriseOrPrivateAddress:(id)_obj {
  id page;

  page = [[self->session application] pageWithName:@"SkyWizardChoicePage"];

  [page setPosibilities:
        [NSArray arrayWithObjects:
                 [NSDictionary dictionaryWithObjectsAndKeys:
                               @"LSWAddressEditor",     @"page",
                               @"chooseMailingAddress", @"label", nil],
                 [NSDictionary dictionaryWithObjectsAndKeys:
                               @"LSWEnterpriseFullSearch", @"page",
                               @"chooseEnterprise"       , @"label", nil],
                 nil]];
  [page setWizard:self];
  return page;
}

- (id)enterEnterpriseOrPrivateAddress:(id)_obj {
  WOComponent *page;
  BOOL flag;

  page = [self cachedPage];
  flag = [NSStringFromClass([page class]) isEqualToString:
                             [self choosenPageName]];
  if (!((page == nil) || !flag))
    return page;
  
  if ([choosenPageName isEqualToString:@"LSWAddressEditor"])
    return [self enterAddress:_obj type:@"mailing"];
  
  if ([choosenPageName isEqualToString:@"LSWEnterpriseFullSearch"]) {
    page = [self->session instantiateComponentForCommand:@"wizard-search"
                  type:[NGMimeType mimeType:@"eo" subType:@"enterprise"]];
    [(OGoEditorPage *)page setWindowTitle:@"WizardFullSearch"];
    [(OGoEditorPage *)page setWizard:self];
    return page;
  }

  [self logWithFormat:
          @"WARNING: wrong pagename for enterEnterpriseOrPrivateAddress"];
  return page;
}

- (id)doStep:(int)_step withObject:(id)_obj {
  WOComponent *page;

  page = nil;
  
   if (!(self->stepForward && ([self pageCouldChangeForStep:_step])))
     page = [self cachedPage];
      
  if (page == nil) {
    [self->session transferObject:self owner:nil];
    switch (_step) {
      case 0:
        page = [self enterPersonData:_obj];
        break;
      case 1:
        page = [self enterAddress:_obj type:@"private"];
        break;
      case 2:
        page = [self enterAddress:_obj type:@"location"];
        break;
      case 3:
        page = [self chooseEnterpriseOrPrivateAddress:_obj];
        break;
      case 4:
        page = [self enterEnterpriseOrPrivateAddress:_obj];
        break;
    }
  }
  return [self goToPage:page];
}

@end /* SkyPersonWizard */
