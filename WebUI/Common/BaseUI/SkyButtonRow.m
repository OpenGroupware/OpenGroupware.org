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

#include "SkyButtonRow.h"
#include <OGoFoundation/WOSession+LSO.h>
#include <LSFoundation/LSCommandContext.h>
#include <NGObjWeb/WEClientCapabilities.h>
#include "common.h"

static NSString *SkyButton_ne    = @"button_ne.gif";
static NSString *SkyButton_nw    = @"button_nw.gif";
static NSString *SkyButton_se    = @"button_se.gif";
static NSString *SkyButton_sw    = @"button_sw.gif";
static NSString *SkyButton_pixel = @"button_pixel.gif";
static NSString *SkyButton_left  = @"[";
static NSString *SkyButton_right = @"]";

@implementation SkyButtonRow

static NSMutableSet *defButtons = nil;
static NSString *SkyExternalLinkAction = nil;

+ (int)version {
  return 3;
}

+ (void)initialize {
  if (defButtons) return;
  
  defButtons = [[NSMutableSet alloc] initWithCapacity:8];
  [defButtons addObject:@"edit"];
  [defButtons addObject:@"delete"];
  [defButtons addObject:@"move"];
  [defButtons addObject:@"new"];
  [defButtons addObject:@"mail"];
  [defButtons addObject:@"clip"];

  SkyExternalLinkAction = [[[NSUserDefaults standardUserDefaults]
                             stringForKey:@"SkyExternalLinkAction"] copy];
}

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_c
{
  if ((self = [super initWithName:_name associations:_config template:_c])) {
    NSZone         *z = [self zone];
    NSMutableSet   *buttons;
    NSEnumerator   *e;
    NSString       *key;
    id tmp;
    
    buttons = [NSMutableSet setWithCapacity:16];
    
    self->template = RETAIN(_c);
    self->oid      = OWGetProperty(_config, @"oid");
    self->size     = OWGetProperty(_config, @"size");
    
    if ((self->ordering = OWGetProperty(_config, @"ordering")) == nil) {
#if DEBUG
      NSLog(@"%s: missing ordering binding (open config=%@).",
            __PRETTY_FUNCTION__, _config);
#endif
    }
    
    /* fix associations */

    /* dynamic associations */
    
    e = [_config keyEnumerator];
    while ((key = [e nextObject]) != nil) {
      WOAssociation *a;
      
      if ([key hasPrefix:@"on"]) {
        /* an event handler */
        if (self->eventHandlers == nil)
          self->eventHandlers = [[NSMutableDictionary alloc] initWithCapacity:8];
        
        a = [_config objectForKey:key];
        key = [key substringFromIndex:2];
        key = [key lowercaseString];

        [(NSMutableDictionary *)self->eventHandlers setObject:a forKey:key];
        [buttons addObject:key];
      }
      else if ([key hasPrefix:@"url"]) {
        /* a URL button */
        if (self->urls == nil)
          self->urls = [[NSMutableDictionary alloc] initWithCapacity:8];

        a   = [_config objectForKey:key];
        key = [key substringFromIndex:3];
        key = [key lowercaseString];

        [(NSMutableDictionary *)self->urls setObject:a forKey:key];
        [buttons addObject:key];
      }
      else if ([key hasPrefix:@"has"]) {
        /* a condition */
        if (self->conditions == nil)
          self->conditions = [[NSMutableDictionary alloc] initWithCapacity:8];
        
        a   = [_config objectForKey:key];
        key = [key substringFromIndex:3];
        key = [key lowercaseString];

        [(NSMutableDictionary *)self->conditions setObject:a forKey:key];
        [buttons addObject:key];
      }
      else if ([key hasPrefix:@"tip"]) {
        /* a tooltip */
        if (self->tooltips == nil)
          self->tooltips = [[NSMutableDictionary alloc] initWithCapacity:8];
        
        a   = [_config objectForKey:key];
        key = [key substringFromIndex:3];
        key = [key lowercaseString];

        [(NSMutableDictionary *)self->tooltips setObject:a forKey:key];
        [buttons addObject:key];
      }
      else if ([key hasPrefix:@"target"]) {
        /* a target */
        if (self->targets == nil)
          self->targets = [[NSMutableDictionary alloc] initWithCapacity:8];

        a  = [_config objectForKey:key];
        key = [key substringFromIndex:6];
        key = [key lowercaseString];

        [(NSMutableDictionary *) self->targets setObject:a forKey:key];
        [buttons addObject:key];
      }
      else {
        /* a label */
        if (self->labels == nil)
          self->labels = [[NSMutableDictionary alloc] initWithCapacity:8];
        
        a = [_config objectForKey:key];
        [(NSMutableDictionary *)self->labels setObject:a forKey:key];
      }
    }
    
    /* make config immutable for faster access */

    tmp = self->eventHandlers;
    self->eventHandlers = [tmp copyWithZone:z];
    [tmp release]; tmp = nil;

    tmp = self->urls;
    self->urls = [tmp copyWithZone:z];
    [tmp release]; tmp = nil;

    tmp = self->conditions;
    self->conditions = [tmp copyWithZone:z];
    [tmp release]; tmp = nil;

    tmp = self->tooltips;
    self->tooltips = [tmp copyWithZone:z];
    [tmp release]; tmp = nil;

    tmp = self->targets;
    self->targets = [tmp copyWithZone:z];
    [tmp release]; tmp = nil;
    
    self->activeButtons = [buttons copyWithZone:z];
    
    /* check for default buttons */
    self->defaultButtons.hasEdit   = [buttons containsObject:@"edit"]   ? 1:0;
    self->defaultButtons.hasDelete = [buttons containsObject:@"delete"] ? 1:0;
    self->defaultButtons.hasMove   = [buttons containsObject:@"move"]   ? 1:0;
    self->defaultButtons.hasNew    = [buttons containsObject:@"new"]    ? 1:0;
    self->defaultButtons.hasMail   = [buttons containsObject:@"mail"]   ? 1:0;
    self->defaultButtons.hasClip   = [buttons containsObject:@"clip"]   ? 1:0;
    
    /* remove all objects .. */
    [(NSMutableDictionary *)_config removeAllObjects];

    /* check ordering */

    if (self->ordering == nil) {
      if ([activeButtons count] > 0) {
        self->ordering =
          [WOAssociation associationWithValue:[activeButtons allObjects]];
        self->ordering = [self->ordering retain];
      }
    }
  }
  return self;
}

- (void)dealloc {
  [self->oid           release];
  [self->ordering      release];
  [self->size          release];
  [self->conditions    release];
  [self->activeButtons release];
  [self->urls          release];
  [self->eventHandlers release];
  [self->tooltips      release];
  [self->targets       release];
  [self->labels        release];
  [self->template      release];
  [super dealloc];
}

/* form values */

- (void)takeValuesFromRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  [self->template takeValuesFromRequest:_rq inContext:_ctx];
}

/* event handling */

- (id)invokeActionForRequest:(WORequest *)_request
  inContext:(WOContext *)_ctx
{
  WOAssociation *action;
  id buttonKey;
  id result;

  if ((buttonKey = [[_ctx currentElementID] stringValue]) == nil)
    return [self->template invokeActionForRequest:_request inContext:_ctx];

  [_ctx appendElementIDComponent:buttonKey];
  
  if ((action = [self->eventHandlers objectForKey:buttonKey]) != nil)
    result = [action valueInComponent:[_ctx component]];
  else {
    [self logWithFormat:@"no matching event handler for button %@", buttonKey];
    result = [self->template invokeActionForRequest:_request inContext:_ctx];
  }
  
  [_ctx deleteLastElementIDComponent];
  return result;
}

/* HTML generation */

- (NSString *)_getActionUrlOfButton:(NSString *)_key
  inContext:(WOContext *)_ctx
  withURL:(NSString *)url
{
  if (url == nil) {
    [_ctx appendElementIDComponent:_key];
    /* no URL was specified, use componentActionURL */
    url = [_ctx componentActionURL];
    [_ctx deleteLastElementIDComponent];
    return url;
  }
  
  /* both - an action handler and a url where specified */
  
  [_ctx appendElementIDComponent:_key];
  if ([_key isEqualToString:@"mail"]) {
    /* .. which is ok for mail-buttons */
    /* TODO: this sounds like HACK HACK */

    if (self->isMailAvailable) {
      NSString *mailButtonType;

      mailButtonType = [[[_ctx session]
                                   userDefaults]
                                   stringForKey:@"mail_editor_type"];
      if (mailButtonType == nil)
	mailButtonType = @"internal";

      if (![mailButtonType isEqualToString:@"external"])
	url = [_ctx componentActionURL];
    }
  }
  else {
    /* .. but not for other ones */
    [[_ctx component]
      logWithFormat:@"WARNING: specified both, url and action for button %@",
        _key];
    url = [_ctx componentActionURL];
  }
  
  [_ctx deleteLastElementIDComponent];
  return url;
}

- (NSString *)_getUrlOfButton:(NSString *)_key
  hasAction:(BOOL)_hasAction
  inContext:(WOContext *)_ctx
{
  /* Note: mail buttons specify both: 'onMail' and 'urlMail' */
  WOComponent *sComponent;
  NSString *url;

  sComponent = [_ctx component];
  url = [[self->urls objectForKey:_key] stringValueInComponent:sComponent];
  
  if (_hasAction) {
    /* button has an 'onBlah' handler specified */
    url = [self _getActionUrlOfButton:_key inContext:_ctx withURL:url];
  }
  else if (url == nil) {
    NSString *soid;
    
    if ((soid = [self->oid stringValueInComponent:sComponent])) {
      if ([soid intValue] != 0)
        url = [_ctx directActionURLForActionNamed:@"activate"
                    queryDictionary:
                    [NSDictionary dictionaryWithObjectsAndKeys:
                                  soid, @"oid",
                                  _key, @"verb",
                                  nil]];
    }
    else
      [sComponent logWithFormat:@"WARNING: missing oid for 'activate' da .."];
  }

  return url;
}

- (void)_appendTextButton:(NSString *)_key
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
  hideInactive:(BOOL)_hideInactive
{
  WOComponent *sComponent;
  NSString    *label, *url, *tip, *target;
  BOOL        hasAction, isEnabled;
  id          tmp;
  
  sComponent = [_ctx component];
  
  isEnabled = ((tmp = [self->conditions objectForKey:_key]))
    ? [tmp boolValueInComponent:sComponent]
    : YES;
  
  if (!isEnabled && _hideInactive)
    /* the button is disabled and disabled ones are not to be displayed */
    return;

  /* hasAction is YES if an 'onBlah' handler is specified */
  hasAction = ([self->eventHandlers objectForKey:_key] != nil) ? YES : NO;
  label =
    [[self->labels   objectForKey:_key] stringValueInComponent:sComponent];
  tip =
    [[self->tooltips objectForKey:_key] stringValueInComponent:sComponent];
  target =
    [[self->targets objectForKey:_key] stringValueInComponent:sComponent];
  url =
    [[self->urls     objectForKey:_key] stringValueInComponent:sComponent];

  if (label == nil) {
#if 0 && DEBUG
    [sComponent debugWithFormat:
                  @"WARNING: missing label for button %@ in "
                  @"SkyButtonRow %@.", _key, self];
#endif
    label = _key;
  }
  if (tip == nil)
    tip = label;
  
  /* determine URL */

  url = [self _getUrlOfButton:_key hasAction:hasAction inContext:_ctx];

  /* generate */

  if (self->size) {
    [_response appendContentString:@"<font size=\""];
    [_response appendContentHTMLAttributeValue:
               [self->size stringValueInComponent:sComponent]];
    [_response appendContentString:@"\">"];
  }
  [_response appendContentHTMLString:SkyButton_left];
  
  if (isEnabled) {
    [_response appendContentString:
                 @"<a href=\""];
    if ((!hasAction) && (target != nil)) {
      // seems to be external link
      NSString *action;
      
      action = [SkyExternalLinkAction stringByAppendingFormat:@"?url=%@",
                                      [url stringByEscapingURL]];
      [_response appendContentHTMLAttributeValue:action];
    }
    else {
      [_response appendContentHTMLAttributeValue:url];
    }
    if (target != nil) {
      [_response appendContentString:
                 @"\" target=\""];
      [_response appendContentHTMLAttributeValue:target];
    }
    [_response appendContentString:@"\">"];
  }

  [_response appendContentHTMLString:label];
  
  if (isEnabled)
    [_response appendContentString:@"</a>"];
  
  [_response appendContentHTMLString:SkyButton_right];
  if (self->size)
    [_response appendContentString:@"</font>"];
}

- (void)_appendTableButton:(NSString *)_key
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
  nw:(NSString *)nw ne:(NSString *)ne sw:(NSString *)sw se:(NSString *)se
  pixel:(NSString *)pixel
{
  WOComponent *sComponent;
  NSString    *label, *url, *tip, *target;
  BOOL        hasAction, isEnabled;
  id          tmp;
  
  // unused: verb = _key;
  sComponent = [_ctx component];
  
  isEnabled = ((tmp = [self->conditions objectForKey:_key]))
    ? [tmp boolValueInComponent:sComponent]
    : YES;
  
  hasAction = ([self->eventHandlers objectForKey:_key] != nil) ? YES : NO;
  label =
    [[self->labels   objectForKey:_key] stringValueInComponent:sComponent];
  tip =
    [[self->tooltips objectForKey:_key] stringValueInComponent:sComponent];
  target =
    [[self->targets objectForKey:_key] stringValueInComponent:sComponent];
  url = [[self->urls     objectForKey:_key] stringValueInComponent:sComponent];

  if (label == nil) {
#if 0 && DEBUG
    [sComponent logWithFormat:
                  @"WARNING: missing label for button %@ in "
                  @"SkyButtonRow %@.", _key, self];
#endif
    label = _key;
  }
  if (tip == nil)
    tip = label;

  /* determine URL */

  url = [self _getUrlOfButton:_key hasAction:hasAction inContext:_ctx];
  
  /* begin encoding */
  
  [_response appendContentString:@"<td>"];

  /* first row */
  {
    [_response appendContentString:
                 @"<table class=\"skybuttonrow\" cellpadding='0' cellspacing='0' border='0'>"
                 @"<tr>"
                 @"<td width='2' height='2' rowspan='2' colspan='2'>"
                 @"<img src=\""];
    [_response appendContentHTMLAttributeValue:nw];
    [_response appendContentString:
                 @"\" /></td>"
                 @"<td height='1' bgcolor=\"#C0C0C0\"><img src=\""];
    [_response appendContentHTMLAttributeValue:pixel];
    [_response appendContentString:
                 @"\" /></td>"
                 @"<td width='2' height='2' rowspan='2' colspan='2'>"
                 @"<img src=\""];
    [_response appendContentHTMLAttributeValue:ne];
    [_response appendContentString:
                 @"\" /></td>"
                 @"</tr>"
                 @"<tr>"
                 @"<td height='1' bgcolor=\"#FFFFFF\"><img src=\""];
    [_response appendContentHTMLAttributeValue:pixel];
    [_response appendContentString:
                 @"\" /></td>"
                 @"</tr>"];
  }

  /* second row */
  {
    [_response appendContentString:
                 @"<tr>"
                 @"<td height='1' bgcolor=\"#C0C0C0\"><img src=\""];
    [_response appendContentHTMLAttributeValue:pixel];
    [_response appendContentString:
                 @"\" /></td>"
                 @"<td height='1' bgcolor=\"#FFFFFF\"><img src=\""];
    [_response appendContentHTMLAttributeValue:pixel];
    [_response appendContentString:
                 @"\" /></td>"
                 @"<td class=\"skybuttoncolor\" nowrap=\"true\" valign='middle' align='center'>"];
    
    /* the link stuff */
    {
      if (self->size) {
        [_response appendContentString:@"<font size=\""];
        [_response appendContentHTMLAttributeValue:
                   [self->size stringValueInComponent:sComponent]];
        [_response appendContentString:@"\">"];
      }
      [_response appendContentString:@"&nbsp;"];

      if (isEnabled) {
        isEnabled = (((!hasAction) && (target != nil)) || ([url length] > 0))
          ? YES : NO;
      }
      if (isEnabled) {
        [_response appendContentString:
                     @"<a class=\"skybuttonlink\" href=\""];
        if ((!hasAction) && (target != nil)) {
          // seems to be external link
          NSString *action;
          
          action = [SkyExternalLinkAction stringByAppendingFormat:@"?url=%@", 
                                            [url stringByEscapingURL]];
          [_response appendContentHTMLAttributeValue:action];
        }
        else {
          [_response appendContentHTMLAttributeValue:url];
        }
        if (target != nil) {
          [_response appendContentString:
                     @"\" target=\""];
          [_response appendContentHTMLAttributeValue:target];
        }
        [_response appendContentString:@"\">"];
      }
      [_response appendContentString:@"<span class=\"skybuttonrow\">"];
      
      [_response appendContentHTMLString:label];

      [_response appendContentString:@"</span>"];
      if (isEnabled) [_response appendContentString:@"</a>"];
      [_response appendContentString:@"&nbsp;"];
      if (self->size) 
        [_response appendContentString:@"</font>"];
    }
    
    [_response appendContentString:
                 @"</td>"
                 @"<td bgcolor=\"#8C8C8C\"><img src=\""];
    [_response appendContentHTMLAttributeValue:pixel];
    [_response appendContentString:
                 @"\" /></td>"
                 @"<td bgcolor=\"#333333\"><img src=\""];
    [_response appendContentHTMLAttributeValue:pixel];
    [_response appendContentString:@"\" /></td>  </tr>"];
  }

  /* third row */
  {
    [_response appendContentString:
                 @"  <tr>"
                 @"    <td width='2' height='2' rowspan='2' colspan='2'>"
                 @"<img src=\""];
    [_response appendContentHTMLAttributeValue:sw];
    [_response appendContentString:
                 @"\" /></td>"
                 @"<td height='1' bgcolor=\"#8C8C8C\"><img src=\""];
    [_response appendContentHTMLAttributeValue:pixel];
    [_response appendContentString:
                 @"\"></td>"
                 @"<td width='2' height='2' rowspan='2' colspan='2'>"
                 @"<img src=\""];
    [_response appendContentHTMLAttributeValue:se];
    [_response appendContentString:
                 @"\" /></td>"
                 @"</tr>"
                 @"<tr>"
                 @"<td bgcolor=\"#333333\"><img src=\""];
    [_response appendContentHTMLAttributeValue:pixel];
    [_response appendContentString:
                 @"\" /></td>"
                 @"</tr>"
                 @"</table>"];
  }
  
  [_response appendContentString:@"</td>"];
}

- (void)_appendInTextModeToResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSUserDefaults *ud;
  BOOL defLeft, hideInactive;
  
  ud           = [[_ctx session] userDefaults];
  defLeft      = [ud boolForKey:@"SkyButtonRowDefaultButtonsLeft"];
  hideInactive = [ud boolForKey:@"SkyButtonRowHideInactiveButtons"];
  
  /* encode custom stuff */
  if (!defLeft) {
    NSEnumerator *o;
    NSString *key;
    
    [self->template appendToResponse:_response inContext:_ctx];
    
    o = [[self->ordering valueInComponent:[_ctx component]] objectEnumerator];
    while ((key = [o nextObject])) {
      if ([defButtons containsObject:key])
        continue;
      
      if ([self->activeButtons containsObject:key]) {
        [self _appendTextButton:key toResponse:_response inContext:_ctx
              hideInactive:hideInactive];
      }
    }
  }
  
  /* encode each default button */
  {
    NSEnumerator *defOrdering;
    NSString     *key;

    defOrdering = [[ud arrayForKey:@"SkyButtonRowOrdering"] objectEnumerator];
    while ((key = [defOrdering nextObject])) {
      if ([self->activeButtons containsObject:key]) {
        [self _appendTextButton:key toResponse:_response inContext:_ctx
              hideInactive:hideInactive];
      }
    }
  }
  
  /* encode custom stuff */
  if (defLeft) {
    NSEnumerator *o;
    NSString *key;
    
    [self->template appendToResponse:_response inContext:_ctx];
    
    o = [[self->ordering valueInComponent:[_ctx component]] objectEnumerator];
    while ((key = [o nextObject])) {
      if ([defButtons containsObject:key])
        continue;
      
      if ([self->activeButtons containsObject:key]) {
        [self _appendTextButton:key toResponse:_response inContext:_ctx
              hideInactive:hideInactive];
      }
    }
  }
}

- (void)_beginNoWrapTable:(WOResponse *)_response inContext:(WOContext *)_ctx {
  [_response appendContentString:
               @"<table class=\"skybuttonrow\" border='0' cellpadding='0' cellspacing='1'>"
               @"<tr>"];
}

- (void)_appendInTableModeToResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSUserDefaults    *ud = [[_ctx session] userDefaults];
  WOResourceManager *rm;
  NSArray           *languages;
  WORequest         *request;
  WOComponent       *sComponent;
  NSString          *nw, *ne, *sw, *se, *pixel;
  BOOL              defLeft, hideInactive;
  id                tmp;
  BOOL              didWriteTable;

  sComponent = [_ctx component];

  defLeft      = [ud boolForKey:@"SkyButtonRowDefaultButtonsLeft"];
  hideInactive = [ud boolForKey:@"SkyButtonRowHideInactiveButtons"];

  rm        = [[_ctx application] resourceManager];
  languages = [[_ctx session] languages];
  request   = [_ctx request];
    
  nw = [rm urlForResourceNamed:SkyButton_nw inFramework:nil
           languages:languages request:request];
  ne = [rm urlForResourceNamed:SkyButton_ne inFramework:nil
           languages:languages request:request];
  sw = [rm urlForResourceNamed:SkyButton_sw inFramework:nil
           languages:languages request:request];
  se = [rm urlForResourceNamed:SkyButton_se inFramework:nil
           languages:languages request:request];
  pixel = [rm urlForResourceNamed:SkyButton_pixel inFramework:nil
              languages:languages request:request];
  
  /* start encoding */

  didWriteTable = NO;
  
  /* encode custom stuff */
  if (!defLeft) {
    NSEnumerator *o;
    NSString *key;
    
    [self->template appendToResponse:_response inContext:_ctx];
    
    o = [[self->ordering valueInComponent:[_ctx component]] objectEnumerator];
    while ((key = [o nextObject])) {
      if ([defButtons containsObject:key])
        continue;
      
      if ([self->activeButtons containsObject:key]) {
        BOOL isEnabled;
        
        isEnabled = ((tmp = [self->conditions objectForKey:key]))
          ? [tmp boolValueInComponent:sComponent]
          : YES;

        if (hideInactive && !isEnabled)
          continue;

        if (!didWriteTable) {
          [self _beginNoWrapTable:_response inContext:_ctx];
          didWriteTable = YES;
        }
        
        [self _appendTableButton:key toResponse:_response inContext:_ctx
              nw:nw ne:ne sw:sw se:se
              pixel:pixel];
      }
    }
  }

  /* encode each default button */
  {
    NSEnumerator *defOrdering;
    NSString *key;

    defOrdering = [[ud arrayForKey:@"SkyButtonRowOrdering"] objectEnumerator];
    while ((key = [defOrdering nextObject])) {
      if ([self->activeButtons containsObject:key]) {
        BOOL isEnabled;
        
        isEnabled = ((tmp = [self->conditions objectForKey:key]))
          ? [tmp boolValueInComponent:sComponent]
          : YES;

        if (hideInactive && !isEnabled)
          continue;

        if (!didWriteTable) {
          [self _beginNoWrapTable:_response inContext:_ctx];
          didWriteTable = YES;
        }
        
        [self _appendTableButton:key toResponse:_response inContext:_ctx
              nw:nw ne:ne sw:sw se:se
              pixel:pixel];
      }
    }
  }
  
  /* encode custom stuff */
  if (defLeft) {
    NSEnumerator *o;
    NSString *key;
    
    [self->template appendToResponse:_response inContext:_ctx];
    
    o = [[self->ordering valueInComponent:[_ctx component]] objectEnumerator];
    while ((key = [o nextObject])) {
      if ([defButtons containsObject:key])
        continue;
      
      if ([self->activeButtons containsObject:key]) {
        BOOL isEnabled;
        
        isEnabled = ((tmp = [self->conditions objectForKey:key]))
          ? [tmp boolValueInComponent:sComponent]
          : YES;

        if (hideInactive && !isEnabled)
          continue;
        
        if (!didWriteTable) {
          [self _beginNoWrapTable:_response inContext:_ctx];
          didWriteTable = YES;
        }
        
        [self _appendTableButton:key toResponse:_response inContext:_ctx
              nw:nw ne:ne sw:sw se:se
              pixel:pixel];
      }
    }
  }

  if (didWriteTable) {
    [_response appendContentString:
                 @"</tr>"
                 @"</table>"];
  }
}

- (BOOL)hasMailComponent {
  static int hasMail = -1;

  if (hasMail == -1) {
    NGBundleManager *bm = nil;
    
    bm = [NGBundleManager defaultBundleManager];
    
    if ([bm bundleProvidingResource:@"LSWImapMailEditor"
            ofType:@"WOComponents"] != nil)
      hasMail = 1;
    else
      hasMail = 0;
  }
  return hasMail ? YES : NO;
}

- (void)appendToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
  OGoSession *sn;
  BOOL       textMode;
  
  self->isMailAvailable = [self hasMailComponent];
  
  sn       = [_ctx session];
  textMode = [[sn userDefaults] boolForKey:@"SkyButtonTextMode"];
  
  if (!textMode) {
    WEClientCapabilities *ccaps;
    
    ccaps    = [[_ctx request] clientCapabilities];
    textMode = ![ccaps isFastTableBrowser] || [ccaps isTextModeBrowser];
  }
  
  if (textMode)
    [self _appendInTextModeToResponse:_r inContext:_ctx];
  else
    [self _appendInTableModeToResponse:_r inContext:_ctx];
}

/* description */

- (NSString *)description {
  NSMutableString *s;
  
  s = [NSMutableString stringWithCapacity:32];
  [s appendFormat:@"<%@[%p]:", NSStringFromClass([self class]), self];
  [s appendFormat:@" buttons=%@",
       [[self->activeButtons allObjects] componentsJoinedByString:@","]];
  [s appendString:@">"];
  return s;
}

@end /* SkyButtonRow */
