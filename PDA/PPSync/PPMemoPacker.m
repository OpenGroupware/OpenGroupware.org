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

#include "PPMemoPacker.h"
#include "PPMemoDatabase.h"
#include "PPSyncContext.h"
#include "common.h"

@implementation PPMemoPacker

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

struct Memo {
  char * text;
};

static int pack_Memo(struct Memo *a, unsigned char * buffer, int len)
     __attribute__((unused));
static int pack_Memo(struct Memo *a, unsigned char * buffer, int len) {
  int destlen = (a->text ? strlen(a->text) : 0)+1;
  if (!buffer)
    return destlen;
  if (len < destlen)
    return 0;
  if(a->text) {
    if (buffer)
      strcpy((char*)buffer,a->text);
    return strlen(a->text)+1;
  } else {
    if (buffer)
      buffer[0] = 0;
    return 1;
  }
}

- (NSData *)packWithDatabase:(PPRecordDatabase *)_db {
  NSString *text;
  int      len;
  char     buf[0xFFFF];
  
  text = [self->eo storedValueForKey:@"text"];
  if (text == nil) text = @"";
  len = [text cStringLength];

  [text getCString:buf];
  buf[len] = '\0'; len++;
  
  return [NSData dataWithBytes:buf length:len];
}

- (int)unpackWithDatabase:(PPRecordDatabase *)_db data:(NSData *)_data {
  unsigned char *buffer;
  unsigned char *start;
  int           len;
  NSString      *s;
  
  buffer = start = (void *)[_data bytes];
  len    = [_data length];

  if (len < 1)
    /* too short */
    return 0;

  s = [[NSString alloc] initWithCString:buffer];
  [self->eo takeStoredValue:s forKey:@"text"];
  len = [s cStringLength] + 1;
  RELEASE(s);
  
  return len;
}

@end /* PPMemoPacker */
