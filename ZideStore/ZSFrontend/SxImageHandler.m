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

#include "SxImageHandler.h"
#include "common.h"

@implementation SxImageHandler

- (id)initWithName:(NSString *)_key inContainer:(id)_folder {
  if ((self = [super init])) {
    self->nameInContainer = [_key copy];
    self->container       = _folder;
  }
  return self;
}

- (void)dealloc {
  [self detachFromContainer];
  [super dealloc];
}

/* containment */

- (id)container {
  return self->container;
}
- (NSString *)nameInContainer {
  return self->nameInContainer;
}

- (void)detachFromContainer {
  self->container = nil;
  [self->nameInContainer release]; self->nameInContainer = nil;
}

/* lookup */

- (NSString *)contentTypeForPath:(NSString *)_name {
  if ([_name hasSuffix:@"css"])
    return @"text/css";
  return [@"image/" stringByAppendingString:[_name pathExtension]];
}

- (id)lookupName:(NSString *)_name inContext:(id)_ctx acquire:(BOOL)_ac {
  WOResourceManager *rm;
  NSString   *p;
  NSData     *data;
  WOResponse *response;
  
  rm = [[WOApplication application] resourceManager];
  p  = [rm pathForResourceNamed:_name inFramework:nil languages:nil];
  
  if (p == nil) {
    [self logWithFormat:@"did not find image '%@'", _name];
    return nil;
  }
  
  if ((data = [NSData dataWithContentsOfMappedFile:p]) == nil) {
    [self logWithFormat:@"could not load image '%@'", _name];
    return nil;
  }
  
  response = [(WOContext *)_ctx response];
  [response setHeader:[self contentTypeForPath:p] forKey:@"content-type"];
  [response setContent:data];
  return response;
}

@end /* SxImageHandler */
