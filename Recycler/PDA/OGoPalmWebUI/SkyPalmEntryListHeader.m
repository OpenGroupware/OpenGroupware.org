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

@interface SkyPalmEntryListHeader : OGoComponent
{
  NSString *type;                   // address / date / memo / job
  NSString *newLabelKey;
  NSString *newFromSkyrixLabelKey;
  NSString *titleLabelKey;

  NSString *titleLabel;
  NSString *newFromSkyrixLabel;
  NSString *newLabel;
}

@end

#include "common.h"
#include <NGExtensions/EOCacheDataSource.h>
#include <OGoPalm/SkyPalmEntryDataSource.h>
#include <OGoPalm/SkyPalmDocument.h>

@implementation SkyPalmEntryListHeader

- (void)dealloc {
  RELEASE(self->type);
  RELEASE(self->newLabelKey);
  RELEASE(self->newFromSkyrixLabelKey);
  RELEASE(self->titleLabelKey);

  RELEASE(self->titleLabel);
  RELEASE(self->newFromSkyrixLabel);
  RELEASE(self->newLabel);
  [super dealloc];
}

/* notifications */

- (void)syncSleep {
  RELEASE(self->type);                   self->type                  = nil;
  RELEASE(self->newLabelKey);            self->newLabelKey           = nil;
  RELEASE(self->newFromSkyrixLabelKey);  self->newFromSkyrixLabelKey = nil;
  RELEASE(self->titleLabelKey);          self->titleLabelKey         = nil;
  RELEASE(self->newLabel);               self->newLabel              = nil;
  RELEASE(self->newFromSkyrixLabel);     self->newFromSkyrixLabel    = nil;
  RELEASE(self->titleLabel);             self->titleLabel            = nil;
  [super syncSleep];
}

/* accessors */

- (BOOL)synchronizesVariablesWithBindings {
  return NO;
}

- (void)setType:(NSString *)_type {
  ASSIGNCOPY(self->type,_type);
  
  RELEASE(self->newLabelKey);
  RELEASE(self->newFromSkyrixLabelKey);
  RELEASE(self->titleLabelKey);
  
  self->newLabelKey   = [[@"new_" stringByAppendingString:_type] copy];
  self->titleLabelKey = [[@"list_title_" stringByAppendingString:_type] copy];
  
  self->newFromSkyrixLabelKey =
    [[NSString alloc] initWithFormat:@"new_%@_from_skyrix", _type];
}

- (void)loadBindings {
  id tmp;
  
  [self setType:[self valueForBinding:@"type"]];

  // label keys
  tmp = [self valueForBinding:@"titleLabelKey"];
  if ([tmp length] > 0) {
    ASSIGN(self->titleLabelKey,tmp);
  }
  tmp = [self valueForBinding:@"newLabelKey"];
  if ([tmp length]) {
    ASSIGN(self->newLabelKey,tmp);
  }
  tmp = [self valueForBinding:@"newFromSkyrixLabelKey"];
  if ([tmp length]) {
    ASSIGN(self->newFromSkyrixLabelKey,tmp);
  }

  // labels
  tmp = [self valueForBinding:@"newLabel"];
  if ([tmp length]) {
    ASSIGN(self->newLabel,tmp);
  } else {
    RELEASE(self->newLabel);
    self->newLabel =
      [[self labels] valueForKey:self->newLabelKey];
    RETAIN(self->newLabel);
  }
  tmp = [self valueForBinding:@"newFromSkyrixLabel"];
  if ([tmp length]) {
    ASSIGN(self->newFromSkyrixLabel,tmp);
  } else {
    RELEASE(self->newFromSkyrixLabel);
    self->newFromSkyrixLabel =
      [[self labels] valueForKey:self->newFromSkyrixLabelKey];
    RETAIN(self->newFromSkyrixLabel);
  }
  tmp = [self valueForBinding:@"titleLabel"];
  if ([tmp length]) {
    ASSIGN(self->titleLabel,tmp);
  } else {
    RELEASE(self->titleLabel);
    self->titleLabel =
      [[self labels] valueForKey:self->titleLabelKey];
    RETAIN(self->titleLabel);
  }
}

- (NSString *)type {
  if (self->type == nil) {
    [self loadBindings];
  }
  return self->type;
}

- (NSString *)newLabelKey {
  if (self->newLabelKey == nil)
    [self loadBindings];
  return self->newLabelKey;
}
- (NSString *)newLabel {
  if (self->newLabel == nil)
    [self loadBindings];
  return self->newLabel;
}

- (NSString *)newFromSkyrixLabelKey {
  if (self->newFromSkyrixLabelKey == nil)
    [self loadBindings];
  return self->newFromSkyrixLabelKey;
}
- (NSString *)newFromSkyrixLabel {
  if (self->newFromSkyrixLabel == nil)
    [self loadBindings];
  return self->newFromSkyrixLabel;
}

- (NSString *)titleLabelKey {
  if (self->titleLabelKey == nil)
    [self loadBindings];
  return self->titleLabelKey;
}
- (NSString *)titleLabel {
  if (self->titleLabel == nil)
    [self loadBindings];
  return self->titleLabel;
}

- (id)hideNewActions {
  return [self valueForBinding:@"hideNewActions"];
}

- (id)dataSource {
  return [self valueForBinding:@"dataSource"];
}

- (BOOL)hasNewFromSkyrix {
  id val = [self valueForBinding:@"hideNewFromSkyrix"];

  if ((val != nil) && [val boolValue])
    return NO;
  
  return YES;
}

// actions

- (id)newRecord {
  id page = nil;
  id ds   = nil;

  ds = [self dataSource];
  if ([ds isKindOfClass:[EOCacheDataSource class]])
    ds = [ds source];
  if (![ds isKindOfClass:[SkyPalmEntryDataSource class]]) {
    [self logWithFormat:
          @"DataSource %@ is not kindOfClass "
          @"SkyPalmEntryDataSource.", [ds class]];
    return nil;
  }

  {
    // check wether user has already synced with skyrix,
    // so if there is already a device registered for user
    // if not, don't know what categories to take
    NSString *device = [ds defaultDevice];
    if (device == nil) {
      [[[self parent] parent] setErrorString:
            [[self labels] valueForKey:@"error_nodeviceentry"]];
      return nil;
    }

  }
  page = [ds newDocument];
  page = [[[self session] navigation] activateObject:page
                                      withVerb:@"new"];
  return page;
}

- (id)newFromSkyrixRecord {
  id page = nil;
  id ds   = nil;

  ds = [self dataSource];
  if ([ds isKindOfClass:[EOCacheDataSource class]])
    ds = [ds source];
  if (![ds isKindOfClass:[SkyPalmEntryDataSource class]]) {
    [self logWithFormat:
          @"DataSource %@ is not kindOfClass "
          @"SkyPalmEntryDataSource.", [ds class]];
    return nil;
  }

  {
    // check wether user has already synced with skyrix,
    // so if there is already a device registered for user
    // if not, don't know what categories to take
    NSString *device = [ds defaultDevice];
    if (device == nil) {
      [[[self parent] parent] setErrorString:
            [[self labels] valueForKey:@"error_nodeviceentry"]];
      return nil;
    }

  }
  page = [ds newDocument];
  page = [[[self session] navigation] activateObject:page
                                      withVerb:@"new-from-skyrix-record"];
  [page takeValue:ds forKey:@"dataSource"];
  return page;
}

#if 0
- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  NSLog(@"%s", __PRETTY_FUNCTION__);
  [super appendToResponse:_response inContext:_ctx];
  NSLog(@"%s done", __PRETTY_FUNCTION__);
}
#endif

@end /* SkyPalmEntryListHeader */
