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

#include "NSObject+DBColumns.h"
#include "NSString+DBName.h"
#include "common.h"

@implementation NSObject(DBColumns)

- (NSString *)modelName {
  static NSString *modelName = nil;
  if (modelName == nil) {
    modelName = [[[NSUserDefaults standardUserDefaults]
		   stringForKey:@"LSModelName"] copy];
  }
  return modelName;
}

- (NSString *)numberColumn {
  static NSString *numberName = nil;
  if (numberName == nil) {
    NSString *mName;

    mName = [self modelName];

    if ([mName isPostgreSQL])
      numberName = @"number";
    else if (([mName isOracle]) || ([mName isFrontbase]))
      numberName = @"fnumber";
    else numberName = @"number";
  }
  return numberName;
}

- (NSString *)typeColumn {
  static NSString *typeName = nil;
  if (typeName == nil) {
    NSString *mName;

    mName = [self modelName];

    if ([mName isPostgreSQL])
      typeName = @"type";
    else if (([mName isOracle]) || ([mName isFrontbase]))
      typeName = @"ftype";
    else typeName = @"type";
  }
  return typeName;
}
  
@end /* NSObject(DBColumns) */
