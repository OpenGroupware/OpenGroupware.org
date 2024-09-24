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

#include "LSWPartBodyViewer.h"

@interface LSWMessageRfc822BodyViewer : LSWPartBodyViewer
@end

#include "LSWMimePartViewer.h"
#include <NGMail/NGMimeMessageParser.h>
#include "common.h"

/*
  The body of this class has to be of type 'NGMimeMessage' !
*/

@implementation LSWMessageRfc822BodyViewer

- (id)activateObject:(id)_obj verb:(NSString *)_verb type:(NGMimeType *)_type {
  if ([_obj isKindOfClass:[NSString class]]) {
    [self debugWithFormat:
            @"WARNING: got rfc822 message as an NSString object !"];
    _obj = [_obj dataUsingEncoding:NSISOLatin1StringEncoding];
  }
  
  if ([_obj isKindOfClass:[NSData class]]) {
    NGMimeMessageParser *parser;
    NSAutoreleasePool   *pool;
    id message;
    
    pool = [[NSAutoreleasePool alloc] init];
    parser = [[NGClassFromString(@"NGMimeMessageParser") alloc] init];
    message = [[parser parsePartFromData:_obj] retain];
    [parser release]; parser = nil;
    [pool release]; pool = nil;
    _obj = [message autorelease];
  }
  return [super activateObject:_obj verb:_verb type:_type];
}

- (WOComponent *)partViewerComponent {
  NSString *pageName;
  id page;

  pageName = [[self session] viewerComponentForPart:[self body]];
  page     = [self pageWithName:pageName];
  
  [page setSource:[self source]];
  
  return page;
}

@end /* LSWMessageRfc822BodyViewer */
