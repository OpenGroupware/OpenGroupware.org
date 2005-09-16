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

#include "OGoUserSelectionComponent.h"

@interface SkyParticipantsSelection : OGoUserSelectionComponent
{
  NSString *headLineLabel;
  struct {
    int viewHeadLine:1;
    int reserved:31;
  } spsFlags;
}
@end

#include <OGoFoundation/OGoSession.h>
#include <LSFoundation/LSCommandContext.h>
#include "common.h"

@implementation SkyParticipantsSelection

static BOOL hasLSWEnterprises = NO;

+ (void)initialize {
  NGBundleManager *bm = [NGBundleManager defaultBundleManager];
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  hasLSWEnterprises = [bm bundleProvidingResource:@"LSWEnterprises"
			  ofType:@"WOComponents"] ? YES : NO;
}

- (id)init {
  if ((self = [super init]) != nil) {
    self->spsFlags.viewHeadLine = 1;
  }
  return self;
}

/* accessors */

- (void)setViewHeadLine:(BOOL)_view {
  self->spsFlags.viewHeadLine = _view ? 1 : 0;
}
- (BOOL)viewHeadLine {
  return self->spsFlags.viewHeadLine ? YES : NO;
}

- (void)setHeadLineLabel:(NSString *)_str {
  ASSIGNCOPY(self->headLineLabel, _str);
}
- (NSString *)headLineLabel {
  return self->headLineLabel;
}

- (BOOL)isEnterpriseAvailable {
  return hasLSWEnterprises;
}

- (BOOL)showExtendEnterprisesCheckBox {
  return (!self->uscFlags.onlyAccounts && hasLSWEnterprises);
}

@end /* SkyParticipantsSelection */
