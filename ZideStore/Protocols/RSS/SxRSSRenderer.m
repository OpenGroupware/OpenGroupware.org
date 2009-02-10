/*
  Copyright (C) 2002-2008 SKYRIX Software AG
  Copyright (C) 2008      Helge Hess

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

#include "SxRSSRenderer.h"
#include "common.h"
#include <ZSFrontend/SxFolder.h>

#include <EOControl/EOGenericRecord.h>
#include <EOControl/EOKeyGlobalID.h>
#include <NGObjWeb/WOResponse.h>

@implementation SxRSSRenderer

+ (id)renderer {
  return [[[self alloc] init] autorelease];
}

- (NSString *)title {
#if NeXT_Foundation_LIBRARY || APPLE_FOUNDATION_LIBRARY
  [self errorWithFormat:@"method must be overridden: %s", __PRETTY_FUNCTION__];
  return nil;
#else
  return [self subclassResponsibility:_cmd];
#endif
}

- (NSString *)info {
#if NeXT_Foundation_LIBRARY || APPLE_FOUNDATION_LIBRARY
  [self errorWithFormat:@"method must be overridden: %s", __PRETTY_FUNCTION__];
  return nil;
#else
  return [self subclassResponsibility:_cmd];
#endif
}

- (NSString *)viewURI {
#if NeXT_Foundation_LIBRARY || APPLE_FOUNDATION_LIBRARY
  [self errorWithFormat:@"method must be overridden: %s", __PRETTY_FUNCTION__];
  return nil;
#else
  return [self subclassResponsibility:_cmd];
#endif
}

- (NSString *)skyrixLinkForEO:(EOGenericRecord *)_task {
  NSUserDefaults *ud;
  NSString *linkPrefix;

  ud = [NSUserDefaults standardUserDefaults];
  if ((linkPrefix = [ud valueForKey:@"SxSkyrixLinkPrefix"]) != nil) {
    NSString *objectId;
    
    objectId = [[[_task valueForKey:@"globalID"] keyValuesArray]
                        objectAtIndex:0];
    
    return [NSString stringWithFormat:
                     @"%@/OpenGroupware.org/wa/LSWViewAction/%@=%@",
                     linkPrefix, [self viewURI], objectId];
  }
  return nil;
}

- (NSString *)rssHeader {
  NSMutableString *h;

  h = [NSMutableString stringWithCapacity:256];
  [h appendString:@"<?xml version=\"1.0\"?>\n"];
  [h appendString:@"<!DOCTYPE rss PUBLIC \"-//Netscape Communications//DTD"];
  [h appendString:@" RSS 0.91//EN\" \"http://my.netscape.com/publish/"];
  [h appendString:@"formats/rss-0.91.dtd\">\n\n"];
  [h appendString:@"<rss version=\"0.91\">\n<channel>\n<title>"];
  [h appendString:[self title]];
  [h appendString:@"</title>\n<description>"];
  [h appendString:[self info]];
  [h appendString:@"</description>\n<language>de-de</language>\n"];
  return h;
}

- (NSString *)rssFooter {
  return @"</channel>\n</rss>";  
}

- (NSString *)itemHeader {
  return @"<item>\n";
}

- (NSString *)itemFooter {
  return @"\n</item>\n";
}

- (NSString *)rssStringForFolder:(SxFolder *)_folder inContext:(id)_ctx {
#if NeXT_Foundation_LIBRARY || APPLE_FOUNDATION_LIBRARY
  [self errorWithFormat:@"method must be overridden: %s", __PRETTY_FUNCTION__];
  return nil;
#else
  return [self subclassResponsibility:_cmd];
#endif
}

- (WOResponse *)rssResponseForFolder:(SxFolder *)_folder inContext:(id)_ctx {
  WOResponse *response;
  NSString   *data;
  
  response = [WOResponse responseWithRequest:[(WOContext *)_ctx request]];
  
  if ((data = [self rssStringForFolder:_folder inContext:_ctx]) != nil) {
    NSData   *contentData = [data dataUsingEncoding:NSUTF8StringEncoding];
    NSString *clen = [NSString stringWithFormat:@"%i", [contentData length]];
    
    [response setStatus:200 /* OK */];
    [response setHeader:clen forKey:@"content-length"];
    [response setHeader:
		@"application/rss+xml; disposition-type=text; charset=utf-8"
	      forKey:@"content-type"];
    
    [response setContent:contentData];
  }
  else {
    [self errorWithFormat:@"got no RSS for folder: %@", _folder];
    [response setStatus:500 /* server error */];
  }
  
  return response;
}

@end /* SxRSSRenderer */
