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

#import <Foundation/NSObject.h> // required by gstep-base
#import <Foundation/NSURLHandle.h>
#import <Foundation/NSURL.h>

@class NSDictionary, NSData;

/*
  Handles SKYRiX URLs, see SkyDocumentManager.
*/

@interface SkyURLHandle : NSURLHandle
{
  NSURL             *url;
  
  BOOL              shallCache;
  NSURLHandleStatus status;
}
@end

#include "SkyDocumentManager.h"
#include "common.h"

#ifndef LIB_FOUNDATION_LIBRARY
@interface NSObject(SubclassResp)
- (void)notImplemented:(SEL)_sel;
@end
#endif

@implementation SkyURLHandle

+ (BOOL)canInitWithURL:(NSURL *)_url {
  return [[_url scheme] isEqualToString:@"skyrix"];
}

- (id)initWithURL:(NSURL *)_url cached:(BOOL)_flag {
  if (_url == nil) {
    [self release];
    return nil;
  }
  if (![[_url scheme] isEqualToString:@"skyrix"]) {
    NSLog(@"%s: invalid URL scheme %@ for SkyURLHandle !",
          __PRETTY_FUNCTION__, [_url scheme]);
    [self release];
    return nil;
  }
  
  self->shallCache = _flag;
  self->status     = NSURLHandleNotLoaded;
  self->url        = [_url copy];
  
  [self logWithFormat:@"ERROR(%s): this method is not implemented.",
	  __PRETTY_FUNCTION__];
  return nil;
}

- (void)dealloc {
  [self->url release];
  [super dealloc];
}

/* status */

- (NSURLHandleStatus)status {
  return self->status;
}
- (NSString *)failureReason {
  if (self->status != NSURLHandleLoadFailed)
    return nil;
  
  return @"loading of SKYRiX URL failed";
}

@end /* SkyURLHandle */
