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

#include <SOGoUI/UIxComponent.h>

@interface UIxMailView : UIxComponent
{
  id currentAddress;
}

- (BOOL)isDeletableClientObject;

@end

#include "UIxMailRenderingContext.h"
#include "WOContext+UIxMailer.h"
#include <SoObjects/Mailer/SOGoMailObject.h>
#include <NGImap4/NGImap4Envelope.h>
#include <NGImap4/NGImap4EnvelopeAddress.h>
#include "common.h"

@implementation UIxMailView

- (void)dealloc {
  [self->currentAddress release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self->currentAddress release]; self->currentAddress = nil;
  [super sleep];
}

/* accessors */

- (void)setCurrentAddress:(id)_addr {
  ASSIGN(self->currentAddress, _addr);
}
- (id)currentAddress {
  return self->currentAddress;
}

- (NSString *)objectTitle {
  return [[self clientObject] subject];
}
- (NSString *)panelTitle {
  NSString *s;
  
  s = [self labelForKey:@"View Mail"];
  s = [s stringByAppendingString:@": "];
  s = [s stringByAppendingString:[self objectTitle]];
  return s;
}

/* links (DUP to UIxMailPartViewer!) */

- (NSString *)linkToEnvelopeAddress:(NGImap4EnvelopeAddress *)_address {
  // TODO: make some web-link, eg open a new compose panel?
  return [@"mailto:" stringByAppendingString:[_address baseEMail]];
}

- (NSString *)currentAddressLink {
  return [self linkToEnvelopeAddress:[self currentAddress]];
}

/* fetching */

- (id)message {
  return [[self clientObject] fetchCoreInfos];
}

- (BOOL)hasCC {
  return [[[self clientObject] ccEnvelopeAddresses] count] > 0 ? YES : NO;
}

/* viewers */

- (id)contentViewerComponent {
  // TODO: I would prefer to flatten the body structure prior rendering,
  //       using some delegate to decide which parts to select for alternative.
  id info;
  
  info = [[self clientObject] bodyStructure];
  return [[[self context] mailRenderingContext] viewerForBodyInfo:info];
}

/* actions */

- (id)defaultAction {
  if ([self message] == nil) {
    return [NSException exceptionWithHTTPStatus:404 /* Not Found */
			reason:@"did not find specified message!"];
  }
  return self;
}

- (BOOL)isDeletableClientObject {
  return [[self clientObject] respondsToSelector:@selector(delete)];
}
- (BOOL)isInlineViewer {
  return NO;
}

- (id)deleteAction {
  NSException *ex;
  
  if (![self isDeletableClientObject]) {
    return [NSException exceptionWithHTTPStatus:400 /* Bad Request */
                        reason:@"method cannot be invoked on "
                               @"the specified object"];
  }
  
  if ((ex = [[self clientObject] delete]) != nil) {
    // TODO: improve error handling
    [self debugWithFormat:@"failed to delete: %@", ex];
    return ex;
  }
  
  if (![self isInlineViewer]) {
    // if everything is ok, close the window (send a JS closing the Window)
    id page;
    
    page = [self pageWithName:@"UIxMailWindowCloser"];
    [page takeValue:@"YES" forKey:@"refreshOpener"];
    return page;
  }
  else {
    id url;

    url = [[[self clientObject] container] baseURLInContext:[self context]];
    return [self redirectToLocation:url];
  }
}

- (id)getMailAction {
  // TODO: we might want to flush the caches?
  return [self redirectToLocation:@"view"];
}

/* generating response */

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  UIxMailRenderingContext *mctx;

  mctx = [[UIxMailRenderingContext alloc] initWithViewer:self context:_ctx];
  [_ctx pushMailRenderingContext:mctx];
  [mctx release];
  
  [super appendToResponse:_response inContext:_ctx];
  
  [[_ctx popMailRenderingContext] reset];
}

@end /* UIxMailView */
