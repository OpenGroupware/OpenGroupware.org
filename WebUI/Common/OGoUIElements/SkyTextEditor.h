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

#include <NGObjWeb/WOComponent.h>

@class NSString, NSArray;

/*
  Bindings:

    text             - string - inout
    name             - string - in
    wrap             - string - in
    rows             - int    - inout
    columns          - int    - inout
    noSizeControls   - bool   - in
    showValidateXML  - bool   - in
    showValidateHTML - bool   - in
    isValidXML       - bool   - out
    isValidHTML      - bool   - out
*/

@interface SkyTextEditor : WOComponent
{
  NSString *text;
  NSString *name;

  NSString *wrap;
 
  /* TODO: make that flags */
  BOOL     noSizeControls;
  BOOL     showValidateXML;
  BOOL     showValidateHTML;
  NSString *htmlErrorString;
  NSString *xmlErrorString;
  BOOL     didValidateHTML;
  BOOL     didValidateXML;
  struct {
    int enableEpoz:1;
    int reserved:31;
  } steFlags;
  
  int rows;
  int columns;
}

- (NSString *)validationText;
- (NSString *)_formatSaxExceptions:(NSArray *)_exceptions;

@end
