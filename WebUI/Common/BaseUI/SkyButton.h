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

#ifndef __LSWBase_SkyButton_H__
#define __LSWBase_SkyButton_H__

#import <NGObjWeb/WODynamicElement.h>

@class WOAssociation;

/*
  SkyButton requires several icons:

    button_ne.gif
    button_nw.gif
    button_se.gif
    button_sw.gif
    button_pixel.gif
*/

@interface SkyButtonFrame : WODynamicElement
{
  // WODynamicElement: extraAttributes
  // WODynamicElement: otherTagString
@protected
  WOElement     *template;
  WOAssociation *textMode;
  WOAssociation *embedInCell;
  WOAssociation *hideIfDisabled;
  WOAssociation *disabled;
}

@end

@interface SkyButton : SkyButtonFrame
{
  // WODynamicElement: extraAttributes
  // WODynamicElement: otherTagString
  // SkyButtonFrame:   template;
  // SkyButtonFrame:   textMode;
@protected
  enum { SkyButton_href, SkyButton_action, SkyButton_da } actionType;
  WOAssociation *string;
  WOAssociation *tooltip;
  WOAssociation *action;
}

@end

@class NSDictionary, NSSet;

#include "SkyButtonRow.h"

#endif /* __LSWBase_SkyButton_H__ */
