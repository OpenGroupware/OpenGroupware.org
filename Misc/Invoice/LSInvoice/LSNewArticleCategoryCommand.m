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
#import "LSNewArticleCategoryCommand.h"

@interface LSNewArticleCategoryCommand(privateMethods)
- (void)_checkCategoryNameInContext:(id)_context;
@end

@implementation LSNewArticleCategoryCommand

- (void)_checkCategoryNameInContext:(id)_context {
  NSArray*       categories = nil;
  NSEnumerator* catEnum    = nil;
  id category = nil;
  NSString* catName = [self valueForKey:@"categoryName"];
  NSString* scndName = nil;

  [self assert:
    ((catName != nil) &&
     ([catName isNotNull]) &&
     (![catName isEqualToString:@""]))
    reason:@"No CategoryName set!"];

  categories = LSRunCommandV(_context, @"articlecategory", @"get",
                             @"returnType", intObj(LSDBReturnType_ManyObjects),
                             nil);
  catEnum = [categories objectEnumerator];

  while ((category = [catEnum nextObject])) {
    scndName = [category valueForKey:@"categoryName"];
    [self assert: (![scndName isEqualToString:catName])
          reason:@"CategoryName already existent!"];
  }

}

- (void)_prepareForExecutionInContext:(id)_context {
  id account = [_context valueForKey:LSAccountKey];
  NSEnumerator *teamEnum =
    [LSRunCommandV(_context, @"account", @"teams",
                  @"account", account,
                  @"returnType", intObj(LSDBReturnType_ManyObjects),
                  nil) objectEnumerator];
  id team;
  BOOL access = NO;
  while ((team = [teamEnum nextObject])) {
    if ([[team valueForKey:@"login"] isEqualToString:@"invoices"]) {
      access = YES;
    }
  }
  [self assert:access
        reason:@"You have no permission for doing that!"];
  [self _checkCategoryNameInContext:_context];

  [super _prepareForExecutionInContext:_context];
}

- (NSString*)entityName {
  return @"ArticleCategory";
}

@end
