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

#ifndef __OGo_OGoFoundation_H__
#define __OGo_OGoFoundation_H__

// Module Header File

#include <OGoFoundation/OGoComponent.h>
#include <OGoFoundation/OGoContentPage.h>
#include <OGoFoundation/OGoNavigation.h>
#include <OGoFoundation/OGoSession.h>

#include <OGoFoundation/LSStringFormatter.h>
#include <OGoFoundation/NSObject+LSWPasteboard.h>
#include <OGoFoundation/OGoResourceManager.h>
#include <OGoFoundation/LSWTreeState.h>
#include <OGoFoundation/LSWViewerPage.h>
#include <OGoFoundation/NSObject+Commands.h>
#include <OGoFoundation/SkyWizard.h>
#include <OGoFoundation/SkyWizardViewer.h>
#include <OGoFoundation/WOComponent+Commands.h>
#include <OGoFoundation/WOComponent+Navigation.h>
#include <OGoFoundation/WOComponent+config.h>
#include <OGoFoundation/WOSession+LSO.h>
#include <OGoFoundation/LSWLabelHandler.h>
#include <OGoFoundation/SkyMoneyFormatter.h>

#include <OGoFoundation/OGoSession.h>
#include <OGoFoundation/LSWClipboardOwner.h>
#include <OGoFoundation/LSWConfigHandler.h>
#include <OGoFoundation/OGoEditorPage.h>
#include <OGoFoundation/LSWEditorPage+Wizard.h>
#include <OGoFoundation/LSWMailEditorComponent.h>
#include <OGoFoundation/LSWMasterComponent.h>
#include <OGoFoundation/LSWMimeContent.h>
#include <OGoFoundation/OGoModuleManager.h>
#include <OGoFoundation/LSWNotifications.h>
#include <OGoFoundation/OGoObjectMailPage.h>

// kit class

@interface LSWFoundation : NSObject
@end

#define LINK_LSWFoundation \
  static void __LINK_LSWFoundation(void) __attribute__((unused));\
  static void __LINK_LSWFoundation(void) { [LSWFoundation class]; }

#endif /* __OGo_OGoFoundation_H__ */
