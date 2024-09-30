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
  This element doesn't pass down -takeValues.. to it's template.
*/

@interface SkyProfileTemplate : WODynamicElement
{
  WOAssociation *profileId;
  WOElement     *template;
}

@end

#include "common.h"

#if NeXT_RUNTIME || APPLE_RUNTIME || GNUSTEP_BASE_LIBRARY
#  include <objc/objc.h>
#  define sel_get_name(__X__) sel_getName(__X__)
#endif

@interface WOContext(CStack)
- (unsigned)componentStackCount;
@end

@implementation SkyProfileTemplate

static int   profileComponents = -1;
static Class NSDateClass = Nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
  
  profileComponents = [[ud objectForKey:@"WOProfileComponents"] boolValue]?1:0;
  
  if (NSDateClass == Nil)
    NSDateClass = [NSDate class];
}

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_templ
{
  if ((self = [super initWithName:_name associations:nil template:_templ])) {
    self->template  = [_templ retain];
    self->profileId = [[_config objectForKey:@"profileId"] copy];
  }
  return self;
}

- (void)dealloc {
  [self->profileId release];
  [self->template  release];
  [super dealloc];
}

/* profiling */

static inline void
_finishprof(SkyProfileTemplate *self, SEL _cmd,
            NSTimeInterval st, WOContext *_ctx)
{
  if (profileComponents) {
    NSTimeInterval diff;
    WOComponent *child;
    int      i;
    NSString *pid;
    
    child = [_ctx component];
    pid   = [self->profileId stringValueInComponent:child];
    
    diff = [[NSDateClass date] timeIntervalSince1970] - st;
    
    for (i = [_ctx componentStackCount]; i >= 0; i--)
      printf("  ");
    
    printf("[%s %s]: ", [[child name] cString], sel_get_name(_cmd));
    
    if (pid) printf("#%s ", [pid cString]);

    printf("%0.3fs", diff);
    printf("\n");
  }
}

/* request handling */

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  NSTimeInterval st = 0.0;
  
  if (profileComponents)
    st = [[NSDateClass date] timeIntervalSince1970];
  
  [self->template takeValuesFromRequest:_req inContext:_ctx];
  
  _finishprof(self, _cmd, st, _ctx);
}

- (id)invokeActionForRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  id result;
  NSTimeInterval st = 0.0;
  
  if (profileComponents)
    st = [[NSDateClass date] timeIntervalSince1970];
  
  result = [self->template invokeActionForRequest:_req inContext:_ctx];

  _finishprof(self, _cmd, st, _ctx);
  return result;
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  NSTimeInterval st = 0.0;
  
  if (profileComponents)
    st = [[NSDateClass date] timeIntervalSince1970];
  [self->template appendToResponse:_response inContext:_ctx];
  
  _finishprof(self, _cmd, st, _ctx);
}

@end /* SkyProfileTemplate */
