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

#include "LSWProjectMailPage.h"
#import "common.h"

@interface LSWProjectMailPage(Private)
@end

@implementation LSWProjectMailPage

- (NSString *)entityName {
  return @"Project";
}

- (NSString *)getCmdName {
  return @"project::get";
}

- (NSString *)objectUrlKey {
  id obj      = nil;
  id folderId = nil;

  obj      = [self object];
  folderId = [obj valueForKey:@"currentFolderId"];

  if ([folderId isNotNull]) {
    return [NSString stringWithFormat:
                       @"wa/LSWViewAction/viewProject"
                       @"?projectId=%@&documentId=%@",
                       [obj valueForKey:@"projectId"],
                       folderId];
  }
  else {
    return [NSString stringWithFormat:
                       @"wa/LSWViewAction/viewProject?projectId=%@",
                       [obj valueForKey:@"projectId"]];
  }
}

@end

@implementation LSWProjectHtmlMailPage
@end

@implementation LSWProjectTextMailPage
@end
