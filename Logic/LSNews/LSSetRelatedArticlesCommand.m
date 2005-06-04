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
#import "LSSetRelatedArticlesCommand.h"

@implementation LSSetRelatedArticlesCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->relatedArticles);
  [super dealloc];
}
#endif

// command methods

- (BOOL)_object:(id)_object isInList:(NSArray *)_list {
  NSEnumerator *listEnum  = [_list objectEnumerator];
  id           listObject = nil;
  id           pkey;

  pkey = [_object valueForKey:@"subNewsArticleId"];

  while ((listObject = [listEnum nextObject])) {
    id opkey = [listObject valueForKey:@"newsArticleId"];

    if ([pkey isEqual:opkey]) return YES;
  }
  return NO;
}

- (BOOL)_object2:(id)_object isInList:(NSArray *)_list {
  NSEnumerator *listEnum  = [_list objectEnumerator];
  id           listObject = nil;
  id           pkey;

  pkey = [_object valueForKey:@"newsArticleId"];

  while ((listObject = [listEnum nextObject])) {
    id opkey = [listObject valueForKey:@"subNewsArticleId"];

    if ([pkey isEqual:opkey]) return YES;
  }
  return NO;
}

- (void)_removeOldAssignmentsInContext:(id)_context {
  NSArray      *oldAssignments;
  NSEnumerator *listEnum;
  id           assignment; 

  oldAssignments = [[self object] valueForKey:@"toNewsArticleLink"];
  listEnum       = [oldAssignments objectEnumerator];

  while ((assignment = [listEnum nextObject])) {
    if (![self _object:assignment isInList:self->relatedArticles]) {
      LSRunCommandV(_context,        @"newsarticlelink",  @"delete",
                    @"object",       assignment,
                    @"reallyDelete", [NSNumber numberWithBool:YES], nil);
    }
  }
}

- (void)_saveAssignmentsInContext:(id)_context {
  NSArray      *oldAssignments;
  NSEnumerator *listEnum;
  id           obj;
  id           newAssignment;

  obj            = [self object];
  oldAssignments = [obj valueForKey:@"toNewsArticleLink"];
  listEnum       = [self->relatedArticles objectEnumerator];
  
  while ((newAssignment = [listEnum nextObject])) {
    if (![self _object2:newAssignment isInList:oldAssignments]) {
      LSRunCommandV(_context,         @"newsarticlelink",  @"new",
                    @"newsArticleId", [obj valueForKey:@"newsArticleId"],
                    @"subNewsArticleId",
                      [newAssignment valueForKey:@"newsArticleId"], nil);
    }
  }
}

- (void)_executeInContext:(id)_context {
  [self _removeOldAssignmentsInContext:_context];
  [self _saveAssignmentsInContext:_context];
}

// initialize records

- (NSString *)entityName {
  return @"NewsArticleLink";
}

// accessors

- (void)setRelatedArticles:(NSArray *)_articles{
  ASSIGN(self->relatedArticles, _articles);
}
- (NSArray *)relatedArticles {
  return self->relatedArticles;
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"newsArticle"]) {
    [self setObject:_value];
    return;
  }
  else if ([_key isEqualToString:@"relatedArticles"]) {
    [self setRelatedArticles:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"newsArticle"])
    return [self object];
  if ([_key isEqualToString:@"relatedArticles"])
    return [self relatedArticles];
  return [super valueForKey:_key];
}

@end