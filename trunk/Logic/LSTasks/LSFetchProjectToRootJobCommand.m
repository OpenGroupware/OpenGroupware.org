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

#import <LSFoundation/LSDBFetchRelationCommand.h>

@interface LSFetchProjectToRootJobCommand : LSDBFetchRelationCommand
@end

#import "common.h"

#define RootProcess @"01_root_process"

@implementation LSFetchProjectToRootJobCommand

- (NSString *)entityName {
  return @"Project";
}

- (EOEntity *)destinationEntity {
  return [[self databaseModel] entityNamed:@"Job"];
}
 
- (BOOL)isToMany {
  return YES; 
}
 
- (NSString *)sourceKey {
  return @"projectId";
}

- (NSString *)destinationKey {
  return @"projectId";
}

- (EOSQLQualifier *)_qualifier {
  EOSQLQualifier *qualifier = nil;

  qualifier = [[EOSQLQualifier allocWithZone:[self zone]]
                            initWithEntity:[self destinationEntity]
                            qualifierFormat:
                            @"(%A = '%@')",
                            @"kind", RootProcess, nil];
  [qualifier conjoinWithQualifier:[super _qualifier]];  
  return AUTORELEASE(qualifier);
}

- (void)_executeInContext:(id)_context {
  id obj = [[self object] lastObject];
  
  [super _executeInContext:_context];

  {
    NSString *relKey = [self relationKey];
    NSArray  *r      = nil;
    
    r = (relKey == nil) ? [self returnValue] : [obj valueForKey:relKey];

    if (([r lastObject] == nil) ||
        ![[[r lastObject] valueForKey:@"kind"] isEqualToString:RootProcess])
      r = [NSArray array];

    [self assert:([r count] <= 1)
          reason:@"project has more than one root process!!!"];

    // if no root process
    if ([r count] == 0) {
      id rootProcess = LSRunCommandV(_context, @"job", @"new",
        @"projectId", [obj valueForKey:@"projectId"],
        @"kind",      RootProcess,
        @"name",      @"RootProcess",
        @"startDate", [obj valueForKey:@"startDate"],
        @"endDate",   [NSCalendarDate dateWithString:@"2028-01-01 00:00:00 +0"],
        nil);
      
      r = [NSArray arrayWithObject:rootProcess];
    }
    if (relKey == nil) 
      [self setReturnValue:[r lastObject]];
    else
      [obj takeValue:[r lastObject] forKey:relKey];
  }
}

@end
