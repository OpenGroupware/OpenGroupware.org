/*
  Copyright (C) 2003-2004 SKYRIX Software AG

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

#include <NGObjWeb/WOComponent.h>

/*
  SxFolderRSS
  
    parent-folder: SxProjectFolder
    subjects:      -
*/

@interface SxFolderRSS : WOComponent
{
  NSArray *list;
  
  /* transient */
  id item;
}

@end

@interface SxFolderRDF : WOComponent
@end

@interface NSObject(SoRSSObject)

- (NSString *)rssChannelTitleInContext:(WOContext *)_ctx;
- (NSEnumerator *)rssChildKeysInContext:(WOContext *)_ctx;
- (NSString *)rssTitleInContext:(WOContext *)_ctx;
- (NSString *)rssLinkInContext:(WOContext *)_ctx;
- (NSString *)rssDescriptionInContext:(WOContext *)_ctx;

@end

#include <SaxObjC/XMLNamespaces.h>
#include "common.h"

@implementation SxFolderRSS

static NSString *docTypeID  = @"-//Netscape Communications//DTD RSS 0.91//EN";
static NSString *docTypeDTD = 
  @"http://my.netscape.com/publish/formats/rss-0.91.dtd";

static unsigned int fetchLimit = 1000;

- (void)dealloc {
  [self->item release];
  [self->list release];
  [super dealloc];
}

/* configuration */

- (unsigned int)fetchLimit {
  return fetchLimit;
}

/* accessors */

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

/* folder */

- (NSArray *)fetch {
  NSMutableArray *lList;
  NSEnumerator *names;
  NSString     *name;
  id           folder;
  
  if ((folder = [self clientObject]) == nil)
    return nil;
  
  // TODO: use some bulk fetch for better performance (ala WebDAV)
  
  names = [folder rssChildKeysInContext:[self context]];
  lList = [NSMutableArray arrayWithCapacity:32];
  while ((name = [names nextObject]) != nil) {
    id object;
    
    if ([lList count] >= [self fetchLimit]) {
      [self logWithFormat:@"Note: RSS fetch was limited to %d items.", 
	      [self fetchLimit]];
      break;
    }
    
    object = [folder lookupName:name inContext:[self context] acquire:NO];
    
    if ([object isKindOfClass:[NSException class]])
      /* some kind of error */
      continue;
    if (![object isNotNull])
      /* not found? weird */
      continue;

    [lList addObject:object];
  }
  return lList;
}

/* actions */

- (id)defaultAction {
  [self->list release]; self->list = nil;
  self->list = [[self fetch] retain];
  [self debugWithFormat:@"fetched %d items for RSS display ...", 
	  [self->list count]];
  return self;
}

/* RSS channel accessors (the channel is the folder) */

- (NSString *)channelTitle {
  return [[self clientObject] rssChannelTitleInContext:[self context]];
}
- (NSString *)channelLink {
  return [[self clientObject] rssLinkInContext:[self context]];
}
- (NSString *)channelLanguage {
  return @"en";
}

/* RSS item accessors */

- (NSString *)itemTitle {
  return [[self item] rssTitleInContext:[self context]];
}
- (NSString *)itemLink {
  return [[self item] rssLinkInContext:[self context]];
}
- (NSString *)itemDescription {
  return [[self item] rssDescriptionInContext:[self context]];
}

/* generating response */

- (void)appendItemToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
  [self debugWithFormat:@"gen RSS item: %@", [self item]];
  
  [_r appendContentString:@"        <title>"];
  [_r appendContentXMLString:[self itemTitle]];
  [_r appendContentString:@"</title>\n"];
  
  [_r appendContentString:@"        <link>"];
  [_r appendContentXMLString:[self itemLink]];
  [_r appendContentString:@"</link>\n"];
  
  [_r appendContentString:@"        <description>"];
  [_r appendContentXMLString:[self itemDescription]];
  [_r appendContentString:@"</description>\n"];
}

- (void)appendItemsToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx{
  NSEnumerator *e;
  id object;
  
  e = [self->list objectEnumerator];
  while ((object = [e nextObject]) != nil) {
    [self setItem:object];
    
    [_r appendContentString:@"    <item>\n"];
    [self appendItemToResponse:_r inContext:_ctx];
    [_r appendContentString:@"    </item>\n"];
  }
  [self setItem:nil];
}


- (void)appendChannelToResponse:(WOResponse *)_r inContext:(WOContext *)_c {
  /*
    <description>project info</description>
    <webMaster>email of project lead</webMaster>
    <image>
      <title>Mulle kybernetiK</title>
      <url>http://www.mulle-kybernetik.com/images/MK.gif</url>
      <link>http://www.mulle-kybernetik.com/</link>
      <height>100</height>
      <width>100</width>
    </image>
  */
  [_r appendContentString:@"    <title>"];
  [_r appendContentXMLString:[self channelTitle]];
  [_r appendContentString:@"</title>\n"];
  
  [_r appendContentString:@"    <link>"];
  [_r appendContentXMLString:[self channelLink]];
  [_r appendContentString:@"</link>\n"];

  [_r appendContentString:@"    <language>"];
  [_r appendContentXMLString:[self channelLanguage]];
  [_r appendContentString:@"</language>\n"];
}

- (void)appendHeaderToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx{
  [_r appendContentString:@"<?xml version=\"1.0\"?>\n"];
  [_r appendContentString:@"<!DOCTYPE rss PUBLIC \""];
  [_r appendContentString:docTypeID];
  [_r appendContentString:@"\" \""];
  [_r appendContentString:docTypeDTD];
  [_r appendContentString:@"\">\n"];
  
  [_r appendContentString:@"<rss version=\"0.91\">\n"];
  [_r appendContentString:@"  <channel>\n"];
  [self appendChannelToResponse:_r inContext:_ctx];
  
  /* yes, in RSS the items are children of the channel! */
}
- (void)appendFooterToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx{
  [_r appendContentString:@"  </channel>\n</rss>\n"];
}

- (void)appendToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
  [_r setHeader:@"text/xml" forKey:@"content-type"];
  [self appendHeaderToResponse:_r inContext:_ctx];
  [self appendItemsToResponse:_r  inContext:_ctx];
  [self appendFooterToResponse:_r inContext:_ctx];
}

@end /* SxFolderRSS */

@implementation SxFolderRDF

/* generating response */

- (void)appendItemToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx
{
  /*
  <item rdf:about="http://freshmeat.net/releases/173828/">
    <title>Electronic Human Resource Management System 0.1 </title>
    <link>http://freshmeat.net/releases/173828/</link>
    <description>A Web-based HR management system.</description>
    <dc:date>2004-09-24T17:18-08:00</dc:date>
  </item>
  */
}

- (void)appendChannelToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx{
  NSString *aboutURL;

  aboutURL = [[self clientObject] baseURLInContext:_ctx];
  
  [_r appendContentString:@"<channel rdf:about=\""];
  [_r appendContentXMLAttributeValue:aboutURL];
  [_r appendContentString:@"\">\n"];
  
  // TODO: implement
  /*
    <title>freshmeat.net</title>
    <link>http://freshmeat.net/</link>
    <description>freshmeat.net maintains the Web's largest index of Unix and cross-platform open sou
rce software. Thousands of applications are meticulously cataloged in the freshmeat.net database, an
d links to new code are added daily.</description>
    <dc:language>en-us</dc:language>
    <dc:subject>Technology</dc:subject>
    <dc:publisher>freshmeat.net</dc:publisher>
    <dc:creator>freshmeat.net contributors</dc:creator>
    <dc:rights>Copyright (c) 1997-2004 OSTG</dc:rights>
    <dc:date>2004-09-25T01:50+00:00</dc:date>
    <items>
      <rdf:Seq>
        <rdf:li rdf:resource="http://freshmeat.net/releases/173828/" />
        <rdf:li rdf:resource="http://freshmeat.net/releases/173816/" />
      </rdf:Seq>
    </items>
    <image rdf:resource="http://images.freshmeat.net/img/button.gif" />
    <textinput rdf:resource="http://freshmeat.net/search/" />
  */
  
  [_r appendContentString:@"</channel>\n"];
}

- (void)appendHeaderToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx{
  [_r appendContentString:@"<?xml version=\"1.0\"?>\n"];

  [_r appendContentString:@"<rdf:RDF "];

  [_r appendContentString:@" xmlns=\""];
  [_r appendContentXMLAttributeValue:@"http://purl.org/rss/1.0/"];
  [_r appendContentString:@"\""];
  
  [_r appendContentString:@" xmlns:rdf=\""];
  [_r appendContentXMLAttributeValue:XMLNS_RDF];
  [_r appendContentString:@"\""];
  
  [_r appendContentString:@" xmlns:dc=\""];
  [_r appendContentXMLAttributeValue:XMLNS_DublinCore];
  [_r appendContentString:@"\""];
  
  [_r appendContentString:@">\n"];
  
  [self appendChannelToResponse:_r inContext:_ctx];
}
- (void)appendFooterToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx{
  [_r appendContentString:@"</rdf:RDF>\n"];
}

@end /* SxFolderRDF */

#include <NGObjWeb/SoDAV.h>

@implementation NSObject(SoRSSObject)

- (NSString *)rssChannelTitleInContext:(WOContext *)_ctx {
  NSString *s;
  
  // TODO: should ask channel for title
  s = @"Items of OGo Channel '";
  s = [s stringByAppendingString:[self nameInContainer]];
  s = [s stringByAppendingString:@"'"];
  return s;
}

- (NSString *)rssTitleInContext:(WOContext *)_ctx {
  return [self davDisplayName];
}

- (NSString *)rssDescriptionInContext:(WOContext *)_ctx {
  return [self valueForKey:@"contentAsString"];
}

- (NSString *)rssLinkInContext:(WOContext *)_ctx {
  // TODO: the link is displayed in Thunderbird. There are multiple options
  //       for RSS links:
  //       a) generate a specific RSS view (current approach)
  //       b) 
  NSString *url;
  SoClass  *clazz;
  
  url   = [self baseURLInContext:_ctx];
  clazz = [self soClass];

  if ([clazz hasKey:@"rssView" inContext:_ctx])
    url = [url stringByAppendingString:@"/rssView"];
  else if ([clazz hasKey:@"asBrHTML" inContext:_ctx])
    url = [url stringByAppendingString:@"/asBrHTML"];
  else if ([clazz hasKey:@"view" inContext:_ctx])
    url = [url stringByAppendingString:@"/view"];
  
  return url;
}

- (NSEnumerator *)rssChildKeysInContext:(WOContext *)_ctx {
  return [self davChildKeysInContext:_ctx];
}

@end /* NSObject(SoRSSObject) */
