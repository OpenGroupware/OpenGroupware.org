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

#import <LSFoundation/LSDBFetchRelationCommand.h>

@interface LSFetchControlJobsCommand : LSDBFetchRelationCommand
@end

#import "common.h"

@implementation LSFetchControlJobsCommand

- (NSString *)entityName {
  return @"Person";
}

- (EOEntity *)destinationEntity {
  return [[self databaseModel] entityNamed:@"Job"];
}
 
- (BOOL)isToMany {
  return YES; 
}
 
- (NSString *)sourceKey {
  return @"companyId";
}

- (NSString *)destinationKey {
  return @"executantId";
}

- (EOSQLQualifier *)_qualifier {
  EOSQLQualifier *qualifier = nil;
  qualifier = [[EOSQLQualifier allocWithZone:[self zone]]
                            initWithEntity:[self destinationEntity]
                            qualifierFormat:
                              @"(%A <> '%@') AND (%A = 1) AND (%A IS NULL)",
                              @"jobStatus", LSJobArchived,
                              @"isControlJob", @"kind", nil];
  [qualifier conjoinWithQualifier:[super _qualifier]];  
  return AUTORELEASE(qualifier);
}

@end
