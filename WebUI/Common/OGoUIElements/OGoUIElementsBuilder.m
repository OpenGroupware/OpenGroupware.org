/*
  Copyright (C) 2004-2005 SKYRIX Software AG

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

#include <NGObjWeb/WOxElemBuilder.h>

/*
  This builder builds various OGo XML elements.
  
  All tags are mapped into the <OGo:> namespace:
    "http://www.opengroupware.org/ns/wox/ogo"
  
  Supported tags:
    <OGo:tableview .../>    maps to SkyTableView
    <OGo:tbutton   .../>    maps to WETableViewButtonMode
    <OGo:ttitle    .../>    maps to WETableViewTitleMode
    <OGo:tfooter   .../>    maps to WETableViewFooterMode
    <OGo:tgroup    .../>    maps to WETableViewGroupMode
    <OGo:td        .../>    maps to WETableData
    <OGo:th        .../>    maps to WETableHeader
*/

@interface OGoUIElementsBuilder : WOxTagClassElemBuilder
@end

#include "common.h"

#ifndef XMLNS_OGoWOx
#  define XMLNS_OGoWOx @"http://www.opengroupware.org/ns/wox/ogo"
#endif

@implementation OGoUIElementsBuilder

static Class ChildRefClass     = Nil;
static Class CompoundElemClass = Nil;
static BOOL  debugOn           = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  ChildRefClass     = NSClassFromString(@"WOChildComponentReference");
  CompoundElemClass = NSClassFromString(@"WOCompoundElement");
  
  if ((debugOn = [ud boolForKey:@"OGoElemBuilderDebugEnabled"]))
    NSLog(@"Note: OGoElemBuilder debugging enabled.");
}

/* element classes */

- (NSString *)tableViewComponentName {
  return @"SkyTableView";
}

/* support elements */

/* building specific components */

- (WOElement *)buildTableView:(id<DOMElement>)_el templateBuilder:(id)_b {
  NSMutableDictionary *assocs;
  NSArray  *children;
  NSString *cid;
  
  if (debugOn) [self debugWithFormat:@"  build OGo tableview: %@", _el];
  
  /* unique component ID */
  
  cid = [_b uniqueIDForNode:_el];
  if (debugOn) [self debugWithFormat:@"  CID: %@", cid];

  /* component content */
  
  children = [_el hasChildNodes]
    ? [_b buildNodes:[_el childNodes] templateBuilder:_b]
      : nil;

  /* build associations */
  
  if ((assocs = [_b associationsForAttributes:[_el attributes]]) == nil)
    assocs = [NSMutableDictionary dictionaryWithCapacity:2];
  
  /* build component reference */
  
  [_b registerSubComponentWithId:cid 
      componentName:[self tableViewComponentName] bindings:assocs];
  
  return [[ChildRefClass alloc]
           initWithName:cid associations:nil contentElements:children];
}

/* element class builder (direct mappings of XML tag to dynamic element) */

- (Class)classForElement:(id<DOMElement>)_element {
  NSString *tagName;
  unsigned tl;
  unichar c1;
  
  if (![[_element namespaceURI] isEqualToString:XMLNS_OGoWOx])
    return [super classForElement:_element];
  
  tagName = [_element tagName];
  if ((tl = [tagName length]) < 2)
    return Nil;

  c1 = [tagName characterAtIndex:0];

  switch (c1) {
    case 't': { /* starting with 't' */
      unichar c2;
      
      c2 = [tagName characterAtIndex:1];
      
      if (tl == 2) {
        if (c2 == 'd') return NSClassFromString(@"WETableData");
        if (c2 == 'h') return NSClassFromString(@"WETableHeader");
      }
      if (tl > 5) {
        if ([tagName isEqualToString:@"tbutton"])
          return NSClassFromString(@"WETableViewButtonMode");
        if ([tagName isEqualToString:@"ttitle"])
          return NSClassFromString(@"WETableViewTitleMode");
        if ([tagName isEqualToString:@"tfooter"])
          return NSClassFromString(@"WETableViewFooterMode");
        if ([tagName isEqualToString:@"tgroup"])
          return NSClassFromString(@"WETableViewGroupMode");
      }
      break;
    }
  }
  
  return [super classForElement:_element];
}

/* main dispatcher for hooking up non-class based elements */

- (WOElement *)buildElement:(id<DOMElement>)_element templateBuilder:(id)_b {
  NSString  *tagName;
  unsigned  tl;
  unichar   c1;

  if (debugOn) [self debugWithFormat:@"try to build element: %@", _element];
  
  if (![[_element namespaceURI] isEqualToString:XMLNS_OGoWOx]) {
    if (debugOn) [self debugWithFormat:@"  not in OGo namespace: %@",_element];
    return [self->nextBuilder buildElement:_element templateBuilder:_b];
  }
  
  tagName = [_element tagName];
  if ((tl = [tagName length]) < 2)
    return nil;
  c1 = [tagName characterAtIndex:0];
  
  if (debugOn) [self debugWithFormat:@"  try to build OGo tag: %@", tagName];

  switch (c1) {
  case 't':
    if (tl == 9 && [tagName isEqualToString:@"tableview"])
      return [self buildTableView:_element templateBuilder:_b];
  }
  
  /* we need to call super, so that the build queue processing continues */
  return [super buildElement:_element templateBuilder:_b];
}

@end /* OGoUIElementsBuilder */
