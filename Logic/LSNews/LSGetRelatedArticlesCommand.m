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

#include "LSGetRelatedArticlesCommand.h"
#include "common.h"

@implementation LSGetRelatedArticlesCommand

- (void)dealloc {
  [self->articles release];
  [super dealloc];
}

/* command methods */

- (NSString *)_articleIdString {
  NSMutableString *ids;
  NSEnumerator    *listEnum;
  id              myArticle;
  BOOL            isFirst   = YES;
  
  ids      = [NSMutableString stringWithCapacity:256];
  listEnum = [self->articles objectEnumerator];
  while ((myArticle = [listEnum nextObject]) != nil) {
    if (isFirst)
      isFirst = NO;
    else
      [ids appendString:@","];
    
    [ids appendString:[[myArticle valueForKey:@"companyId"] stringValue]];
  }
  return ids;
}

- (EOSQLQualifier *)_qualifierForOneArticle {
  EOEntity       *relEntity;
  EOSQLQualifier *qualifier;
  id             art;

  relEntity = [[self databaseModel] entityNamed:[self relatedEntityName]];

  art       = [self article];
  qualifier = [[EOSQLQualifier alloc] initWithEntity:relEntity
				      qualifierFormat:
                                   @"%A=%@",
                                   @"toNewsArticleLink1.newsArticleId",
                                   [art valueForKey:@"newsArticleId"]];
  
  [qualifier setUsesDistinct:YES];
  
  return [qualifier autorelease];  
}

- (EOSQLQualifier *)_qualifierForNewsArticleLink {
  EOEntity       *assignmentEntity = nil;
  EOSQLQualifier *qualifier        = nil;
  NSString       *in               = nil;

  assignmentEntity = [[self databaseModel] entityNamed:@"NewsArticleLink"];

  in = [self _articleIdString];

  if ([in length] > 0) {
    qualifier = [[EOSQLQualifier alloc] initWithEntity:assignmentEntity
                                     qualifierFormat:
                                     @"%A IN (%@)", @"articleId", in];
  }
  else {
    qualifier  = [[EOSQLQualifier alloc] initWithEntity:assignmentEntity
                                      qualifierFormat:@"1=2"];
  }

  [qualifier setUsesDistinct:YES];

  return [qualifier autorelease];  
}

- (EOSQLQualifier *)_qualifierForMoreArticles {
  EOEntity       *relEntity = nil;
  EOSQLQualifier *qualifier = nil;
  NSString       *in        = nil;

  relEntity = [[self databaseModel] entityNamed:[self relatedEntityName]];
  in = [self _articleIdString];

  if ([in length] > 0) {
    qualifier = [[EOSQLQualifier alloc] initWithEntity:relEntity
                                     qualifierFormat:@"%A IN (%@)",
                                     @"toNewsArticleLink1.newsArticleId", in];
  }
  else {
    qualifier = [[EOSQLQualifier alloc] initWithEntity:relEntity
                                     qualifierFormat:@"1=2"];
  }

  [qualifier setUsesDistinct:YES];

  return [qualifier autorelease];  
}

- (NSArray *)_fetchForOneObjectInContext:(id)_context {
  NSMutableArray *relArticles;
  BOOL           isOk         = NO;
  id             obj          = nil; 

  relArticles = [NSMutableArray arrayWithCapacity:16];
  isOk = [[self databaseChannel] selectObjectsDescribedByQualifier:
				   [self _qualifierForOneArticle]
                                 fetchOrder:nil];

  [self assert:isOk reason:[dbMessages description]];
  
  while ((obj = [[self databaseChannel] fetchWithZone:NULL])) {
    [relArticles addObject:obj];
    obj = nil;
  }

  [[self article] takeValue:relArticles forKey:@"relatedArticles"];

  return relArticles;
}

- (id)_findArticlesWithId:(NSNumber *)_articleId
  inArticles:(NSArray *)_articles
{
  NSEnumerator *listEnum;
  id           art;
  
  listEnum = [_articles objectEnumerator];
  while ((art = [listEnum nextObject])) {
    if ([[art valueForKey:@"companyId"] isEqual:_articleId])
      return art;
  }
  return nil;
}

- (void)_setAssignments:(NSMutableArray *)_assignments
  andRelArticles:(NSArray *)_relArticles 
{
  NSEnumerator *listEnum;
  id           myArticle;

  listEnum = [self->articles objectEnumerator];
  while ((myArticle = [listEnum nextObject])) {
    NSMutableArray *myAssignments = [[NSMutableArray alloc] init];
    NSMutableArray *relArticles   = [[NSMutableArray alloc] init];
    int            i, cnt         = [_assignments count];

    i = 0;
    
    while (i < cnt) {
      id myAssignment = [_assignments objectAtIndex:i];

      if ([[myArticle valueForKey:@"newsArticleId"]
          isEqual:[myAssignment valueForKey:@"newsArticleId"]]) {
        NSNumber *snAId = [myAssignment valueForKey:@"subNewsArticleId"];
        id       relArt = [self _findArticlesWithId:snAId
                                inArticles:_relArticles];

        [myAssignments addObject:myAssignment];

        if (relArt != nil) {
          [relArticles addObject:relArt];
        }
        [_assignments removeObjectAtIndex:i];
        cnt--;
      }
      else {
        i++;
      }
    }
    [myArticle takeValue:relArticles forKey:@"relatedArticles"];
    [myAssignments release]; myAssignments = nil;
    [relArticles   release]; relArticles = nil;
  }
}

- (NSArray *)_fetchForMoreObjectsInContext:(id)_context {
  NSMutableArray *myAssignments;
  NSMutableArray *relArticles;
  BOOL           isOk           = NO;
  id             obj            = nil; 

  myAssignments = [[NSMutableArray alloc] initWithCapacity:16];
  relArticles   = [NSMutableArray arrayWithCapacity:16];
  isOk = [[self databaseChannel] selectObjectsDescribedByQualifier:
                                 [self _qualifierForNewsArticleLink]
                                 fetchOrder:nil];

  [self assert:isOk reason:[dbMessages description]];
  
  while ((obj = [[self databaseChannel] fetchWithZone:NULL])) {
    [myAssignments addObject:obj];
    obj = nil;
  }

  isOk = [[self databaseChannel] selectObjectsDescribedByQualifier:
                                 [self _qualifierForMoreArticles]
                                 fetchOrder:nil];

  [self assert:isOk reason:[dbMessages description]];
  
  while ((obj = [[self databaseChannel] fetchWithZone:NULL])) {
    [relArticles addObject:obj];
    obj = nil;
  }

  [self _setAssignments:myAssignments andRelArticles:relArticles];
  [myAssignments release]; myAssignments = nil;  
  
  return relArticles;
}

- (void)_executeInContext:(id)_context {
  [self setReturnValue:([self->articles count] == 1)
          ? [self _fetchForOneObjectInContext:_context]
          : [self _fetchForMoreObjectsInContext:_context]];
}

/* record initializer */

- (NSString *)entityName {
  return @"NewsArticle";
}
- (NSString *)relatedEntityName {
  return @"NewsArticle";
}

/* accessors */

- (void)setArticle:(id)_article {
  _article = [NSArray arrayWithObject:_article];
  ASSIGN(self->articles, _article);
}
- (id)article {
  return [self->articles lastObject];
}

- (void)setArticles:(NSArray *)_articles {
  ASSIGN(self->articles, _articles);
}
- (NSArray *)articles {
  return self->articles;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"article"] || [_key isEqualToString:@"object"])
    [self setArticle:_value];
  else if ([_key isEqualToString:@"articles"])
    [self setArticles:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"article"] || [_key isEqualToString:@"object"])
    return [self article];
  if ([_key isEqualToString:@"articles"])
    return [self articles];
  return [super valueForKey:_key];
}

@end /* LSGetRelatedArticlesCommand */
