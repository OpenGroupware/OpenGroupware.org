/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include <NGObjWeb/WODynamicElement.h>

/*
 * component for external links
 * for dereffering links
 *
 * bindings:
 * href, target, string, title
 *
 * does this:
 * <a href="$externalLinkAction?url=$href" target="$target" title="$title">
 * $string<content></a>
 *
 */

@interface SkyExternalLink : WODynamicElement
{
  WOAssociation *href;
  WOAssociation *target;
  WOAssociation *string;
  WOAssociation *title;

  WOElement *template;
}

@end /* SkyExternalLink */

#include "common.h"
#include <NGExtensions/NSString+misc.h>

@implementation SkyExternalLink

static NSString *server          = nil;
static BOOL     hideInvalidLinks = NO;
static BOOL     validateLinks    = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  if (server == nil)
    server = [[ud stringForKey:@"SkyExternalLinkAction"] copy];
  
  hideInvalidLinks = [ud boolForKey:@"SkyExternalLinkHideInvalid"]  ? 1 : 0;
  validateLinks    = [ud boolForKey:@"SkyExternalLinkCheckInvalid"] ? 1 : 0;
}

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_t
{
  if ((self = [super initWithName:_name associations:_config template:_t])) {
    self->template = [_t retain];
    self->href     = OWGetProperty(_config, @"href");
    self->target   = OWGetProperty(_config, @"target");
    self->string   = OWGetProperty(_config, @"string");
    self->title    = OWGetProperty(_config, @"title");
  }
  return self;
}

- (void)dealloc {
  [self->href     release];
  [self->target   release];
  [self->string   release];
  [self->title    release];
  [self->template release];
  [super dealloc];
}

/* request processing */

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  [self->template takeValuesFromRequest:_req inContext:_ctx];
}

- (id)invokeActionForRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  return [self->template invokeActionForRequest:_req inContext:_ctx];
}

/* response generation */

- (NSString *)externalLinkAction {
  return server;
}
- (BOOL)hideInvalidLinks {
  return hideInvalidLinks ? YES : NO;
}
- (BOOL)checkIfValid {
  return validateLinks ? YES : NO;
}

/* is a valid external link? */
- (BOOL)isLinkValid:(NSString *)_link {
  if ([_link length] == 0) return NO;
  if ([self checkIfValid]) {
    NSURL *url = [NSURL URLWithString:_link];
    if ([[url host] length] == 0) {
#if 0
      NSLog(@"%s: did't find host in external link: %@",
            __PRETTY_FUNCTION__, _link);
#endif
      return NO;
    }
  }
  return YES;
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  WOComponent *comp;
  NSString    *link, *s;
  BOOL        valid;
  
  if ([[_ctx request] isFromClientComponent])
    return;

  comp  = [_ctx component];
  link  = [self->href stringValueInComponent:comp];
  valid = [self isLinkValid:link];
    
  if (valid) {
      NSDictionary *qd;
      NSString     *da;
      NSString     *ta, *ti;
      // append link
      [_response appendContentString:@"<a href=\""];

      da = [self externalLinkAction];
      // use an external server to redirect links
      if ([da length]) {
        da = [NSString stringWithFormat:@"%@?url=%@", da,
                       [link stringByEscapingURL]];
      }
      else {
        // build query dictionary for direct action
        qd = [NSDictionary dictionaryWithObjectsAndKeys:
                           link, @"url",
                           nil];
        // build direct action
        da = [_ctx directActionURLForActionNamed:@"viewExternalLink"
                   queryDictionary:qd];
      }
      [_response appendContentString:da];
      [_response appendContentString:@"\" target=\""];
      
      // appending target
      ta = [self->target stringValueInComponent:comp];
      if ([ta length] == 0) ta = @"SKYRiX External Link Frame";
      [_response appendContentString:ta];
      [_response appendContentString:@"\" title=\""];
      
      // appending title
      ti = [self->title stringValueInComponent:comp];
      if ([ti length] == 0)
        ti = [NSString stringWithFormat:@"External Link: %@", link];
      [_response appendContentString:ti];
      [_response appendContentCharacter:'\"'];

      [self appendExtraAttributesToResponse:_response inContext:_ctx];

      [_response appendContentCharacter:'>'];

      // append string
      s = [self->string stringValueInComponent:comp];
      if ([s length] > 0) [_response appendContentHTMLString:s];

      // append content
      [self->template appendToResponse:_response inContext:_ctx];
  }
  else if (![self hideInvalidLinks]) {
      s = [self->string stringValueInComponent:comp];
      if ([s length] > 0) [_response appendContentHTMLString:s];
      
  }
  
  if (valid) {
      // close link  
      [_response appendContentString:@"</a>"];
  }
}

@end /* SkyExternalLink */

#if 0 /* now implemented in Skyrix.m */
@implementation WODirectAction(SkyExternalLinkAction)
- (id<WOActionResults>)viewExternalLinkAction {
  NSString   *url      = [[self request] formValueForKey:@"url"];
  WOResponse *response = [WOResponse responseWithRequest:[self request]];

  [response appendContentString:
            @"<html><head><title>OpenGroupware.org External Link</title>\n"];  
  [response appendContentString:
            @"<meta http-equiv=\"refresh\" content=\"0; url="];
  [response appendContentString:url];
  [response appendContentString:@"\">\n"];
  [response appendContentString:@"</head></html>\n"];
  return response;
}
@end /* WODirectAction(SkyExternalLinkAction) */
#endif
