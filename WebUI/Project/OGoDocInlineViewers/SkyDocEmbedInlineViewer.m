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

#include <OGoFoundation/OGoComponent.h>

@class NSString, NSData;
@class NGMimeType;

@interface SkyDocEmbedInlineViewer : OGoComponent
{
  NSString   *uri;
  NGMimeType *contentType;
  unsigned   contentLength;
  NSData     *data;
  NSString   *fileName;
}

- (void)setObject:(id)_object;
- (void)setContentType:(NGMimeType *)_type;

@end

#include <NGMime/NGMimeType.h>
#include "common.h"

@interface WOSession(Defs)
- (NSUserDefaults *)userDefaults;
@end

@implementation SkyDocEmbedInlineViewer

- (void)dealloc {
  [self->uri         release];
  [self->contentType release];
  [self->fileName    release];
  [self->data        release];
  [super dealloc];
}

/* activation */

- (id)activateObject:(id)_obj verb:(NSString *)_verb type:(NGMimeType *)_type {
  if (_obj == nil) {
    [self logWithFormat:
            @"missing object for activation with verb %@, type %@ ..",
           _verb, _type];
    return nil;
  }
  if (![_obj isKindOfClass:[NSData class]]) {
    [self logWithFormat:
            @"invalid object %@ for activation with verb %@, type %@ ..",
           _obj, _verb, _type];
    return nil;
  }
  
  [self setContentType:_type];
  [self setObject:_obj];
  
  return self;
}

/* accessors */

- (void)setObject:(id)_object {
  ASSIGN(self->data, _object);
  self->contentLength = [self->data length];
}
- (id)object {
  return self->data;
}

- (void)setFileName:(NSString *)_object {
  ASSIGNCOPY(self->fileName, _object);
}
- (id)fileName {
  return self->fileName;
}

- (void)setUri:(NSString *)_object {
  ASSIGNCOPY(self->uri, _object);
}
- (id)uri {
  return self->uri;
}

- (void)setContentType:(NGMimeType *)_type {
  ASSIGN(self->contentType, _type);
}
- (NGMimeType *)contentType {
  return self->contentType;
}

- (id)mimeContent {
  return [LSWMimeContent mimeContent:[self object]
                         ofType:[self contentType]
                         inContext:[self context]];
}

- (BOOL)isIE5 {
  return [[[[self context] request] clientCapabilities] isInternetExplorer5];
}
- (BOOL)useIFrame {
  return [[[[self context] request] clientCapabilities] isIFrameBrowser];
}
- (BOOL)useURI {
  return [self->uri length] > 0 ? YES : NO;
}

- (BOOL)isAudio {
  return [[[self contentType] type] isEqualToString:@"audio"] ? YES : NO;
}
- (BOOL)isVideo {
  return [[[self contentType] type] isEqualToString:@"video"] ? YES : NO;
}

- (id)width {
  id ud;

  ud = [[self session] userDefaults];
  
  if ([self isVideo])
    return [ud stringForKey:@"sky_embed_inline_viewer_video_width"];
  
  if ([self useIFrame]) 
    return [ud stringForKey:@"sky_embed_inline_viewer_ie5_width"];
  
  return [ud stringForKey:@"sky_embed_inline_viewer_other_width"];
}
- (id)height {
  id ud;

  ud = [[self session] userDefaults];
  
  if ([self isAudio])
    return [ud stringForKey:@"sky_embed_inline_viewer_audio_height"];
  
  if ([self isVideo])
    return [ud stringForKey:@"sky_embed_inline_viewer_video_height"];

  if ([self useIFrame]) 
    return [ud stringForKey:@"sky_embed_inline_viewer_ie5_height"];
  
  return [ud stringForKey:@"sky_embed_inline_viewer_other_height"];
}

@end /* SkyDocEmbedInlineViewer */
