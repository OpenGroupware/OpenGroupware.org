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

#include "SkyJSSendMail.h"
#include <NGObjWeb/WOMailDelivery.h>
#include "common.h"

@implementation SkyJSSendMail

static BOOL debugDealloc = NO;

- (void)dealloc {
  if (debugDealloc)
    NSLog(@"%s: dealloc JS sendmail 0x%p ..", __PRETTY_FUNCTION__, self);
  
  [self->subject release];
  [self->from    release];
  [self->to      release];
  [self->body    release];
  [self->cc      release];
  [super dealloc];
}

- (id)_jsprop_From:(id)_value {
  ASSIGNCOPY(self->from, _value);
  return self;
}
- (id)_jsprop_From {
  return self->from;
}

- (id)_jsprop_To:(id)_value {
  ASSIGNCOPY(self->to, _value);
  return self;
}
- (id)_jsprop_To {
  return self->to;
}

- (id)_jsprop_Body:(id)_value {
  ASSIGNCOPY(self->body, _value);
  return self;
}
- (id)_jsprop_Body {
  return self->body;
}

- (id)_jsprop_Subject:(id)_value {
  ASSIGNCOPY(self->subject, _value);
  return self;
}
- (id)_jsprop_Subject {
  return self->subject;
}

- (id)_jsprop_Cc:(id)_value {
  ASSIGNCOPY(self->cc, _value);
  return self;
}
- (id)_jsprop_Cc {
  return self->cc;
}

/* methods */

- (id)_jsfunc_send:(NSArray *)_array {
  WOMailDelivery *mailer;
  id   mail;
  BOOL isOk = NO;

  NS_DURING {
    NSArray *tos;
    NSArray *ccs;

    tos = [self->to componentsSeparatedByString:@","];
    ccs = [self->cc componentsSeparatedByString:@","];
    
    mailer = [WOMailDelivery sharedInstance];
    
    mail = [mailer composeEmailFrom:self->from
                   to:tos cc:ccs
                   subject:self->subject
                   plainText:self->body
                   send:NO];

    if ([mailer sendEmail:mail])
      isOk = YES;
  }
  NS_HANDLER {
    fprintf(stderr, "catched %s\n", [[localException description] cString]);
    isOk = NO;
  }
  NS_ENDHANDLER;
  
  return [NSNumber numberWithBool:isOk];
}

@end /* SkyJSSendMail */
