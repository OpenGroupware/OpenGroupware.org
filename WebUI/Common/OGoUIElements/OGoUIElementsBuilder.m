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

    //TODO: this is in OGoElemBuilder?!
    <OGo:collapsible .../>  maps to SkyCollapsibleContent

    <OGo:field     .../>    maps to OGoField
    <OGo:fieldset  .../>    maps to OGoFieldSet

    <OGo:calpopup .../>        maps to SkyCalendarPopUp
    <OGo:calpopup-script .../> maps to SkyCalendarScript
*/

@interface OGoUIElementsBuilder : WOxTagClassElemBuilder
@end

#include "common.h"
#include <NGExtensions/NSString+Ext.h>

#ifndef XMLNS_OGoWOx
#  define XMLNS_OGoWOx @"http://www.opengroupware.org/ns/wox/ogo"
#endif

@implementation OGoUIElementsBuilder

static Class         ChildRefClass     = Nil;
static Class         CompoundElemClass = Nil;
static BOOL          debugOn           = NO;
static NSNumber      *yesNum           = nil;
static WOAssociation *yesAssoc         = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  ChildRefClass     = NSClassFromString(@"WOChildComponentReference");
  CompoundElemClass = NSClassFromString(@"WOCompoundElement");
  
  if ((debugOn = [ud boolForKey:@"OGoElemBuilderDebugEnabled"]))
    NSLog(@"Note: OGoElemBuilder debugging enabled.");

  if (yesNum   == nil) 
    yesNum = [[NSNumber numberWithBool:YES] retain];
  if (yesAssoc == nil)
    yesAssoc = [[WOAssociation associationWithValue:yesNum] retain];
}

/* element classes */

- (NSString *)tableViewComponentName {
  return @"SkyTableView";
}
- (NSString *)collapsibleComponentName {
  return @"SkyCollapsibleContent";
}
- (NSString *)datePopUpComponentName {
  return @"SkyCalendarPopUp";
}
- (NSString *)datePopUpScriptComponentName {
  return @"SkyCalendarScript";
}

- (Class)collapsibleContentClass {
  return NGClassFromString(@"SkyCollapsibleContentMode");
}
- (Class)collapsibleTitleClass {
  return NGClassFromString(@"SkyCollapsibleTitleMode");
}

/* support elements */

/* building specific components */

- (WOElement *)buildCollapsible:(id<DOMElement>)_el templateBuilder:(id)_b {
  /*
    visibilityDefault
    visibility
    emptySubmit
    title
    label

    <OGo:collapsible visibilityDefault="scheduler_editor_expand_attributes"
                     emptySubmit="1">
      title
      content
    or:
    OGo:collapsible title="..."


    <#AppCollapsible>
      <#CollTitleMode>...</#CollTitleMode>
      <#CollContentMode>..</#CollContentMode>
    </#AppCollapsible>

    CollTitleMode:   SkyCollapsibleTitleMode   {}
    CollContentMode: SkyCollapsibleContentMode {}

    AppCollapsible: SkyCollapsibleContent {
      visibility = session.userDefaults.scheduler_editor_expand_attributes;
      submitActionName = "";
      structuredMode   = YES;
    }
    
    or:
    ParticipantsTitle:  SkyCollapsibleContent {
      visibility = session.userDefaults.scheduler_editor_expand_participants;
      title      = labels.searchParticipants;
      submitActionName = "";
      isClicked = isParticipantsClicked;
    }
  */
  NSMutableDictionary *assocs;
  id<NSObject,DOMNamedNodeMap> attrs;
  id<NSObject,DOMAttr> attr;
  NSArray   *children;
  NSString  *cid, *s;
  id tmp;
  
  if (debugOn) [self debugWithFormat:@"  build OGo collapsible: %@", _el];
  
  assocs = [NSMutableDictionary dictionaryWithCapacity:8];
  attrs  = [_el attributes];
  
  /* unique component ID */
  
  cid = [_b uniqueIDForNode:_el];
  if (debugOn) [self debugWithFormat:@"  CID: %@", cid];
  
  /* check children */

  if ((tmp = [self lookupUniqueTag:@"content" inElement:_el]) != nil) {
    /* mode a: explicit hierarchy with 'title' and 'content' subelements */
    WOElement *title, *content, *buttons;
    
    /* mark as structured */
    [assocs setObject:yesAssoc forKey:@"structuredMode"];
    
    content = [self wrapChildrenOfElement:tmp
                    inElementOfClass:[self collapsibleContentClass]
                    templateBuilder:_b];
    
    if ((tmp = [self lookupUniqueTag:@"title" inElement:_el]) == nil) {
      [self warnWithFormat:@"WARNING: missing collap. title in: %@", _el];
      title = [self elementForRawString:@"<!-- missing collapsible head -->"];
    }
    else {
      title = [self wrapChildrenOfElement:tmp
                    inElementOfClass:[self collapsibleTitleClass]
                    templateBuilder:_b];
    }

    // TODO: add button mode!
    if ((tmp = [self lookupUniqueTag:@"buttons" inElement:_el]) != nil) {
      [self errorWithFormat:@"NOT SUPPORTING BUTTONS YET!"];
    }
    else
      buttons = nil;

    children = [NSArray arrayWithObjects:title, content, buttons, nil];
    [title   release]; title   = nil;
    [content release]; content = nil;
  }
  else {
    /* mode b: arbitary subelements */
    // TODO: check whether returned children array are retained!
    children = [_el hasChildNodes]
      ? (id)[_b buildNodes:[_el childNodes] templateBuilder:_b]
      : nil;
  }
  
  /* fill associations */

  if ((attr = [attrs namedItem:@"visibility" namespaceURI:@"*"]))
    [assocs setObject:[_b associationForAttribute:attr] forKey:@"visibility"];
  else if ((s = [_el attribute:@"visibilityDefault" namespaceURI:@"*"])) {
    s = [@"session.userDefaults." stringByAppendingString:s];
    [assocs setObject:[WOAssociation associationWithKeyPath:s]
	    forKey:@"visibility"];
  }
  
  if ([[_el attribute:@"emptySubmit" namespaceURI:@"*"] boolValue]) {
    static WOAssociation *emptyStrAssoc = nil;
    if (emptyStrAssoc == nil)
      emptyStrAssoc = [[WOAssociation associationWithValue:@""] retain];
    [assocs setObject:emptyStrAssoc forKey:@"submitActionName"];
  }

  if ((attr = [attrs namedItem:@"isClicked" namespaceURI:@"*"]))
    [assocs setObject:[_b associationForAttribute:attr] forKey:@"isClicked"];
  
  if ((attr = [attrs namedItem:@"title" namespaceURI:@"*"]))
    [assocs setObject:[_b associationForAttribute:attr] forKey:@"title"];
  else if ((s = [_el attribute:@"label" namespaceURI:@"*"])) {
    s = [@"labels." stringByAppendingString:s];
    [assocs setObject:[WOAssociation associationWithKeyPath:s]
            forKey:@"title"];
  }
  
  /* create component */
  
  if (debugOn) [self debugWithFormat:@"collapsible children: %@", children];
  
  [_b registerSubComponentWithId:cid 
      componentName:[self collapsibleComponentName] bindings:assocs];
  return [[ChildRefClass alloc]
           initWithName:cid associations:nil contentElements:children];
}

- (WOElement *)buildComponent:(NSString *)_name element:(id<DOMElement>)_el
  templateBuilder:(id)_b
{
  NSMutableDictionary *assocs;
  WOElement *component;
  NSArray   *children;
  NSString  *cid;
  
  if (debugOn) [self debugWithFormat:@"  build %@: %@", _name, _el];
  
  /* unique component ID */
  
  cid = [_b uniqueIDForNode:_el];
  if (debugOn) [self debugWithFormat:@"  CID: %@", cid];

  /* component content */
  
  children = [_el hasChildNodes]
    ? (id)[_b buildNodes:[_el childNodes] templateBuilder:_b]
    : nil;
  
  /* build associations */
  
  if ((assocs = [_b associationsForAttributes:[_el attributes]]) == nil)
    assocs = [NSMutableDictionary dictionaryWithCapacity:2];
  
  /* build component reference */
  
  [_b registerSubComponentWithId:cid 
      componentName:_name bindings:assocs];
  if (debugOn) 
    [self logWithFormat:@"ref: %@ => %@, %@: %@", _name, _b, cid, assocs];
  
  component = [[ChildRefClass alloc]
		initWithName:cid associations:nil contentElements:children];
  if (debugOn) [self logWithFormat:@"  %@", component];
  return component;
}

- (WOElement *)buildSimpleCollapsible:(id<DOMElement>)_el
  templateBuilder:(id)_b
{
  Class               clazz;
  NSMutableDictionary *assocs;
  NSArray             *children;
  WODynamicElement    *element;
  id tmp;
  
  clazz    = NSClassFromString(@"WOCollapsibleComponentContent");
  assocs   = [_b associationsForAttributes:[_el attributes]];
  children = [_b buildNodes:[_el childNodes] templateBuilder:_b];

  /* patch bindings */
  
  if ([assocs objectForKey:@"openedImageFileName"] == nil) {
    tmp = [WOAssociation associationWithValue:@"expanded.gif"];
    [assocs setObject:tmp forKey:@"openedImageFileName"];
  }
  if ([assocs objectForKey:@"closedImageFileName"] == nil) {
    tmp = [WOAssociation associationWithValue:@"collapsed.gif"];
    [assocs setObject:tmp forKey:@"closedImageFileName"];
  }
  
  if ([assocs objectForKey:@"visibility"] == nil) {
    if ((tmp = [assocs objectForKey:@"visible"]) != nil) {
      if ([tmp isValueSettable]) {
	[assocs setObject:tmp forKey:@"visibility"];
	[assocs removeObjectForKey:@"visible"];
      }
      else if ([tmp isValueConstant]) {
	if ([tmp boolValueInComponent:nil]) {
	  [self logWithFormat:
		  @"ERROR: does not support static 'visible' YES binding."];
	}
      }
      else {
	[self logWithFormat:
		@"ERROR: does not support unsettable 'visible' binding."];
      }
    }
    if ((tmp = [assocs objectForKey:@"visibility"]) == nil) {
      NSString *v;
      
      v = [self uniqueIDForNode:_el];
      v = [v stringByReplacingString:@"." withString:@"_"];
      v = [@"cvisi_" stringByAppendingString:v];
      tmp = [WOAssociation associationWithKeyPath:v];
      [assocs setObject:tmp forKey:@"visibility"];
    }
  }
  
  if ((tmp = [assocs objectForKey:@"title"]) != nil) {
    [assocs setObject:tmp forKey:@"label"];
    [assocs removeObjectForKey:@"title"];
  }
  if ((tmp = [assocs objectForKey:@"label"]) != nil) {
    if ([assocs objectForKey:@"openedLabel"] == nil)
      [assocs setObject:tmp forKey:@"openedLabel"];
    if ([assocs objectForKey:@"closedLabel"] == nil)
      [assocs setObject:tmp forKey:@"closedLabel"];
    [assocs removeObjectForKey:@"label"];
  }
  
  if ([assocs objectForKey:@"submitActionName"] == nil) {
    // Note: form submits are only generated if this is set
  }
  
  /* create element */
  
  element = [[clazz alloc] initWithName:[_el tagName] associations:assocs 
			   contentElements:children];
  [element setExtraAttributes:assocs];
  // TODO: check whether retain-counting is OK for assocs and children!
  return element;
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
    case 'f': { /* starting with 'f' */
      if (tl == 5 && [tagName isEqualToString:@"field"])
	return NGClassFromString(@"OGoField");
      if (tl == 8 && [tagName isEqualToString:@"fieldset"])
	return NGClassFromString(@"OGoFieldSet");
      break;
    }
    case 't': { /* starting with 't' */
      unichar c2;
      
      c2 = [tagName characterAtIndex:1];
      
      if (tl == 2) {
        if (c2 == 'd') return NGClassFromString(@"WETableData");
        if (c2 == 'h') return NGClassFromString(@"WETableHeader");
      }
      if (tl > 5) {
        if ([tagName isEqualToString:@"tbutton"])
          return NGClassFromString(@"WETableViewButtonMode");
        if ([tagName isEqualToString:@"ttitle"])
          return NGClassFromString(@"WETableViewTitleMode");
        if ([tagName isEqualToString:@"tfooter"])
          return NGClassFromString(@"WETableViewFooterMode");
        if ([tagName isEqualToString:@"tgroup"])
          return NGClassFromString(@"WETableViewGroupMode");
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
    case 'c': { /* starting with 'c' */
      if (tl == 11 && [tagName isEqualToString:@"collapsible"])
        return [self buildCollapsible:_element templateBuilder:_b];
      
      if (tl == 8 && [tagName isEqualToString:@"calpopup"]) {
	return [self buildComponent:[self datePopUpComponentName]
		     element:_element templateBuilder:_b];
      }
      if (tl == 15 && [tagName isEqualToString:@"calpopup-script"]) {
	return [self buildComponent:[self datePopUpScriptComponentName]
		     element:_element templateBuilder:_b];
      }
      break;
    }
    case 's': { /* starting with 's' */
      if (tl == 12 && [tagName isEqualToString:@"scollapsible"])
	return [self buildSimpleCollapsible:_element templateBuilder:_b];
      break;
    }
    case 't': {
      if (tl == 9 && [tagName isEqualToString:@"tableview"])
	return [self buildComponent:[self tableViewComponentName]
		     element:_element templateBuilder:_b];
      break;
    }
  }
  
  /* we need to call super, so that the build queue processing continues */
  return [super buildElement:_element templateBuilder:_b];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

@end /* OGoUIElementsBuilder */
