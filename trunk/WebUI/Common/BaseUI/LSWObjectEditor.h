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

#ifndef __BaseUI_LSWObjectEditor_H__
#define __BaseUI_LSWObjectEditor_H__

#include <OGoFoundation/OGoComponent.h>

@class NSArray, NSDictionary, NSString;

/*
  Usage:

    Attribute-Keys:

      key       - value to get (from object via -valueForKey:)
      label     - label or labelKey for current attribute
      values    - mapping of attribute values to strings
      valueKeys - mapping of attribute values to label string-keys

    Editor: LSWObjectEditor {
      object     = address;
      // attributeKeys = ( "name1", "name2", "name3" );
      attributes = (
        { key = "name1"; label = "Name 1"; },
        { key = "name2"; label = "Name 2"; },
        { key = "name3"; label = "Name 3"; },
        { key = "id"; values = { "1" = "eins"; "2" = "zwei"; "3" = "drei" }; }
      );
    }
*/

@interface LSWObjectEditor : OGoComponent
{
@protected
  id           object;        // API
  NSArray      *attributes;   // API
  id           labels;        // API
  NSString     *privateLabel; // API
  NSDictionary *map;          // API
  NSArray      *showOnly;
  NSString     *prefix;
  
  // transient
  NSDictionary *attribute;    // non-retained
  NSString     *currentKey;   // non-retained
  
  id item;                    // non-retained

  int colVal;
  int colAttr;
}

- (int)currentTypeCode;

@end

#endif /* __BaseUI_LSWObjectEditor_H__ */
