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

#include "PPToDoDatabase.h"
#include "PPSyncContext.h"
#include "PPToDoPacker.h"
#import <Foundation/Foundation.h>
#import <EOControl/EOControl.h>

#define id _pid
#include <pi-appinfo.h>
#include <pi-source.h>
#include <pi-socket.h>
#include <pi-dlp.h>
#include <pi-todo.h>
#undef id

static EONull *null = nil;

@implementation PPToDoDatabase

+ (void)initialize {
  if (null == nil) null = [EONull null];
}

/* accessors */

- (BOOL)sortByPriority {
  return self->sortByPriority;
}
- (BOOL)isDirty {
  return self->isDirty;
}

/* records */

- (Class)databaseRecordClassForGlobalID:(EOGlobalID *)_oid {
  return [PPToDoRecord class];
}

/* packing & unpacking */

- (NSData *)packRecord:(id)_eo {
  PPToDoPacker *packer;
  NSData *data;

  packer = [[PPToDoPacker alloc] initWithObject:_eo];
  data = [packer packWithDatabase:self];
  RELEASE(packer);
  return data;
}

- (int)decodeAppBlock:(NSData *)_block {
  const unsigned char *record;
  int                 len, i;
  const unsigned char *start;
  //unsigned long       r;
  //struct CategoryAppInfo category;
  
  record = start = [_block bytes];
  len    = [_block length];

  i = [super decodeAppBlock:_block];
  record += i;
  len    -= i;

  if (len < 4)
    return 0;
  
  self->isDirty        = get_short(record) ? YES : NO; record += 2;
  self->sortByPriority = get_byte(record)  ? YES : NO; record += 2;
  self->hasAppInfo = YES;
  return record - start;
}

/* description */

- (NSString *)propertyDescription {
  if (self->hasAppInfo) {
    NSMutableString *s;

    s = [NSMutableString stringWithString:[super propertyDescription]];
    [s appendFormat:@" isDirty=%s", self->isDirty ? "yes" : "no"];
    [s appendFormat:@" sortByPriority=%s", self->sortByPriority ? "yes" : "no"];
    return s;
  }
  else
    return [super propertyDescription];
}

@end /* PPToDoDatabase */

@implementation PPToDoRecord

+ (void)initialize {
  if (null == nil) null = [EONull null];
}

+ (long)palmCreator {
  return 'memo';
}
+ (long)palmType {
  return 'DATA';
}

- (void)awakeFromDatabase:(PPRecordDatabase *)_db
  objectID:(EOGlobalID *)_oid
  attributes:(int)_attrs
  category:(int)_category
  data:(NSData *)_data
{
  PPToDoPacker *packer;

  [super awakeFromDatabase:_db objectID:_oid attributes:_attrs
         category:_category data:_data];

  if ([self isDeleted])
    return;
  
  packer = [[PPToDoPacker alloc] initWithObject:self];
  [packer unpackWithDatabase:_db data:_data];
  RELEASE(packer);
  
#if 0
  NSTimeZone *tz;
  struct ToDo ai;
  unsigned long d;
  unsigned char *buffer;
  unsigned char *start;
  int len;

  [super awakeFromDatabase:_db objectID:_oid attributes:_attrs
         category:_category data:_data];
  
  buffer = start = (void *)[_data bytes];
  len    = [_data length];
  
  if (len < 3) {
    // too short
    return;
  }

  d = (unsigned short int)get_short(buffer); buffer += 2; len -= 2;
  if (d != 0xffff) {
    tz = [NSTimeZone timeZoneWithName:@"GMT"];
    
    self->due = [[NSCalendarDate alloc] initWithYear:((d >> 9) + 1904)
                                        month:(((d >> 5) & 15))
                                        day:(d & 31)
                                        hour:0 minute:0 second:0
                                        timeZone:tz];
  }

  self->priority = get_byte(buffer);
  if (self->priority & 0x80) {
    self->priority    &= 0x7F;
    self->isCompleted = YES;
  }
  else
    self->isCompleted = NO;
  buffer += 1;
  len    -= 1;

  if (len > 0) {
    unsigned slen = strlen(buffer);
    if (slen > 0) {
      self->title = [[NSString alloc] initWithCString:buffer length:slen];
      buffer += slen + 1;
      len    -= slen + 1;
    }
  }
  if (len > 0) {
    unsigned slen = strlen(buffer);
    if (slen > 0) {
      self->note = [[NSString alloc] initWithCString:buffer length:slen];
      buffer += slen + 1;
      len    -= slen + 1;
    }
  }
#endif
}

- (void)dealloc {
  RELEASE(self->due);
  RELEASE(self->title);
  RELEASE(self->note);
  [super dealloc];
}

/* accessors */

- (void)setDue:(NSCalendarDate *)_due {
  if (_due == (id)null) _due = nil;
  
  if (self->due != _due) {
    [self willChange];
    ASSIGN(self->due, _due);
  }
}
- (NSCalendarDate *)due {
  return self->due;
}
- (BOOL)isIndefinite {
  return self->due == nil ? YES : NO;
}

- (NSException *)validatePriority:(int)_pri {
  if (_pri > 5) {
    NSLog(@"WARNING: priority in record %@ is too high, reducing to 5 !", self);
    self->priority = 5;
  }
  if (_pri < 1) {
    NSLog(@"WARNING: priority in record %@ is too low, increasing to 1 !", self);
    self->priority = 1;
  }
  return nil;
}
- (void)setPriority:(int)_pri {
  if (self->priority != _pri) {
    [self willChange];
    self->priority = _pri;
  }
}
- (int)priority {
  return self->priority;
}

- (void)setIsCompleted:(BOOL)_flag {
  _flag = _flag ? YES : NO;
  if (self->isCompleted != _flag) {
    [self willChange];
    self->isCompleted = _flag;
  }
}
- (BOOL)isCompleted {
  return self->isCompleted;
}

- (void)setTitle:(NSString *)_title {
  if (_title == (id)null) _title = nil;
  
  if (self->title != _title) {
    [self willChange];
    ASSIGN(self->title, _title);
  }
}
- (NSString *)title {
  return self->title;
}

- (void)setNote:(NSString *)_note {
  if (_note == (id)null) _note = nil;
  
  if (self->note != _note) {
    [self willChange];
    ASSIGN(self->note, _note);
  }
}
- (NSString *)note {
  return self->note ? self->note : @"";
}

/* description */

- (NSString *)propertyDescription {
  NSMutableString *s;

  s = [NSMutableString stringWithCapacity:100];
  
  [s appendFormat:@" '%@'", [self title]];
  [s appendFormat:@" pri=%i", [self priority]];

  if ([self due])
    [s appendFormat:@" due=%@", [self due]];
  
  if ([self isCompleted])
    [s appendString:@" completed"];

  [s appendString:[super propertyDescription]];
  
  return s;
}

- (NSArray *)attributeKeys {
  static NSArray *keys = nil;
  if (keys == nil) {
    keys = [[NSArray alloc] initWithObjects:
                              @"category", @"isPrivate",
                              @"due", @"priority", @"isCompleted",
                              @"title", @"note", nil];
  }
  return keys;
}

- (NSException *)validateForSave {
  NSException *e;

  if ((e = [self validateCategory:[self category]]))
    [self setCategory:@""];
  
  if ((e = [super validateForSave]))
    return e;

  return nil;
}

@end /* PPToDoRecord */
