/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include "LSWJobMailPage.h"
#include "common.h"

@implementation LSWJobMailPage

- (NSString *)entityName {
  return @"Job";
}

- (NSString *)getCmdName {
  return @"job::get";
}

- (void)setObject:(id)_object {
  [super setObject:_object];
  {
    id obj = [self object];

    [obj run:@"job::setcreator",   @"relationKey", @"creator", nil];
    [obj run:@"job::get-job-history", @"relationKey", @"jobHistory", nil];
    [self runCommand:@"job::get-job-executants",
          @"relationKey", @"executant", @"object", obj, nil];
  }
}

- (NSString *)objectUrlKey {
  return [NSString stringWithFormat:@"wa/LSWViewAction/viewJob?jobId=%@",
                     [[self object] valueForKey:@"jobId"]];
}

@end /* LSWJobMailPage */

@implementation LSWJobHtmlMailPage
@end

@implementation LSWJobTextMailPage
@end
