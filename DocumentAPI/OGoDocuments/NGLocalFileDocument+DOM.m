/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#include "NGLocalFileDocument.h"
#include "common.h"
#include <DOM/EDOM.h>
#include <DOM/DOMSaxHandler.h>
#include <SaxObjC/SaxObjC.h>

#ifndef LIB_FOUNDATION_LIBRARY
@interface NSObject(SubclassResp)
- (void)notImplemented:(SEL)_sel;
@end
#endif

#ifndef XMLNS_OD_BIND
#  define XMLNS_OD_BIND             @"http://www.skyrix.com/od/binding"
#endif
#ifndef XMLNS_OD_CONST
#  define XMLNS_OD_CONST            @"http://www.skyrix.com/od/constant"
#endif
#ifndef XMLNS_OD_ACTION
#  define XMLNS_OD_ACTION           @"http://www.skyrix.com/od/action"
#endif
#ifndef XMLNS_OD_EVALJS
#  define XMLNS_OD_EVALJS           @"http://www.skyrix.com/od/javascript"
#endif
#ifndef XMLNS_XHTML
#  define XMLNS_XHTML               @"http://www.w3.org/1999/xhtml"
#endif
#ifndef XMLNS_XUL
#  define XMLNS_XUL \
     @"http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul"
#endif

@interface NSObject(DeclNamespace)
- (void)declarePrefix:(NSString *)_prefix namespaceURI:(NSString *)_uri;
@end

@interface NGLocalFileDocument(PublisherAPI)
- (NSString *)pubPath;
@end

@implementation NGLocalFileDocument(DOM)

static BOOL dontUseParserCache = NO;
static BOOL debugDOM           = NO;
static int  maxContentDOMCacheSize = 16000;

- (NSString *)xmlReaderNameForBLOB {
  NSString *mimeType;
  
  mimeType = [[self valueForKey:@"NSFileMimeType"] stringValue];
  
  if ([mimeType hasPrefix:@"text/html"])
    return @"libxmlHTMLSAXDriver";
  
  return nil; /* default reader */
}

- (DOMImplementation *)domImplementationForBLOB {
  static DOMImplementation *domimp = nil; // THREAD
  if (domimp == nil)
    domimp = [[DOMImplementation alloc] init];
  return domimp;
}

- (NSException *)handleDOMParsingException:(NSException *)_exception {
  /* ignore exceptions */
  return nil;
}

- (id)_configuredParserWithName:(NSString *)_name {
  static NSMutableDictionary *parsers = nil;
  id       parser;
  BOOL     predefineNS;
  NSString *key;

  if ((key = _name) == nil)
    key = (id)[NSNull null];
  
  if (!dontUseParserCache) {
    if (parsers == nil)
      parsers = [[NSMutableDictionary alloc] initWithCapacity:16];
  }
  
  if ((parser = [parsers objectForKey:key]))
    return parser;
  
  parser = [[SaxXMLReaderFactory standardXMLReaderFactory]
                                 createXMLReaderWithName:_name];
  if (parser == nil)
    return nil;
  
  /* apply predefined namespaces */
  
  NS_DURING
    *(&predefineNS) =
      [parser feature:
               @"http://www.skyrix.com/sax/features/predefined-namespaces"];
  NS_HANDLER
    predefineNS = NO;
  NS_ENDHANDLER;
  
  if (predefineNS) {
    /* default namespace is XHTML */
    [parser declarePrefix:@""      namespaceURI:XMLNS_XHTML];
    
    /* prefixed namespaces */
    [parser declarePrefix:@"html"  namespaceURI:XMLNS_XHTML];
    [parser declarePrefix:@"xul"   namespaceURI:XMLNS_XUL];
    [parser declarePrefix:@"var"   namespaceURI:XMLNS_OD_BIND];
    [parser declarePrefix:@"js"    namespaceURI:XMLNS_OD_EVALJS];
    [parser declarePrefix:@"const" namespaceURI:XMLNS_OD_CONST];
  }
  else if (parser != nil && debugDOM)
    NSLog(@"WARNING: SAX parser doesn't support predefined namespaces !");
  
  if (parser)
    /* store in cache */
    [parsers setObject:parser forKey:key];
  
  return parser;
}
- (id)_configuredDOMSaxHandler:(id)_dom {
  static id saxHandler = nil;
  
  if (_dom == nil)
    return nil;
  if (saxHandler)
    return saxHandler;
  
  return [[[DOMSaxHandler alloc] initWithDOMImplementation:_dom] autorelease];
  saxHandler = [[DOMSaxHandler alloc] initWithDOMImplementation:_dom];
  return saxHandler;
}

- (void)setContentDOMDocument:(id)_dom {
  // TODO: implement ! (serialize a DOM to body)
  [self notImplemented:_cmd];
}

- (id)contentAsDOMDocument {
  NSAutoreleasePool *pool;
  NSString          *string;
  DOMImplementation *domimp;
  id   parser;
  id   saxHandler;
  id   domDocument;
  
  if (self->contentDOM) /* cached */
    return self->contentDOM;
  
  pool = [[NSAutoreleasePool alloc] init];
  
  if (debugDOM) {
    NSLog(@"%s: parsing DOM of document '%@' ...",
          __PRETTY_FUNCTION__, [self pubPath]);
  }
  
  if ((domimp = [self domImplementationForBLOB]) == nil) {
    if (debugDOM)
      NSLog(@"%s: missing DOMImplementation ...", __PRETTY_FUNCTION__);
    return nil;
  }
  
  /* Retrieve content. Use string, so that the encoding is ok. */
  
  if ((string = [self contentAsString]) == nil) {
    if (debugDOM)
      NSLog(@"%s: document %@ has no data ...", __PRETTY_FUNCTION__, self);
    return nil;
  }
  
  /* create parser */
  
  parser = [self _configuredParserWithName:[self xmlReaderNameForBLOB]];
  if (parser == nil) {
    if (debugDOM)
      NSLog(@"%s: did not find proper parser ...", __PRETTY_FUNCTION__);
    return nil;
  }
  
  /* create SAX processor */

  if ((saxHandler = [self _configuredDOMSaxHandler:domimp]) == nil) {
    if (debugDOM)
      NSLog(@"%s: couldn't create DOM SAX handler ...", __PRETTY_FUNCTION__);
    return nil;
  }
  
  [parser setContentHandler:saxHandler];
  [parser setDTDHandler:saxHandler];
  [parser setErrorHandler:saxHandler];
  
  /* start parsing */
  
  domDocument = nil;
  NS_DURING {
    [parser parseFromSource:string systemId:[self pubPath]];
    domDocument = [[saxHandler document] retain];
  }
  NS_HANDLER {
    [[self handleDOMParsingException:localException] raise];
    domDocument = nil;
  }
  NS_ENDHANDLER;
  
  /* cache DOM */
  if ((int)[string length] < maxContentDOMCacheSize)
    self->contentDOM = [domDocument retain];
  
  [pool release];
  
  return [domDocument autorelease];
}

@end /* NGLocalFileDocument */
