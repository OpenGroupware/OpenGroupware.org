/*
  Copyright (C) 2004 SKYRIX Software AG

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

#include "OGoStringTable.h"
#include "common.h"

@implementation OGoStringTable

static BOOL debugOn = NO;

+ (id)stringTableWithPath:(NSString *)_path {
  return [[(OGoStringTable *)[self alloc] initWithPath:_path] autorelease];
}

- (id)initWithPath:(NSString *)_path {
  self->path = [_path copyWithZone:[self zone]];
  return self;
}

- (void)dealloc {
  [self->path     release];
  [self->lastRead release];
  [self->data     release];
  [super dealloc];
}

/* loading */

- (NSException *)reportParsingError:(NSException *)_error {
  NSLog(@"%s: could not load strings file '%@': %@", 
        __PRETTY_FUNCTION__, self->path, _error);
  return nil;
}

- (void)checkState {
  NSString     *tmp;
  NSDictionary *plist;
  
  if (self->data)
    return;
  
  if ((tmp = [NSString stringWithContentsOfFile:self->path]) == nil) {
    self->data = nil;
    return;
  }
  
  self->data = nil;
  NS_DURING {
    if ((plist = [tmp propertyListFromStringsFileFormat]) == nil) {
      NSLog(@"%s: could not load strings file '%@'",
            __PRETTY_FUNCTION__,
            self->path);
    }
    self->data = [plist copy];
    self->lastRead = [[NSDate date] retain];
  }
  NS_HANDLER
    [[self reportParsingError:localException] raise];
  NS_ENDHANDLER;
}

/* access */

- (NSString *)stringForKey:(NSString *)_key withDefaultValue:(NSString *)_def {
  NSString *value;
  
  [self checkState];
  value = [self->data objectForKey:_key];
  return value ? value : _def;
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

@end /* OGoStringTable */
