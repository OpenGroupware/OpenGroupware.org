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
// $Id: LSMBoxFileImportCommand.m 1 2004-08-20 11:17:52Z znek $

#import "LSMBoxFileImportCommand.h"
#import "common.h"

@implementation LSMBoxFileImportCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->emailFolderId);
  [super dealloc];
}
#endif

- (void)_prepareForExecutionInContext:(id)_context {
  [self assert:(self->emailFolderId != nil) reason:@"no emailFolderId is set"];
  [self assert:([self object] != nil)       reason:@"no file is set"];
  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {
  NGMBoxReader   *reader = nil;
  id<NGMimePart> part    = nil;
  NSArray        *mails  = nil;
  id             folder  = nil;

  folder = LSRunCommandV(_context,
                         @"emailFolder", @"get",
                         @"emailFolderId", self->emailFolderId,
                         nil);
  if ([folder count] > 0)
    folder = [folder lastObject];
  else
    [self assert:YES reason:@"no folder for given folderId"];

  LSRunCommandV(_context,
                @"emailFolder", @"fetch-content",
                @"object",      folder,
                nil);
  mails  = [(NSArray *)[folder valueForKey:@"email"] map:@selector(valueForKey:)
                       with:@"messageId"];
  reader = [NGMBoxReader readerForMBox:[self object]];
  while ((part = [reader nextMessage])) {
    if (![mails containsObject:
                [[part valuesOfHeaderFieldWithName:@"message-id"]
                       nextObject]]) {
      id email = LSRunCommandV(_context,
                               @"email",       @"new",
                               @"emailFolder", folder,
                               @"mimePart",    part,
                               @"owner",
                               [_context valueForKey:LSAccountKey], nil);
      [EODatabase forgetObject:email];
    }
  }
  [super _executeInContext:_context];
}

// accessors

- (void)setEmailFolderId:(NSNumber *)_id {
  ASSIGN(self->emailFolderId, _id);
}
- (NSNumber *)emailFolderId {
  return self->emailFolderId;
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"emailFolderId"])
    [self setEmailFolderId:_value];
  else if ([_key isEqualToString:@"emailFolder"])
    [self setEmailFolderId:[_value valueForKey:@"emailFolderId"]];
  else if ([_key isEqualToString:@"file"])
    [super takeValue:_value forKey:@"object"];
  else
    [super takeValue:_value forKey:_key];
}


- (id)valueForKey:(id)_key {
  return [super valueForKey:_key];
}

@end
