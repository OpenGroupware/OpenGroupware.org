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

#import "common.h"
#include <LSFoundation/LSDBFetchRelationCommand.h>

@interface LSGetCommentForAppointmentsCommand : LSDBFetchRelationCommand
@end

@implementation LSGetCommentForAppointmentsCommand

/* accessors */

- (NSString *)entityName {
  return @"Date";
}

- (EOEntity *)destinationEntity {
  return [[self databaseModel] entityNamed:@"DateInfo"];
}
 
- (BOOL)isToMany {
  return NO; 
}
 
- (NSString *)sourceKey {
  return @"dateId";
}

- (NSString *)destinationKey {
  return @"dateId";
}

- (NSString *)relationKey {
  return @"dateInfo";
}

/* run command */

- (void)_executeInContext:(id)_context {
  /* TODO: rewrite to use the adaptor to fetch comments */
  int     i, cnt;
  NSArray *apmts;
  
  [super _executeInContext:_context];
  
  apmts = [self object];
  for (i = 0, cnt = [apmts count]; i < cnt; i++) {
    id       apmt;
    NSString *comment;
    
    apmt    = [apmts objectAtIndex:i];
    comment = [[apmt valueForKey:@"dateInfo"] valueForKey:@"comment"];
    if ([comment isNotNull])
      [apmt takeValue:[comment stringValue] forKey:@"comment"];
  }
}

@end /* LSGetCommentForAppointmentsCommand */
