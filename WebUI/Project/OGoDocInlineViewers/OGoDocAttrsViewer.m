/*
  Copyright (C) 2005 Helge Hess

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

#include <OGoDocInlineViewers/OGoDocPartViewer.h>

@class NSString;

@interface OGoDocAttrsViewer : OGoDocPartViewer
{
  NSString *key;
  id item;
}

@end

#include <OGoProject/SkyProject.h>
#include <OGoDatabaseProject/SkyProjectDocument.h>
#include "common.h"

@implementation OGoDocAttrsViewer

+ (BOOL)canShowInDocumentViewer:(OGoComponent *)_viewer {
  // TODO: not entirely correct, eg a Svn store has versioned properties
  if ([[_viewer valueForKey:@"isVersion"] boolValue])
    return NO;
  
  return [super canShowInDocumentViewer:_viewer];
}

- (void)dealloc {
  [self->item release];
  [self->key  release];
  [super dealloc];
}

/* notifications */

- (void)syncSleep {
  [self->item release]; self->item = nil;
  [self->key  release]; self->key  = nil;
  [super syncSleep];
}

/* accessors */

- (void)setItem:(id)_id {
  ASSIGN(self->item, _id);
}
- (id)item {
  return self->item;
}

- (void)setKey:(NSString *)_id {
  ASSIGNCOPY(self->key, _id);
}
- (NSString *)key {
  return self->key;
}

- (BOOL)hasEditAttrs {
  if (![[self fileManager] isWritableFileAtPath:[self _documentPath]])
    return NO;
  
  return YES;
}

- (BOOL)supportsProperties {
  return [(id)[self fileManager] supportsProperties];
}

- (NSString *)defaultPropertyNamespace {
  return XMLNS_PROJECT_DOCUMENT;
}

- (NSDictionary *)docStandardAttrs {
  NSString *subj;
  
  // TODO: use property?
  subj = [(id)[self document] subject];

  if (![subj isNotNull])
    subj = @"";
  
  return [NSDictionary dictionaryWithObject:subj forKey:@"subject"];
}

@end /* OGoDocAttrsViewer */
