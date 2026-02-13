/*
  Copyright (C) 2008 Whitemice Consulting (Adam Tauno Williams)

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

#ifndef __LSFoundation_LSGetAsRSSFeedCommand_H__
#define __LSFoundation_LSGetAsRSSFeedCommand_H__

#include <LSFoundation/LSDBObjectBaseCommand.h>

@class NSCalendarDate, NSTimeZone, NSNumber;
@class NSMutableString;
@class LSCommandContext;

/**
 * @class LSGetAsRSSFeedCommand
 * @brief Abstract base command for generating RSS 2.0 feeds
 *   from database queries.
 *
 * Subclasses override -buildQueryExpression to construct the
 * SQL query, -rssChannelTitle and -rssChannelDescription to
 * provide channel metadata, and -appendRSSItem: to render
 * each database record as an RSS item.
 *
 * The command produces a UTF-8 encoded NSData containing
 * the complete RSS XML document as its return value.
 * Supports configurable time zone, item limit, feed URL,
 * and channel URL.
 *
 * @see LSDBObjectBaseCommand
 */
@interface LSGetAsRSSFeedCommand : LSDBObjectBaseCommand
{
  NSMutableString   *rss, *sql;
  NSTimeZone        *tz;
  NSNumber          *limit;
  NSString          *feedURL, *channelURL;
}

- (NSTimeZone *)timeZone;
- (void)setTimeZone:(NSTimeZone *)_tz;
- (NSNumber *)limit;
- (void)setLimit:(NSNumber *)_limit;
- (NSString *)feedURL;
- (void)setFeedURL:(NSString *)_url;
- (NSString *)channelURL;
- (void)setChannelURL:(NSString *)_url;
- (void)buildQueryExpression;
- (NSMutableString *)query;
- (NSString *)rssChannelTitle;
- (NSString *)rssChannelDescription;
- (void)appendRSSItem:(NSDictionary *)_record;
- (void)addTable:(NSString *)_entity as:(NSString *)_as;
- (void)addInnerJoin:(NSString *)_entity as:(NSString *)_as on:(NSString *)_on;
- (void)addOuterJoin:(NSString *)_entity as:(NSString *)_as on:(NSString *)_on;
- (void)appendRSSItem:(NSString *)_description
           withTitle:(NSString *)_title
             andDate:(NSCalendarDate *)_date
           andAuthor:(NSString *)_author
             andLink:(NSString *)_link
             andGUID:(NSString *)_guid
           forObject:(id)_objectId;

@end /* LSGetAsRSSFeedCommand */

#endif /*  __LSFoundation_LSGetAsRSSFeedCommand_H__ */
