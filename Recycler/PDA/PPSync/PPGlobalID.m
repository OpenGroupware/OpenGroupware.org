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

#include "PPGlobalID.h"
#include "PPSyncContext.h"
#include "common.h"

#include <netinet/in.h>

@implementation PPGlobalID

+ (id)ppGlobalIDForCreator:(unsigned long)_c type:(unsigned long)_t
  databaseName:(NSString *)_dbName uniqueID:(unsigned long)_uid
{
  PPGlobalID *gid;

  NSAssert(_dbName, @"missing database name ..");
  
  gid = [[self alloc] init];
  gid->creator  = _c;
  gid->type     = _t;
  gid->uniqueID = _uid;
  gid->dbName   = [_dbName copy];
  
  return AUTORELEASE(gid);
}

- (void)dealloc {
  RELEASE(self->dbName);
  [super dealloc];
}

/* accessors */

- (NSString *)entityName {
  return self->dbName;
}
- (unsigned long)creator {
  return self->creator;
}
- (unsigned long)type {
  return self->type;
}
- (unsigned long)uniqueID {
  return self->uniqueID;
}

/* comparison */

- (unsigned)hash {
  return self->uniqueID;
}

- (BOOL)isEqual:(id)_other {
  PPGlobalID *other;
  
  if (_other == self)
    return YES;
  
  if (self->isa != ((PPGlobalID *)_other)->isa)
    return NO;
  
  other = _other;
  
  if (other->uniqueID != self->uniqueID) return NO;
  if (other->creator  != self->creator)  return NO;
  if (other->type     != self->type)     return NO;
  return [self->dbName isEqualToString:other->dbName];
}

/* description */

- (NSString *)description {
  NSMutableString *s;
  unsigned long ul;
  char buf[5];

  s = [NSMutableString stringWithCapacity:128];
  
  [s appendFormat:@"<%@[0x%p]: db=%@ uid=%i", 
       NSStringFromClass([self class]), self,
       self->dbName, self->uniqueID];
  
  ul = ntohl(self->creator);
  strncpy(buf, (char *)&ul, 4); buf[4] = '\0';
  [s appendFormat:@" creator=%s", buf];

  ul = ntohl(self->type);
  strncpy(buf, (char *)&ul, 4); buf[4] = '\0';
  [s appendFormat:@" type=%s", buf];

  [s appendString:@">"];
  return s;
}

- (NSString *)stringValue {
  NSMutableString *s;
  s = [NSMutableString stringWithCapacity:64];
  [s appendString:self->dbName];
  [s appendString:@"/"];
  [s appendString:PPStringFromCreator(self->creator)];
  [s appendString:@"/"];
  [s appendString:PPStringFromType(self->type)];
  [s appendFormat:@"/%p", self->uniqueID];
  return s;
}

@end /* PPGlobalID */
