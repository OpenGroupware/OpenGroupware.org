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

#include <NGObjWeb/WOApplication.h>
#include <NGObjWeb/WOSession.h>

#include <NGJavaScript/NGJavaScriptObjectMappingContext.h>

@interface Application : WOApplication
{
  NGJavaScriptObjectMappingContext *jsMapContext;
  id commandContext;
  id fileManager;
}
@end

@interface Session : WOSession
{
  id commandContext;
  id fileManager;
}
@end

#include "SkyPubResourceManager.h"
#include "SkyPubRequestHandler.h"
#include "SkyPubFileManager.h"
#include "common.h"
#include <NGJavaScript/NGJavaScript.h>
#include <NGScripting/NGScriptLanguage.h>
#include <NGExtensions/NGFileManager.h>
#include <OGoDocuments/SkyDocuments.h>

@interface TestComp : WOComponent
@end

@implementation TestComp

- (void)appendToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
  [_r appendContentString:@"<h3>WO Component 'Template' !</h3>"];
}

@end /* TestComp */

@interface NSObject(UsedPrivates)
- (id)initWithContext:(id)_ctx projectCode:(id)_code;
@end

@implementation Application

- (id)init {
  if ((self = [super init])) {
    NSUserDefaults *ud;
    NSString *projectKey, *login, *pwd, *rootPath;
    id fm;
    id tmp;
    SkyPubResourceManager *rm;

#if DEBUG
    [self debugWithFormat:@"JS version: %@",
            [NGJavaScriptRuntime javaScriptImplementationVersion]];
#endif
    
#if 0 // old, before skyrix-sope-42
    self->jsMapContext = [[NGJavaScriptObjectMappingContext alloc] init];
#else
    self->jsMapContext = (id)[[NGScriptLanguage languageWithName:@"javascript"]
                                            createMappingContext];
#endif    
    
    ud = [NSUserDefaults standardUserDefaults];
    
    if ((rootPath = [ud stringForKey:@"local"])) {
      fm = [[NGLocalFileManager alloc] initWithRootPath:rootPath
                                       allowModifications:NO];
      if (fm == nil) {
        [self logWithFormat:@"could not create filemanager for path %@ ..",
              rootPath];
        [self release];
        return nil;
      }
    }
    else {
      Class fmClass = Nil;
      
      login    = [ud stringForKey:@"login"];
      pwd      = [ud stringForKey:@"password"];
      [self logWithFormat:@"Defaults: %@ (login=%@,passwd=%s)",
            ud, login, [pwd length] > 0 ? "yes" : "no"];
    
      /* make default command context */
    
      if ((self->commandContext = [[LSCommandContext alloc] init]) == nil) {
        [self logWithFormat:@"couldn't create command context .."];
        [self release];
        return nil;
      }
      if (![self->commandContext login:login password:pwd]) {
        [self logWithFormat:@"couldn't login '%@' user ..",
              [ud stringForKey:@"login"]];
        [self release];
        return nil;
      }

      /* make filemanager */

      projectKey = [ud stringForKey:@"project"];
      if (projectKey == nil) {
        [self logWithFormat:@"missing -project parameter, exiting .."];
        [self release];
        return nil;
      }

      fmClass = NSClassFromString(@"SkyProjectFileManager");
      fm = [[fmClass alloc] initWithContext:self->commandContext
                            projectCode:projectKey];
      if (fm == nil) {
        [self logWithFormat:@"couldn't create filemanager for project %@ ..",
              projectKey];
        [self release];
        return nil;
      }
    }
    [self debugWithFormat:@"fm: %@", fm];
    self->fileManager = [[SkyPubFileManager alloc] initWithFileManager:fm];
    [fm release]; fm = nil;
    
    /* make resource manager and request handler */

    rm = [[SkyPubResourceManager alloc] initWithFileManager:self->fileManager];
    [self setResourceManager:rm];
    
    tmp = [[SkyPubRequestHandler alloc] initWithFileManager:self->fileManager
                                        resourceManager:rm];
    [self setDefaultRequestHandler:tmp];
    [tmp release];
    [rm  release];
  }
  return self;
}

- (void)dealloc {
  [self->jsMapContext   release];
  [self->fileManager    release];
  [self->commandContext release];
  [super dealloc];
}

/* accessors */

- (NGJavaScriptObjectMappingContext *)jsMapContext {
  return self->jsMapContext;
}

- (id)fileManager {
  return self->fileManager;
}
- (id)commandContext {
  return self->commandContext;
}

/* exceptions */

- (WOResponse *)handleException:(NSException *)_exc
  inContext:(WOContext *)_ctx
{
#if 1
  [self logWithFormat:@"%@: catched:\n  %@.", self, _exc];
  
  if ([[[NSUserDefaults standardUserDefaults]
                        objectForKey:@"WOCoreOnAppException"]
                        boolValue])
    abort();
#endif
  
  return [super handleException:_exc inContext:_ctx];
}

/* sessions */

- (WOSession *)createSessionForRequest:(WORequest *)_request {
  [self debugWithFormat:@"WARNING: creating session .."];
  return [super createSessionForRequest:_request];
}

- (void)awake {
  [self->commandContext pushContext];
  [self->jsMapContext pushContext];
  
  [self->fileManager enableCache];
}
- (void)sleep {
  [super sleep];
  
  [self->fileManager disableCache];
  
  if ([self->commandContext isTransactionInProgress]) {
    if (![self->commandContext commit])
      [self logWithFormat:@"lso: %@: last commit failed.",
              self->commandContext];
  }
  [(NGObjectMappingContext *)self->jsMapContext popContext];
  [(LSCommandContext *)self->commandContext popContext];
  
#if 0
  [self->fileManager flush];
#endif
}

@end /* Application */

@implementation Session

- (void)dealloc {
  [self->fileManager    release];
  [self->commandContext release];
  [super dealloc];
}

/* accessors */

- (id)fileManager {
  return self->fileManager;
}
- (id)commandContext {
  return self->commandContext;
}

/* notifications */

- (void)awake {
  [self->commandContext pushContext];
}
- (void)sleep {
  [super sleep];
  
  [self->fileManager pubFlush];
  
  if ([self->commandContext isTransactionInProgress]) {
    if (![self->commandContext commit])
      [self logWithFormat:@"lso: %@: last commit failed.",
              self->commandContext];
  }
  [(LSCommandContext *)self->commandContext popContext];
  
#if 0
  [self->fileManager flush];
#endif
}

@end /* Session */

int main(int argc, char **argv, char **env) {
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
  [NSAutoreleasePool enableDoubleReleaseCheck:NO];
#endif
  WOWatchDogApplicationMain(@"Application", argc, (void*)argv);
  return 0;
}
