/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#import <LSFoundation/LSDBObjectNewCommand.h>

@class NSData, NSString;

@interface LSNewBookmarkCommand : LSBaseCommand
{
@protected  
  NSData   *data;
}

@end

#import "common.h"

@implementation LSNewBookmarkCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->data);
  [super dealloc];
}
#endif

- (void)_executeInContext:(id)_context {
  BOOL     isOk      = NO;
  NSString *path     = nil;
  NSString *fileName = nil;
  id       pkey      = nil;

  path     = [[_context userDefaults] stringForKey:@"LSAttachmentPath"];
  pkey     = [[_context valueForKey:LSAccountKey] valueForKey:@"companyId"];
  fileName = [NSString stringWithFormat:@"%@/%@.html", path, pkey];
    
  if (self->data != nil) {
    NSLog(@"write bookmark %@ ", fileName);
    isOk = [self->data writeToFile:fileName atomically:YES];
  }
  [self assert:isOk reason:@"error during save of attachment"];
}

- (void)setData:(NSData *)_data {
  ASSIGN(self->data, _data);
}
- (NSData *)data {
  return self->data;
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"data"]) {
    [self setData:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"data"])
    return [self data];
  return [super valueForKey:_key];
}

@end
