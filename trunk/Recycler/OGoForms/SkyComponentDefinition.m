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

#include <OGoForms/SkyComponentDefinition.h>
#include "common.h"
#include "used_privates.h"
#include <OGoForms/SkyFormNamespaces.h>
#include <SaxObjC/SaxXMLReaderFactory.h>
#include <NGObjWeb/NGObjWeb.h>
#include <NGObjDOM/NGObjDOM.h>
#include <DOM/EDOM.h>
#include <DOM/DOMSaxHandler.h>
#include "SkyFormComponent.h"

@implementation WOComponent(Compability41)
+ (BOOL)isScriptedComponent {
  return NO;
}
@end /* Compability41 */

@interface SkyComponentDefinition(Privates)
- (BOOL)_loadFromData:(NSData *)_data encoding:(NSStringEncoding)_encoding;
@end

@interface NSObject(DeclNamespace)
- (void)declarePrefix:(NSString *)_prefix namespaceURI:(NSString *)_uri;
@end

@interface WOComponent(ContentURL)
- (NSData *)contentForComponentRelativeURL:(NSString *)_url;
@end

@implementation SkyComponentDefinition

+ (int)version {
  return [super version] + 0; /* v0 */
}

- (id)initWithName:(NSString *)_name path:(NSString *)_path
  baseURL:(NSString *)_baseURL frameworkName:(NSString *)_fwname
{
  if ((self = [self init])) {
    self->cname = [_name copy];
    self->path  = [_path copy];
  }
  return self;
}

- (void)dealloc {
  [(id)self->componentClass release];
  [self->domDocument    release];
  [self->parser   release];
  [self->cname    release];
  [self->path     release];
  [self->template release];
  [super dealloc];
}

/* accessors */

- (void)setComponentName:(NSString *)_name {
  ASSIGNCOPY(self->cname, _name);
}
- (NSString *)componentName {
  return self->cname;
}
- (void)setComponentClass:(Class)_class {
  ASSIGN(self->componentClass, _class);
}
- (Class)componentClass {
  return self->componentClass;
}

- (WOElement *)template {
  if (self->template == nil)
    [self load];
  
  return self->template;
}

- (void)setParser:(id<NSObject,SaxXMLReader>)_parser {
  ASSIGN(self->parser, _parser);
}
- (id<NSObject,SaxXMLReader>)parser {
  return self->parser;
}

/* loading the component templates */

- (id)_saxParserForSource:(id)_source {
  if (self->parser)
    return self->parser;
  
  if ([[[self componentName] pathExtension] isEqualToString:@"html"]) {
    self->parser =
      [[[SaxXMLReaderFactory standardXMLReaderFactory]
         createXMLReaderForMimeType:@"text/html"] retain];
  }
  
  if (self->parser)
    return self->parser;
  
  self->parser =
    [[[SaxXMLReaderFactory standardXMLReaderFactory] 
       createXMLReaderForMimeType:@"text/xml"] retain];
  
  return self->parser;
}

- (BOOL)loadFromSource:(id)_source {
  NSAutoreleasePool *pool;
  volatile id saxHandler;
  id lparser;
  id domimp;
  BOOL predefineNS;
  
  pool = [[NSAutoreleasePool alloc] init];

  [self->domDocument release]; self->domDocument = nil;
  [self->template    release]; self->template    = nil;
  
  domimp = [[[DOMImplementation alloc] init] autorelease];
  
  *(&lparser) = [self _saxParserForSource:_source];
  
  /* setup SAX handler */
  
  *(&saxHandler) = [[DOMSaxHandler alloc] initWithDOMImplementation:domimp];
  saxHandler = [saxHandler autorelease];
  
  [lparser setContentHandler:saxHandler];
  [lparser setDTDHandler:saxHandler];
  [lparser setErrorHandler:saxHandler];
  
  /* apply predefined namespaces */
  
  NS_DURING
    *(&predefineNS) =
      [lparser feature:
               @"http://www.skyrix.com/sax/features/predefined-namespaces"];
  NS_HANDLER
    predefineNS = NO;
  NS_ENDHANDLER;
  
  if (predefineNS) {
#if 1 // does not work ??
    /* default namespace is XHTML */
    [lparser declarePrefix:@""      namespaceURI:XMLNS_XHTML];
#endif

    /* prefixed namespaces */
    [lparser declarePrefix:@"html"  namespaceURI:XMLNS_XHTML];
    [lparser declarePrefix:@"xul"   namespaceURI:XMLNS_XUL];
    [lparser declarePrefix:@"var"   namespaceURI:XMLNS_OD_BIND];
    [lparser declarePrefix:@"js"    namespaceURI:XMLNS_OD_EVALJS];
    [lparser declarePrefix:@"const" namespaceURI:XMLNS_OD_CONST];
  }
  else if (lparser)
    NSLog(@"WARNING: SAX parser doesn't support predefined namespaces !");
  
  /* start parsing */
  
  if ([_source isKindOfClass:[NSURL class]])
    [lparser parseFromSystemId:[_source absoluteString]];
  else 
    [lparser parseFromSource:_source];
  
  /* process parse result */
  
  if ((self->domDocument = [[saxHandler document] retain])) {
    NSMutableDictionary *assocs;
    static id defaultRenderer = nil;
    NSAutoreleasePool *pool;
    WOAssociation *domAssoc;
    WOAssociation *factoryAssoc;

    pool = [NSAutoreleasePool new];

    if (defaultRenderer == nil)
      defaultRenderer = [[NSClassFromString(@"SkyNodeRendererSet") alloc] init];
    
    domAssoc     = [WOAssociation associationWithValue:self->domDocument];
    factoryAssoc = [WOAssociation associationWithValue:defaultRenderer];
    assocs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    domAssoc,     @"domDocument",
                                    factoryAssoc, @"factory",
                                  nil];
    
    self->template = [[WORenderDOM alloc] initWithName:self->cname
                                          associations:assocs
                                          template:nil];
    
    [pool release];
  }
  
  //NSLog(@"TEMPLATE: %@", self->template);
  
  /* release parser */
  [self->parser release]; self->parser = nil;
  
  [pool release];
  return self->template ? YES : NO;
}

- (BOOL)load {
  NSURL *url;
  
  url = [[[NSURL alloc] initFileURLWithPath:self->path] autorelease];
  return [self loadFromSource:url];
}

/* component instantiation */

- (NSString *)scriptTextFromNode:(id)_node inComponent:(WOComponent *)_c {
  NSMutableString *result;
  
  result = [NSMutableString stringWithCapacity:1024];
  
  if ([_node hasAttribute:@"src"]) {
    NSString *src;
    NSData   *data;
    
    src = [_node attribute:@"src"];
#if DEBUG
    [_c debugWithFormat:@"loading JS script with source '%@' ..", src];
#endif
    
    if ([_c respondsToSelector:@selector(contentForComponentRelativeURL:)])
      data = [_c contentForComponentRelativeURL:src];
    else
      data   = [[NSURL URLWithString:src] resourceDataUsingCache:NO];
    
    if ([data length] > 0) {
      NSString *script;
      
      script = [[NSString alloc] initWithData:data
                                 encoding:NSISOLatin1StringEncoding];
      [result appendString:script];
      [script release];
    }
  }
  
  if ([_node hasChildNodes]) {
    NSEnumerator *e;
    id subnode;
    
    e = [(id)[_node childNodes] objectEnumerator];
    while ((subnode = [e nextObject])) {
      [result appendString:[subnode textValue]];
    }
  }
  
  return result;
}

- (WOComponent *)instantiateWithResourceManager:(WOResourceManager *)_rm
  languages:(NSArray *)_languages
{
  NSMutableDictionary *childComponents = nil;
  WOComponent         *component       = nil;
  Class               cClass;
  
  cClass = [self componentClass];

  /* instantiate */
  
  if ([cClass isScriptedComponent]) {
    component = [cClass scriptedComponentWithName:[self componentName]];
  }
  else if (cClass == nil) {
    NSLog(@"WARNING(%s): missing class for component %@ !", __PRETTY_FUNCTION__,
          [self componentName]);
    component = [[[SkyFormComponent alloc] init] autorelease];
  }
  else {
    component = [[[cClass alloc] init] autorelease];
  }
  
  if (component == nil) {
    NSLog(@"missing component ..");
    return nil;
  }
  
  /* instantiate child components */

  {
    static DOMQueryPathExpression *qpexpr = nil;
    NSEnumerator *embedNodes;
    id embedNode;
    
    if (qpexpr == nil)
      qpexpr = [[DOMQueryPathExpression queryPathWithString:@"embed"] retain];
    
    embedNodes = [[qpexpr evaluateWithNodeList:[self->domDocument childNodes]]
                          objectEnumerator];
    
    while ((embedNode = [embedNodes nextObject])) {
      id           fault;
      NSString     *scname;
      NSString     *key;
      NSDictionary *bindings;
      
      scname = [[[embedNode attributes]
                            namedItem:@"name" namespaceURI:XMLNS_OD_BIND]
                            textValue];
      if ([scname length] == 0) {
        NSLog(@"couldn't instantiate component for node %@", embedNode);
        continue;
      }

      key = [[[embedNode attributes]
                         namedItem:@"id" namespaceURI:XMLNS_OD_BIND]
                         textValue];
      if ([key length] == 0)
        key = scname;
      
      bindings = nil;
      
      fault = [NSClassFromString(@"WOComponentFault") alloc];
      fault = [fault initWithResourceManager:_rm
                     pageName:scname
                     languages:_languages
                     bindings:bindings];
      if (fault) {
        if (childComponents == nil)
          childComponents = [NSMutableDictionary dictionaryWithCapacity:16];
        
        [childComponents setObject:fault forKey:key];
        [fault release];
      }
    }
  }
  
  /* setup general info */
  
  [component setName:[self componentName]];
  [component setSubComponents:childComponents];
  [component setTemplate:[self template]];
  
  return component;
}

@end /* SkyComponentDefinition */
