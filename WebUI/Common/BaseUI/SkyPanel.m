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

#include <OGoFoundation/LSWContentPage.h>
#include <NGObjWeb/WODynamicElement.h>

/*
  TODO: document what this is and does!
  - eg used by SkyWarningPanel

   > title
   > string
   > filename
   > panelName
  <> isVisible
*/

@class NSString, WOAssociation;

@interface SkyPanel : LSWContentPage
{
 @protected
  BOOL     isVisible;
  NSString *string;
  NSString *filename;
  NSString *panelName;
  BOOL     doActionOnCancel; // don't use javaScript on cancel button
}
@end

#include <NGObjWeb/WEClientCapabilities.h>
#include "common.h"

/* SkyPanel */

static NSString *SkyPanel_IsScriptSet = @"IsPanelScriptSet";

@implementation SkyPanel

- (void)dealloc {
  RELEASE(self->string);
  RELEASE(self->filename);
  RELEASE(self->panelName);
  [super dealloc];
}

/* notifications */

- (void)syncAwake {
  NSArray *tmp;
  NSString *str;

  tmp  = [[[self context] elementID] componentsSeparatedByString:@"."];
  str  = [@"obj" stringByAppendingString:[tmp componentsJoinedByString:@"x"]];
  
  ASSIGN(self->panelName, str);
}

/* request handling */

- (void)takeValuesFromRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  [_ctx removeObjectForKey:SkyPanel_IsScriptSet];
  [super takeValuesFromRequest:_rq inContext:_ctx];
}
- (id)invokeActionForRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  [_ctx removeObjectForKey:SkyPanel_IsScriptSet];
  return [super invokeActionForRequest:_rq inContext:_ctx];
}

/* accessors */

- (void)setString:(NSString *)_string {
  ASSIGN(self->string, _string);
}
- (NSString *)string {
  return self->string;
}

- (void)setFilename:(NSString *)_filename {
  ASSIGN(self->filename, _filename);
}
- (NSString *)filename {
  return self->filename;
}

- (void)setIsVisible:(BOOL)_flag {
  self->isVisible = _flag;
}
- (BOOL)isVisible {
  return self->isVisible;
}

- (void)setPanelName:(NSString *)_panelName {
  ASSIGN(self->panelName, _panelName);
  // do nothing
}
                                             
- (NSString *)panelName {
  return self->panelName;
}

- (void)setDoActionOnCancel:(BOOL)_doActionOnCancel {
  self->doActionOnCancel = _doActionOnCancel;
}
- (BOOL)doActionOnCancel {
  return self->doActionOnCancel;
}

/* conditions */

- (BOOL)isPanelManagerScript {
  WOContext *ctx;
  BOOL      state;

  ctx   = [self context];
  state = [[ctx objectForKey:SkyPanel_IsScriptSet] boolValue];
  
  if (!state)
    [ctx setObject:[NSNumber numberWithBool:YES] forKey:SkyPanel_IsScriptSet];
  return !state;
}

- (BOOL)isNetscape {
  WEClientCapabilities *ccaps;
  
  ccaps = [[[self context] request] clientCapabilities];
  
  return ![ccaps isInternetExplorer];
}

- (BOOL)isActivationLink {
  return (self->string != nil || self->filename != nil);
}

// ------------------

- (NSString *)panelMouseDownString {
  return [NSString stringWithFormat:@"javascript:panelMouseDown(%@)",
                   self->panelName];
}

- (NSString *)layerElementName {
  return ([self isNetscape]) ? @"layer" : @"div";
}

- (NSString *)visibility {  // used by netscape
  return ([self isNetscape])
    ? ([self isVisible]) ? @"visible" : @"hide"
    : nil;
}

- (NSString *)browserDependentWidth {
  return ([self isNetscape]) ? @"202" : @"100%";
}


- (NSString *)style {       // used by explorer
  NSString *visibility = ([self isVisible]) ? @"visible" : @"hidden";

  if ([self isNetscape])
    return nil;
  
  return [NSString stringWithFormat:
          @"position:absolute; right:25; top:150; width:240; height:210;\n"
          @"visibility:%@;", visibility];
}


@end /* SkyPanel */

/* --- SkyPanelLink -------------------------------------------------------- */

@interface SkyPanelLink : WODynamicElement
{
@protected
  WOAssociation *verb;
  WOAssociation *filename;
  WOAssociation *string;
  WOAssociation *panelName;
  WOAssociation *isVisible;
  WOAssociation *doAction;
}
@end

@implementation SkyPanelLink

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_subs
{
  if ((self = [super initWithName:_name associations:_config template:_subs])) {
    self->verb      = OWGetProperty(_config, @"verb");
    self->panelName = OWGetProperty(_config, @"panelName");
    self->string    = OWGetProperty(_config, @"string");
    self->filename  = OWGetProperty(_config, @"filename");
    self->isVisible = OWGetProperty(_config, @"isVisible");
    self->doAction  = OWGetProperty(_config, @"doAction");
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->panelName);
  RELEASE(self->filename);
  RELEASE(self->string);
  RELEASE(self->verb);
  RELEASE(self->isVisible);
  RELEASE(self->doAction);

  [super dealloc];
}

- (NSString *)_urlFrom:(WOAssociation *)_src inContext:(WOContext *)_ctx {
  WOResourceManager *rm;
  NSString          *str = nil;

  if (_src == nil) return nil;
  str = [_src stringValueInComponent:[_ctx component]];
  if (str == nil) return nil;

  rm  = [[_ctx application] resourceManager];
  return [rm urlForResourceNamed:str
	     inFramework:nil
	     languages:[[_ctx session] languages]
	     request:[_ctx request]];
}
  
/* handling requests */

- (id)invokeActionForRequest:(WORequest *)_request
  inContext:(WOContext *)_ctx
{
  NSString *str;
  BOOL     state;
  
  if (self->isVisible == nil)
    return nil;
  
  str   = [self->verb stringValueInComponent:[_ctx component]];
  state = [self->isVisible boolValueInComponent:[_ctx component]];

  state = (str != nil)
    ? ([str isEqualToString:@"view"]) ? YES : NO : !state;
  
  [self->isVisible setBoolValue:state inComponent:[_ctx component]];
  return nil;
}

- (BOOL)isNetscape:(WOContext *)_ctx {
  return ![[[_ctx request] clientCapabilities] isInternetExplorer];
}

- (void)_appendScriptActionTo:(WOResponse *)_resp inContext:(WOContext *)_ctx {
  WOComponent *cmp       = [_ctx component];
  BOOL        isNetscape = [self isNetscape:_ctx];

  if (self->verb == nil)
    NSLog(@"Warning: No verb set in SkyPanelLink! use default 'view'");
  if (self->panelName == nil)
    NSLog(@"Warning: No panelName set in SkyPanelLink!");

  [_resp appendContentString:@"JavaScript:"];
  if (self->verb != nil)
    [_resp appendContentString:[self->verb stringValueInComponent:cmp]];
  else
    [_resp appendContentString:@"view"];
  [_resp appendContentString:@"Panel("];
  
  if (isNetscape) [_resp appendContentCharacter:'\''];
  
  [_resp appendContentString:[self->panelName stringValueInComponent:cmp]];
  
  if (isNetscape) [_resp appendContentCharacter:'\''];
  [_resp appendContentCharacter:')'];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  BOOL     doScript;
  NSString *icon = nil;
  
  doScript = [[[_ctx session] valueForKey:@"isJavaScriptEnabled"] boolValue];
  
  if ([self->doAction boolValueInComponent:[_ctx component]])
    doScript = NO;
  
  if (doScript) {
    [_response appendContentString:@"<a href=\""];
    [self _appendScriptActionTo:_response inContext:_ctx];
    [_response appendContentString:@"\">"];
  }
  else {
    [_response appendContentString:@"<a href=\""];
    [_response appendContentString:[_ctx componentActionURL]];
    [_response appendContentString:@"\">"];
  }

  if (self->string != nil) {
    [_response appendContentHTMLString:
               [self->string stringValueInComponent:[_ctx component]]];
  }
  if ((self->filename != nil) &&
      (icon = [self _urlFrom:self->filename inContext:_ctx])) {
    [_response appendContentString:@"<img border=\"0\" src=\""];
    [_response appendContentString:icon];
    [_response appendContentString:@"\" />"];
  }
  
  [_response appendContentString:@"</a>"];
}

@end /* SkyPanelLink */
