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

#ifndef __LSWebInterface_LSWFoundation_LSWMimeContent_H__
#define __LSWebInterface_LSWFoundation_LSWMimeContent_H__

#import <Foundation/NSObject.h>

@class NSData;
@class NGMimeType;
@class WOContext, WOResponse;

@interface LSWMimeContent : NSObject
{
@protected
  WOContext  *context;
  NGMimeType *type;
  NSData     *content;
  NSString   *contentDisposition;
}

+ (id)mimeContent:(NSData *)_data
  ofType:(NGMimeType *)_type
  inContext:(WOContext *)_ctx;

+ (id)mimeContent:(NSData *)_data
  ofType:(NGMimeType *)_type
  contentDisposition:(NSString *)_cd
  inContext:(WOContext *)_ctx;

// accessors

- (NSData *)content;
- (NGMimeType *)type;

// response

- (WOResponse *)generateResponse;
- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx;

@end

#endif /* __LSWebInterface_LSWFoundation_LSWMimeContent_H__ */
