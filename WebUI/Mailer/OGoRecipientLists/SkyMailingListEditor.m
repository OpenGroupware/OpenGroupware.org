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

#include <OGoFoundation/OGoContentPage.h>

@class NSString, NSMutableDictionary, NSData;

@interface SkyMailingListEditor : OGoContentPage
{
  NSString            *emails;
  NSMutableDictionary *entry;
  BOOL                isNew;
  id                  data;
}

@end

#include "common.h"
#include "SkyMailingListDataSource.h"

@implementation SkyMailingListEditor

- (void)dealloc {
  [self->data   release];
  [self->entry  release];
  [self->emails release];
  [super dealloc];
}

/* accessors */

- (BOOL)isNew {
  return self->isNew;
}

- (void)setEmails:(NSString *)_emails {
  ASSIGN(self->emails, _emails);
}
- (NSString *)emails {
  if (self->emails == nil) {
    self->emails = [[[self->entry objectForKey:@"emails"]
                                  componentsJoinedByString:@"\n"] copy];
  }
  return self->emails;
}

- (void)setData:(id)_data { /* can be either NSData or NSString */
  ASSIGN(self->data, _data);
}
- (id)data {
  return self->data;
}

- (void)setEntry:(id)_entry {
  ASSIGN(self->entry, _entry);
}
- (id)entry {
  return self->entry;
}

- (SkyMailingListDataSource *)dataSource {
  LSCommandContext *cmdctx;
  
  cmdctx = [[self session] commandContext];
  return [[(SkyMailingListDataSource *)[SkyMailingListDataSource alloc] 
				       initWithContext:(id)cmdctx]
                                       autorelease];
}

/* actions */

- (id)confirmUpload {
  NSString *str;
  
  if (![self->data isNotNull])
    return nil;
  if ([self->data length] == 0)
    return nil;
  
  if ([self->data isKindOfClass:[NSString class]]) {
    str = [self->data copy];
  }
  else if ([self->data isKindOfClass:[NSData class]]) {
    str = [[NSString alloc] initWithData:self->data
                            encoding:[NSString defaultCStringEncoding]];
  }
  else {
    [self setErrorString:@"got unsupported form parameter class!"];
    [self logWithFormat:@"ERROR: unexpected form parameter class: %@ (%@)",
            self->data, NSStringFromClass([self->data class])];
    return nil;
  }

  if (self->emails) {
    id tmp;

    tmp = self->emails;
    
    self->emails = [[[self->emails stringByAppendingString:@"\n"]
                                   stringByAppendingString:str] retain];
    [tmp release]; tmp = nil;
    [str release]; str = nil;
  }
  else {
    self->emails = str;
  }
  return nil;
}

- (id)save {
  NSEnumerator *enumerator;
  NSDictionary *obj;
  int          i;
  NSString     *name;
  
  SkyMailingListDataSource *ds;

  name = [self->entry objectForKey:@"name"];

  if (![name length]) {
    [self setWarningPhrase:[[self labels] valueForKey:@"MissingMailListName"]];
    return nil;
  }
  ds         = [self dataSource];
  enumerator = [[ds fetchObjects] objectEnumerator];

  [self->entry setObject:[self->emails componentsSeparatedByString:@"\n"]
       forKey:@"emails"];

  i = 0;
  while ((obj = [enumerator nextObject])) {
    if ([[obj objectForKey:@"name"] isEqual:name])
      break;
    
    i++;
  }
  if (isNew) {
    if (obj) {
      NSString *str;
      
      str = [[self labels] valueForKey:@"NameAlreadyExist"];
      str = [[NSString alloc] initWithFormat:str, name];
      [self setWarningPhrase:str];
      [str release];
      return nil;
    }
    
    [ds insertObject:self->entry];
  }
  else {
    [ds updateObject:self->entry];
  }
  [self leavePage];
  return nil;
}

- (id)delete {
  [[self dataSource] deleteObject:self->entry];
  [self leavePage];
  return nil;
}

- (id)cancel {
  [self leavePage];
  return nil;
}

- (BOOL)isEditorPage {
  return YES;
}

/* KVC */

- (void)takeValue:(id)_v forKey:(id)_k {
  if ([_k isEqualToString:@"entry"])
    [self setEntry:_v];
  else if ([_k isEqualToString:@"isNew"])
    self->isNew = [_v boolValue];
  else
    [super takeValue:_v forKey:_k];
}

@end /* SkyMailingListEditor */
