/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include "SkyPubComponentDefinition.h"
#include "SkyPubComponent.h"
#include "SkyPubFileManager.h"
#include "SkyDocument+Pub.h"
#include "common.h"
#include <NGObjDOM/ODNodeRendererFactory.h>
#include <NGObjDOM/WORenderDOM.h>

@interface WOComponent(UsedPrivates)
- (void)setName:(NSString *)_name;
- (void)setSubComponents:(NSDictionary *)_children;
- (void)setTemplate:(WOElement *)_template;
@end

/* this component definition is created and managed by SkyPubResourceManager */

@implementation SkyPubComponentDefinition

+ (int)version {
  return [super version] + 0; /* v0 */
}

- (id)initWithName:(NSString *)_name path:(NSString *)_path
  baseURL:(NSString *)_baseURL frameworkName:(NSString *)_fwname
{
  if ((self = [super init])) {
    self->cname = [_name copy];
    self->path  = [_path copy];
  }
  return self;
}
- (id)init {
  return [self initWithName:nil path:nil baseURL:nil frameworkName:nil];
}

- (void)dealloc {
  [self->renderFactoryName release];
  [self->fileManager release];
  [self->template    release];
  [self->domDocument release];
  [self->cname       release];
  [self->path        release];
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
  return self->componentClass
    ? self->componentClass
    : [SkyPubComponent class];
}

- (WOElement *)template {
  if (self->template)
    return self->template;
  
  if (![self load]) {
    [self logWithFormat:@"WARNING(%s): could not load template ...", 
            __PRETTY_FUNCTION__];
    return nil;
  }
  return self->template;
}

- (void)setFileManager:(SkyPubFileManager *)_fileManager {
  ASSIGN(self->fileManager, _fileManager);
}
- (SkyPubFileManager *)fileManager {
  return self->fileManager;
}
- (SkyDocument *)document {
  return [[self fileManager] documentAtPath:self->path];
}

/* WO caching */

- (void)touch {
}

/* template loading */

- (void)setRenderFactoryName:(NSString *)_name {
  ASSIGNCOPY(self->renderFactoryName, _name);
}
- (NSString *)renderFactoryName {
  return self->renderFactoryName
    ? self->renderFactoryName
    : @"SkyPubNodeRenderFactory";
}
- (Class)renderFactoryClass {
  return NSClassFromString([self renderFactoryName]);
}
- (id)renderFactory {
  return [[[[self renderFactoryClass] alloc] init] autorelease];
}

- (BOOL)load {
  ODNodeRendererFactory *factory;
  NSMutableDictionary *assocs;
  
  if (self->template) return YES;
  
  if (self->domDocument == nil) {
    id doc;
    
    if ((doc = [self document]) == nil) {
      [self logWithFormat:@"%s: missing document ...", __PRETTY_FUNCTION__];
      return NO;
    }
    
    if (![doc supportsFeature:SkyDocumentFeature_DOMBLOB]) {
      [self logWithFormat:@"%s: doc %@ can't represent it's content as DOM !",
            __PRETTY_FUNCTION__, doc];
      return NO;
    }
    
    self->domDocument =
      [[(id<SkyDOMBLOBDocument>)doc contentAsDOMDocument] retain];
  }
  
  if (self->domDocument == nil) {
    [self logWithFormat:@"%s: missing DOM-document ...", __PRETTY_FUNCTION__];
    return NO;
  }
  
  if ((factory = [self renderFactory]) == nil)
    [self logWithFormat:@"%s: missing render factory ...",__PRETTY_FUNCTION__];
  
  assocs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  [WOAssociation associationWithValue:
                                                   self->domDocument],
                                  @"domDocument",
                                  [WOAssociation associationWithValue:
                                                   factory],
                                  @"factory",
                                  nil];
  
  self->template = [[WORenderDOM alloc] initWithName:[self componentName]
                                        associations:assocs
                                        template:nil];

  if (self->template == nil) {
    NSLog(@"%s: couldn't instantiate WORenderDOM ...");
    return NO;
  }
  
  return self->template ? YES : NO;
}

/* instantiation */

- (WOComponent *)instantiateWithResourceManager:(WOResourceManager *)_rm
  languages:(NSArray *)_languages
{
  NSMutableDictionary *childComponents = nil;
  WOComponent         *component       = nil;
  Class               cClass;
  id doc;
  
  cClass = [self componentClass];

#if DEBUG && 0
  NSLog(@"%s: instantiate component ...", __PRETTY_FUNCTION__);
#endif
  
  /* instantiate */
  
  if (cClass == nil) {
    NSLog(@"WARNING(%s): missing class for component %@ !",
          __PRETTY_FUNCTION__,
          [self componentName]);
    cClass = [SkyPubComponent class];
  }
  
  if ((doc = [self document]) == nil) {
    [self logWithFormat:@"WARNING(%s): got no document for path: '%@'", 
	    __PRETTY_FUNCTION__, self->path];
  }
  
  component = [[cClass alloc]
                       initWithFileManager:[self fileManager]
                       document:doc];
  component = [component autorelease];
  
  if ([component respondsToSelector:@selector(setResourceManager:)])
    [(id)component setResourceManager:_rm];
  
  if (component == nil) {
    NSLog(@"%s: couldn't instantiate component %@ ..", __PRETTY_FUNCTION__,
          [self componentName]);
    return nil;
  }
  
  /* instantiate child components */
#if 0
  {
    static DOMQueryPathExpression *qpexpr = nil;
    NSEnumerator *embedNodes;
    id embedNode;
    
    if (qpexpr == nil) {
      qpexpr = [[DOMQueryPathExpression queryPathWithString:@"embed"] retain];
    }
    
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
#endif
  
  /* setup general info */
  
  [component setName:[self componentName]];
  [component setSubComponents:childComponents];
  [component setTemplate:[self template]];
  
  return component;
}

@end /* SkyPubComponentDefinition */
