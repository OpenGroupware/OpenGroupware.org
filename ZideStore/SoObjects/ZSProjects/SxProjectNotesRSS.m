/*
  Copyright (C) 2003-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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
  SxProjectNotesRSS
  
    parent-folder: SxProjectFolder
    subjects:      -
*/

@interface SxProjectNotesRSS : WOComponent
{
  NSArray *notes;
}

@end

@interface SxProjectNotesRDF : WOComponent
@end

#include <SaxObjC/XMLNamespaces.h>
#include "common.h"

@implementation SxProjectNotesRSS

static BOOL format = NO;
static NSString *docTypeID  = @"-//Netscape Communications//DTD RSS 0.91//EN";
static NSString *docTypeDTD = 
  @"http://my.netscape.com/publish/formats/rss-0.91.dtd";

- (void)dealloc {
  [self->notes release];
  [super dealloc];
}

/* folder */

- (id)notesFolder {
  return [[self clientObject] lookupName:@"Notes" inContext:[self context]
			      acquire:NO];
}

- (NSArray *)fetchAllNotes {
  NSMutableArray *lNotes;
  NSArray  *names;
  id       folder;
  unsigned i, count;
  
  if ((folder = [self notesFolder]) == nil)
    return nil;
  
  // TODO: use some bulk fetch for better performance (ala WebDAV)
  
  names = [folder toOneRelationshipKeys];
  if ((count = [names count]) == 0)
    return names;
  
  lNotes = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    id note;

    note = [folder lookupName:[names objectAtIndex:i]
		   inContext:[self context]
		   acquire:NO];
    
    if ([note isKindOfClass:[NSException class]])
      /* some kind of error */
      continue;
    if (![note isNotNull])
      /* not found? weird */
      continue;

    [lNotes addObject:note];
  }
  return lNotes;
}

/* actions */

- (id<WOActionResults>)defaultAction {
  [self->notes release]; self->notes = nil;
  self->notes = [[self fetchAllNotes] retain];
  [self debugWithFormat:@"fetched %d notes ...", [self->notes count]];
  return self;
}

/* generating response */

- (void)appendRSSItem:(id)_note
  toResponse:(WOResponse *)_r inContext:(WOContext *)_ctx
{
  NSString *url, *content;
  
  [self debugWithFormat:@"gen RSS item: %@", _note];

  url = [_note baseURLInContext:_ctx];
  url = [url stringByAppendingString:@"/asBrHTML"];
  
  content = [_note valueForKey:@"noteContent"];
  if ([content isNotEmpty]) {
    /* we are apparently doing RSS 0.91, so lets deliver old-style HTML */
    content = [content stringByReplacingString:@"\n" withString:@"<BR>"];
  }
  
  if (format) [_r appendContentString:@"        "];
  [_r appendContentString:@"<title>"];
  [_r appendContentXMLString:[_note davDisplayName]];
  [_r appendContentString:@"</title>"];
  if (format) [_r appendContentString:@"\n"];
  
  if ([url isNotEmpty]) {
    if (format) [_r appendContentString:@"        "];
    [_r appendContentString:@"<link>"];
    [_r appendContentXMLString:url];
    [_r appendContentString:@"</link>"];
    if (format) [_r appendContentString:@"\n"];
  }
  
  if ([content isNotEmpty]) {
    if (format) [_r appendContentString:@"        "];
    [_r appendContentString:@"<description>"];
    [_r appendContentXMLString:content];
    [_r appendContentString:@"</description>"];
    if (format) [_r appendContentString:@"\n"];
  }
}

- (void)appendRSSItemsToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx{
  NSEnumerator *e;
  id note;
  
  e = [self->notes objectEnumerator];
  while ((note = [e nextObject]) != nil) {
    [_r appendContentString:format ? @"    <item>\n" : @"<item>"];
    [self appendRSSItem:note toResponse:_r inContext:_ctx];
    [_r appendContentString:format ? @"    </item>\n" : @"</item>"];
  }
}


- (void)appendRSSChannelToResponse:(WOResponse *)_r inContext:(WOContext *)_c {
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
  id project;
  
  project = [self clientObject];
  
  if (format) [_r appendContentString:@"    "];
  [_r appendContentString:@"<title>"];
  [_r appendContentString:@"Notes of OGo Project '"];
  [_r appendContentXMLString:[project nameInContainer]];
  [_r appendContentString:@"'</title>"];
  if (format) [_r appendContentString:@"\n"];
  
  if (format) [_r appendContentString:@"    "];
  [_r appendContentString:@"<link>"];
  [_r appendContentXMLString:[project baseURLInContext:[self context]]];
  [_r appendContentString:@"</link>"];
  if (format) [_r appendContentString:@"\n"];
  
  if (format) [_r appendContentString:@"    "];
  [_r appendContentString:@"<language>en</language>"];
  if (format) [_r appendContentString:@"\n"];
}

- (void)appendRSSHeaderToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx{
  [_r appendContentString:@"<?xml version=\"1.0\"?>\n"];
  [_r appendContentString:@"<!DOCTYPE rss PUBLIC \""];
  [_r appendContentString:docTypeID];
  [_r appendContentString:@"\" \""];
  [_r appendContentString:docTypeDTD];
  [_r appendContentString:@"\">\n"];
  
  [_r appendContentString:@"<rss version=\"0.91\">\n"];
  [_r appendContentString:format ? @"  <channel>\n" : @"<channel>"];
  [self appendRSSChannelToResponse:_r inContext:_ctx];
  
  /* yes, in RSS the items are children of the channel! */
}
- (void)appendRSSFooterToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx{
  [_r appendContentString:format ? @"  </channel>\n" : @"</channel>"];
  [_r appendContentString:@"</rss>\n"];
}

- (void)appendToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
  [_r setContentEncoding:NSUTF8StringEncoding];
  [_r setHeader:@"text/xml; charset=utf-8" forKey:@"content-type"];
  [self appendRSSHeaderToResponse:_r inContext:_ctx];
  [self appendRSSItemsToResponse:_r  inContext:_ctx];
  [self appendRSSFooterToResponse:_r inContext:_ctx];
}

@end /* SxProjectNotesRSS */

@implementation SxProjectNotesRDF

/* generating response */

- (void)appendRSSItem:(id)_note
  toResponse:(WOResponse *)_r inContext:(WOContext *)_ctx
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

- (void)appendRSSHeaderToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx{
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
- (void)appendRSSFooterToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx{
  [_r appendContentString:@"</rdf:RDF>\n"];
}

@end /* SxProjectNotesRDF */
