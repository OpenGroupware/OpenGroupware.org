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

#include <NGObjWeb/WODynamicElement.h>

@class NSString;
@class WOAssociation, WOElement, WOContext;

/*
  SkyObjectField
  
  Note: this is used by SkyCompanyAttributesViewer.
*/

@interface SkyObjectField : WODynamicElement
{
  WOAssociation *object;
  WOAssociation *attributes;
  WOAssociation *labels;
  WOAssociation *action;

  WOElement     *template;
}
- (NSString *)_attributeValueInContext:(WOContext *)_ctx;
@end

#include <OGoFoundation/WOComponent+config.h>
#include <LSFoundation/LSCommandContext.h>
#include "common.h"

@interface NSObject(MailEditor)
- (void)setContentWithoutSign:(NSString *)_str;
- (void)addReceiver:(id)_receiver type:(NSString *)_rcvType;
@end

@implementation SkyObjectField

static NSString *ZIDELOOK_MARKER = @"ZideLook rich-text compressed comment:";
static NSString *SkyExternalLinkAction = nil;
static NSString *tlink = @"<a href=\"%@\" target=\"_new\">";

+ (int)version {
  return [super version] + 0;
}
+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  if (SkyExternalLinkAction == nil)
    SkyExternalLinkAction = [[ud stringForKey:@"SkyExternalLinkAction"] copy];
}

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_t 
{
  if ((self = [super initWithName:_name associations:_config template:_t])) {

    self->object     = OWGetProperty(_config, @"object");
    self->attributes = OWGetProperty(_config, @"attributes");
    self->labels     = OWGetProperty(_config, @"labels");
    self->action     = OWGetProperty(_config, @"action");

    self->template = [_t retain];
  }
  return self;
}

- (void)dealloc {
  [self->object     release];
  [self->attributes release];
  [self->labels     release];
  [self->action     release];
  [super dealloc];
}

/* configs */

- (NSDictionary *)labelsInContext:(WOContext *)_ctx {
  return [self->labels valueInComponent:[_ctx component]];
}

- (NSDictionary *)_attributesDictInContext:(WOContext *)_ctx {
  return [self->attributes valueInComponent:[_ctx component]];
}

- (NSString *)keyAttributeInContext:(WOContext *)_ctx {
  NSDictionary *attrib;
  attrib = [self _attributesDictInContext:_ctx];
  return [[attrib valueForKey:@"key"] stringValue];
}

- (NSString *)relKeyAttributeInContext:(WOContext *)_ctx {
  NSDictionary *attrib;
  attrib = [self _attributesDictInContext:_ctx];
  return [[attrib valueForKey:@"relKey"] stringValue];
}

- (NSString *)localizeValueAttribute:(NSString *)_value
  inContext:(WOContext *)_ctx{
  return [[self labelsInContext:_ctx] valueForKey:_value];
}

- (NSString *)calFormatAttributeInContext:(WOContext *)_ctx {
  NSDictionary *attrib;
  attrib = [self _attributesDictInContext:_ctx];
  return [[attrib valueForKey:@"calendarFormat"] stringValue];
}

- (BOOL)isHrefInContext:(WOContext *)_ctx {
  NSDictionary *attrib;
  
  attrib = [self _attributesDictInContext:_ctx];
  return ([attrib valueForKey:@"href"] != nil) ? YES : NO;
}

- (NSString *)hrefAttributeInContext:(WOContext *)_ctx {
  NSString     *tmp;
  NSDictionary *attrib;

  if (![self isHrefInContext:_ctx]) return nil;

  attrib = [self _attributesDictInContext:_ctx];
  tmp = [[attrib valueForKey:@"href"] stringValue];

  return ([tmp isEqualToString:@""])
    ? [self _attributeValueInContext:_ctx]
    : tmp;
}

- (BOOL)isEMailTypeInContext:(WOContext *)_ctx {
  id           ttype;
  NSDictionary *attrib;
  attrib = [self _attributesDictInContext:_ctx];
  ttype = [attrib valueForKey:@"type"];
  return ([ttype intValue] == 3) ? YES : NO;
}

- (BOOL)hasTargetInContext:(WOContext *)_ctx {
  NSDictionary *attrib;
  attrib = [self _attributesDictInContext:_ctx];
  return ([attrib valueForKey:@"target"] != nil) ? YES : NO; 
}


- (NSString *)_localizeKeyValue:(id)_value attribute:(id)_attribute
  inContext:(WOContext *)_ctx
{
  NSString *labelKey;
  
  labelKey = [_attribute valueForKey:@"key"];
  labelKey = [labelKey stringByAppendingString:@"_"];
  labelKey = [labelKey stringByAppendingString:[_value description]];
  
  return [[_attribute valueForKey:@"localizeKey"] boolValue]
    ? [self localizeValueAttribute:labelKey inContext:_ctx]
    : [labelKey stringValue];
}
- (NSString *)_attributeValueInContext:(WOContext *)_ctx {
  id           tmp;
  NSArray      *ak; /* all keys */
  NSString     *ret;
  NSDictionary *attrib;
  id           obj;

  attrib = [self _attributesDictInContext:_ctx];

  ak  = [attrib allKeys];
  obj = [self->object valueInComponent:[_ctx component]];
  tmp = [obj valueForKey:[self keyAttributeInContext:_ctx]];

  if (![tmp isNotNull])
    ret = @"";

  else if ([ak containsObject:@"relKey"])
    ret = [tmp valueForKey:[self relKeyAttributeInContext:_ctx]];
  
  else if ([ak containsObject:@"localizeValue"]) {
    ret = ([[attrib valueForKey:@"localizeValue"] boolValue])
      ? [self localizeValueAttribute:[tmp stringValue] inContext:_ctx]
      : [tmp stringValue];
  }
  else if ([ak containsObject:@"localizeKey"])
    ret = [self _localizeKeyValue:tmp attribute:attrib inContext:_ctx];
  else if ([ak containsObject:@"calendarFormat"]) {
    ret = ([tmp isKindOfClass:[NSCalendarDate class]])
      ? [tmp descriptionWithCalendarFormat:
             [self calFormatAttributeInContext:_ctx]]
      : [tmp stringValue];
  }
  else
    ret = [tmp stringValue];
  
  return ret;
}

- (BOOL)isMailEditorInContext:(WOContext *)_ctx {
  WOComponent      *comp  = nil;
  OGoSession       *sn    = nil;
  LSCommandContext *cctx  = nil;
  NGBundleManager  *bm    = nil;
  NSString         *eType = nil;


  comp  = [_ctx component];
  sn    = (OGoSession *)[comp session];
  cctx  = [sn commandContext];
  bm    = [NGBundleManager defaultBundleManager];
  eType = [[sn userDefaults] objectForKey:@"mail_editor_type"];

  if (![eType isEqualToString:@"internal"])
    return NO;

  return [bm bundleProvidingResource:@"LSWImapMailEditor"
	     ofType:@"WOComponents"] != nil;
}

/* processing requests */

- (id)invokeActionForRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  WOComponent *comp;
  id          mailEditor;
  NSString    *keyAttr, *type;
  
  if (!([self isEMailTypeInContext:_ctx] && [self isMailEditorInContext:_ctx]))
    /* not an active element */
    return nil;
    
  comp       = [_ctx component];
  mailEditor = [[comp application] pageWithName:@"LSWImapMailEditor"];
  keyAttr    = [self keyAttributeInContext:_ctx];
    
  type = ([keyAttr isEqualToString:@"email2"])
    ? @"to:email2"
    : @"to";
    
  if (mailEditor != nil) {
    [(id)mailEditor addReceiver:[self->object valueInComponent:comp]type:type];
    [(id)mailEditor setContentWithoutSign:@""];
    [[[comp session] navigation] enterPage:(id<OGoContentPage>)mailEditor];
    // TODO: try whether we can just return 'mailEditor' instead of -enterPage:
  }
  return nil;
}

/* generating response */

- (void)_appendLink:(NSString *)data toResponse:(WOResponse *)_res 
  inContext:(WOContext *)_ctx 
{
  // external link
  NSString *tmp;
  NSString *link;
  
  tmp  = [self hrefAttributeInContext:_ctx];
  link = SkyExternalLinkAction;
  tmp  = ([tmp isEqualToString:@""]) ? data : tmp;
  tmp  = [[[link stringValue] stringByAppendingString:@"?url="]
                 stringByAppendingString:[tmp stringByEscapingURL]];
  
  // TODO: the following looks weird! Use the proper NSString method
  tmp = [WOResponse stringByEscapingHTMLAttributeValue:tmp];
  tmp = [NSString stringWithFormat:tlink,tmp];
  
  [_res appendContentString:tmp];
}
- (void)_appendMail:(NSString *)data toResponse:(WOResponse *)_res 
  inContext:(WOContext *)_ctx 
{
  NSString *tmp;
  
  if ([self isMailEditorInContext:_ctx]) {
    [_res appendContentString:@"<a href=\""];
    [_res appendContentHTMLAttributeValue:[_ctx componentActionURL]];
    [_res appendContentString:@"\">"];
    return;
  }

  tmp = [@"mailto:" stringByAppendingString:
            [WOResponse stringByEscapingHTMLAttributeValue:data]];
  tmp = [NSString stringWithFormat:tlink,tmp];
  
  [_res appendContentString:tmp];
}

- (void)_appendValue:(NSString *)data toResponse:(WOResponse *)_res 
  inContext:(WOContext *)_ctx 
{
  NSArray *sepData;
  int     i, cnt;

  /* avoid output of ZideLook richtext fields (base64 encoded content) */
  if ([data hasPrefix:ZIDELOOK_MARKER]) {
    // TODO: localize warning
    [_res appendContentString:@"<i>"];
    [_res appendContentString:@"Binary Outlook content (hidden)"];
    [_res appendContentString:@"</i>"];
    return;
  }
    
  sepData = [data componentsSeparatedByString:@"\n"];
  for (i = 0, cnt = [sepData count]; i < cnt; i++) {
    NSString *s;
    
    if (i > 0)
      [_res appendContentString:@"<br />"];
    
    s = [sepData objectAtIndex:i];
    [_res appendContentHTMLString:s];
  }
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  NSString *data;
  BOOL     closeAnker;
  
  data       = [self _attributeValueInContext:_ctx];
  closeAnker = NO;
  
  if ((closeAnker = [self isHrefInContext:_ctx]))
    [self _appendLink:data toResponse:_response inContext:_ctx];
  else if ((closeAnker = [self isEMailTypeInContext:_ctx]))
    [self _appendMail:data toResponse:_response inContext:_ctx];
  
  [self _appendValue:data toResponse:_response inContext:_ctx];
  
  if (closeAnker) [_response appendContentString:@"</a>"];
  
  /* this seems to be intentional */
  
  [self->template appendToResponse:_response inContext:_ctx];
}

@end /* SkyObjectField */
