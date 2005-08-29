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

#include "common.h"
#include <OGoFoundation/OGoSession.h>

// DEPRECATED: we are OpenSource now :-)
/*
  Still used in:
  
  find . -type f -name "*.wod" -exec grep -l SkyLicenseConditional \{\} \;
    EnterprisesUI/SkyEnterpriseProjectList.wod
    EnterprisesUI/SkyEnterpriseAttributesEditor.wod
    EnterprisesUI/SkyWizardEnterpriseViewer.wod
    EnterprisesUI/SkyEnterpriseEditor.wod
    LSWScheduler/SkyAppointmentPrintViewer.wod
    JobUI/SkyAssignProjectToJobEditor.wod
    NewsUI/LSWNewsArticleViewer.wod
    NewsUI/LSWNewsArticleEditor.wod
    NewsUI/SkyNewsPreferences.wod
*/

@interface SkyLicenseConditional : WODynamicElement
{
@protected
  // WODynamicElement: extraAttributes
  // WODynamicElement: otherTagString
  WOElement *template;
}

@end /* SkyLicenseConditional */

#include <LSFoundation/LSCommandContext.h>

@implementation SkyLicenseConditional

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_c
{
  if ((self = [super initWithName:_name associations:_config template:_c])) {
    self->template  = [_c retain];
  }
  return self;
}

- (void)dealloc {
  [self->template release];
  [super dealloc];
}

/* accessors */

- (id)template {
  return self->template;
}

/* handle requests */

- (void)takeValuesFromRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  [self->template takeValuesFromRequest:_rq inContext:_ctx];
}

- (id)invokeActionForRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  return [self->template invokeActionForRequest:_rq inContext:_ctx];
}

/* generate response */

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  [self->template appendToResponse:_response inContext:_ctx];
}

/* description */

- (NSString *)associationDescription {
  NSMutableString *str = [NSMutableString stringWithCapacity:128];
  
  if (self->template != nil)
    [str appendFormat:@" template=%@",  self->template];
  return str;
}

@end /* SkyLicenseConditional */
