/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include "LSWJobMailPage.h"
#include "common.h"

@implementation LSWJobMailPage

static NSArray *historySortOrderings = nil;

+ (void)initialize {
  EOSortOrdering *so;
  
  so = [EOSortOrdering sortOrderingWithKey:@"actionDate"
		       selector:EOCompareAscending];
  historySortOrderings = [[NSArray alloc] initWithObjects:&so count:1];
}

/* fetching */

- (NSString *)entityName {
  return @"Job";
}

- (NSString *)getCmdName {
  return @"job::get";
}

- (void)setObject:(id)_object {
  id obj;
  
  [super setObject:_object];
  
  obj = [self object];
  
  [self runCommand:@"job::setcreator",
          @"relationKey", @"creator", @"object", obj, nil];
  [self runCommand:@"job::get-job-history", 
          @"relationKey", @"jobHistory", @"object", obj, nil];
  [self runCommand:@"job::get-job-executants",
          @"relationKey", @"executant", @"object", obj, nil];
}

/* URL */

- (NSString *)objectUrlKey {
  NSString *s;
  
  if ((s = [[[self object] valueForKey:@"jobId"] stringValue]) == nil)
    return nil;

  // TODO: we should use some URL creation method (WOContext)
  return [@"wa/LSWViewAction/viewJob?jobId=" stringByAppendingString:s];
}

/* accessors */

- (BOOL)isTeamJob {
  return [[[self object] valueForKey:@"isTeamJob"] boolValue];
}

- (NSString *)lastComment {
  NSArray  *history;
  NSArray  *sortedHistory;
  NSString *comment;
  
  history = [[self object] valueForKey:@"jobHistory"];
  if (![history isNotNull])
    return nil;
  
  sortedHistory = [history sortedArrayUsingKeyOrderArray:historySortOrderings];
  comment = [[[[sortedHistory lastObject] 
  		valueForKey:@"toJobHistoryInfo"] lastObject]
	      valueForKey:@"comment"];
  return [[comment retain] autorelease];
}

@end /* LSWJobMailPage */

@implementation LSWJobHtmlMailPage
@end /* LSWJobHtmlMailPage */

@implementation LSWJobTextMailPage
@end /* LSWJobTextMailPage */
