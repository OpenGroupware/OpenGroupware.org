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

#include <OGoFoundation/LSWViewerPage.h>

@class NSDictionary;

@interface SkyVacationViewer : LSWViewerPage
{
  NSDictionary *vacation;
  NSDictionary *forward;
}

@end

#include "common.h"
#include "LSWImapMailFilterManager.h"

@implementation SkyVacationViewer

- (void)syncAwake {
  NSEnumerator *enumerator;
  NSDictionary *entry;
  
  [self->vacation release]; self->vacation = nil;
  [self->forward  release]; self->forward = nil;
  
  enumerator = [[LSWImapMailFilterManager vacationForUser:
                                          [[self session] activeAccount]]
                                          objectEnumerator];

  while ((entry = [enumerator nextObject])) {
    if ([[entry objectForKey:@"kind"] isEqual:@"vacation"])
      self->vacation = [entry mutableCopy];
    else if ([[entry objectForKey:@"kind"] isEqual:@"forward"])
      self->forward = [entry mutableCopy];
    
    if (self->forward && self->vacation)
      break;
  }
  [super syncAwake];
}

- (void)syncSleep {
  [self->vacation release]; self->vacation = nil;
  [self->forward  release]; self->forward = nil;
  [super syncSleep];
}

- (id)new {
  NGMimeType   *mt = nil;
  WOComponent  *ct = nil;

  mt = [NGMimeType mimeType:@"objc" subType:@"imap-vacation"];
  ct = [[self session] instantiateComponentForCommand:@"new" type:mt];
  return ct;
}
- (id)delete {
  return nil;
}
- (id)edit {
  NGMimeType   *mt = nil;
  WOComponent  *ct = nil;

  mt = [NGMimeType mimeType:@"objc" subType:@"imap-vacation"];
  ct = [[self session] instantiateComponentForCommand:@"edit" type:mt];
  return ct;
}
- (BOOL)hasVacation {
  return self->vacation ? YES : NO;
}

- (BOOL)hasVacationElse {
  return ![self hasVacation];
}

- (NSDictionary *)vacation {
  return self->vacation;
}

- (NSDictionary *)forward {
  return self->forward;
}

- (NSString *)keepMailString {
  BOOL keepFlag;

  keepFlag = [[self->forward objectForKey:@"keepMails"] boolValue];
  return [[self labels] valueForKey:keepFlag ? @"YES" : @"NO"];
}

@end /* SkyVacationViewer */
