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

#include "SkyButton.h"
#include <OGoFoundation/WOSession+LSO.h>
#include "common.h"

@interface SkyButtonFrame(PrivateMethods)

- (void)_appendContentToResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;

@end

static NSString *SkyButton_ne    = @"button_ne.gif";
static NSString *SkyButton_nw    = @"button_nw.gif";
static NSString *SkyButton_se    = @"button_se.gif";
static NSString *SkyButton_sw    = @"button_sw.gif";
static NSString *SkyButton_pixel = @"button_pixel.gif";
static NSString *SkyButton_left  = @"[";
static NSString *SkyButton_right = @"]";

@implementation SkyButtonFrame

+ (int)version {
  return 2;
}

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_c
{
  if ((self = [super initWithName:_name associations:_config template:_c])) {
    self->template       = [_c retain];
    self->textMode       = OWGetProperty(_config, @"textMode");
    self->embedInCell    = OWGetProperty(_config, @"embedInCell");
    self->hideIfDisabled = OWGetProperty(_config, @"hideIfDisabled");
    self->disabled       = OWGetProperty(_config, @"disabled");
  }
  return self;
}

- (void)dealloc {
  [self->disabled       release];
  [self->hideIfDisabled release];
  [self->embedInCell    release];
  [self->textMode       release];
  [self->template       release];
  [super dealloc];
}

/* request/response */

- (void)takeValuesFromRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  [self->template takeValuesFromRequest:_rq inContext:_ctx];
}

- (id)invokeActionForRequest:(WORequest *)_request
  inContext:(WOContext *)_ctx
{
  return [self->template invokeActionForRequest:_request inContext:_ctx];
}

- (void)_appendContentToResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  [self->template appendToResponse:_response inContext:_ctx];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  WOResourceManager *rm;
  WOComponent *sComponent;
  NSArray     *languages;
  WORequest   *request;
  NSString    *nw = nil, *ne = nil, *sw = nil, *se = nil, *pixel = nil;
  BOOL tm, embed, isDisabled;

  sComponent = [_ctx component];
  isDisabled = [self->disabled boolValueInComponent:sComponent];

  if (isDisabled) {
    if ([self->hideIfDisabled boolValueInComponent:sComponent])
      return;
  }

  if (self->textMode)
    tm = [self->textMode boolValueInComponent:sComponent];
  else
    tm = [[[_ctx session] userDefaults] boolForKey:@"SkyButtonTextMode"];

  embed = [self->embedInCell boolValueInComponent:sComponent];

  if (embed) [_response appendContentString:@"<TD>"];

  if (tm) {
    [_response appendContentHTMLString:SkyButton_left];
  }
  else {
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
  }
  
  /* first row */
  if (!tm) {
    [_response appendContentString:
                 @"<table cellpadding='0' cellspacing='0' border='0'>\n"
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
                 @"<td width='2' height='2' rowspan='2' colspan='2'><img src=\""];
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

  if (!tm) {
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
                 @"<td nowrap='true' valign='middle' align='center'>"];
  }

  /* the link stuff */
  if (!tm) {
    [_response appendContentString:
                 @"<font face=\"Arial,Helvetica,Verdana,Geneva,Tahoma\" size=\"1\">&nbsp;"];
  }
  
  [self _appendContentToResponse:_response inContext:_ctx];

  if (!tm) {  
    [_response appendContentString:
                 @"&nbsp;</font>"];
  }

  if (!tm) {
    [_response appendContentString:
                 @"</td>"
                 @"<td bgcolor=\"#8C8C8C\"><img src=\""];
    [_response appendContentHTMLAttributeValue:pixel];
    [_response appendContentString:
                 @"\" /></td>"
                 @"<td bgcolor=\"#333333\"><img src=\""];
    [_response appendContentHTMLAttributeValue:pixel];
    [_response appendContentString:@"\" /></td></tr>"];
  }

  /* third row */

  if (tm) {
    [_response appendContentHTMLString:SkyButton_right];
  }
  else {
    [_response appendContentString:
                 @"<tr>"
                 @"<td width=\"2\" height=\"2\" rowspan=\"2\" colspan=\"2\">"
	         @"<img src=\""];
    [_response appendContentHTMLAttributeValue:sw];
    [_response appendContentString:
                 @"\" /></td>"
                 @"<td height=\"1\" bgcolor=\"#8C8C8C\"><img src=\""];
    [_response appendContentHTMLAttributeValue:pixel];
    [_response appendContentString:
                 @"\" /></td>"
                 @"<td width=\"2\" height=\"2\" rowspan=\"2\" colspan=\"2\">"
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

  if (embed) [_response appendContentString:@"</td>"];
}

@end /* SkyButtonFrame */

@implementation SkyButton

+ (int)version {
  return 2;
}

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_c
{
  if ((self = [super initWithName:_name associations:_config template:_c])) {
    id tmp;
    self->string   = OWGetProperty(_config, @"string");
    self->tooltip  = OWGetProperty(_config, @"tooltip");

    NSLog(@"WARNING: SkyButton %@ is being instantiated, "
          @"use SkyButtonRow instead !", _name);

    if ((tmp = OWGetProperty(_config, @"action"))) {
      self->actionType = SkyButton_action;
      self->action     = tmp;
    }
    else if ((tmp = OWGetProperty(_config, @"href"))) {
      self->actionType = SkyButton_href;
      self->action     = tmp;
    }
    else if ((tmp = OWGetProperty(_config, @"directActionName"))) {
      self->actionType = SkyButton_da;
      self->action     = tmp;
    }
    else
      self->actionType = -1;
  }
  return self;
}

- (void)dealloc {
  [self->string  release];
  [self->tooltip release];
  [self->action  release];
  [super dealloc];
}

/* request processing */

- (id)invokeActionForRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  if (self->actionType == SkyButton_action) {
    //if ([[_ctx senderID] isEqualToString:[_ctx elementID]])
    return [self->action valueInComponent:[_ctx component]];
  }
  
  return [self->template invokeActionForRequest:_rq inContext:_ctx];
}

- (void)_appendContentToResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  WOComponent *sComponent;
  BOOL isDisabled, tm;
  NSString *tt = nil, *s = nil;
  
  sComponent = [_ctx component];

  if (self->textMode)
    tm = [self->textMode boolValueInComponent:sComponent];
  else
    tm = [[[_ctx session] userDefaults] boolForKey:@"SkyButtonTextMode"];
      
  isDisabled = [self->disabled boolValueInComponent:sComponent];

  if (self->string)
    s = [self->string stringValueInComponent:sComponent];
  
  if (self->tooltip)
    tt = [self->tooltip stringValueInComponent:sComponent];
  else if (s)
    tt = s;

  if (!tm) {
    [_response appendContentString:
                 @"<font face=\"Arial,Helvetica,Verdana,Geneva,Tahoma\" "
	         @"size=\"1\">"
                 @"&nbsp;"];
  }

  if (!isDisabled && (self->action != nil)) {
    NSString *url;
    
    if (tm) {
      [_response appendContentString:@"<a href=\""];
    }
    else {
      [_response appendContentString:
                   @"<a style=\"text-decoration:none\" href=\""];
    }
    
    if (self->actionType == SkyButton_href) {
      url = [self->action stringValueInComponent:sComponent];
    }
    else if (self->actionType == SkyButton_da) {
      NSDictionary *qd;

      qd = [NSDictionary dictionaryWithObjectsAndKeys:
                           [[_ctx session] sessionID],
                           WORequestValueSessionID,
                           [[WOApplication application] number],
                           WORequestValueInstance,
                           nil];

      url = [_ctx directActionURLForActionNamed:
                    [self->action stringValueInComponent:sComponent]
                  queryDictionary:qd];
    }
    else {
      url = [_ctx elementID];
    }
    
#if DEBUG
    NSAssert1([url rangeOfString:@"wa"].length == 0,
              @"url '%@' contains /wa/ !!", url);
#endif
    [_response appendContentHTMLAttributeValue:url];
    [_response appendContentString:@"\">"];
  }

  if (s) {
    if (!tm) [_response appendContentString:@"<b>"];
    [_response appendContentString:@"<font color=\""];
    if (isDisabled)
      [_response appendContentString:@"#AAAAAA"];
    else
      [_response appendContentString:@"black"];
    [_response appendContentString:@"\">"];
    
    [_response appendContentHTMLString:s];

    [_response appendContentString:@"</font>"];
    if (!tm) [_response appendContentString:@"</b>"];
  }

#if 0
  if (self->template)
    [self->template appendToResponse:_response inContext:_ctx];
#endif

  if (!isDisabled && (self->action != nil))
    [_response appendContentString:@"</a>"];

  if (!tm) {
    [_response appendContentString:
                 @"&nbsp;"
                 @"</font>"];
  }
}
    
@end /* SkyButton */
