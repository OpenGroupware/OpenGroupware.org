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

#import <LSFoundation/LSDBObjectBaseCommand.h>

@class NSArray;

/**
 * @class LSSetRelatedArticlesCommand
 * @brief Updates the set of articles linked to a news
 *        article.
 *
 * Synchronises the NewsArticleLink join-table rows
 * for the given news article object. Existing links
 * that are no longer in the `relatedArticles` array
 * are deleted, and new links are created for articles
 * not yet present. The command accepts the source
 * article via "newsArticle" key.
 */
@interface LSSetRelatedArticlesCommand : LSDBObjectBaseCommand
{
@private 
  NSArray *relatedArticles;
}

@end
