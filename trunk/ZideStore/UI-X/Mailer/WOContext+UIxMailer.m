/*
  Copyright (C) 2004 SKYRIX Software AG

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

#include "WOContext+UIxMailer.h"
#include "UIxMailRenderingContext.h"
#include "UIxMailFormatter.h"
#include "common.h"

@implementation WOContext(UIxMailer)

// TODO: make configurable
// TODO: cache!

- (NSFormatter *)mailSubjectFormatter {
  return [[[UIxSubjectFormatter alloc] init] autorelease];
}

- (NSFormatter *)mailDateFormatter {
  return [[[UIxMailDateFormatter alloc] init] autorelease];
}

- (NSFormatter *)mailEnvelopeAddressFormatter {
  return [[[UIxEnvelopeAddressFormatter alloc] init] autorelease];
}
- (NSFormatter *)mailEnvelopeFullAddressFormatter {
  return [[[UIxEnvelopeAddressFormatter alloc] 
	    initWithMaxLength:256 generateFullEMail:YES] autorelease];
}

/* mail rendering */

static NSString *MRK = @"UIxMailRenderingContext";

- (void)pushMailRenderingContext:(UIxMailRenderingContext *)_mctx {
  [self setObject:_mctx forKey:MRK];
}
- (UIxMailRenderingContext *)popMailRenderingContext {
  UIxMailRenderingContext *mctx;
  
  if ((mctx = [self objectForKey:MRK]) == nil)
    return nil;
  
  mctx = [[mctx retain] autorelease];
  [self removeObjectForKey:MRK];
  return mctx;
}
- (UIxMailRenderingContext *)mailRenderingContext {
  return [self objectForKey:MRK];
}

@end /* WOContext(UIxMailer) */
