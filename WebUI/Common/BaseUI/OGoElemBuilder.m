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
  
  Note: The implementation of this builder is hackish and code intense, 
        because the elements being constructed are not designed with XML
	in mind. If everything is driven by .wox we might be able to fix
	this issue.
  
  All tags are mapped into the <OGo:> namespace:
    "http://www.opengroupware.org/ns/wox/ogo"
  
  Supported tags:
    <OGo:page [title,onClose] .../> to LSWSkyrixFrame, OGoWindowFrame
      <head/>
      <body/>
      <warn/>
    <OGo:page-head .../>
    <OGo:page-body .../>
    <OGo:buttons   .../>
      <button>
    <OGo:attributes .../>
      <attribute>
    <OGo:tab       .../>
    <OGo:span      .../>
    <OGo:calendarpopup .../>
    <OGo:container .../>
    <OGo:font .../>
    <OGo:label .../>
*/

@interface OGoElemBuilder : WOxTagClassElemBuilder
{
}

@end

#include "common.h"

#ifndef XMLNS_OGoWOx
#  define XMLNS_OGoWOx @"http://www.opengroupware.org/ns/wox/ogo"
#endif

@interface WOElement(UsedPrivates)
+ (id)allocForCount:(int)_count zone:(NSZone *)_zone;
- (id)initWithContentElements:(NSArray *)_elements;
- (id)initWithValue:(id)_value escapeHTML:(BOOL)_flag;
@end

@implementation OGoElemBuilder

static Class ChildRefClass     = Nil;
static Class CompoundElemClass = Nil;
static Class StrClass          = Nil;
static Class DynStrClass       = Nil;
static BOOL  debugOn           = NO;
static NSNumber      *yesNum   = nil;
static WOAssociation *yesAssoc = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  ChildRefClass     = NSClassFromString(@"WOChildComponentReference");
  CompoundElemClass = NSClassFromString(@"WOCompoundElement");
  StrClass          = NSClassFromString(@"_WOSimpleStaticString");
  DynStrClass       = NSClassFromString(@"_WOSimpleDynamicString");
  
  if (yesNum   == nil) 
    yesNum = [[NSNumber numberWithBool:YES] retain];
  if (yesAssoc == nil)
    yesAssoc = [[WOAssociation associationWithValue:yesNum] retain];
  
  if ((debugOn = [ud boolForKey:@"OGoElemBuilderDebugEnabled"]))
    NSLog(@"Note: OGoElemBuilder debugging enabled.");
}

/* element classes */

- (NSString *)frameComponentName {
  return @"LSWSkyrixFrame";
}
- (Class)windowFrameClass {
  return NSClassFromString(@"OGoWindowFrame");
}
- (Class)viewerTitleClass {
  return NSClassFromString(@"LSWViewerTitle");
}
- (Class)buttonRowClass {
  return NSClassFromString(@"SkyButtonRow");
}
- (Class)attributeClass {
  return NSClassFromString(@"SkyAttribute");
}
- (Class)tabClass {
  return NSClassFromString(@"SkyTabView");
}
- (Class)objValueClass {
  return NSClassFromString(@"SkyObjectValue");
}
- (Class)tabItemClass {
  return NSClassFromString(@"SkyTabItem");
}
- (Class)conditionalClass {
  return NSClassFromString(@"WOConditional");
}

- (Class)fontClass {
  return NSClassFromString(@"SkyConfigFont");
}
- (Class)editFontClass {
  return NSClassFromString(@"SkyConfigEditFont");
}

- (NSString *)calPopUpComponentName {
  return @"SkyCalendarPopUp";
}

- (NSString *)warningComponentName {
  return @"LSWWarningPanel";
}

- (NSString *)collapsibleComponentName {
  return @"SkyCollapsibleContent";
}

/* convenience methods */

- (id<DOMElement>)lookupUniqueTag:(NSString *)_name in:(id<DOMElement>)_elem {
  id<DOMNodeList> list;
  
  if ((list = [_elem getElementsByTagName:_name]) == nil)
    return nil;
  if ([list length] == 0)
    return nil;
  if ([list length] > 1) {
    [self logWithFormat:
	    @"WARNING: more than once occurence of tag %@ in element: %@", 
	    _name, _elem];
  }
  return [list objectAtIndex:0];
}

/* support elements */

- (WOElement *)elementForRawString:(NSString *)_rawstr {
  /* Note: returns a retained element! */
  WOAssociation *a;
  
  if (_rawstr == nil) return nil;
  a = [WOAssociation associationWithValue:_rawstr];
  return [[StrClass alloc] initWithValue:a escapeHTML:NO];
}

- (WOElement *)elementForElementsAndStrings:(NSArray *)_elements {
  /* Note: returns a retained element! */
  NSMutableArray *ma;
  WOElement *element;
  unsigned  i, count;
  
  if ((count = [_elements count]) == 0)
    return nil;
  
  ma = [[NSMutableArray alloc] initWithCapacity:count];
  for (i = 0; i < count; i++) {
    id elem;
    
    elem = [_elements objectAtIndex:i];
    if ([elem isKindOfClass:[WOElement class]]) {
      [ma addObject:elem];
      continue;
    }
    
    if ((elem = [self elementForRawString:[elem stringValue]]))
      [ma addObject:elem];
  }
  if ((count = [ma count]) == 0)
    element = nil;
  else if (count == 1) {
    element = [[ma objectAtIndex:0] retain];
  }
  else {
    element = [[CompoundElemClass allocForCount:count zone:NULL]
		initWithContentElements:ma];
  }
  [ma release];
  return element;
}

- (WOElement *)wrapElement:(WOElement *)_element 
  inCondition:(WOAssociation *)_condition
  negate:(BOOL)_flag
{
  // NOTE: *releases* _element parameter!
  //       returns retained conditional
  static NSString *key = @"condition";
  NSMutableDictionary *assocs;
  WOElement *element;
  NSArray   *children;
  
  if (_element == nil)
    return nil;
  if (_condition == nil)
    return _element;
  
  if (_flag) {
    assocs = [[NSMutableDictionary alloc] 
	       initWithObjectsAndKeys:_condition, key,
	       yesAssoc, @"negate", nil];
  }
  else {
    assocs = [[NSMutableDictionary alloc] initWithObjects:&_condition
					  forKeys:&key count:1];
  }
  children = [[NSArray alloc] initWithObjects:&_element count:1];
  element = [[[self conditionalClass] alloc] initWithName:nil
                                             associations:assocs
                                             contentElements:children];
  [children release];
  [_element release];
  [assocs   release];
  return element;
}
- (WOElement *)wrapElement:(WOElement *)_element 
  inCondition:(WOAssociation *)_condition
{
  return [self wrapElement:_element inCondition:_condition negate:NO];
}

- (WOElement *)wrapElements:(NSArray *)_children inElement:(Class)_class {
  WOElement *element;
  
  if (_children == nil)
    return nil;
  
  element = [[_class alloc] initWithName:nil
                            associations:nil
                            contentElements:_children];
  return element;
}

/* build specific elements */

- (WOElement *)buildObjectValue:(id<DOMElement>)_elem templateBuilder:(id)_b {
  /*
    object > object // always keypath
    key    > value  // always keypath: $object.$key
    
    <objectvalue object="note.currentOwner" key="login" />

    NoteOwner: SkyObjectValue {
      object = note.currentOwner;
      value  = note.currentOwner.login;
    }
  */
  NSMutableDictionary *assocs;
  WOElement *element;
  NSString  *objectKP, *s;
  
  assocs = [[NSMutableDictionary alloc] initWithCapacity:8];
  
  objectKP = [_elem attribute:@"object" namespaceURI:@"*"];
  if ([objectKP length] == 0) {
    [self logWithFormat:@"WARNING: missing 'object' attribute in tag: %@",
	    _elem];
    objectKP = @"object";
  }
  
  [assocs setObject:[WOAssociation associationWithKeyPath:objectKP]
	  forKey:@"object"];
  
  if ((s = [_elem attribute:@"key" namespaceURI:@"*"])) {
    s = [[objectKP stringByAppendingString:@"."] stringByAppendingString:s];
    [assocs setObject:[WOAssociation associationWithKeyPath:s]
	    forKey:@"value"];
  }
  
  element = [[[self objValueClass] alloc] initWithName:nil
					  associations:assocs
					  contentElements:nil];
  [assocs release];
  return element;
}

- (WOElement *)buildTab:(id<DOMElement>)_elem templateBuilder:(id)_b {
  /*
    selectionDefault > selection // always keypath: session.userDefaults.$value
    selection        > selection // regular assoc
    
    <tab selectionDefault="IPubProjectPage_lasttab"> ... </tab>
    
    Tab: SkyTabView { // dynamic element
      selection = session.userDefaults.IPubProjectPage_lasttab;
    }
  */
  id<NSObject,DOMNamedNodeMap> attrs;
  id<NSObject,DOMAttr> attr;
  NSMutableDictionary *assocs;
  NSArray   *children;
  WOElement *element;
  NSString  *s;
  
  assocs = [[NSMutableDictionary alloc] initWithCapacity:8];
  attrs  = [_elem attributes];
  
  /* fill associations */
  
  if ((attr = [attrs namedItem:@"selection" namespaceURI:@"*"]))
    [assocs setObject:[_b associationForAttribute:attr] forKey:@"selection"];
  
  else if ((s = [_elem attribute:@"selectionDefault" namespaceURI:@"*"])) {
    s = [@"session.userDefaults." stringByAppendingString:s];
    [assocs setObject:[WOAssociation associationWithKeyPath:s]
	    forKey:@"selection"];
  }
  
  /* create element */
  
  children = [_elem hasChildNodes]
    ? [_b buildNodes:[_elem childNodes] templateBuilder:_b]
    : nil;
  
  element = [[[self tabClass] alloc] initWithName:nil
				     associations:assocs
				     contentElements:children];
  [assocs release];
  return element;
}

- (WOElement *)buildTabItem:(id<DOMElement>)_elem templateBuilder:(id)_b {
  // TODO: should we build a SkySimpleTabItem instead?
  /*
    key     // regular assoc
    label   // always keypath: labels.$value
    enabled // wrap in WOConditional, enabled=>condition, always keypath
    
    <tabitem key="01" label="Institute"/>
    
    InstituteTabItem: SkyTabItem { // dynamic element
      key   = "01";
      label = "Institute";
    }
  */
  id<NSObject,DOMNamedNodeMap> attrs;
  id<NSObject,DOMAttr> attr;
  NSMutableDictionary  *assocs;
  WOAssociation *condition;
  NSArray       *children;
  WOElement     *element;
  NSString      *s;
  
  assocs = [[NSMutableDictionary alloc] initWithCapacity:8];
  attrs  = [_elem attributes];
  
  /* fill associations */
  
  if ((attr = [attrs namedItem:@"key" namespaceURI:@"*"]))
    [assocs setObject:[_b associationForAttribute:attr] forKey:@"key"];
  
  if ((s = [_elem attribute:@"label" namespaceURI:@"*"])) {
    s = [@"labels." stringByAppendingString:s];
    [assocs setObject:[WOAssociation associationWithKeyPath:s]forKey:@"label"];
  }
  
  condition = ((s = [_elem attribute:@"enabled" namespaceURI:@"*"]))
    ? [WOAssociation associationWithKeyPath:s] : nil;
  
  /* create element */
  
  children = [_elem hasChildNodes]
    ? [[_b buildNodes:[_elem childNodes] templateBuilder:_b] retain]
    : nil;
  
  if (children) { /* wrap children in standard font */
    if ((element = [self wrapElements:children inElement:[self fontClass]])) {
      children = [[NSArray alloc] initWithObjects:&element count:1];
      [element release]; element = nil;
    }
  }
  
  element = [[[self tabItemClass] alloc] initWithName:nil
					 associations:assocs
					 contentElements:children];
  [assocs   release];
  [children release];
  return [self wrapElement:element inCondition:condition];
}

- (WOElement *)buildAttribute:(id<DOMElement>)_elem templateBuilder:(id)_b {
  /*
    label     // always keypath: labels.$value
    condition // always keypath: $value
    string    // regular assoc
    width     // regular assoc
    enabled   // wrap in WOConditional, enabled=>condition, always keypath
    is-sub    // BOOL, generates 'subAttributeCell'/'subValueCell' bindings
    shows-deleted-object // BOOL, generates 'valueFontColor' binding
    
    <attribute label="FileManager" string="fileManager" />
    
    TestInfoA: SkyAttribute { // dynamic element
      label  = "TestInfoA";
      string = fileManager;
      doTR   = YES;
    }
  */
  id<NSObject,DOMNamedNodeMap> attrs;
  id<NSObject,DOMAttr> attr;
  NSMutableDictionary *assocs;
  WOAssociation *condition;
  NSArray   *children;
  WOElement *element;
  NSString  *s;
  
  assocs = [[NSMutableDictionary alloc] initWithCapacity:8];
  attrs  = [_elem attributes];
  
  /* setup associations */
  
  [assocs setObject:yesAssoc forKey:@"doTR"];
  
  if ([[_elem attribute:@"is-sub" namespaceURI:@"*"] boolValue]) {
    static WOAssociation *keyColor = nil, *valueColor = nil;
    if (keyColor == nil) {
      keyColor = [[WOAssociation associationWithValue:
                                   @"subAttributeCell"] retain];
    }
    if (valueColor == nil) {
      valueColor = [[WOAssociation associationWithValue:
                                     @"subValueCell"] retain];
    }
    
    [assocs setObject:keyColor   forKey:@"keyColor"];
    [assocs setObject:valueColor forKey:@"valueColor"];
  }
  if ([[_elem attribute:@"shows-deleted-object" namespaceURI:@"*"] boolValue]){
    static WOAssociation *color = nil;
    if (color == nil) {
      color = [[WOAssociation associationWithValue:
                                @"colors_deleted_object"] retain];
    }
    [assocs setObject:color forKey:@"valueFontColor"];
  }
  
  if ((s = [_elem attribute:@"label" namespaceURI:@"*"])) {
    s = [@"labels." stringByAppendingString:s];
    [assocs setObject:[WOAssociation associationWithKeyPath:s]
	    forKey:@"label"];
  }
  if ((attr = [attrs namedItem:@"string" namespaceURI:@"*"]))
    [assocs setObject:[_b associationForAttribute:attr] forKey:@"string"];
  if ((attr = [attrs namedItem:@"width" namespaceURI:@"*"]))
    [assocs setObject:[_b associationForAttribute:attr] forKey:@"width"];

  
  condition = ((s = [_elem attribute:@"enabled" namespaceURI:@"*"]))
    ? [WOAssociation associationWithKeyPath:s] : nil;
  
  /* create element */
  
  children = [_elem hasChildNodes]
    ? [_b buildNodes:[_elem childNodes] templateBuilder:_b]
    : nil;
  
  element = [[[self attributeClass] alloc] initWithName:nil
					   associations:assocs
					   contentElements:children];
  [assocs release];
  return [self wrapElement:element inCondition:condition];
}
- (WOElement *)buildAttributes:(id<DOMElement>)_elem templateBuilder:(id)_b {
  /*
    <attributes sub-table="1">
      <attribute label="FileManager" string="fileManager" />
      <attribute label="Test Info"   const:string="blub" />
    </attributes>
    
    TestInfoA: SkyAttribute {
      label  = "TestInfoA";
      string = fileManager;
    }
  */
  NSArray   *children;
  WOElement *result;
  
  children = [_elem hasChildNodes]
    ? [_b buildNodes:[_elem childNodes] templateBuilder:_b]
    : nil;
  
  if ([[_elem attribute:@"sub-table" namespaceURI:@"*"] boolValue]) {
    NSMutableArray *ma;
    
    ma = [[NSMutableArray alloc] initWithCapacity:([children count] + 3)];
    
    /* Note: this definition was taken from LSWAppointmentViewer.wod */
    // TODO: replace table-values with CSS
    [ma addObject:
          @"<table width=\"100%\" bgcolor=\"#FAE8B8\" border=\"0\" "
          @"cellpadding=\"4\" cellspacing=\"0\">"];
    [ma addObjectsFromArray:children];
    [ma addObject:@"</table>"];
    
    result = [self elementForElementsAndStrings:ma];
    [ma release]; ma = nil;
  }
  else
    result = [self elementForElementsAndStrings:children];
  return result;
}

- (void)addButton:(id<DOMElement>)_button withName:(NSString *)_name
  toRowAssociations:(NSMutableDictionary *)_assocs templateBuilder:(id)_b
{
  /*
    action  => on$_name      // always keypath: $value
    label   => $_name        // always keypath: labels.$value
    target  => target$_name  // regular assoc
    url     => url$_name     // regular assoc
    enabled => has$_name     // regular assoc
  */
  id<NSObject,DOMNamedNodeMap> attrs;
  id<NSObject,DOMAttr> attr;
  NSString *s;
  
  attrs = [_button attributes];
  
  if ((s = [_button attribute:@"action" namespaceURI:@"*"])) {
    [_assocs setObject:[WOAssociation associationWithKeyPath:s]
	     forKey:[@"on" stringByAppendingString:_name]];
  }
  if ((s = [_button attribute:@"label" namespaceURI:@"*"])) {
    s = [@"labels." stringByAppendingString:s];
    [_assocs setObject:[WOAssociation associationWithKeyPath:s]
	     forKey:_name];
  }
  
  if ((attr = [attrs namedItem:@"target" namespaceURI:@"*"])) {
    [_assocs setObject:[_b associationForAttribute:attr] 
	     forKey:[@"target" stringByAppendingString:_name]];
  }
  if ((attr = [attrs namedItem:@"url" namespaceURI:@"*"])) {
    [_assocs setObject:[_b associationForAttribute:attr] 
	     forKey:[@"url" stringByAppendingString:_name]];
  }
  if ((attr = [attrs namedItem:@"enabled" namespaceURI:@"*"])) {
    [_assocs setObject:[_b associationForAttribute:attr] 
	     forKey:[@"has" stringByAppendingString:_name]];
  }
  
  // TODO: complete
}

- (WOElement *)buildButtonRow:(id<DOMElement>)_element templateBuilder:(id)_b {
  /*
    <buttons>
      <button name="pubpreview" target="pubPreviewTarget" url="tabPreviewURL"
              label="preview"/>
      <button name="mail" action="mailObject"/>
    </buttons>
    
    Builds:
    Buttons: SkyButtonRow { // dynamic element
      ordering  = ( pubpreview, mail );
      onMail    = mailObject;
      mail      = "mail";
      targetPubPreview = "pubPreviewTarget";
      urlPubPreview    = tabPreviewURL;
      pubpreview       = "preview";
    }
  */
  NSMutableDictionary      *assocs;
  id<NSObject,DOMNodeList> children;
  NSMutableArray           *ordering;
  WOElement *element;
  unsigned  i, count;
  
  children = [_element childNodes];
  if ((count = [children length]) == 0) /* no buttons */
    return nil;
  
  assocs   = [[NSMutableDictionary alloc] initWithCapacity:16];
  ordering = [[NSMutableArray alloc] initWithCapacity:(count + 1)];
  
  /* walk over the buttons */
  
  for (i = 0; i < count; i++) {
    id<DOMElement> button;
    NSString *name;
    
    button = [children objectAtIndex:i];
    if (debugOn) [self debugWithFormat:@"check button: %@", button];
    
    // TODO: print a warning for unexpected elements?
    if ([button nodeType] != DOM_ELEMENT_NODE)
      continue;
    if (![[button tagName] isEqualToString:@"button"])
      continue;
    
    name = [button attribute:@"name" namespaceURI:@"*"];
    if ([name length] == 0)
      name = [NSString stringWithFormat:@"%d", i];
    
    [ordering addObject:name];
    [self addButton:button withName:name toRowAssociations:assocs
	  templateBuilder:_b];
  }
  
  /* finish associations */
  
  [assocs setObject:[WOAssociation associationWithValue:ordering] 
	  forKey:@"ordering"];
  [ordering release];

  if (debugOn) [self debugWithFormat:@"  assocs: %@", assocs];
  
  element = [[[self buttonRowClass] alloc] initWithName:@"buttons"
					   associations:assocs
					   contentElements:nil];
  [assocs release];
  return element;
}

- (WOElement *)buildPageHead:(id<DOMElement>)_element templateBuilder:(id)_b {
  /*
    <OGo:page-head title="IPK Publisher Project">
      <OGo:buttons>...</OGo:buttons>
      <OGo:attributes>
        <attribute label="FileManager" string="fileManager" />
        <attribute label="Test Info"   const:string="blub" />
         ..
      </OGo:attributes>
    </OGo:page-head>
    
    Builds:
    <table width="100%" border="0" cellpadding="4" cellspacing="0">
      <#ViewerTitle><#Buttons /></#ViewerTitle>
      <tr><#TestInfoA /></tr>
      <tr><#TestInfoB /></tr>
    </table>
    
    ViewerTitle: LSWViewerTitle { // dynamic element
      title = "IPK Publisher Project";
    }
    TestInfoA: SkyAttribute {
      label  = "TestInfoA";
      string = fileManager;
    }
  */
  NSMutableDictionary *assocs;
  NSMutableArray *rootElements;
  WOElement      *element;
  NSArray        *children;
  id tmp;
  
  rootElements = [[NSMutableArray alloc] initWithCapacity:8];
  
  /* build associations */
  
  if ((assocs = [_b associationsForAttributes:[_element attributes]]) == nil)
    assocs = [NSMutableDictionary dictionaryWithCapacity:2];
  
  /* fill in missing default associations */
  
  if ([assocs objectForKey:@"title"] == nil) {
    id tmp = [WOAssociation associationWithKeyPath:@"labels.$name"];
    [assocs setObject:tmp forKey:@"title"];
  }
  
  /* start table */
  
  // TODO: use CSS
  [rootElements addObject:
		  @"<table width=\"100%\" border=\"0\" "
		  @"cellpadding=\"4\" cellspacing=\"0\">"];
  
  /* viewer title */
  
  children = nil;
  if ((tmp = [self lookupUniqueTag:@"buttons" in:_element])) {
    if (debugOn) [self debugWithFormat:@"got head buttons: %@", tmp];
    element  = [self buildButtonRow:tmp templateBuilder:_b];
    children = [[NSArray alloc] initWithObjects:&element count:1];
  }
  else if (debugOn)
    [self logWithFormat:@"got no buttons for viewer title in: %@", _element];
  
  element = [[[self viewerTitleClass] alloc] initWithName:@"title"
					     associations:assocs
					     contentElements:children];
  [children release];
  [rootElements addObject:element];
  [element release];
  
  /* attributes */
  
  if ((tmp = [self lookupUniqueTag:@"attributes" in:_element])) {
    tmp = [self buildAttributes:tmp templateBuilder:_b];
    [rootElements addObject:tmp];
  }
  
  /* end table */
  
  [rootElements addObject:@"</table>"];
  
  /* construct top level element (a compound) */
  
  element = [self elementForElementsAndStrings:rootElements];
  [rootElements release];
  return element;
}

- (WOElement *)buildPageBody:(id<DOMElement>)_element templateBuilder:(id)_b {
  /*
    <OGo:page-body>
      ...
    </OGo:page-body>
  */
  NSMutableArray *ma;
  NSArray   *children;
  WOElement *element;
  
  children = [_element hasChildNodes]
    ? [_b buildNodes:[_element childNodes] templateBuilder:_b]
    : nil;
  
  ma = [[NSMutableArray alloc] initWithCapacity:[children count] + 3];
  [ma addObject:@"<p>"]; // TODO: add CSS class
  
  if ((element = [self wrapElements:children inElement:[self fontClass]])) {
    [ma addObject:element];
    [element release]; element = nil;
  }
  
  [ma addObject:@"</p>"];
  element = [self elementForElementsAndStrings:ma];
  [ma release];
  return element;
}

- (WOElement *)buildPageWarn:(id<DOMElement>)_element templateBuilder:(id)_b {
  /*
    okAction      - always keypath
    warningPhrase - regular assoc
    
    <OGo:page>
      <OGo:warn okAction="warningOkAction" var:phrase="warningPhrase" />
      ...
    </OGo:page>

    Builds:
      Warning: LSWWarningPanel {
        onOk   = warningOkAction;
        phrase = warningPhrase;
      }
  */
  NSMutableDictionary  *assocs;
  id<NSObject,DOMAttr> attr;
  NSString *cid, *s;
  
  if (debugOn) [self debugWithFormat:@"  build OGo page-warn: %@", _element];
  
  /* unique component ID */
  
  cid = [_b uniqueIDForNode:_element];
  if (debugOn) [self debugWithFormat:@"  CID: %@", cid];

  /* setup associations */
  
  assocs = [[NSMutableDictionary alloc] initWithCapacity:4];
  
  if ((s = [_element attribute:@"okAction" namespaceURI:@"*"]) != nil) {
    [assocs setObject:[WOAssociation associationWithKeyPath:s] 
            forKey:@"onOk"];
  }
  
  if ((attr = [[_element attributes] namedItem:@"phrase" namespaceURI:@"*"]))
    [assocs setObject:[_b associationForAttribute:attr] forKey:@"phrase"];
  
  /* create component */
  
  [_b registerSubComponentWithId:cid 
      componentName:[self warningComponentName] bindings:assocs];
  [assocs release]; assocs = nil;
  
  return [[ChildRefClass alloc]
           initWithName:cid associations:nil contentElements:nil];
}

- (WOElement *)buildPage:(id<DOMElement>)_element templateBuilder:(id)_b {
  /*
    This builds the common content page wrapper:
       <#Frame><#Window>...</#Window></#Frame>
    
    where "Frame" is LSWSkyrixFrame (component) and "Window" is 
    OGoWindowFrame (element). Window has the parameters "title" and "onClose".
    
    It is extended to build some specific subelements like:
       <OGo:head>
         <OGo:buttons>
           xyz
         </OGo:buttons>
         <OGo:field name="a" var:value="xx" />
         <OGo:field name="b" var:value="xx" />
       </OGo:head>

    TODO: add support for SkyCalendarScript (should be first element in frame)
      Calendar: SkyCalendarScript {}
    
    TODO: add support for generating "focus" (JavaScript) scripts, like:
      if (document.personEditor) {
        if (document.personEditor.elements[0])
          document.personEditor.elements[0].focus();
      }
    => this is now supported by OGoWindowFrame!
  */
  NSMutableDictionary *assocs;
  NSArray   *children, *frameChildren;
  NSString  *cid;
  WOElement *window;
  id tmp;
  
  if (debugOn) [self debugWithFormat:@"  build OGo page: %@", _element];
  
  /* unique component ID */
  
  cid = [_b uniqueIDForNode:_element];
  if (debugOn) [self debugWithFormat:@"  CID: %@", cid];
  
  /* construct child elements (rework for OGo:body?) */
  
  if ((tmp = [self lookupUniqueTag:@"body" in:_element]) != nil) {
    /* mode a: explicit hierarchy with 'head' and 'body' subelements */
    WOElement *head, *body, *warn;
    
    body = [self buildPageBody:tmp templateBuilder:_b];
    
    if ((tmp = [self lookupUniqueTag:@"head" in:_element]) == nil) {
      [self logWithFormat:@"WARNING: missing page head in: %@", _element];
      head = [self elementForRawString:@"<!-- missing page head -->"];
    }
    else
      head = [self buildPageHead:tmp templateBuilder:_b];
    
    warn = ((tmp = [self lookupUniqueTag:@"warn" in:_element]) != nil)
      ? [self buildPageWarn:tmp templateBuilder:_b] : nil;

    if (warn != nil) {
      /* wrap body / wrap warn using 'isInWarningMode' binding */
      static WOAssociation *warnAssoc = nil; // THREAD
      
      if (warnAssoc == nil) {
	warnAssoc =
	  [[WOAssociation associationWithKeyPath:@"isInWarningMode"] copy];
      }
      
      head = [self wrapElement:head inCondition:warnAssoc negate:YES];
      body = [self wrapElement:body inCondition:warnAssoc negate:YES];
      warn = [self wrapElement:warn inCondition:warnAssoc negate:NO];
    }
    
    children = [NSArray arrayWithObjects:head, body, warn, nil];
    [head release]; head = nil;
    [body release]; body = nil;
    [warn release]; warn = nil;
  }
  else {
    /* mode b: arbitary subelements */
    // TODO: check whether returned children array are retained!
    children = [_element hasChildNodes]
      ? [_b buildNodes:[_element childNodes] templateBuilder:_b]
      : nil;
  }
  
  /* build associations */
  
  if ((assocs = [_b associationsForAttributes:[_element attributes]]) == nil)
    assocs = [NSMutableDictionary dictionaryWithCapacity:2];
  
  /* fill in missing default associations */
  
  if ([assocs objectForKey:@"onClose"] == nil) {
    tmp = [WOAssociation associationWithKeyPath:
                           @"existingSession.navigation.leavePage"];
    [assocs setObject:tmp forKey:@"onClose"];
  }
  if ([assocs objectForKey:@"title"] == nil) {
    tmp = [WOAssociation associationWithKeyPath:@"labels.$name"];
    [assocs setObject:tmp forKey:@"title"];
  }
  
  /* build window */
  
  if (debugOn) [self debugWithFormat:@"  window assocs: %@", assocs];
  
  window = [[[self windowFrameClass] alloc] initWithName:@"win"
                                            associations:assocs
                                            contentElements:children];
  frameChildren = [NSArray arrayWithObjects:&window count:1];
  [window release]; window = nil;
  
  /* create component */
  
  if (debugOn) [self debugWithFormat:@"frame children: %@", frameChildren];
  
  [_b registerSubComponentWithId:cid 
      componentName:[self frameComponentName] bindings:nil];
  return [[ChildRefClass alloc]
           initWithName:cid associations:nil contentElements:frameChildren];
}

- (WOElement *)buildSpan:(id<DOMElement>)_element templateBuilder:(id)_b {
  NSMutableArray *ma;
  NSArray   *children;
  WOElement *element;
  
  children = [_element hasChildNodes]
    ? [_b buildNodes:[_element childNodes] templateBuilder:_b]
    : nil;
  
  ma = [[NSMutableArray alloc] initWithCapacity:[children count] + 3];
  [ma addObject:@"<span>"]; // TODO: add CSS class
  if (children) [ma addObjectsFromArray:children];
  [ma addObject:@"</span>"];
  element = [self elementForElementsAndStrings:ma];
  [ma release];
  return element;
}
- (WOElement *)buildContainer:(id<DOMElement>)_element templateBuilder:(id)_b {
  // this is a 'noop' tag, which only generates its children, useful for
  // as a roottag for templates
  NSArray *children;
  
  children = [_element hasChildNodes]
    ? [_b buildNodes:[_element childNodes] templateBuilder:_b]
    : nil;
  
  return [self elementForElementsAndStrings:children];
}

- (WOElement *)buildLabel:(id<DOMElement>)_elem templateBuilder:(id)_b {
  /* 
     key  > value // always keypath: labels.$key
     
     <label key="notettitle"/>
  */
  NSMutableDictionary *associations;
  WOElement *element;
  NSString  *kp;
  
  kp = [_elem attribute:@"key" namespaceURI:@"*"];
  if ([kp length] == 0) {
    [self logWithFormat:@"WARNING: missing 'key' attribute in tag: %@", _elem];
    kp = @"missing label key";
  }
  
  kp = [@"labels." stringByAppendingString:kp];
  
  associations = [[NSMutableDictionary alloc] initWithCapacity:2];
  [associations setObject:[WOAssociation associationWithKeyPath:kp]
		forKey:@"value"];
  
  element = [[DynStrClass alloc] initWithName:nil associations:associations
				 contentElements:nil];
  [associations release];
  return element;
}

- (WOElement *)buildFont:(id<DOMElement>)_element templateBuilder:(id)_b {
  NSArray *children;
  
  children = [_element hasChildNodes]
    ? [_b buildNodes:[_element childNodes] templateBuilder:_b]
    : nil;
  
  return [self wrapElements:children inElement:[self fontClass]];
}
- (WOElement *)buildEditFont:(id<DOMElement>)_element templateBuilder:(id)_b {
  NSArray *children;
  
  children = [_element hasChildNodes]
    ? [_b buildNodes:[_element childNodes] templateBuilder:_b]
    : nil;
  
  return [self wrapElements:children inElement:[self editFontClass]];
}

- (WOElement *)buildCalendarPopUp:(id<DOMElement>)_el templateBuilder:(id)_b {
  /*
    name     // always constant
    formName // always constant [default: 'editform']
    
    <calendarpopup name="startDate" formName="editform" />
    
    CalendarPopupStartDateLink: SkyCalendarPopUp { // WOComponent!
      elementName = "startDate";
      formName    = "editform";
    }
  */
  NSMutableDictionary *assocs;
  NSString *s;
  NSString *cid;
  
  cid = [_b uniqueIDForNode:_el];
  if (debugOn) [self debugWithFormat:@"  calpopup CID: %@", cid];
  
  /* setup associations */
  
  assocs = [[NSMutableDictionary alloc] initWithCapacity:4];
  
  if ((s = [_el attribute:@"name" namespaceURI:@"*"]) != nil) {
    [assocs setObject:[WOAssociation associationWithValue:s] 
            forKey:@"elementName"];
  }
  else
    [self logWithFormat:@"ERROR: missing 'name' attribute on tag: %@", _el];
  
  if ((s = [_el attribute:@"formName" namespaceURI:@"*"]) == nil)
    s = @"editform";
  [assocs setObject:[WOAssociation associationWithValue:s] 
          forKey:@"formName"];
  
  /* build component */
  
  [_b registerSubComponentWithId:cid
      componentName:[self calPopUpComponentName] bindings:assocs];
  [assocs release]; assocs = nil;
  
  return [[ChildRefClass alloc] 
           initWithName:cid associations:nil contentElements:nil];
}

- (WOElement *)buildCollapsible:(id<DOMElement>)_el templateBuilder:(id)_b {
  // TODO: register in dispatcher!
  /*
    OGo:collapsible
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
  // TODO: add support for SkyCollapsibleContent (WOComponent!)
  //  'visibility', 'visibilityDefault', 'title' (label), 'submitActionName'
  NSMutableDictionary *assocs;
  NSArray   *children;
  NSString  *cid;
  id tmp;
  
  if (debugOn) [self debugWithFormat:@"  build OGo collapsible: %@", _el];

  /* unique component ID */
  
  cid = [_b uniqueIDForNode:_el];
  if (debugOn) [self debugWithFormat:@"  CID: %@", cid];
  
  /* check children */

  if ((tmp = [self lookupUniqueTag:@"content" in:_el]) != nil) {
    /* mode a: explicit hierarchy with 'title' and 'content' subelements */
    WOElement *title, *content;
    
    // content = [self buildCollapsibleContent:tmp templateBuilder:_b];

    if ((tmp = [self lookupUniqueTag:@"title" in:_el]) == nil) {
      [self logWithFormat:@"WARNING: missing collap. title in: %@", _el];
      title = [self elementForRawString:@"<!-- missing collapsible head -->"];
    }
    else
      ;//title = [self buildCollapsibleTitle:tmp templateBuilder:_b];

    children = [NSArray arrayWithObjects:title, content, nil];
    [title   release]; title   = nil;
    [content release]; content = nil;
  }
  else {
    /* mode b: arbitary subelements */
    // TODO: check whether returned children array are retained!
    children = [_el hasChildNodes]
      ? [_b buildNodes:[_el childNodes] templateBuilder:_b]
      : nil;
  }
  
  /* build associations */
  
  if ((assocs = [_b associationsForAttributes:[_el attributes]]) == nil)
    assocs = [NSMutableDictionary dictionaryWithCapacity:2];
  
  
#warning COMPLETE ME
  
  /* create component */
  
  if (debugOn) [self debugWithFormat:@"collapsible children: %@", children];
  
  [_b registerSubComponentWithId:cid 
      componentName:[self collapsibleComponentName] bindings:nil];
  return [[ChildRefClass alloc]
           initWithName:cid associations:assocs contentElements:children];
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
  case 't': /* starting with 't' */
    if (tl == 7 && [tagName isEqualToString:@"td-attr"])
      return NSClassFromString(@"SkyAttributeCell");
    if (tl == 8 && [tagName isEqualToString:@"td-value"])
      return NSClassFromString(@"SkyValueCell");
    break;
  }
  return [super classForElement:_element];
}

/* main build dispatcher */

- (WOElement *)buildElement:(id<DOMElement>)_element templateBuilder:(id)_b {
  NSString  *tagName;
  unsigned  tl;
  unichar   c1;
  WOElement *element;

  if (![[_element namespaceURI] isEqualToString:XMLNS_OGoWOx])
    return [self->nextBuilder buildElement:_element templateBuilder:_b];
  
  tagName = [_element tagName];
  if ((tl = [tagName length]) < 2)
    return nil;
  c1 = [tagName characterAtIndex:0];
  
  if (debugOn) [self debugWithFormat:@"try to build OGo tag: %@", tagName];
  
  element = nil;
  switch (c1) {
  case 'a':
    if (tl == 10 && [tagName isEqualToString:@"attributes"])
      element = [self buildAttributes:_element templateBuilder:_b];
    if (tl == 9 && [tagName isEqualToString:@"attribute"])
      element = [self buildAttribute:_element templateBuilder:_b];
    break;

  case 'b':
    if (tl == 7 && [tagName isEqualToString:@"buttons"])
      element = [self buildButtonRow:_element templateBuilder:_b];
    break;

  case 'c':
    if (tl == 13 && [tagName isEqualToString:@"calendarpopup"])
      element = [self buildCalendarPopUp:_element templateBuilder:_b];
    if (tl == 9 && [tagName isEqualToString:@"container"])
      element = [self buildContainer:_element templateBuilder:_b];
    break;

  case 'e':
    if (tl == 8 && [tagName isEqualToString:@"editfont"])
      element = [self buildEditFont:_element templateBuilder:_b];
    break;

  case 'f':
    if (tl == 4 && [tagName isEqualToString:@"font"])
      element = [self buildFont:_element templateBuilder:_b];
    break;

  case 'l':
    if (tl == 5 && [tagName isEqualToString:@"label"])
      element = [self buildLabel:_element templateBuilder:_b];
    break;
    
  case 'o':
    if (tl == 11 && [tagName isEqualToString:@"objectvalue"])
      element = [self buildObjectValue:_element templateBuilder:_b];
    break;
    
  case 'p':
    if (tl == 4 && [tagName isEqualToString:@"page"])
      element = [self buildPage:_element templateBuilder:_b];
    if (tl == 9 && [tagName isEqualToString:@"page-head"])
      element = [self buildPageHead:_element templateBuilder:_b];
    if (tl == 9 && [tagName isEqualToString:@"page-body"])
      element = [self buildPageBody:_element templateBuilder:_b];
    break;
    
  case 's':
    if (tl == 4 && [tagName isEqualToString:@"span"])
      element = [self buildSpan:_element templateBuilder:_b];
    break;

  case 't':
    if (tl == 3 && [tagName isEqualToString:@"tab"])
      element = [self buildTab:_element templateBuilder:_b];
    if (tl == 7 && [tagName isEqualToString:@"tabitem"])
      element = [self buildTabItem:_element templateBuilder:_b];
    
    if (tl == 7 && [tagName isEqualToString:@"td-attr"])
      return [super buildElement:_element templateBuilder:_b];
    if (tl == 8 && [tagName isEqualToString:@"td-value"])
      return [super buildElement:_element templateBuilder:_b];
    
    break;
  }
  
  if (element == nil) {
    if (debugOn)
      [self logWithFormat:@"WARNING: could not build OGo tag: '%@'", tagName];
    
    /* we need to call super, so that the build queue processing continues */
    return [super buildElement:_element templateBuilder:_b];
  }
  
  return element;
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

@end /* OGoElemBuilder */
