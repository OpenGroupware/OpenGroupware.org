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

#include "UIxMailRenderingContext.h"
#include <SoObjects/Mailer/SOGoMailObject.h>
#include "common.h"

@implementation UIxMailRenderingContext

- (id)initWithViewer:(WOComponent *)_viewer context:(WOContext *)_ctx {
  if ((self = [super init])) {
    self->viewer  = _viewer;
    self->context = _ctx;
  }
  return self;
}
- (id)init {
  return [self initWithViewer:nil context:nil];
}

- (void)dealloc {
  [self->alternativeViewer release];
  [self->mixedViewer   release];
  [self->textViewer    release];
  [self->imageViewer   release];
  [self->linkViewer    release];
  [self->messageViewer release];
  [super dealloc];
}

/* resetting state */

- (void)reset {
  [self->flatContents      release]; self->flatContents      = nil;
  [self->alternativeViewer release]; self->alternativeViewer = nil;
  [self->mixedViewer       release]; self->mixedViewer       = nil;
  [self->textViewer        release]; self->textViewer        = nil;
  [self->imageViewer       release]; self->imageViewer       = nil;
  [self->linkViewer        release]; self->linkViewer        = nil;
  [self->messageViewer     release]; self->messageViewer     = nil;
}

/* fetching */

- (NSDictionary *)flatContents {
  if (self->flatContents != nil)
    return [self->flatContents isNotNull] ? self->flatContents : nil;
  
  self->flatContents =
    [[[self->viewer clientObject] fetchPlainTextParts] retain];
  [self debugWithFormat:@"CON: %@", self->flatContents];
  return self->flatContents;
}

- (NSData *)flatContentForPartPath:(NSArray *)_partPath {
  NSString *pid;
  
  pid = _partPath ? [_partPath componentsJoinedByString:@"."] : @"";
  return [[self flatContents] objectForKey:pid];
}

/* viewer components */

- (WOComponent *)mixedViewer {
  if (self->mixedViewer == nil) {
    self->mixedViewer =
      [[self->viewer pageWithName:@"UIxMailPartMixedViewer"] retain];
  }
  return self->mixedViewer;
}

- (WOComponent *)alternativeViewer {
  if (self->alternativeViewer == nil) {
    self->alternativeViewer =
      [[self->viewer pageWithName:@"UIxMailPartAlternativeViewer"] retain];
  }
  return self->alternativeViewer;
}

- (WOComponent *)textViewer {
  if (self->textViewer == nil) {
    self->textViewer = 
      [[self->viewer pageWithName:@"UIxMailPartTextViewer"] retain];
  }
  return self->textViewer;
}

- (WOComponent *)imageViewer {
  if (self->imageViewer == nil) {
    self->imageViewer = 
      [[self->viewer pageWithName:@"UIxMailPartImageViewer"] retain];
  }
  return self->imageViewer;
}

- (WOComponent *)linkViewer {
  if (self->linkViewer == nil) {
    self->linkViewer = 
      [[self->viewer pageWithName:@"UIxMailPartLinkViewer"] retain];
  }
  return self->linkViewer;
}

- (WOComponent *)messageViewer {
  if (self->messageViewer == nil) {
    self->messageViewer = 
      [[self->viewer pageWithName:@"UIxMailPartMessageViewer"] retain];
  }
  return self->messageViewer;
}

- (WOComponent *)viewerForBodyInfo:(id)_info {
  NSString *mt, *st;

  mt = [[_info valueForKey:@"type"]    lowercaseString];
  st = [[_info valueForKey:@"subtype"] lowercaseString];
  
  if ([mt isEqualToString:@"multipart"]) {
    if ([st isEqualToString:@"mixed"])
      return [self mixedViewer];
    if ([st isEqualToString:@"signed"]) // TODO: temporary workaround
      return [self mixedViewer];
    if ([st isEqualToString:@"alternative"])
      return [self alternativeViewer];
  }
  else if ([mt isEqualToString:@"text"]) {
    if ([st isEqualToString:@"plain"])
      return [self textViewer];
    if ([st isEqualToString:@"html"])
      return [self textViewer]; // TODO: temporary workaround
  }
  else if ([mt isEqualToString:@"image"])
    return [self imageViewer];
  else if ([mt isEqualToString:@"message"] && [st isEqualToString:@"rfc822"])
    return [self messageViewer];
  else if ([mt isEqualToString:@"application"]) {
    /*
      octet-stream (generate download link?, autodetect type?)
      pgp-viewer
    */
  }

  // TODO: always fallback to octet viewer?!
#if 0
  [self errorWithFormat:@"found no viewer for MIME type: %@/%@", mt, st];
#endif
  return [self linkViewer];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return NO;
}

@end /* UIxMailRenderingContext */
