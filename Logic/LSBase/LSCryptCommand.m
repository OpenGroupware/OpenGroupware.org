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

#include "LSCryptCommand.h"
#include "common.h"
#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>

@implementation LSCryptCommand

- (void)dealloc {
  [self->passwd release];
  [self->salt   release];
  [super dealloc];
}

- (NSString *)_salt {
  NSMutableString *mySalt;
  int             i, timeInt;
  unsigned char   c;    
  
  mySalt    = [NSMutableString stringWithCapacity:16];
  timeInt = (int)time(0);
  srand(timeInt);

  for (i = 0; i < 2; i++) {
    NSString *s;
    
    do {
      c = 46 + (rand() % 76);
    }
    while (((c > 57) && (c < 65)) || ((c > 90) && (c < 97)));
    
    s = [[NSString alloc] initWithCString:(char *)&c length:1];
    [mySalt appendString:s];
    [s release];
  }
  return mySalt;
}

- (void)_executeInContext:(id)_context {
  NSString *mySalt        = nil;
  NSString *cryptedPasswd = nil;

  mySalt = self->salt ? self->salt : [self _salt];
  
  if ([self->passwd isNotNull] && [mySalt isNotNull]) {
#if defined(__MINGW32__) || defined(__CYGWIN32__)
    cryptedPasswd = self->passwd;
#else
    cryptedPasswd = [NSString stringWithCString:crypt([self->passwd cString],
                                                      [mySalt cString])];
#endif
  }
  else {
    cryptedPasswd = @"";
  }
  [self setReturnValue:cryptedPasswd];
}

- (void)setPasswd:(NSString *)_passwd {
  if (self->passwd != _passwd) {
    [self->passwd release]; self->passwd = nil;
    self->passwd = [_passwd copy];
  }
}
- (NSString *)passwd {
  return self->passwd;
}

- (void)setSalt:(NSString *)_salt {
  if (self->salt != _salt) {
    [self->salt release]; self->salt = nil;
    self->salt = [_salt copy];
  }
}
- (NSString *)salt {
  return self->salt;
}

/* command type */

- (BOOL)requiresChannel {
  return NO;
}
- (BOOL)requiresTransaction {
  return NO;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"password"])
    [self setPasswd:_value];
  else if ([_key isEqualToString:@"salt"])
    [self setSalt:_value];
  else
    [self foundInvalidSetKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"password"])
    return [self passwd];
  if ([_key isEqualToString:@"salt"])
    return [self passwd];

  return [super valueForKey:_key];
}

@end /* LSCryptCommand */
