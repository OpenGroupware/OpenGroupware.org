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

#include <OGoFoundation/OGoComponent.h>

@class NSData, NSArray, NSMutableArray, NSDictionary;
@class NGMimeType;

@interface SkyDocZipInlineViewer : OGoComponent 
{
  NSString       *uri;
  NGMimeType     *contentType;
  NSData         *data;
  int            contentLength;
  NSString       *fileName;
  BOOL           showZipInfo;
  NSArray        *infoList;
  NSDictionary   *infoItem;
  id             fileManager;
  NSMutableArray *excludeList;
  BOOL           onlyInfo;
}

- (void)setObject:(id)_object;
- (void)setContentType:(NGMimeType *)_type;
- (void)setFileManager:(id)_fm;
- (id)fileManager;

- (void)setExclude:(BOOL)_excl;
- (BOOL)exclude;

@end

#include "common.h"

@implementation SkyDocZipInlineViewer

- (id)init {
  if ((self = [super init])) {
    self->excludeList = [[[self context] page] valueForKey:@"excludeList"];
    if ([self->excludeList isKindOfClass:[NSMutableArray class]]) {
      // alles ok, liste existiert schon...
    }
    else {
      [self->excludeList release];
      self->excludeList = [[NSMutableArray alloc] init];
      [[[self context] page] takeValue:self->excludeList
                             forKey:@"excludeList"];
    }
    self->onlyInfo = NO;
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->uri);         self->uri         = nil;
  RELEASE(self->contentType); self->contentType = nil;
  RELEASE(self->data);        self->data        = nil;
  RELEASE(self->fileName);    self->fileName    = nil;
  RELEASE(self->infoList);    self->infoList    = nil;

  [super dealloc];
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  object:(id)_object
{
  [self setContentType:_type];
  [self setObject:_object];
  return YES;
}

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

- (void)setZipVisibility:(BOOL)_vis {
  [[[self context] page] takeValue:[NSNumber numberWithBool:_vis]
                                             forKey:@"zipVisibility"];
}
- (BOOL)zipVisibility {
  return [[[[self context] page] valueForKey:@"zipVisibility"] boolValue];
}

- (NSArray *)infoList {
  if (self->infoList == nil) {
    NGFileManagerZipInfo *zipInfo = nil;

    zipInfo = [[NGFileManagerZipInfo alloc] init];
    [zipInfo setFileManager:[self fileManager]];
    self->infoList = [zipInfo infoListOnZippedData:[self object]];
    RETAIN(self->infoList);

    RELEASE(zipInfo);
  }

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
    if (![self exclude])
      [self->excludeList addObject:[[self infoItem]
                                          objectForKey:@"pathName"]];
  }
  else {
    [self->excludeList removeObject:[[self infoItem]
                                           objectForKey:@"pathName"]];
  }
}
- (BOOL)exclude {
  return [self->excludeList containsObject:
              [[self infoItem] objectForKey:@"pathName"]];
}

- (void)setOnlyInfo:(BOOL)_no {
  self->onlyInfo = _no;
}
- (BOOL)onlyInfo {
  return self->onlyInfo;
}

- (BOOL)doesZipinfoExist {
  NSFileManager *fm = nil;

  fm = [NSFileManager defaultManager];
  return [fm fileExistsAtPath:
	       [NSClassFromString(@"NGUnixTool") pathToZipTool]];
}

@end /* SkyDocZipInlineViewer */
