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

#include "SkyPubComponent.h"
#include "SkyPubLinkManager.h"
#include "SkyPubFileManager.h"
#include "SkyDocument+Pub.h"
#include <NGObjDOM/WOContext+Cursor.h>
#include <DOM/EDOM.h>
#include <NGJavaScript/NGJavaScriptShadow.h>
#include <NGJavaScript/NGJavaScriptObjectMappingContext.h>
#include "common.h"

@interface SkyPubComponent(JSSupport)

- (NGJavaScriptObjectMappingContext *)jsMapContext;
- (NGJavaScriptShadow *)_shadow;
- (void)_evaluateTemplateJSInContext:(WOContext *)_ctx;

- (NSException *)_handleException:(NSException *)_exception
  inContext:(WOContext *)_ctx;
- (NSException *)_handleException:(NSException *)_exception
  inContext:(WOContext *)_ctx
  inJavaScript:(NSString *)_script;

@end

@interface SkyPubComponent(Template)
- (WOElement *)template;
@end

@implementation SkyPubComponent

static BOOL componentAsCursor = NO;
static BOOL coreOnException   = NO;

+ (int)version {
  return [super version] + 1 /* v3 */;
}
+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
  
  coreOnException = [ud boolForKey:@"SkyPubCoreOnException"];
}

- (id)initWithFileManager:(SkyPubFileManager *)_fm
  document:(SkyDocument *)_doc
{
  if (_doc == nil) {
    [self logWithFormat:
	    @"ERROR: missing document for SkyPubComponent (filemanager=%@).",
	    _fm];
  }
  
  if ((self = [super init])) {
    self->fileManager = [_fm  retain];
    self->document    = [_doc retain];
  }
  return self;
}
- (id)init {
  return [self initWithFileManager:nil document:nil];
}

- (void)dealloc {
  [self->cursorStack release];
  [self->template    release];
  
  [self->shadow setMasterObject:nil];
  [self->shadow release];
  
  [self->rm          release];
  [self->linkManager release];
  [self->document    release];
  [self->fileManager release];
  [super dealloc];
}

/* accessors */

- (void)setIsTemplate:(BOOL)_flag {
  self->isTemplate = _flag ? YES : NO;
}
- (BOOL)isTemplate {
  return self->isTemplate ? YES : NO;
}

- (void)setTemplate:(WOElement *)_template {
  ASSIGN(self->template, _template);
}
- (WOElement *)template {
  return self->template;
}
- (WOElement *)templateWithName:(NSString *)_name {
  return [self template];
}

- (SkyPubFileManager *)fileManager {
  return self->fileManager;
}
- (SkyDocument *)document {
  if ([self isTemplate])
    return [[self context] valueForKey:@"pageDocument"];
  
  return self->document;
}
- (SkyDocument *)componentDocument {
  return self->document;
}

- (SkyPubFileManager *)pubFileManager {
  // required for preview
  return self->fileManager;
}
- (EOGlobalID *)projectGlobalID {
  // required for preview
  return [[[self pubFileManager]
                 fileSystemAttributesAtPath:@"/"]
                 objectForKey:@"NSFileSystemNumber"];
}

- (SkyPubLinkManager *)linkManager {
  if (self->linkManager)
    return self->linkManager;
  if (self->document == nil)
    return nil;
  
  self->linkManager =
    [[SkyPubLinkManager alloc] initWithDocument:self->document
                               fileManager:[self fileManager]];
  
  return self->linkManager;
}

/* resource manager */

- (void)setResourceManager:(WOResourceManager *)_rm {
  if (self->rm == _rm)
    return;

#if 0 && DEBUG
  if (self->rm) {
    [self debugWithFormat:@"WARNING: resource manager already set (%@ vs %@)",
            self->rm, _rm];
  }
#endif
  ASSIGN(self->rm, _rm);
}
- (WOResourceManager *)resourceManager {
  if (self->rm)
    return self->rm;
  
  return (self->rm = [[super resourceManager] retain]);
}

/* awake & sleep */

- (void)awake {
  [self->cursorStack removeAllObjects]; 
  [super awake];
  
  if (!self->didEvaluate)
    [self _evaluateTemplateJSInContext:[self context]];
}

- (void)sleep {
  [super sleep];
  [self->cursorStack removeAllObjects]; 
}

/* cursors */

- (void)pushCursor:(id)_obj {
  if (self->cursorStack == nil)
    self->cursorStack = [[NSMutableArray alloc] initWithCapacity:4];
  [self->cursorStack addObject:(_obj ? _obj : [NSNull null])];
}
- (id)popCursor {
  unsigned len;
  id old;
  
  if ((len = [self->cursorStack count]) == 0) {
    [self logWithFormat:
	    @"WARNING: tried to pop element from empty cursor stack"];
    return nil;
  }
  
  old = [[self->cursorStack objectAtIndex:(len - 1)] retain];
  [self->cursorStack removeObjectAtIndex:(len - 1)];
  return [old autorelease];
}
- (id)cursor {
  // cache ?
  unsigned len;
  
  if ((len = [self->cursorStack count]) == 0)
    return self;
  return [self->cursorStack objectAtIndex:(len - 1)];
}

/* response */

- (BOOL)logTemplates {
  static int logTemplates = -1;
  if (logTemplates == -1)
    logTemplates = [[NSUserDefaults standardUserDefaults]
                                    boolForKey:@"LogTemplates"] ? 1 : 0;
  return logTemplates ? YES : NO;
}

- (NSException *)handleException:(NSException *)_exception
  duringGenerationOfResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  [self logWithFormat:@"%@: catched exception: %@", 
	  self->isTemplate ? @"Template" : @"PubDoc",
	  _exception];
  
  if (coreOnException) {
    printf("aborting, because SkyPubCoreOnException is enabled !\n");
    abort();
  }
  
  if (_response == nil)
    return nil;
  
  [_response appendContentString:
	       @"<font color=\"red\">Exception:</font><br/><pre>"];
  [_response appendContentString:@"Name:     "];
  [_response appendContentHTMLString:[_exception name]];
  [_response appendContentString:@"<br/>"];
  [_response appendContentString:@"Reason:   "];
  [_response appendContentHTMLString:[_exception reason]];
  [_response appendContentString:@"<br/>"];
  [_response appendContentString:@"InfoDict:\n"];
  [_response appendContentHTMLString:[[_exception userInfo] stringValue]];
  [_response appendContentString:@"</pre><br/>"];
  
  return nil;
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  NSAutoreleasePool *pool;

#if DEBUG && 0
  [self logWithFormat:@"append to response %@ ctx %@", _response, _ctx];
#endif
  
  if (self->document == NULL) {
    [_response appendContentString:@"<!-- missing document for component "];
    [_response appendContentHTMLString:[self name]];
    [_response appendContentString:@" -->"];
    return;
  }
  
  pool = [[NSAutoreleasePool alloc] init];
  
  /* load current ctx */
  if (!componentAsCursor) [_ctx pushCursor:[self document]];
  
  NS_DURING {
    /* append template ... */
  
    if ([self logTemplates]) {
      NSString *dpath;
    
      dpath = [self->document valueForKey:@"NSFilePath"];
    
      [_response appendContentString:@"<!-- begin "];
      if ([self isTemplate])
        [_response appendContentString:@"Template: "];
      [_response appendContentHTMLString:dpath];
      [_response appendContentString:@"-->"];
    
      [super appendToResponse:_response inContext:_ctx];
    
      [_response appendContentString:@"<!-- end "];
      if ([self isTemplate])
        [_response appendContentString:@"Template: "];
      [_response appendContentHTMLString:dpath];
      [_response appendContentString:@"-->"];
    }
    else
      [super appendToResponse:_response inContext:_ctx];
  }
  NS_HANDLER {
    [[self handleException:localException
           duringGenerationOfResponse:_response
           inContext:_ctx]
           raise];
  }
  NS_ENDHANDLER;
  
  /* restore parent ctx ... */
  if (!componentAsCursor) [_ctx popCursor];
  
#if DEBUG && 0
  [self debugWithFormat:@"objects in pool: %d", [pool autoreleaseCount]];
#endif
  [pool release];
}

@end /* SkyPubComponent */
