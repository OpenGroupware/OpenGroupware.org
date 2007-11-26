/*
  Copyright (C) 2006-2007 Whitemice Consulting

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

#include "zOGIAction.h"
#include "zOGIAction+Object.h"
#include "zOGIAction+News.h"

@implementation zOGIAction(News)

-(id)_renderArticles:(NSArray *)_articles withDetail:(NSNumber *)_detail {
  NSMutableArray      *results;
  EOGenericRecord     *eoArticle;
  NSMutableDictionary *article;
  int                 i;

  if (_articles == nil)
    return [NSArray arrayWithObjects:nil];
  results = [NSMutableArray arrayWithCapacity:[_articles count]];
  for(i = 0; i < [_articles count]; i++) {
    eoArticle = [_articles objectAtIndex:i];
    article = [NSMutableDictionary new];
    [self _addObjectDetails:article withDetail:_detail];
    [self _stripInternalKeys:article];
    [results addObject:article];
  }
  return results;
} /* end _renderDocuments */

-(id)_getArticleForKey:(id)_pkey withDetail:(NSNumber *)_detail {
  return [[self _renderArticles:[self _getUnrenderedArticlesForKeys:_pkey]
                     withDetail:_detail] objectAtIndex:0];
} /* end _getArticleForKey */

-(id)_getArticlesForKeys:(id)_pkeys withDetail:(NSNumber *)_detail {
  return [[self _renderArticles:[self _getUnrenderedArticlesForKeys:_pkeys]
                     withDetail:_detail] objectAtIndex:0];
} /* end _getArticlesForKeys */

-(id)_getUnrenderedArticlesForKeys:(id)_keys {
  id keys;

  if ([_keys isKindOfClass:[NSArray class]])
    keys = _keys;
  else
    keys = [NSArray arrayWithObject:_keys];

  return [[self getCTX] runCommand:@"newsarticle::get",
            @"gids", [self _getEOsForPKeys:keys],
            @"returnType", intObj(LSDBReturnType_ManyObjects),
            nil];

} /* end _getUnrenderedArticlesForKeys */

@end /* End zOGIAction(Document) */
