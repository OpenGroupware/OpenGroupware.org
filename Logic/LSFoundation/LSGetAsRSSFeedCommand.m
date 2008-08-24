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


#include <LSFoundation/LSDBObjectBaseCommand.h>
#include <LSFoundation/LSCommandContext.h>
#include <LSFoundation/LSGetAsRSSFeedCommand.h>
#include "common.h"

@class NSCalendarDate, NSTimeZone;
@class NSMutableString;

@implementation LSGetAsRSSFeedCommand

static BOOL       debugOn      = NO; 

+ (void)initialize {
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    rss = [NSMutableString stringWithString:@"<?xml version=\"1.0\"?>"];
    [rss appendString:@"<rss version=\"2.0\" xmlns:atom=\"http://www.w3.org/2005/Atom\">\n"];
    sql = [NSMutableString stringWithCapacity:512];
  }
  return self;
}

- (void)dealloc {
  [self->feedURL release];
  [self->channelURL release];
  [self->limit release];
  [self->tz release];
  [super dealloc];
}

/* accessors */

- (NSTimeZone *)timeZone {
  return self->tz;
}

- (void)setTimeZone:(NSTimeZone *)_tz {
  ASSIGNCOPY(self->tz, _tz);
}

- (NSNumber *)limit {
  return self->limit;
}

- (void)setLimit:(NSNumber *)_limit {
  ASSIGNCOPY(self->limit, _limit);
}

- (NSString*)feedURL {
  return self->feedURL;
}

- (void)setFeedURL:(NSString *)_url {
  ASSIGNCOPY(self->feedURL, _url);
}

- (NSString*)channelURL {
  NSUserDefaults      *ud;
 
  if ([self->channelURL isNotNull])
    return self->channelURL;

  ud = [NSUserDefaults standardUserDefaults];
  return [ud stringForKey:@"RSSDefaultChannelLinkURL"];
}

- (void)setChannelURL:(NSString *)_url {
  ASSIGNCOPY(self->channelURL, _url);
}

- (NSMutableString *)query {
  return sql;
}

/* Data expression, override in descendent */

- (void)buildQueryExpression {
}

/* RSS data methods, override in descendents */

- (NSString *)rssChannelTitle {
  return @"override in descendent";
}

- (NSString *)rssChannelDescription {
  return @"override in descendent";
}

- (void)appendRSSItem:(NSDictionary *)_record {
}

/* RSS Rendering Methods */

/* This method creates the header of the RSS feed which declares the channel,
   the title and description come from the rssChannelTitle and 
   rssChannelDescription methods which should be overridden in subclasses that
   implement actual feeds.  The pubDate wil always be now. */
- (void)_openRSSChannelInfo {

  if ([self feedURL] == nil)
    [self warnWithFormat:@"no feedURL provided for RSS feed, "
                         @"produced feed will not be valid!"];

  if ([self channelURL] == nil)
    [self warnWithFormat:@"no channelURL provided for RSS feed, "
                         @"produced feed will not be valid!"];

  /* We are indening the XML tags so they look pretty if the feed / XML
     is viewed in a text editor */ 
  [rss appendString:@"<channel>\n"];
  [rss appendFormat:@"  <title>%@</title>\n", 
    [[self rssChannelTitle] stringByEscapingHTMLString]];
  [rss appendFormat:@"  <description>%@</description>\n", 
    [[self rssChannelDescription] stringByEscapingHTMLString]];
  [rss appendString:@"  <generator>OpenGroupware</generator>\n"];
  if ([[self feedURL] isNotNull])
     [rss appendFormat:@"  <atom:link href=\"%@\" rel=\"self\" type=\"application/rss+xml\"/>\n", 
                       [[self feedURL] stringByEscapingHTMLString]];
  if ([[self channelURL] isNotNull]) 
    [rss appendFormat:@"  <link>%@</link>\n",
                      [[self channelURL] stringByEscapingHTMLString]];
  [rss appendFormat:@"  <pubDate>%@</pubDate>\n", 
     [[NSCalendarDate date] descriptionWithCalendarFormat:@"%a, %d %b %Y %H:%M:%S GMT"]];
}

- (void)_closeRSSChannel {
  [rss appendString:@"</channel>\n"];
}

- (void)_closeRSS {
  [rss appendString:@"</rss>"];
}

- (void)appendRSSItem:(NSString *)_description 
           withTitle:(NSString *)_title 
             andDate:(NSCalendarDate *)_date
           andAuthor:(NSString *)_author
             andLink:(NSString *)_link
             andGUID:(NSString *)_guid
           forObject:(id)_objectId {

  NSString   *comment, *timestamp, *url;

  comment = [_description stringByReplacingString:@"\n" withString:@"<BR>"];
  comment = [comment stringByReplacingString:@"\r" withString:@""];
  comment = [comment stringByEscapingHTMLString];

  /* TODO: We are assuming the date is GMT, if a timezone was specified
           then we should changed the time accordingly and specify that
           time zone */
  timestamp = [_date descriptionWithCalendarFormat:@"%a, %d %b %Y %H:%M:%S GMT"];

  /* We are indening the XML tags so they look pretty if the feed / XML
     is viewed in a text editor */ 
  [rss appendFormat:@"  <item>\n"
                    @"    <title>%@</title>\n"
                    @"    <description>%@</description>\n"
                    @"    <pubDate>%@</pubDate>\n"
                    @"    <guid isPermaLink=\"false\">%@</guid>\n",
                    _title, comment, timestamp, _guid];

  if ([_author isNotNull]) {
    [rss appendFormat:@"    <author>%@</author>\n", _author];
  }

  if ([_link isNotNull]) {
    url = _link;
  } else {
      // get the default URL pattern from defaults
      NSUserDefaults *ud;

      ud = [NSUserDefaults standardUserDefaults]; 
      url = [ud stringForKey:@"RSSDefaultItemLinkURL"];
      if ([url isNotNull]) {
        // replace $objectId in default pattern with provided objectId
        if ([_objectId isNotNull]) {
          url = [url stringByReplacingString:@"$objectId" 
                                  withString:[_objectId stringValue]];
        }
        // replace $GUID in default pattern with provided GUID
        url = [url stringByReplacingString:@"$GUID" withString:_guid];
      }
    }
  if ([url isNotNull])
    [rss appendFormat:@"    <link>%@</link>\n",
                      [url stringByEscapingHTMLString]];
  [rss appendFormat:@"  </item>\n"];
}

/* SQL helper methods */

- (void)addTable:(NSString *)_entity as:(NSString *)_as {
  [[self query] appendFormat:@" %@ AS %@ ",
                     [[[self databaseModel] entityNamed:_entity] externalName],
                     _as];
}

- (void)addInnerJoin:(NSString *)_entity as:(NSString *)_as on:(NSString *)_on {
  [[self query] appendFormat:@" INNER JOIN %@ %@ ON %@ ",
                     [[[self databaseModel] entityNamed:_entity] externalName],
                     _as,
                     _on];
}

- (void)addOuterJoin:(NSString *)_entity as:(NSString *)_as on:(NSString *)_on {
  [[self query] appendFormat:@" LEFT OUTER JOIN %@ %@ ON %@ ",
                     [[[self databaseModel] entityNamed:_entity] externalName],
                     _as,
                     _on];
}

/* processing */

- (void)_prepareForExecutionInContext:(id)_context {
}

- (void)_executeInContext:(id)_context {
  NSArray             *attributes;
  NSDictionary        *record;
  EOAdaptorChannel    *eoChannel;

  eoChannel = [[self databaseChannel] adaptorChannel];
  [self buildQueryExpression];

  if ([eoChannel evaluateExpression:[self query]]) {
    if ((attributes = [eoChannel describeResults]) != nil) {
      [self _openRSSChannelInfo];
      while ((record = [eoChannel fetchAttributes:attributes withZone:NULL]) != nil) {
        [self appendRSSItem:record];
      }
     [self _closeRSSChannel];
     [self _closeRSS];
    }
  }
  [self setReturnValue:rss];
  [_context rollback]; 
}

/* key-value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"timeZone"]) {
    [self setTimeZone:_value];
  } else if ([_key isEqualToString:@"limit"]) {
    [self setLimit:_value];
  } else if ([_key isEqualToString:@"feedURL"]) {
    [self setFeedURL:_value];
  } else if ([_key isEqualToString:@"channelURL"]) {
    [self setChannelURL:_value];
  } else {
      [super takeValue:_value forKey:_key];
    }
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"timeZone"])
    return [self timeZone];
  if ([_key isEqualToString:@"limit"])
    return [self limit];
  if ([_key isEqualToString:@"feedURL"])
    return [self feedURL];
  if ([_key isEqualToString:@"channelURL"])
    return [self channelURL];
  return [super valueForKey:_key];
}

@end /* LSGetRSSFeedCommand */
