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

#include <NGObjWeb/WODynamicElement.h>

/*
  This component renders a Window frame.

  Stylesheet-Classes:
    wintitle
    wincontent
    winscroll
  
  Usage:
    MyWindow: OGoWindowFrame {
      title = "PersonViewer";
    }

  Associations:
    title        - the title of the window
    onClose      - action to trigger if the close button is pressed
    onTest       - action to trigger if the test button is pressed (OGoForms)
    hasTest      - whether to show the test button
    isFormWindow - whether the window should generate a <form/>
    formAction   - action to trigger on form submits
    focusField   - name of field to focus/select using JavaScript
    focusForm    - name of form where the focus field is in
  
  It can also generate a <form/> tag which get's the name 'windowform'.
*/

@class WOAssociation;

@interface OGoWindowFrame : WODynamicElement
{
@protected
  WOAssociation *title;
  WOAssociation *onClose;
  WOAssociation *onTest;
  WOAssociation *hasTest;
  WOElement     *template;
  
  /* form support */
  WOAssociation *isFormWindow; /* BOOL */
  WOAssociation *formAction;
  WOAssociation *focusField;
  WOAssociation *focusForm;
}

@end

@interface LSWWindowFrame : OGoWindowFrame // DEPRECATED NAME
@end

// TODO: onClose should be replaced with a direct-action?

#include "common.h"
#include <OGoFoundation/WOComponent+config.h>
#include <WEExtensions/WEClientCapabilities.h>

@interface WOContext(PrivateAPI)
- (WODynamicElement *)activeFormElement;
@end

#define OGoWindowFrame_CtxKey @"LSWWindowFrame_CtxKey"

@interface WOContext(WindowNesting)
- (unsigned)increaseWindowNesting;
- (void)decreaseWindowNesting;
@end

@implementation OGoWindowFrame

static NSString *OGoWindowFrameFocusScriptTemplate = nil;
static NSNumber *num0 = nil, *num1 = nil;

+ (int)version {
  return 4;
}
+ (void)initialize {
  // TODO: check superclass version
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  if (num0 == nil) num0 = [[NSNumber numberWithUnsignedInt:0] retain];
  if (num1 == nil) num1 = [[NSNumber numberWithUnsignedInt:1] retain];

  if (OGoWindowFrameFocusScriptTemplate == nil) {
    OGoWindowFrameFocusScriptTemplate = 
      [[ud stringForKey:@"OGoWindowFrameFocusScriptTemplate"] copy];
  }
}

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_subs
{
  if ((self = [super initWithName:_name associations:_config template:_subs])) {
    self->title        = OWGetProperty(_config, @"title");
    self->onClose      = OWGetProperty(_config, @"onClose");
    self->hasTest      = OWGetProperty(_config, @"hasTest");
    self->onTest       = OWGetProperty(_config, @"onTest");
    self->isFormWindow = OWGetProperty(_config, @"isFormWindow");
    self->formAction   = OWGetProperty(_config, @"formAction");
    self->focusForm    = OWGetProperty(_config, @"focusForm");
    self->focusField   = OWGetProperty(_config, @"focusField");
    self->template = [_subs retain];
  }
  return self;
}

- (void)dealloc {
  [self->focusForm    release];
  [self->focusField   release];
  [self->hasTest      release];
  [self->onTest       release];
  [self->isFormWindow release];
  [self->formAction   release];
  [self->template     release];
  [self->onClose      release];
  [self->title        release];
  [super dealloc];
}

/* handling requests */

- (void)takeValuesFromRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  if ([self->isFormWindow boolValueInComponent:[_ctx component]]) {
    [_ctx setInForm:YES];
    
    if ([[_ctx elementID] isEqualToString:[_ctx senderID]])
      [self->template takeValuesFromRequest:_rq inContext:_ctx];
    
    [_ctx setInForm:NO];
    return;
  }
  
  [self->template takeValuesFromRequest:_rq inContext:_ctx];
}

- (id)invokeActionForRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  id       result = nil;
  NSString *cid;
  
  cid = [_ctx currentElementID];

  if ([cid isEqualToString:@"__winclose"])
    return [self->onClose valueInComponent:[_ctx component]];
  if ([cid isEqualToString:@"__wintest"])
    return [self->onTest valueInComponent:[_ctx component]];
  
  if ([self->isFormWindow boolValueInComponent:[_ctx component]]) {
    [_ctx setInForm:YES];
    
    if (cid == nil) {
      if ([_ctx activeFormElement]) {
        result = [[_ctx activeFormElement]
                        invokeActionForRequest:_rq inContext:_ctx];
      }
      else if (self->formAction)
        result = [self->formAction valueInComponent:[_ctx component]];
    }
    else
      result = [self->template invokeActionForRequest:_rq inContext:_ctx];
    
    [_ctx setInForm:NO];
    return result;
  }

  return [self->template invokeActionForRequest:_rq inContext:_ctx];
}

/* generating response */

- (void)_appendTextToResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  WOComponent *sComponent;

  sComponent = [_ctx component];
  
  /* window title */
  [_response appendContentString:@"<center><h3>"];
  [_response appendContentHTMLString:
               [self->title stringValueInComponent:sComponent]];
  [_response appendContentString:@"</h3></center>"];
  [_response appendContentString:@"<hr />"];
  
  /* window content */
  [self->template appendToResponse:_response inContext:_ctx];
  
  /* window footer */
  [_response appendContentString:@"<hr />"];
}

- (NSString *)uriForImage:(NSString *)_name inContext:(WOContext *)_ctx {
  WOResourceManager *rm;
  NSString *uri;

  rm = [[_ctx application] resourceManager];
  uri = [rm urlForResourceNamed:_name inFramework:nil
	    languages:[[_ctx session] languages]
	    request:[_ctx request]];
  if ([uri length] == 0) {
    uri = nil;
    [self logWithFormat:@"ERROR: did not find image resource: '%@'", _name];
  }
  return uri;
}

- (void)_appendButton:(NSString *)_title elementID:(NSString *)_eid
  imageName:(NSString *)_imgname
  toResponse:(WOResponse *)_r inContext:(WOContext *)_ctx 
  isInTextMode:(BOOL)textClose
{
  [_r appendContentString:@"<a href=\""];
  [_ctx appendElementIDComponent:_eid];
  [_r appendContentHTMLAttributeValue:[_ctx componentActionURL]];
  [_ctx deleteLastElementIDComponent];
  [_r appendContentString:@"\">"];
  
  if (!textClose) {
    NSString *uri;

    if ((uri = [self uriForImage:_imgname inContext:_ctx]) == nil) {
      textClose = YES;
    }
    else {
      [_r appendContentString:@"<img border=\"0\" alt=\""];
      [_r appendContentHTMLAttributeValue:_title]; // eg: X or T
      [_r appendContentString:@"\" src=\""];
      [_r appendContentHTMLAttributeValue:uri];
      [_r appendContentString:@"\" />"];
    }
  }
      
  if (textClose) { // TODO: use stylesheet!
    [_r appendContentString:@"<font color=\"white\"><b>"];
    [_r appendContentHTMLString:_title];
    [_r appendContentString:@"</b></font>"];
  }
  
  [_r appendContentString:@"</a>"];
}

- (void)_appendTitleToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
  /* window title */
  NSString *t;

  t    = [self->title stringValueInComponent:[_ctx component]];
  if ([t length] == 0) t = @"<no title>";
  
  [_r appendContentString:@"<tr>"];
  
  if ((self->onClose != nil) || (self->onTest != nil)) {
    [_r appendContentString:
	  @"<td class=\"wintitle\">"
	  @"<table cellpadding=\"0\" cellspacing=\"0\" width=\"100%\">"
	  @"<tr><td width=\"5\"></td>"];
  }
  
  [_r appendContentString:@"<td class=\"wintitle\">"];
  [_r appendContentString:t];
  [_r appendContentString:@"</td>"];

  if ((self->onClose != nil) || (self->onTest != nil)) {
    WOComponent *c = [_ctx component];
    BOOL textClose;
    
    textClose = [[[_ctx request] clientCapabilities] isTextModeBrowser];
    
    [_r appendContentString:
	  @"<td width=\"36\" align=\"right\" valign=\"center\">"];
    
    if (self->onTest != nil && [self->hasTest boolValueInComponent:c]) {
      /* the "test" button is used in forms (to exit the test mode)  */
      [self _appendButton:@"T" elementID:@"__wintest" 
	    imageName:@"testwindow.gif"
	    toResponse:_r inContext:_ctx isInTextMode:textClose];
    }
    if (self->onClose) {
      [self _appendButton:@"X" elementID:@"__winclose" 
	    imageName:@"closewindow.gif"
	    toResponse:_r inContext:_ctx isInTextMode:textClose];
    }
    
    [_r appendContentString:@"</td></tr></table>"];
    [_r appendContentString:@"</td>"];
  }
  
  [_r appendContentString:@"</tr>"];
}

- (void)_appendContentToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
  BOOL doForm;
      
  doForm = [self->isFormWindow boolValueInComponent:[_ctx component]];
      
  if (doForm) {
    [_ctx setInForm:YES];
    [_r appendContentString:
	  @"<form name=\"windowform\" method=\"post\" action=\""];
    [_r appendContentString:[_ctx componentActionURL]];
    [_r appendContentString:@"\">"];
  }
  
  /* add window content */
  [self->template appendToResponse:_r inContext:_ctx];
      
  if (doForm) {
    [_r appendContentString:@"</form>"];
    [_ctx setInForm:NO];
  }
}

- (void)_appendFocusScriptToResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  WEClientCapabilities *ccaps;
  NSDictionary *bindings;
  NSString     *fieldName, *formName, *s;
  
  if (self->focusField == nil)
    return;
  
  // TODO: should we check the session JavaScript marker instead?
  ccaps = [[_ctx request] clientCapabilities];
  if (![ccaps isJavaScriptBrowser])
    return;
  
  fieldName = [self->focusField stringValueInComponent:[_ctx component]];
  if ([fieldName length] == 0)
    return;
  
  formName = [self->focusForm stringValueInComponent:[_ctx component]];
  if ([formName length] == 0) {
    [self logWithFormat:
	    @"WARNING: missing form name value for focus script! (field=%@)",
	    fieldName];
    return;
  }

  bindings = [[NSDictionary alloc] initWithObjectsAndKeys:
				     fieldName, @"fieldName",
				     formName,  @"formName",
				   nil];
  s = [OGoWindowFrameFocusScriptTemplate 
	stringByReplacingVariablesWithBindings:bindings];
  [bindings release]; bindings = nil;
  
  if (s) [_response appendContentString:s];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  WOComponent *c;
  id          cfg;
  BOOL        winScroller;
  unsigned    windowNesting;

  windowNesting = [_ctx increaseWindowNesting];
  
  if ([[_ctx request] isFromClientComponent]) {
    [self->template appendToResponse:_response inContext:_ctx];
  }
  else if ([[[_ctx session] valueForKey:@"isTextModeBrowser"] boolValue]) {
    [self _appendTextToResponse:_response inContext:_ctx];
  }
  else {
    winScroller = NO;
    
    c    = [_ctx component];
    cfg  = [c config]; /* config of current component */
    
    if (windowNesting > 1) {
      [_response appendContentString:
                   @"<table class=\"nestedwintable\" "
                   @"cellspacing=\"0\" cellpadding=\"5\""];
      [_response appendContentString:@" width='100%'>"];
    }
    else {
      [_response appendContentString:
                   @"<table id=\"skywintable\" class=\"wintable\" "
                   @"cellspacing=\"0\" cellpadding=\"5\""];
      if (winScroller)
        [_response appendContentString:@" height=\"78%\""];
      [_response appendContentString:@" width='100%'>"];
    }

    [self _appendTitleToResponse:_response inContext:_ctx];
      
    /* window content */
    [_response appendContentString:winScroller
	       ? @"<tr height=\"95%\">"
	       : @"<tr>"];
    [_response appendContentString:
		 @"<td id=\"skywinbodycell\" class=\"wincontent\">"];
      
    /* overflow-def */
    if (winScroller)
      [_response appendContentString:@"<p class=\"winscroll\">"];
      
    [self _appendContentToResponse:_response inContext:_ctx];
    
    /* height */
    if (winScroller)
      [_response appendContentString:@"</p>"];
      
    [_response appendContentString:@"</td></tr>"];
    
    [_response appendContentString:@"</table>"];

    if (windowNesting <= 1)
      [self _appendFocusScriptToResponse:_response inContext:_ctx];
  }
  
  [_ctx decreaseWindowNesting];
}

@end /* OGoWindowFrame */

@implementation LSWWindowFrame
@end /* LSWWindowFrame */

@implementation WOContext(WindowNesting)

- (unsigned)increaseWindowNesting {
  unsigned windowNesting;
  NSNumber *num;
  
  windowNesting = [[self objectForKey:OGoWindowFrame_CtxKey] unsignedIntValue];
  windowNesting++;
  switch (windowNesting) {
  case 0:  num = num0; break;
  case 1:  num = num1; break;
  default: num = [NSNumber numberWithUnsignedInt:windowNesting];
  }
  [self setObject:num forKey:OGoWindowFrame_CtxKey];
  return windowNesting;
}
- (void)decreaseWindowNesting {
  unsigned windowNesting;
  NSNumber *num;
  
  windowNesting = [[self objectForKey:OGoWindowFrame_CtxKey] unsignedIntValue];
  windowNesting--;
  switch (windowNesting) {
  case 0:  num = num0; break;
  case 1:  num = num1; break;
  default: num = [NSNumber numberWithUnsignedInt:windowNesting];
  }
  [self setObject:num forKey:OGoWindowFrame_CtxKey];
}

@end /* WOContext(WindowNesting) */
