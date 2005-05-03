
#include "SkyFSDocument.h"
#include <DOM/EDOM.h>
#include <DOM/DOMSaxHandler.h>
#include <SaxObjC/XMLNamespaces.h>
#include <SaxObjC/SaxObjC.h>
#include "common.h"

/* 
   TODO: this is really lame, pretty much copied from SkyProjectDocument -
         I guess this should be moved to SkyDocument?
*/

@interface NSObject(DeclNamespace)
- (void)declarePrefix:(NSString *)_prefix namespaceURI:(NSString *)_uri;
@end

#define SX_SAX_PREDEFINED_NS_FEATURE \
  @"http://www.skyrix.com/sax/features/predefined-namespaces"

@implementation SkyFSDocument(DOM)


static BOOL         debugPredefinedNS = NO;
static NSDictionary *xmlTypeMap = nil;

static void _categoryInitialize(void) {
  static BOOL didInit = NO;
  NSUserDefaults *ud;
  NSDictionary   *defs;
  if (didInit) return;
  
  ud = [NSUserDefaults standardUserDefaults];
  defs = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"skyrix/xtmpl", @"text/xml",
                         @"text/rdf",     @"text/xml",
                         nil];
  [ud registerDefaults:defs];
  
  xmlTypeMap = [[ud dictionaryForKey:@"SkyXmlParserTypeMap"] copy];
  
  didInit = YES;
}

- (void)resetDOM {
  ASSIGN(self->blobAsDOM, (id)nil);
}

/* SkyDocumentFeature_DOMBLOB */

- (id)domImplementationForBLOB {
  static id domimp = nil; // THREAD
  if (domimp == nil) {
    Class clazz;
    
    if ((clazz = NSClassFromString(@"NGDOMImplementation")) == Nil)
      clazz = NSClassFromString(@"DOMImplementation");
    
    domimp = [[clazz alloc] init];
  }
  return domimp;
}

- (NSException *)handleDOMParsingException:(NSException *)_exception {
  /* ignore exceptions */
  return nil;
}

- (DOMXMLOutputter *)domOutputterForBLOB {
  return [[[DOMXMLOutputter alloc] init] autorelease];
}

- (void)setContentDOMDocument:(id)_dom {
  if (_dom == nil) {
    [self setContentString:nil];
  }
  else {
    DOMXMLOutputter *gen;
    NSMutableString *ms;
    
    ms  = [NSMutableString stringWithCapacity:1024];
    gen = [self domOutputterForBLOB];
    [gen outputDocument:_dom to:ms];
    
    [self setContentString:ms];
  }
}

- (id)_configuredParserForType:(NSString *)_mimeType {
  static NSMutableDictionary *parsers = nil;
  volatile id   parser;
  volatile BOOL predefineNS;
  NSString *key;

  _categoryInitialize();

  if ((key = _mimeType) == nil)
    key = (id)[NSNull null];
  
#if !DONT_USE_PARSER_CACHE
  if (parsers == nil)
    parsers = [[NSMutableDictionary alloc] initWithCapacity:16];
#endif
  
  if ((parser = [parsers objectForKey:_mimeType]))
    return parser;
  
  parser = [[SaxXMLReaderFactory standardXMLReaderFactory]
                                 createXMLReaderForMimeType:_mimeType];
  if (parser == nil) {
    if ([_mimeType hasPrefix:@"image/"]) return nil;
    if ([_mimeType hasPrefix:@"audio/"]) return nil;
    if ([_mimeType hasPrefix:@"video/"]) return nil;
    
    parser = [[SaxXMLReaderFactory standardXMLReaderFactory]
                                   createXMLReaderForMimeType:@"text/xml"];
    if (parser == nil) {
      NSLog(@"%s: didn't found text/xml SAX driver ...", __PRETTY_FUNCTION__);
      return nil;
    }
  }
  
  /* apply predefined namespaces */
  
  if ([_mimeType hasPrefix:@"text/html"])
    predefineNS = NO; /* HTML has no namespaces ... */
  else {
    NS_DURING
      *(&predefineNS) = [parser feature:SX_SAX_PREDEFINED_NS_FEATURE];
    NS_HANDLER
      predefineNS = NO;
    NS_ENDHANDLER;
  }
  
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
  else if (parser != nil && debugPredefinedNS) {
    [self logWithFormat:
            @"WARNING: SAX parser doesn't support predefined namespaces !"];
  }
  
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

- (id)contentAsDOMDocument {
  NSAutoreleasePool *pool;
  NSString          *string;
  NSString          *lMimeType;
  id   domimp;
  id   parser;
  id   saxHandler;
  id   domDocument;

  _categoryInitialize();
  
  if (self->blobAsDOM)
    return [[self->blobAsDOM retain] autorelease];
  
  pool = [[NSAutoreleasePool alloc] init];
  
#if DEBUG && 0
  NSLog(@"%s: parsing DOM of document '%@' ...",
        __PRETTY_FUNCTION__, [self pubPath]);
#endif
  
  if ((domimp = [self domImplementationForBLOB]) == nil) {
#if DEBUG
    NSLog(@"%s: missing DOMImplementation ...", __PRETTY_FUNCTION__);
#endif
    return nil;
  }
  
  /* Retrieve content. Use string, so that the encoding is ok. */
  
  if ((string = [self contentAsString]) == nil) {
#if DEBUG
    NSLog(@"%s: document %@ has no data ...", __PRETTY_FUNCTION__, self);
#endif
    return nil;
  }
  
  /* create parser */
  
  lMimeType = [self valueForKey:@"NSFileMimeType"];
  if (![lMimeType isNotNull]) lMimeType = nil;

  /* try real type */
  parser = [self _configuredParserForType:lMimeType];
  
  /* try mapped type */
  if (parser == nil && (lMimeType != nil)) {
    NSString *mappedType;
    
    if ((mappedType = [xmlTypeMap objectForKey:lMimeType]))
      parser = [self _configuredParserForType:mappedType];
  }
  
  /* look into content */
  if (parser == nil) {
    if ([string hasPrefix:@"<?xml"])
      parser = [self _configuredParserForType:@"text/xml"];
  }
  
  /* return on error */
  if (parser == nil) {
    [self debugWithFormat:
            @"did not find XML parser for MIME type '%@'", lMimeType];
    return nil;
  }
  
  /* create SAX processor */

  if ((saxHandler = [self _configuredDOMSaxHandler:domimp]) == nil) {
#if DEBUG
    NSLog(@"%s: couldn't create DOM SAX handler ...", __PRETTY_FUNCTION__);
#endif
    return nil;
  }
  
  [parser setContentHandler:saxHandler];
  [parser setDTDHandler:saxHandler];
  [parser setErrorHandler:saxHandler];
  
  /* start parsing */
  
  domDocument = nil;
  NS_DURING {
    [parser parseFromSource:string];
    domDocument = [saxHandler document];
  }
  NS_HANDLER {
    [[self handleDOMParsingException:localException] raise];
    domDocument = nil;
  }
  NS_ENDHANDLER;
  
  /* cache DOM */
  
  self->blobAsDOM = [domDocument retain];
  
  [pool release];
  
  return self->blobAsDOM;
}

@end /* SkyFSDocument(DOM) */
