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

@class WOAssociation;

/*
  DEPRECATED!
  
  Used by LSWTableView.wo and LSWObjectViewer.wo.
  
  This element is deprecated and should not be used in new components.
*/

@interface LSWTableViewCell : WODynamicElement
{
  WOAssociation *valueColor; /* the color of the value string     */
  WOAssociation *isItem;     /* is the value a set of values ?    */
  WOAssociation *disabled;   /* is the action disabled ?          */
  WOAssociation *action;     /* the name of the action            */
  WOAssociation *href;       /* a link for a hyperlink            */
  WOAssociation *target;     /* target                            */
  WOAssociation *icon;       /* an icon associated with the value */
  WOAssociation *iconLabel;  /* the ALT of the icon               */
  
  WOAssociation *value;      /* the value                         */
  WOAssociation *formatter;  /* a formatter for the value         */
  WOAssociation *onClick;    /* action to execute on click        */
  WOAssociation *onMailTo;   /* send mail in internal mailer      */

  WOAssociation *isInternalMailEditor; /* is internal MailEditor available?  */
}

@end

#include "LSWTableView.h"
#include "common.h"

@implementation LSWTableViewCell

static NSString *SkyExternalLinkAction = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  if (SkyExternalLinkAction == nil)
    SkyExternalLinkAction = [[ud stringForKey:@"SkyExternalLinkAction"] copy];
}

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_subs
{
  if ((self = [super initWithName:_name associations:_config template:_subs])) {
    self->valueColor = OWGetProperty(_config, @"valueColor");
    self->isItem     = OWGetProperty(_config, @"isItem");
    self->disabled   = OWGetProperty(_config, @"disabled");
    self->action     = OWGetProperty(_config, @"action");
    self->href       = OWGetProperty(_config, @"href");
    self->target     = OWGetProperty(_config, @"target");
    self->icon       = OWGetProperty(_config, @"icon");
    self->iconLabel  = OWGetProperty(_config, @"iconLabel");
    self->value      = OWGetProperty(_config, @"value");
    self->formatter  = OWGetProperty(_config, @"formatter");
    self->onClick    = OWGetProperty(_config, @"onClick");
    self->onMailTo   = OWGetProperty(_config, @"onMailTo");
    
    self->isInternalMailEditor = 
      OWGetProperty(_config, @"isInternalMailEditor");
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->onClick);
  RELEASE(self->target);
  RELEASE(self->value);
  RELEASE(self->formatter);
  RELEASE(self->valueColor);
  RELEASE(self->isItem);
  RELEASE(self->disabled);
  RELEASE(self->action);
  RELEASE(self->href);
  RELEASE(self->icon);
  RELEASE(self->iconLabel);
  RELEASE(self->onMailTo);
  [super dealloc];
}

/* responder */

- (id)invokeActionForRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  WOComponent *sComponent;
  NSString    *sHref;
  BOOL        isHrefLink;
  
  sComponent = [_ctx component];
  sHref      = [self->href stringValueInComponent:sComponent];
  isHrefLink = sHref ? YES : NO;

  if (isHrefLink && ([sHref hasPrefix:@"mailto:"])) {
    if (self->onMailTo == nil)
      NSLog(@"WARNING: %s onMailTo not defined !", __PRETTY_FUNCTION__);
    
    return [self->onMailTo valueInComponent:[_ctx component]];
  }
  if (self->onClick == nil)
    NSLog(@"WARNING: %s onClick not defined !", __PRETTY_FUNCTION__);

  return [self->onClick valueInComponent:[_ctx component]];
}

- (void)appendTextValue:(id)obj toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx formatter:(NSFormatter *)fmt
{
  NSArray  *lines;
  unsigned i, count;
  
  if (fmt) {
    NSString *fmtObj;

    if ((fmtObj = [fmt stringForObjectValue:obj]))
      obj = fmtObj;
  }

  /* make a string value out of object & insert BR's */
  if (obj == nil)
    return;
  
  if (![obj isKindOfClass:[NSString class]])
    obj = [obj stringValue];
  
  if (obj == nil)
    return;
  
  lines = [obj componentsSeparatedByString:@"\n"];
  for (i = 0, count = [lines count]; i < count; i++) {
    NSString *line = [lines objectAtIndex:i];
    
    if (i != 0) [_response appendContentString:@"<br />"];
    [_response appendContentHTMLString:line];
  }
}

- (void)appendIcon:(NSString *)_icon label:(NSString *)_iconLabel
  toResponse:(WOResponse *)_response inContext:(WOContext *)_ctx
{
  NSString *uFi;
  
  uFi = [[[_ctx application] resourceManager]
                urlForResourceNamed:_icon
                inFramework:nil
                languages:[[_ctx session] languages]
                request:[_ctx request]];
  if (uFi == nil) {
    NSLog(@"%@: did not find resource %@", self, _icon);
    uFi = _icon;
  }

  [_response appendContentString:@"<img border=\"0\" src=\""];
  [_response appendContentHTMLAttributeValue:uFi];
  [_response appendContentCharacter:'"'];
  
  if (_iconLabel) {
    [_response appendContentString:@" alt=\""];
    [_response appendContentHTMLAttributeValue:_iconLabel];
    [_response appendContentCharacter:'"'];
  }
  
  [_response appendContentString:
               @" onMouseOver="
               @"\"window.status='show object'; return true\""
               @" onMouseOut="
               @"\"window.status='OGo'; return true\""];
  [_response appendContentString:@" />"];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  WOComponent *sComponent = [_ctx component];
  NSString    *sHref, *sIcon, *sAction, *sTarget;
  BOOL        sDisabled, sIsItem, sIsInternal, hasImage;
  BOOL        isActionLink, isHrefLink;
  NSFormatter *fmt = nil;

  sHref        = [self->href     stringValueInComponent:sComponent];
  sAction      = [self->action   stringValueInComponent:sComponent];
  sIcon        = [self->icon     stringValueInComponent:sComponent];
  sTarget      = [self->target   stringValueInComponent:sComponent];
  sDisabled    = [self->disabled boolValueInComponent:sComponent];
  sIsItem      = [self->isItem   boolValueInComponent:sComponent];
  sIsInternal  = [self->isInternalMailEditor boolValueInComponent:sComponent];  
  isActionLink = (sAction && !sDisabled) ? YES : NO;
  isHrefLink   = sHref ? YES : NO;
  hasImage     = sIcon ? YES : NO;

  if ((isActionLink == NO) && (isHrefLink == YES) &&
      ([sHref hasPrefix:@"mailto:"])) {
    if (sIsInternal && (self->onMailTo != nil)) {
      isActionLink = YES;
      isHrefLink   = NO;
    }
  }
  
  fmt = [self->formatter valueInComponent:sComponent];
  
  /* open anker if necessary */

  if (isActionLink || isHrefLink) {
    [_response appendContentString:@"<a href=\""];

    if (isActionLink) {    /* ActionLinkCond    */
      [_response appendContentHTMLAttributeValue:[_ctx componentActionURL]];
    }
    else if (isHrefLink) { /* HrefLinkCond      */
      if ([sTarget length] > 0) {
        // seems to be an external link
        NSString *link;
        
        link = [[NSString alloc] initWithFormat:@"%@?url=%@",
                                   SkyExternalLinkAction,
                                   [sHref stringByEscapingURL]];
        [_response appendContentHTMLAttributeValue:link];
        [link release];
      }
      else {
        [_response appendContentHTMLAttributeValue:sHref];
      }
    }
    if ([sTarget length] > 0) {
      [_response appendContentString:@"\" target=\""];
      [_response appendContentString:sTarget];
    }

    [_response appendContentCharacter:'"'];

    if (isActionLink) {
      [_response appendContentString:
                   @" onMouseOver="
                   @"\"window.status='show object'; return true\""];
    }
    [_response appendContentString:
                 @" onMouseOut="
                 @"\"window.status='OGo'; return true\""];
  
    [_response appendContentCharacter:'>'];
  }
  
  /* add anker content */

  if (hasImage) {
      [self appendIcon:sIcon
            label:[self->iconLabel stringValueInComponent:sComponent]
            toResponse:_response inContext:_ctx];
  }
  else {
      NSString *txtFont = nil;
      
      if (!(isActionLink || isHrefLink || sIsItem)) {
        if ((txtFont = [self->valueColor stringValueInComponent:sComponent])) {
          [self appendFontToResponse:_response 
                color:txtFont face:nil size:nil];
        }
      }
      
      [self appendTextValue:[self->value valueInComponent:sComponent]
            toResponse:_response
            inContext:_ctx
            formatter:fmt];

      if (txtFont) [_response appendContentString:@"</font>"];
  }
    
  /* close anker if necessary */

  if (isActionLink || isHrefLink)
    [_response appendContentString:@"</a>"];
}

@end /* LSWTableViewCell */
