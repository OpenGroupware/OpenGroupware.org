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

#ifndef __LSWebInterface_LSWFoundation_LSWObjectViewer_H__
#define __LSWebInterface_LSWFoundation_LSWObjectViewer_H__

#include <OGoFoundation/LSWComponent.h>

@class NSArray, NSDictionary, NSString, NSFormatter;

/*
  Usage:

    Attributes:
      labels         - labels
      object         - this object will be viewed
      attributes     - attributes of object
      attributeColor -
      valueColor     -
      privateLabel   -
      markArchivedObjects -
    
    Attribute-Keys:

      key            - value to get (from object via -valueForKey:)
      label          - label or labelKey for current attribute
      values         - mapping of attribute values to strings
      valueKeys      - mapping of attribute values to label string-keys
      hideEmpty      - whether we shall hide empty attributes
      isLocalized    - value is localized

    Viewer: LSWObjectViewer {
      labels     = labels;
      object     = address;
      // attributeKeys = ( "name1", "name2", "name3" );
      attributes = (
        { key = "name1"; label = "Name 1"; },
        { key = "name2"; label = "Name 2"; },
        { key = "name3"; label = "Name 3"; },
        {
          key = "id";
          values = { "1" = "eins"; "2" = "zwei"; "3" = "drei" };
        }
      );
      attributeColor = "red";
      valueColor     = "green";
      privateLabel   = labels.privat;
    }
*/

@interface LSWObjectViewer : LSWComponent
{
@protected
  id           relatedObject;
  NSArray      *attributes;     // API
  id           object;          // API
  NSString     *attributeColor; // API
  NSString     *valueColor;     // API
  id           labels;          // API
  BOOL         hideEmpty;       // API
  NSString     *privateLabel;  // API
  NSString     *nullString;

  // transient
  NSDictionary *attribute;    // non-retained
  NSString     *attributeKey; // non-retained
  NSString     *relKey;       // non-retained
  BOOL          isExtendedAttribute;
  BOOL          useMap;
  BOOL          isMailAvailable;
  BOOL          isInternalMailEditor;
  
  NSDictionary *attributesMap;
  NSDictionary *mapItem;

  // cached methods
  id (*getValue)(id self, SEL _cmd, NSString *_key);

  NSFormatter *dateFormatter;
  NSFormatter *numberFormatter;

  BOOL markArchivedObjects;
}

@end

#endif /* __LSWebInterface_LSWFoundation_LSWObjectViewer_H__ */
