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

#include "SkyArticleCategoryViewer.h"
#include "common.h"
#include <OGoFoundation/LSWSession.h>

@interface SkyArticleCategoryViewer(PrivateMethods)
- (void)setTabKey:(NSString *)_key;
@end

@implementation SkyArticleCategoryViewer

- (id)init {
  if ((self = [super init])) {
    [self setTabKey:@"attributes"];
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->tabKey);
  [super dealloc];
}
#endif

- (BOOL)isEditEnabled {
  return YES;
  // has to be improved
}

- (BOOL)isDeleteEnabled {
  return YES;
  // has to be improved
}

//accessors

- (id)category {
  return self->object;
}

- (void)setTabKey:(NSString *)_tabKey {
  ASSIGN(self->tabKey,_tabKey);
}
- (NSString *)tabKey {
  return self->tabKey;
}

//actions

- (id)edit {
  if ([self isEditEnabled]) {
    return [super edit];
  }
  [self setErrorString:@"Category isn't editable!"];
  return nil;
}


- (id)delete {
  [self setWarningOkAction:@"reallyDelete"];
  [self setWarningPhrase:@"Really Delete"];
  [self setIsInWarningMode:YES];

  return nil;
}

- (id)reallyDelete {
  id result;

  result = [[self object] run:@"articlecategory::delete",
                         @"reallyDelete", [NSNumber numberWithBool:YES],
                         nil];
  [self setIsInWarningMode:NO];
  if (result) {
    if (![self commit]) {
      [self setErrorString:@"Couldn't commit articlecategory delete !"];
      [self rollback];
      return nil;
    }
    [self postChange:@"LSWDeletedArticleCategory" onObject: result];
    [self back];
  }
  
  return nil;
}

- (id)cancel {
  [self setIsInWarningMode:NO];
  return nil;
}

// sales
- (NSArray *)articleIds {
  NSMutableArray *ids = [NSMutableArray array];
  NSArray        *all = nil;
  NSEnumerator   *e   = nil;
  id             one  = nil;

  all = [self runCommand:@"article::get",
              @"articleCategoryId",
              [[self category] valueForKey:@"articleCategoryId"],
              @"returnType", intObj(LSDBReturnType_ManyObjects),
              nil];
  e = [all objectEnumerator];
  while ((one = [e nextObject])) {
    [ids addObject:[one valueForKey:@"articleId"]];
  }
  return ids;
}

@end
