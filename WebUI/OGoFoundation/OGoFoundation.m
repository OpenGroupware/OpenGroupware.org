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

#include "LSWObjectMailPage.h"
#include "NSObject+LSWPasteboard.h"
#include "LSWContentPage.h"
#include "WOSession+LSO.h"
#include "WOComponent+config.h"
#include "WOComponent+Commands.h"
#include "OGoConfigHandler.h"
#include "OGoViewerPage.h"
#include "OGoEditorPage.h"
#include "LSStringFormatter.h"
#include "LSWMasterComponent.h"
#include "LSWComponent.h"
#include "LSWObjectMailPage.h"
#include "OGoFoundation.h"
#include "OGoSession.h"

#import <NGObjWeb/NGObjWeb.h>

extern void __link_WOComponent_config(void);
extern void __link_WOComponent_Commands(void);

@implementation LSWFoundation

- (void)_staticLinkClasses {
  [LSWContentPage        self];
  [OGoConfigHandler      self];
  [LSWViewerPage         self];
  [OGoEditorPage         self];
  [LSStringFormatter     self];
  [LSWComponent          self];
  [LSWObjectMailPage     self];
  [OGoSession            self];
}

- (void)_staticLinkCategories {
  __link_WOComponent_config();
  __link_WOComponent_Commands();
}

- (void)_staticLinkModules {
  [NGObjWeb class];
}

@end /* LSWFoundation */
