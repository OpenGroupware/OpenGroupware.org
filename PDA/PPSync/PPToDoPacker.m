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

#include "PPToDoPacker.h"
#include "PPRecordDatabase.h"
#include "PPSyncContext.h"
#include "common.h"

@implementation PPToDoPacker

- (id)initWithObject:(id)_object {
  self->eo = RETAIN(_object);
  return self;
}

- (void)dealloc {
  RELEASE(self->eo);
  [super dealloc];
}

/* accessors */

- (id)object {
  return self->eo;
}

/* operations */

- (NSData *)packWithDatabase:(PPRecordDatabase *)_db {
  struct {
    int       indefinite;
    struct tm due;
    int       priority;
    int       complete;
    char      *description;
    char      *note;
  } todo;
  unsigned char  buf[0xffff];
  unsigned       len;
  NSCalendarDate *d;
  NSString       *title, *note;

  title = [self->eo storedValueForKey:@"title"];
  note  = [self->eo storedValueForKey:@"note"];

  /* Palm doesn't handle '\r\n' .. */
  
  if ([title indexOfString:@"\r\n"]) {
    title = [[title componentsSeparatedByString:@"\r\n"]
                    componentsJoinedByString:@"\n"];
  }
  if ([note indexOfString:@"\r\n"]) {
    note = [[note componentsSeparatedByString:@"\r\n"]
                  componentsJoinedByString:@"\n"];
  }
  
  if ((d = [self->eo storedValueForKey:@"due"])) {
    [d setTimeZone:[[_db syncContext] pilotTimeZone]];
    
    todo.indefinite   = 0;
    todo.due.tm_mday  = [d dayOfMonth];
    todo.due.tm_mon   = [d monthOfYear] - 1;
    todo.due.tm_year  = [d yearOfCommonEra] - 1900;
  }
  else
    todo.indefinite = 1;
  
  todo.priority     = [[self->eo storedValueForKey:@"priority"] intValue];
  todo.complete     =
    [[self->eo storedValueForKey:@"isCompleted"] boolValue] ? 1 : 0;
  todo.description  = (char *)[title cString];
  todo.note         = (char *)[note cString];
  if (todo.description == NULL) todo.description = "";
  if (todo.note        == NULL) todo.note        = "";

  /* pack */
  if (todo.indefinite) {
    buf[0] = 0xff;
    buf[1] = 0xff;
  }
  else {
    set_short(buf, ((todo.due.tm_year - 4) << 9) |
              ((todo.due.tm_mon  + 1) << 5) |
              todo.due.tm_mday);
  }
  buf[2] = todo.priority;
  if(todo.complete) {
    buf[2] |= 0x80;
  }
  
  len = 3;
  if (todo.description) {
    strcpy((char *)buf + len, todo.description);
    len += strlen(todo.description) + 1;
  }
  else {
    buf[len++] = 0;
  }
  
  if (todo.note) {
    strcpy((char *)buf + len, todo.note);
    len += strlen(todo.note)+1;
  }
  else {
    buf[len++] = 0;
  }

  return [NSData dataWithBytes:buf length:len];
}

- (int)unpackWithDatabase:(PPRecordDatabase *)_db data:(NSData *)_data {
  NSTimeZone    *tz;
#if 0
  struct {
    int       indefinite;
    struct tm due;
    int       priority;
    int       complete;
    char      *description;
    char      *note;
  } ai;
#endif
  unsigned long d;
  unsigned char *buffer;
  unsigned char *start;
  int           len, priority;
  
  buffer = start = (void *)[_data bytes];
  len    = [_data length];

  if (len < 3) {
    /* too short */
    return len;
  }
  
  d = (unsigned short int)get_short(buffer); buffer += 2; len -= 2;
  if (d != 0xffff) {
    NSCalendarDate *due;

    tz = [[_db syncContext] pilotTimeZone];
    
    due = [[NSCalendarDate alloc] initWithYear:((d >> 9) + 1904)
                                  month:(((d >> 5) & 15))
                                  day:(d & 31)
                                  hour:0 minute:0 second:0
                                  timeZone:tz];
    
    [self->eo takeStoredValue:due forKey:@"due"];
  }

  priority = get_byte(buffer);
  if (priority & 0x80) {
    priority &= 0x7F;
    [self->eo takeStoredValue:[NSNumber numberWithBool:YES]
              forKey:@"isCompleted"];
  }
  else {
    [self->eo takeStoredValue:[NSNumber numberWithBool:NO]
              forKey:@"isCompleted"];
  }
  [self->eo takeStoredValue:[NSNumber numberWithInt:priority]
            forKey:@"priority"];
  buffer += 1;
  len    -= 1;
  
  if (len > 0) {
    unsigned slen = strlen(buffer);
    if (slen > 0) {
      NSString *title;
      
      title = [[NSString alloc] initWithCString:buffer length:slen];
      [self->eo takeStoredValue:title forKey:@"title"];
      RELEASE(title); title = nil;
      
      buffer += slen + 1;
      len    -= slen + 1;
    }
  }
  if (len > 0) {
    unsigned slen = strlen(buffer);
    if (slen > 0) {
      NSString *note;
      
      note = [[NSString alloc] initWithCString:buffer length:slen];
      [self->eo takeStoredValue:note forKey:@"note"];
      RELEASE(note); note = nil;
      
      buffer += slen + 1;
      len    -= slen + 1;
    }
  }
  
  return len;
}

@end /* PPToDoPacker */
