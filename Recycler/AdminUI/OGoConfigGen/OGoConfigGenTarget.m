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

#include "OGoConfigGenTarget.h"
#include "common.h"

@implementation OGoConfigGenTarget

+ (id)targetWithName:(NSString *)_name 
  inTransaction:(OGoConfigGenTransaction *)_tx
{
  return [[[self alloc] initWithName:_name inTransaction:_tx] autorelease];
}
- (id)initWithName:(NSString *)_name 
  inTransaction:(OGoConfigGenTransaction *)_tx
{
  if ((self = [super init])) {
    self->tx      = _tx;
    self->name    = [_name copy];
    self->content = [[NSMutableString alloc] init];
  }
  return self;
}

- (void)dealloc {
  [self->name    release];
  [self->content release];
  [super dealloc];
}

- (void)_resetTransaction:(OGoConfigGenTransaction *)_tx {
  if (self->tx == _tx)
    self->tx = nil;
}

/* accessors */

- (OGoConfigGenTransaction *)configGenTransaction {
  return self->tx;
}
- (NSString *)name {
  return self->name;
}
- (NSString *)content {
  return [[self->content copy] autorelease];
}

/* operations */

- (NSException *)write:(NSString *)_s {
  if ([_s length] == 0) return nil;
  
  [self->content appendString:_s];
  
  return nil;
}

- (NSException *)writeln:(NSString *)_s {
  return [self write:[_s stringByAppendingString:@"\n"]];
}

/* description */

- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:128];
  [ms appendFormat:@"<0x%08X[%@]:", self, NSStringFromClass([self class])];
  
  [ms appendFormat:@" name='%@'",   self->name];
  [ms appendFormat:@" content: %@", self->content];
  
  [ms appendString:@">"];
  return ms;
}

@end /* OGoConfigGenTarget */
