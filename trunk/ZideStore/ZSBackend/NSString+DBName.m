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

#include "NSString+DBName.h"
#import <Foundation/Foundation.h>

@implementation NSString(DBName)

- (BOOL)isPostgreSQL {
  return ([self hasPrefix:@"pgsql_"] ||
          ([self rangeOfString:@"PostgreSQL"].length > 0)) ? YES : NO;
}

- (BOOL)isOracle {
  return ([self hasPrefix:@"oracle_"] ||
          ([self rangeOfString:@"Oracle"].length > 0)) ? YES : NO;
}

- (BOOL)isFrontbase {
  return ([self hasPrefix:@"fb_"] ||
          ([self rangeOfString:@"Frontbase"].length > 0)) ? YES : NO;
}

- (BOOL)isSybase {
  return ([self hasPrefix:@"sybase_"] ||
          ([self rangeOfString:@"Sybase"].length > 0)) ? YES : NO;
}

@end /* NSString(RTF) */
