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

#include "SkyDocument+PubResponse.h"
#include "SkyDocument+Pub.h"
#include "SkyPubResourceManager.h"
#include "common.h"

@implementation SkyDocument(PubResponse)

static BOOL   debugOn    = NO;
static NSData *emptyData = nil;

static inline NSData *EmptyData(void) {
  if (emptyData == nil)
    emptyData = [[NSData alloc] init];
  return emptyData;
}

- (id<WOActionResults>)generateGenericPubResponseInContext:(WOContext *)_ctx {
  WOResponse *r;
  NSString   *mtype;
  NSDate     *date;
  
  r = [WOResponse responseWithRequest:[_ctx request]];
  [r setStatus:200];

  if ((mtype = [[self valueForKey:@"NSFileMimeType"] stringValue]))
    [r setHeader:mtype forKey:@"content-type"];
  
  if ((mtype = [[self valueForKey:@"NSFileSize"] stringValue]))
    [r setHeader:mtype forKey:@"content-length"];
  
  if ((date = [self valueForKey:NSFileModificationDate])) {
    [r setHeader:
         [date descriptionWithCalendarFormat:@"%a, %D %b %Y %H:%M:%S %Z"
               timeZone:[NSTimeZone timeZoneWithName:@"GMT"]
               locale:nil]
       forKey:@"last-modified"];
  }
  
  if ([[[_ctx request] method] isEqualToString:@"HEAD"]) {
    [r setContent:EmptyData()];
  }
  else if ([self supportsFeature:SkyDocumentFeature_BLOB])
    [r setContent:[(id<SkyBLOBDocument>)self content]];
  else {
    NSLog(@"WARNING(%s): document %@ doesn't support BLOB content !",
          __PRETTY_FUNCTION__, self);
    [r setContent:EmptyData()];
  }
  
  return r;
}

- (id<WOActionResults>)generateImagePubResponseInContext:(WOContext *)_ctx {
  WOResponse *r;
  NSString   *mtype;
  
  r = [WOResponse responseWithRequest:[_ctx request]];
  [r setStatus:200];
  
  if ((mtype = [[self valueForKey:@"NSFileMimeType"] stringValue]))
    [r setHeader:mtype forKey:@"content-type"];
  
  if ((mtype = [[self valueForKey:@"NSFileSize"] stringValue]))
    [r setHeader:mtype forKey:@"content-length"];
  
  if ([[[_ctx request] method] isEqualToString:@"HEAD"]) {
    [r setContent:EmptyData()];
  }
  else if ([self supportsFeature:SkyDocumentFeature_BLOB])
    [r setContent:[(id<SkyBLOBDocument>)self content]];
  else {
    NSLog(@"WARNING(%s): document %@ doesn't support BLOB content !",
          __PRETTY_FUNCTION__);
    [r setContent:EmptyData()];
  }
  
  return r;
}

- (id<WOActionResults>)generateXMLPubResponseInContext:(WOContext *)_ctx {
  return [self generateGenericPubResponseInContext:_ctx];
}

- (id<WOActionResults>)generateXHTMLPubResponseInContext:(WOContext *)_ctx {
  static int profile = -1;
  WOResourceManager *rm;
  WOComponent       *template;
  WOResponse        *result;
  NSDate            *date;
  NSString          *ctype;

  if (profile == -1) {
    profile = [[NSUserDefaults standardUserDefaults]
                               boolForKey:@"ProfilePubRequestHandler"]
      ? 1 : 0;
  }
  
  date = profile ? [NSDate date] : nil;
  
  [_ctx takeValue:self forKey:@"pageDocument"];
  
  /* the lookup needs to be done based on the URI, since a document
     could occur on different positions in the file tree */
  
  if ((rm = [_ctx valueForKey:@"mainTemplateResourceManager"]) == nil)
    rm = [[WOApplication application] resourceManager];
  
  if (![rm isNotNull]) {
    NSLog(@"ERROR(%s): got a no resource manager !!", __PRETTY_FUNCTION__);
    return nil;
  }
  
  template = [rm templateWithName:nil /* mastertemplate */
                 atPath:[self valueForKey:@"NSFilePath"]];
  
  if (profile) {
    NSLog(@"template lookup+instantiation: %.3fs",
          [[NSDate date] timeIntervalSinceDate:date]);
  }
  
  [template ensureAwakeInContext:_ctx];
  
  if (profile) {
    NSLog(@"template lookup+instantiation+awake: %.3fs",
          [[NSDate date] timeIntervalSinceDate:date]);
  }
  
  if (template == nil) {
    result = [WOResponse responseWithRequest:[_ctx request]];
    [result setStatus:500];
    [result appendContentString:@"<h2>Did not find template for document</h2>"];
    [result appendContentString:@"Did not find template for document at path "];
    [result appendContentHTMLString:[self valueForKey:@"NSFilePath"]];
  }
  else
    result = [template generateResponse];
  
  if (profile) {
    NSLog(@"template lookup+instantiation+awake+response: %.3fs",
          [[NSDate date] timeIntervalSinceDate:date]);
  }

  ctype = [result headerForKey:@"content-type"];
  if ([ctype length] == 0)
    [result setHeader:@"text/html" forKey:@"content-type"];
  
  if ([[[_ctx request] method] isEqualToString:@"HEAD"])
    [result setContent:EmptyData()];
  
  return result;
}

- (id<WOActionResults>)generateHTMLPubResponseInContext:(WOContext *)_ctx {
  id<WOActionResults> result;
  WOResponse *response;
  NSString *ctype;
  
  if ((result = [self generateXHTMLPubResponseInContext:_ctx]) == nil)
    return nil;
  
  if (![(id)result respondsToSelector:@selector(headerForKey:)])
    /* result is not a WOResponse */
    return result;
  response = (id)result;
  
  /* patch content-type */
  
  ctype = [response headerForKey:@"content-type"];
  if ([ctype length] == 0 || [ctype hasPrefix:@"text/xhtml"])
    [response setHeader:@"text/html" forKey:@"content-type"];
  
  return response;
}

- (id<WOActionResults>)generateDirPubResponseInContext:(WOContext *)_ctx {
  SkyDocument *indexDoc;
  
  if ((indexDoc = [self pubIndexDocument])) {
    NSLog(@"WARNING(%s): generating index document for folder-url !",
          __PRETTY_FUNCTION__);
    return [indexDoc generatePubResponseInContext:_ctx];
  }
  
  return [self generateXHTMLPubResponseInContext:_ctx];
}

- (id<WOActionResults>)generatePubResponseInContext:(WOContext *)_ctx {
  NSString *mtype;
  
  [_ctx takeValue:self forKey:@"pageDocument"];
  
  mtype = [[self valueForKey:@"NSFileMimeType"] stringValue];
  
  if (debugOn) {
    [self debugWithFormat:@"generate response for type: %@ (path=%@)", 
            mtype, [self valueForKey:@"NSFilePath"]];
  }
  
  if ([mtype hasPrefix:@"image/"])
    return [self generateImagePubResponseInContext:_ctx];
  
  if ([mtype hasPrefix:@"text/xhtml"])
    return [self generateXHTMLPubResponseInContext:_ctx];
  
  if ([mtype hasPrefix:@"x-skyrix/filemanager-directory"])
    return [self generateDirPubResponseInContext:_ctx];
  
  if ([mtype hasPrefix:@"text/xml"])
    return [self generateXMLPubResponseInContext:_ctx];
  
  if ([mtype hasPrefix:@"text/html"])
    return [self generateHTMLPubResponseInContext:_ctx];

  if (debugOn) [self debugWithFormat:@"generic response for type: %@", mtype];
  
  return [self generateGenericPubResponseInContext:_ctx];
}

@end /* SkyDocument(PubResponse) */
