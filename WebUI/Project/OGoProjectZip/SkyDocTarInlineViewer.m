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

@class NSString, NSData, NSDictionary, NSArray, NSMutableArray;
@class NGMimeType;

@interface SkyDocTarInlineViewer : OGoComponent 
{
  NSString       *uri;
  NGMimeType     *contentType;
  NSData         *data;
  int            contentLength;
  NSString       *fileName;
  BOOL           showTarInfo;
  NSArray        *infoList;
  NSDictionary   *infoItem;
  id             fileManager;
  NSMutableArray *excludeList; /* apparently non-retained */
  BOOL           onlyInfo;
}

- (void)setObject:(id)_object;
- (void)setContentType:(NGMimeType *)_type;
- (void)setFileManager:(id)_fm;
- (id)fileManager;

- (void)setExclude:(BOOL)_excl;
- (BOOL)exclude;

@end

#include "NGFileManagerTarTool.h"
#include "common.h"

@implementation SkyDocTarInlineViewer

- (id)init {
  if ((self = [super init])) {
    self->excludeList = [[[self context] page] valueForKey:@"excludeList"];
    if ([self->excludeList isKindOfClass:[NSMutableArray class]]) {
      // TODO: WTF??? this looks very broken?
      // everything ok, list already exists ...
    }
    else {
      [self->excludeList release];
      self->excludeList = [[NSMutableArray alloc] initWithCapacity:8];
      [[[self context] page] takeValue:self->excludeList
                             forKey:@"excludeList"];
    }
    self->onlyInfo = NO;
  }
  return self;
}

- (void)dealloc {
  [self->uri         release];
  [self->contentType release];
  [self->data        release];
  [self->fileName    release];
  [self->infoList    release];
  [super dealloc];
}

/* activation */

- (BOOL)prepareForActivationCommand:(NSString *)_verb
  type:(NGMimeType *)_type
  object:(id)_object
{
  [self setContentType:_type];
  [self setObject:_object];
  return YES;
}

/* accessors */

- (void)setFileManager:(id)_fm {
  ASSIGN(self->fileManager, _fm);
}
- (id)fileManager {
  return self->fileManager;
}

- (void)setObject:(id)_object {
  ASSIGN(self->data, _object);
  self->contentLength = [self->data length];
}
- (id)object {
  return self->data;
}

- (void)setUri:(NSString *)_object {
  ASSIGNCOPY(self->uri, _object);
}
- (id)uri {
  return self->uri;
}

- (void)setFileName:(NSString *)_object {
  ASSIGNCOPY(self->fileName, _object);
  self->contentLength = [self->data length];
}
- (id)fileName {
  return self->fileName;
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

- (BOOL)useURI {
  return [self->uri length] > 0 ? YES : NO;
}

- (void)setTarVisibility:(BOOL)_vis {
  NSNumber *n;
  
  n = [NSNumber numberWithBool:_vis];
  [[[self context] page] takeValue:n forKey:@"tarVisibility"];
}
- (BOOL)tarVisibility {
  return [[[[self context] page] valueForKey:@"tarVisibility"] boolValue];
}

- (NSArray *)infoList {
  NGFileManagerTarInfo *tarInfo = nil;
  
  if (self->infoList)
    return self->infoList;

  tarInfo = [[NGFileManagerTarInfo alloc] init];
  [tarInfo setFileManager:[self fileManager]];
  self->infoList = [[tarInfo infoListOnTaredData:[self object]] retain];
  [tarInfo release]; tarInfo = nil;
  
  return self->infoList;
}

- (void)setInfoItem:(NSDictionary *)_item {
  ASSIGN(self->infoItem, _item);
}
- (NSDictionary *)infoItem {
  return self->infoItem;
}

- (NSString *)dateAndTime {
  return [NSString stringWithFormat:@"%@ %@",
                     [[self infoItem] valueForKey:@"date"],
                     [[self infoItem] valueForKey:@"time"]];
}

- (void)setExclude:(BOOL)_excl {
  if (_excl) {
    if (![self exclude]) {
      NSString *pn;

      pn = [[self infoItem] objectForKey:@"pathName"];
      [self->excludeList addObject:pn];
    }
  }
  else {
    NSString *pn;
    
    pn = [[self infoItem] objectForKey:@"pathName"];
    [self->excludeList removeObject:pn];
  }
}
- (BOOL)exclude {
  NSString *pn;
  
  pn = [[self infoItem] objectForKey:@"pathName"];
  return [self->excludeList containsObject:pn];
}

- (void)setOnlyInfo:(BOOL)_no {
  self->onlyInfo = _no;
}
- (BOOL)onlyInfo {
  return self->onlyInfo;
}

- (BOOL)doesTarinfoExist {
  NSFileManager *fm;
  NSString *p;
  
  fm = [NSFileManager defaultManager];
  p  = [NSClassFromString(@"NGUnixTool") pathToTarTool];
  return [fm fileExistsAtPath:p];
}

@end /* SkyDocTarInlineViewer */
