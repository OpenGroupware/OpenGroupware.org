/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include "LSWPartBodyViewer.h"
#include "LSWMimePartViewer.h"
#include "common.h"

@implementation LSWMultipartAlternativeBodyViewer

static NSString *skyrixId = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  if (skyrixId == nil)
    skyrixId = [[ud objectForKey:@"skyrix_id"] copy];
  if ([skyrixId length] == 0)
    [self logWithFormat:@"WARNING: skyrix_id default is not set."];
}

- (void)dealloc {
  [self->part release];
  [super dealloc];
}

/* defaults */

- (NSArray *)viewAlternativePreferences {
  /*
    See Defaults.plist, this contains the sequence of the preferred MIME types
    (which alternative to trigger first)
  */
  NSUserDefaults *defs;
  
  defs = [[self session] userDefaults];
  return [defs objectForKey:@"SkyMailViewer_multipartAlternativePreferences"];
}

/* part processing */

- (id)urlBodyPart {
  NGMimeBodyPart   *p;
  NGMutableHashMap *map;

  map = [[NGMutableHashMap alloc] init];
  [map setObject:@"text/plain" forKey:@"content-type"];
  p = [NGMimeBodyPart bodyPartWithHeader:map];
  [map release];
  [p setBody:self->body];
  return p;
}

- (id)part {
  NSArray      *parts;
  NSString     *type;
  NSEnumerator *eTypes;
  int          pCnt;
  
  if (self->part)
    return self->part;
  
  if ([self->body isKindOfClass:[NSURL class]])
    return [self urlBodyPart];
  
  parts = (self->body != nil)
    ? [self->body parts]
    : [[self->partOfBody body] parts];
  if ([parts count] == 0) return nil;
  
  pCnt   = [parts count];
  eTypes = [[self viewAlternativePreferences] objectEnumerator];
  
  while ((type = [eTypes nextObject])) {
    int i, cnt;
      
    for (i = 0, cnt = pCnt; i < cnt; i++) {
      NGMimeType *t;
      NSString   *str;
      NSString   *mailId;
        
      if ((t = [[parts objectAtIndex:i] contentType]) == nil)
	continue;
        
      str = [[t type] stringByAppendingString:@"/"];
      str = [str stringByAppendingString:[t subType]];
      if (![str isEqualToString:type])
          continue;
        
      if (![str isEqualToString:@"multipart/skyrix"])
	break;
      if (skyrixId == nil)
	break;
	
      if ((mailId = [t valueOfParameter:@"skyrix_id"]) == nil)
	continue;
          
      if ([mailId isEqualToString:skyrixId])
	break;
      else
	/* the multipart content is from a different OGo installation */
	continue;
    }
    if (i < cnt) {
        self->part = [[parts objectAtIndex:i] retain];
        break;
    }
  }
  if (self->part == nil)
    self->part = [[parts objectAtIndex:0] retain];
    
  return self->part;
}

- (id)partViewerComponent {
  NSString *viewerName;
  id       viewer;
  
  viewerName = [[self session] viewerComponentForPart:[self part]];
  if ([viewerName length] == 0)
    return nil;
  
  viewer = [self pageWithName:viewerName];
  [viewer setSource:self->source];
  return viewer;
}

@end /* LSWMultipartAlternativeBodyViewer */
