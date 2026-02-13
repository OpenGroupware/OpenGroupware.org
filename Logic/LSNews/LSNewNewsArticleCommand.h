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

#ifndef __LSLogic_LSNews_LSNewNewsArticleCommand_H__
#define __LSLogic_LSNews_LSNewNewsArticleCommand_H__

#include <LSFoundation/LSDBObjectNewCommand.h>

@class NSData, NSString, NSArray;

/**
 * @class LSNewNewsArticleCommand
 * @brief Creates a new NewsArticle record, saves its
 *        text content and optional image attachment.
 *
 * Inserts a new row into the NewsArticle entity.
 * If the article is marked as the index article,
 * all other articles are demoted first. Related
 * articles are linked via
 * "newsArticle::set-related-Articles"; if none are
 * supplied, the current index articles are used.
 *
 * The text body (`fileContent`) is written to
 * `LSAttachmentPath` and the optional image (`data`
 * with `filePath` for the extension) is written to
 * `LSNewsImagesPath`.
 */
@interface LSNewNewsArticleCommand : LSDBObjectNewCommand
{
@protected  
  NSData   *data;
  NSString *filePath;
  NSString *fileContent;
  NSArray  *relatedArticles;
}

@end

#endif /* __LSLogic_LSNews_LSNewNewsArticleCommand_H__ */
