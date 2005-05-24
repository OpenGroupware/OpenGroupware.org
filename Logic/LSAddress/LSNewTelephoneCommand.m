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

#include <LSFoundation/LSDBObjectNewCommand.h>
#include <LSFoundation/LSDBObjectSetCommand.h>

@interface LSNewTelephoneCommand : LSDBObjectNewCommand
@end

@interface LSSetTelephoneCommand : LSDBObjectSetCommand
@end

#include "common.h"
#include "NSString+Phone.h"
#include <NGExtensions/NSNull+misc.h>

@implementation LSNewTelephoneCommand

- (void)_prepareForExecutionInContext:(id)_ctx {
  id obj;
  NSString *number;
  
  [super _prepareForExecutionInContext:_ctx];
  
  obj = [self object];
  number     = [obj valueForKey:@"number"];
  if ([number isNotNull] && [number length]) {
    NSString *realNumber;
    
    realNumber = [obj valueForKey:@"realNumber"];
    if ((![realNumber isNotNull]) || ([realNumber length] == 0)) {
      realNumber = [number stringByNormalizingOGoPhoneNumber];
      [obj takeValue:realNumber forKey:@"realNumber"];
    }
  }
}

- (NSString *)entityName {
  return @"Telephone";
}

@end /* LSNewTelephoneCommand */

@implementation LSSetTelephoneCommand

- (void)_prepareForExecutionInContext:(id)_ctx {
  id obj;
  NSString *number;
  
  [super _prepareForExecutionInContext:_ctx];
  obj = [self object];
  number     = [obj valueForKey:@"number"];
  if ([number isNotNull] && [number length]) {
    NSString *realNumber = [obj valueForKey:@"realNumber"];
    if ((![realNumber isNotNull]) || (![realNumber length])) {
      realNumber = [number stringByNormalizingOGoPhoneNumber];
      [obj takeValue:realNumber forKey:@"realNumber"];
    }
  }
}

- (NSString *)entityName {
  return @"Telephone";
}

@end /* LSSetTelephoneCommand */
