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

#ifndef __BaseUI_SkyButtonRow_H__
#define __BaseUI_SkyButtonRow_H__

#import <NGObjWeb/WODynamicElement.h>

@class NSSet, NSDictionary;
@class WOAssociation, WOElement;

/*
  SkyButtonRow

    fix associations

      ordering               ordering array for custom buttons

    dynamic associations beginning with

      on      eg onClip      action to be executed on click
      has     eg hasEdit     whether the button is enabled (default: YES)
      url     eg urlMail     href to use for button link
      tip     eg tipMail     tooltip label

    all other associations are considered labels, eg the 'mail' association
    will contain the label for the mail button.
*/

@interface SkyButtonRow : WODynamicElement
{
@protected
  WOElement     *template;      /* additional elements */
  WOAssociation *ordering;
  WOAssociation *oid;
  WOAssociation *size;          /* the font size */
  NSSet         *activeButtons; /* keys of active buttons */
  NSDictionary  *conditions;    /* associations starting with 'has' */
  NSDictionary  *eventHandlers; /* associations starting with 'on'  */
  NSDictionary  *urls;          /* associations starting with 'url' */
  NSDictionary  *tooltips;      /* associations starting with 'tip' */
  NSDictionary  *targets;
  NSDictionary  *labels;        /* the rest is considered a label   */
  BOOL          isMailAvailable;
  struct {
    BOOL hasClip:1;
    BOOL hasMail:1;
    BOOL hasEdit:1;
    BOOL hasDelete:1;
    BOOL hasMove:1;
    BOOL hasNew:1;
  } defaultButtons;
}

@end

#endif /* __BaseUI_SkyButtonRow_H__ */
