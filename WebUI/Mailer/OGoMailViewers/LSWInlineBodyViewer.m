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
#include <NGObjWeb/WEClientCapabilities.h>
#include "common.h"

@implementation LSWInlineBodyViewer

- (BOOL)isDownloadable {
  return YES;
}

- (NSData *)data {
  return self->body;
}

- (NSString *)mimeType {
  NGMimeType *type = nil;
  NSString   *t    = nil;
  NSString   *st   = nil;
  
  type = [self->partOfBody contentType];
  t    = [type type];
  st   = [type subType];
  
  if (type)
    return [NSString stringWithFormat:@"%@/%@", t ? t : @"*", st ? st : @"*"];
  
  return nil;
}

- (id)mimeContent {
  return [LSWMimeContent mimeContent:[self data]
                         ofType:[self->partOfBody contentType]
                         inContext:[self context]];
}


- (NSString *)fileName {
  NSString                            *fn;
  NGMimeType                          *type;
  NGMimeContentDispositionHeaderField *disp;
  
  type = [self->partOfBody contentType];

  if ((fn = [[type parametersAsDictionary] objectForKey:@"name"]))
    return fn;

  disp = [[self->partOfBody
               valuesOfHeaderFieldWithName:@"content-disposition"] nextObject];
  
  if ((fn = [disp filename]))
    return fn;

  return nil;
}

- (BOOL)isIE5 {
  return [[[[self context] request] clientCapabilities] isInternetExplorer5];
}
- (BOOL)useIFrame {
  return [[[[self context] request] clientCapabilities] isIFrameBrowser];
}

- (BOOL)isAudio {
  return [[[self->partOfBody contentType] type]
                             isEqualToString:@"audio"] ? YES : NO;
}
- (BOOL)isVideo {
  return [[[self->partOfBody contentType] type]
                             isEqualToString:@"video"] ? YES : NO;
}

- (id)width {
  id ud;
  NSString *str;

  ud = [[self session] userDefaults];
  
  if ([self isVideo])
    str = [ud stringForKey:@"sky_embed_inline_viewer_video_width"];
  else if ([self useIFrame]) 
    str = [ud stringForKey:@"sky_embed_inline_viewer_ie5_width"];
  else
    str = [ud stringForKey:@"sky_embed_inline_viewer_other_width"];

  if (![str length])
    str = @"100%";

  return str;
}

- (id)height {
  id ud;
  NSString *str;
  

  ud = [[self session] userDefaults];
  
  if ([self isAudio])
    str = [ud stringForKey:@"sky_embed_inline_viewer_audio_height"];
  else if ([self isVideo])
    str = [ud stringForKey:@"sky_embed_inline_viewer_video_height"];
  else if ([self useIFrame]) 
    str = [ud stringForKey:@"sky_embed_inline_viewer_ie5_height"];
  else
    str = [ud stringForKey:@"sky_embed_inline_viewer_other_height"];

  if (![str length])
    str = @"400";

  return str;
}

- (BOOL)showInline {
  NGMimeType *t;
  id         ud;

  ud = [[self session] userDefaults];
  t  = [self->partOfBody contentType];

  if ([[t type] isEqualToString:@"text"] &&
      [[t subType] isEqualToString:@"html"] &&
      [ud boolForKey:@"mail_showHtmlMailTextInline"])
    return YES;
    
  return [ud boolForKey:@"mail_viewAttachmentsInline"];
}

@end /* LSWInlineBodyViewer */

