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

#include <NGObjWeb/WODynamicElement.h>

/*
  SkyDialNumber
  
  This dynamic elements is used to render telephone numbers in SKYRiX. The
  major functionality is that it can place a dial-up link besides the number
  if the STLI module is available.
*/

@interface SkyDialNumber : WODynamicElement
{
  WOAssociation *number;
  WOElement     *template;
}

@end

#include "common.h"
#include <NGStreams/NGInternetSocketAddress.h>

@interface WOSession(CTI)
- (BOOL)canDialNumber:(NSString *)_number;
- (BOOL)dialNumber:(NSString *)_number;
- (BOOL)dialNumber:(NSString *)_number fromDevice:(NSString *)_device;
@end

@interface WOSession(OGoSession)
- (id)commandContext;
- (NSString *)activeLogin;
@end

@implementation SkyDialNumber

static NSString *daDialerLink   = nil;
static NSString *daDialerTarget = nil;
static int useDirectActionDialer = -1;

+ (void)initialize {
  // TODO: should check parent class version
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  daDialerLink = [[ud stringForKey:@"SkyDirectActionDialer_Link"] copy];
  if (daDialerLink == nil) daDialerLink = @"";
  daDialerTarget = [[ud stringForKey:@"SkyDirectActionDialer_Target"] copy];
  if (daDialerTarget == nil) daDialerTarget = @"SkyDirectActionDialerFrame";

  useDirectActionDialer = [daDialerLink isNotEmpty] ? 1 : 0;
}

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_t
{
  if ((self = [super initWithName:_name associations:_config template:_t])) {
    self->template = [_t retain];
    self->number = [[_config objectForKey:@"number"] retain];
  }
  return self;
}

- (void)dealloc {
  [self->number   release];
  [self->template release];
  [super dealloc];
}

/* request processing */

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  [self->template takeValuesFromRequest:_req inContext:_ctx];
}

- (id)invokeActionForRequest:(WORequest *)_request
  inContext:(WOContext *)_ctx
{
  NSString    *num;
  WOComponent *page;
  
  if (![[_ctx elementID] isEqualToString:[_ctx senderID]]) 
    return [self->template invokeActionForRequest:_request inContext:_ctx];

  page = [_ctx page];
  num = [self->number stringValueInComponent:[_ctx component]];
    
  if (![[_ctx session] canDialNumber:num]) {
    [page takeValue:
	    [NSString stringWithFormat:@"cannot dial number '%@'", num]
	  forKey:@"errorString"];
  }
  else if (![[_ctx session] dialNumber:num]) {
    [page takeValue:
	    [NSString stringWithFormat:@"dialing of number '%@' failed", num]
	  forKey:@"errorString"];
  }
  return page;
}

- (NSString *)directActionDialerLink {
  return daDialerLink;
}
- (NSString *)directActionDialerTarget {
  return daDialerTarget;
}
- (BOOL)useDirectActionDialer {
  return useDirectActionDialer;
}

- (NSString *)dialIconURLInContext:(WOContext *)_ctx {
  WOResourceManager *rm;
  NSString *dialIconURL, *dialIconName;
  NSArray *languages;
    
  dialIconURL = nil;
  dialIconName = @"icon_dial_16x19.gif";
    
  /* search for dial icon */
    
  if ((rm = [[_ctx component] resourceManager]) == nil)
    rm = [[_ctx application] resourceManager];
    
  if (rm == nil)
    return nil;
  
  languages = [_ctx hasSession] ? [[_ctx session] languages] : (NSArray *)nil;
      
  dialIconURL = [rm urlForResourceNamed:dialIconName
                    inFramework:nil
                    languages:languages
                    request:[_ctx request]];
  return dialIconURL;
}

- (void)_appendDialLink:(NSString *)_link
  target:(NSString *)_target
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString *dialIconURL;
  NSString *label = @"dial"; // TODO: localize
  
  [_response appendContentString:@"<a href=\""];
  [_response appendContentString:_link];
  if ([_target isNotEmpty]) {
    [_response appendContentString:@"\" target=\""];
    [_response appendContentString:_target];
  }
  [_response appendContentString:@"\">"];

  if ([(dialIconURL = [self dialIconURLInContext:_ctx]) isNotEmpty]) {
    [_response appendContentString:@"<img border=\"0\" src=\""];
    [_response appendContentString:dialIconURL];
    [_response appendContentString:@"\" title=\""];
    [_response appendContentHTMLAttributeValue:label];
    [_response appendContentString:@"\" alt=\""];
    [_response appendContentHTMLAttributeValue:label];
    [_response appendContentString:@"\" />"];
  }
  else {
    [_response appendContentString:@"["];
    [_response appendContentHTMLString:label];
    [_response appendContentString:@"]"];
  }
  [_response appendContentString:@"</a>"];
}

- (void)appendURLDialerForNumber:(NSString *)num
  toResponse:(WOResponse *)_response 
  inContext:(WOContext *)_ctx 
{
  NSString     *link   = [self directActionDialerLink];
  NSString     *target = [self directActionDialerTarget];
  NSString     *login  = [[_ctx session] activeLogin];
  NSString     *remoteHost;
  NSString     *remoteIP;
  NSDictionary *bindings;

  remoteHost = [[_ctx session] valueForKey:@"RemoteClientHost"];
  remoteIP   = [[_ctx session] valueForKey:@"RemoteClientAddress"];
  if (![remoteHost isNotEmpty]) {
    // TODO: check bug #1745
    remoteHost = [[_ctx request] headerForKey:@"x-webobjects-remote-host"];
    if ([remoteHost isNotEmpty]) {
      NGInternetSocketAddress *ip;
      
      [[_ctx session] takeValue:remoteHost forKey:@"RemoteClientHost"];
      ip = [NGInternetSocketAddress addressWithPort:0 onHost:remoteHost];
      if ((remoteIP = [ip address]) != nil)
	[[_ctx session] takeValue:remoteIP forKey:@"RemoteClientAddress"];
    }
  }
  
  bindings =
    [[NSDictionary alloc] initWithObjectsAndKeys:
                    num,                         @"number",
                    [num stringByEscapingURL],   @"numberEscaped",
                    login,                       @"login",
                    [login stringByEscapingURL], @"loginEscaped",
                    [remoteHost stringByEscapingURL], @"remoteHost",
                    remoteIP,                    @"remoteAddress",
		  nil];
  link = [link stringByReplacingVariablesWithBindings:bindings
               stringForUnknownBindings:@"unknown"];
  [bindings release]; bindings = nil;
  
  [self _appendDialLink:link target:target
        toResponse:_response inContext:_ctx];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  NSString *num;
  
  if ([[_ctx request] isFromClientComponent])
    return;
  
  num = [self->number stringValueInComponent:[_ctx component]];

  /* content */
  [self->template appendToResponse:_response inContext:_ctx];

  if (![self useDirectActionDialer]) {
    if (![[_ctx session] canDialNumber:num])
      num = nil;
    
    if ([num isNotEmpty]) {
      [self _appendDialLink:[_ctx componentActionURL] target: nil
            toResponse:_response inContext:_ctx];
    }
  }
  else if ([self useDirectActionDialer] && [num isNotEmpty]) {
    [self appendURLDialerForNumber:num
	  toResponse:_response inContext:_ctx];
  }
}

@end /* SkyDialNumber */


@interface WOApplication(CTI)
- (id)createCTIDialer;
@end

#include <LSFoundation/LSCommandContext.h>

@implementation WOSession(Dialing)

- (id)dialer {
  id dialer;
  
  if ((dialer = [self objectForKey:@"CTIDialer"]) == nil) {
    dialer = [[WOApplication application] createCTIDialer];
    if (dialer == nil) dialer = [NSNull null];
    [self setObject:dialer forKey:@"CTIDialer"];
  }
  
  if (![dialer isNotNull])
    dialer = nil;
  
  return dialer;
}

- (NSString *)activeCTITelephone {
  NSUserDefaults *ud;
  NSString *clientHost;
  NSString *activePhone;

  if ((activePhone = [self objectForKey:@"CTIDialerActivePhone"]) != nil)
    return [activePhone isNotEmpty] ? activePhone : (NSString *)nil;
  
  clientHost = [[[self context] request]
                       headerForKey:@"x-webobjects-remote-host"];
  
  ud = [NSUserDefaults standardUserDefaults];
  activePhone = [[ud dictionaryForKey:@"CTIRemoteHostToDevice"]
                     objectForKey:clientHost];

#if 0
  if (![activePhone isNotEmpty]) {
    [self debugWithFormat:@"no CTI device associated with host %@",
            clientHost];
  }
#endif
  
  return activePhone;
}

- (BOOL)canDialNumber:(NSString *)_number {
  if (![_number isNotEmpty]) {
    //[self debugWithFormat:@"can't dial empty number ..."];
    return NO;
  }
  
  if (![[self activeCTITelephone] isNotEmpty]) {
    if ([self isDebuggingEnabled]) {
      if (![[self objectForKey:@"DidLogCTI"] boolValue]) {
        [self debugWithFormat:@"no CTI device associated with session ..."];
        [self setObject:[NSNumber numberWithBool:YES] forKey:@"DidLogCTI"];
      }
    }
    return NO;
  }
  
  if (![[self dialer] canDialNumber:_number]) {
    [self debugWithFormat:@"CTI dialer cannot dialer number '%@' ...",_number];
    return NO;
  }
  return YES;
}

- (BOOL)dialNumber:(NSString *)_number {
  NSString *phone;
  
  phone = [self activeCTITelephone];
  if (![phone isNotEmpty])
    return NO;
  if (![self canDialNumber:_number])
    return NO;

  [self logWithFormat:@"CTI device '%@': dialing '%@' ..",
          phone, _number];
  
  return [[self dialer] dialNumber:_number fromDevice:phone];
}

@end /* WOSession */
