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

#include "SkyP4ViewerFormComponent.h"
#include "SkyP4ProjectResourceManager.h"
#include "common.h"
#include <OGoDocuments/LSCommandContext+Doc.h>

@implementation SkyP4ViewerFormComponent

+ (int)version {
  return [super version] + 1; /* v5 */
}
+ (void)initialize {
  NSAssert2([super version] == 4,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (void)dealloc {
  [self->rm           release];
  [self->formDocument release];
  [self->document     release];
  [self->fileManager  release];
  [super dealloc];
}

/* accessors */

- (void)setPreview:(BOOL)_flag {
  self->preview = _flag;
}
- (BOOL)preview {
  return self->preview;
}

- (void)setFileManager:(id<NSObject,SkyDocumentFileManager>)_fm {
  ASSIGN(self->fileManager, _fm);
}
- (id<NSObject,SkyDocumentFileManager>)fileManager {
  return self->fileManager;
}

- (void)setErrorString:(NSString *)_s {
  [[[self context] page]
          takeValue:_s
          forKey:@"errorString"];
}

- (void)setDocument:(id)_doc {
  ASSIGN(self->document, _doc);
}
- (id)document {
  return self->document;
}

- (void)setFormDocument:(id)_doc {
  ASSIGN(self->formDocument, _doc);
}
- (id)formDocument {
  if (self->formDocument == nil) {
    if (self->fileManager) {
      NSString *path;
      
      path = [self name];
      
      self->formDocument = 
        [[(id)[self fileManager] documentAtPath:path] retain];
      
      if (self->formDocument == nil) {
        [self debugWithFormat:@"found no document for form '%@' in fm %@ ..",
                path, [self fileManager]];
      }
    }
    else {
      [self debugWithFormat:@"missing filemanager !"];
    }
  }
  return self->formDocument;
}

/* specialized resource manager */

- (WOComponent *)pageWithName:(NSString *)_name {
  id page;
  
  if (![_name isAbsolutePath]) {
    _name = [[[self name]
                    stringByDeletingLastPathComponent]
                    stringByAppendingPathComponent:_name];
  }
  
  [self debugWithFormat:@"pageWithName: %@", _name];
  
  if ((page = [super pageWithName:_name]) == nil) {
    [self debugWithFormat:@"found no page for name '%@'", _name];
    return nil;
  }
  
  if ([page isKindOfClass:[SkyP4ViewerFormComponent class]]) {
    SkyP4ViewerFormComponent *form;
    
    form = page;
    
    if ([self->fileManager fileExistsAtPath:_name]) {
      id formDoc;
      
      if ((formDoc = [(id)[self fileManager] documentAtPath:_name]))
        [form setFormDocument:formDoc];
    }
    
    [form setFileManager:self->fileManager];
    [form setDocument:self->document];
    
    form->rm = RETAIN(self->rm);
  }
  
  return page;
}

- (WOResourceManager *)resourceManager {
  if (self->rm)
    return self->rm;
  
  self->rm = [[SkyP4ProjectResourceManager alloc] initWithFormComponent:self];
  
  return self->rm
    ? self->rm
    : [[self parent] resourceManager];
}

/* properties */

- (id)_jsprop_document:(id)_prop {
  [self setDocument:_prop];
  return self;
}
- (id)_jsprop_document {
  return [self document];
}

- (id)_jsprop_formDocument:(id)_prop {
  [self setFormDocument:_prop];
  return self;
}
- (id)_jsprop_formDocument {
  return [self formDocument];
}

/* methods */

- (id)_jsfunc_goBack:(NSArray *)_array {
  unsigned count;
  id navigation;

  navigation = [(LSWSession *)[self session] navigation];
  
  if ((count = [_array count]) == 0) {
    return [navigation leavePage];
  }
  else {
    unsigned i;
    id page;
    
    count = [[_array objectAtIndex:0] unsignedIntValue];
    for (i = 0; i < count; i++) {
      page = [navigation leavePage];
    }
    return page;
  }
}

- (id)_jsfunc_FileManager:(NSArray *)_args {
  unsigned count;
  
  if ((count = [_args count]) == 0) {
    return [self fileManager];
  }
  else {
    NSString *projectCode;
    NSString *thisFSName;
    
    thisFSName = [[[self fileManager]
                         fileSystemAttributesAtPath:@"."]
                         objectForKey:@"NSFileSystemName"];
    
    projectCode = [_args objectAtIndex:0];
    if ([projectCode isEqualToString:thisFSName])
      return [self _jsfunc_FileManager:nil];
    
    [self logWithFormat:@"can't create filemanager with name '%@'", projectCode];
    return nil;
  }
}

- (NSString *)_absoluteComponentPath:(NSString *)_path {
  NSString *tmp;
  
  if ([_path length] == 0)
    return nil;
  if ([_path isAbsolutePath])
    return _path;
  
  tmp  = [self name];
  tmp  = [tmp stringByDeletingLastPathComponent];
  return [tmp stringByAppendingPathComponent:_path];
}

- (id)_jsfunc_formWithName:(NSArray *)_array {
  unsigned count;
  id       form;
  NSString *path;
  NSString *contentString;
  
  if ((count = [_array count]) == 0) {
    [self debugWithFormat:@"missing parameter in function !"];
    return nil;
  }
  
  if ([self fileManager] == nil) {
    [self setErrorString:@"missing filemanager for form creation"];
    return nil;
  }
  
  path = [[_array objectAtIndex:0] stringValue];
  path = [self _absoluteComponentPath:path];
  
  if (![[self fileManager] fileExistsAtPath:path]) {
    NSString *s;
    
    s = [NSString stringWithFormat:@"did not find form '%@'", path]; 
    [self setErrorString:s];
    return nil;
  }
  
  contentString =
    [[NSString alloc] initWithData:[self->fileManager contentsAtPath:path]
                      encoding:NSISOLatin1StringEncoding];
  AUTORELEASE(contentString);
  
  form = [self formWithName:path
               componentClass:[self class]
               content:contentString];
  
  if ([form isKindOfClass:[SkyP4ViewerFormComponent class]]) {
    if (self->fileManager) [form setFileManager:self->fileManager];
    if (self->document)    [form setDocument:self->document];
  }
  
  [self debugWithFormat:@"form: %@", form];
  
  return form;
}

- (void)_setNewFormInParent:(id)_form {
  [[self parent] takeValue:_form forKey:@"previewFormComponent"];
}

- (id)_pageForForm:(id)_form {
  id form;
  id page;
  
  if (_form == nil)
    return nil;
  
  form = [_form isKindOfClass:[WOComponent class]]
    ? _form
    : [self _jsfunc_formWithName:[NSArray arrayWithObject:_form]];
  
  if (form == nil)
    return nil;
  
  if ([[[form formDocument] valueForKey:@"noframe"] boolValue])
    return form;
  
  page = [[WOApplication application] pageWithName:@"SkyP4FormPage"
                                      inContext:[self context]];
  [page takeValue:[self fileManager] forKey:@"fileManager"];
  [page takeValue:form               forKey:@"currentForm"];
  return page;
}

- (id)_jsfunc_openForm:(NSArray *)_array {
  unsigned count;
  NSString *formName;
  id form;
  id page;
  
  if ((count = [_array count]) == 0) {
    [self debugWithFormat:@"missing parameter in function !"];
    return nil;
  }
  
  /* create form component */

  if ([[_array objectAtIndex:0] isKindOfClass:[SkyFormComponent class]]) {
    form     = [_array objectAtIndex:0];
    formName = [(WOComponent *)form name];
  }
  else {
    form     = nil;
    formName = [[_array objectAtIndex:0] stringValue];
    formName = [self _absoluteComponentPath:formName];
  }
  
  if ((page = [self _pageForForm:form ? form : formName]) == nil)
    return nil;
  
  if (form == nil) {
    if ([page isKindOfClass:[SkyFormComponent class]])
      form = page;
    else
      form = [page valueForKey:@"currentForm"];
  }
  
  [form takeValue:formName forKey:@"$0"];
  
  /* transfer positional parameters (as $0,$1,...) */
  
  if (count > 1) {
    unsigned i;
    
    for (i = 1; i < count; i++) {
      NSString *argName;
      
      argName = [NSString stringWithFormat:@"$%d", i];
      [form takeValue:[_array objectAtIndex:i] forKey:argName];
    }
  }

  /* push form to navigation stack */
  
  if ([[[form formDocument] valueForKey:@"noframe"] boolValue]) {
    return [form generateResponse];
  }
  else {
    [[(id)[self session] navigation] enterPage:page];
    
    /* return success code */
    return [NSNumber numberWithBool:(form != nil ? YES : NO)];
  }
}
- (id)_jsfunc_gotoForm:(NSArray *)_array {
  /* DEPRECATED, use openForm: */
  return [self _jsfunc_openForm:_array];
}

- (id)gotoAnkerURL:(NSString *)_url {
  id form;
  
  if ((form = [self _jsfunc_openForm:[NSArray arrayWithObject:_url]])) {
    if ([form conformsToProtocol:@protocol(WOActionResults)])
      return form;
  }
  return nil;
}

- (NSData *)contentForComponentRelativeURL:(id)_url {
  if ((_url = [_url stringValue]) == nil)
    return nil;
  
  _url = [self _absoluteComponentPath:_url];
  
  if (![[self fileManager] fileExistsAtPath:_url]) {
    [self setErrorString:
            [NSString stringWithFormat:@"did not find file '%@'", _url]];
    return nil;
  }
  
  return [[self fileManager] contentsAtPath:_url];
}

- (id)_jsfunc_pageForDocument:(NSArray *)_array {
  /* not public API */
  EOGlobalID *gid;
  unsigned   count;
  id arg0;
  id page;
  
  if ((count = [_array count]) == 0) {
    /* missing 'document' parameter */
    return nil;
  }
  
  arg0 = [_array objectAtIndex:0];
  if ([arg0 isKindOfClass:NSClassFromString(@"SkyDocument")]) {
    gid = [arg0 globalID];
  }
  else if ([arg0 isKindOfClass:[NSString class]]) {
    gid = [[self fileManager] globalIDForPath:arg0];
  }
  else {
    return nil;
  }
  
  if ((gid == nil) && ![arg0 isKindOfClass:[SkyDocument class]]) {
    /* did not find proper gid */
    [[[self context] page]
            takeValue:@"couldn't determine document global id !"
            forKey:@"errorString"];
    
    [self logWithFormat:
            @"couldn't determine document global id for object %@ !",
            arg0];
    return nil;
  }
  
  if (count == 1) {
    id obj;

    obj = [arg0 isKindOfClass:[SkyDocument class]]
      ? arg0 : gid;
    
    page = [self activateObject:obj withVerb:@"view"];
  }
  else {
    id doc;
    id form;
    
    if ([arg0 isKindOfClass:[SkyDocument class]]) {
      doc = arg0;
    }
    else {
      id<SkyDocumentFileManager> fm;
      
      fm  = (id<SkyDocumentFileManager>)[self fileManager];
      doc = [fm documentAtPath:[arg0 stringValue]];
    }
    
    page = [self _pageForForm:[_array objectAtIndex:1]];
    form = [page valueForKey:@"currentForm"];
    
    [form takeValue:doc forKey:@"document"];
  }
  return page;
}

- (id)_jsfunc_openDocument:(NSArray *)_array {
  id page;
  
  if ((page = [self _jsfunc_pageForDocument:_array]) == nil)
    return [NSNumber numberWithBool:NO];
  
  [[(id)[self session] navigation] enterPage:page];
  
  return [NSNumber numberWithBool:YES];
}
- (id)_jsfunc_viewDocument:(NSArray *)_array {
  /* DEPRECATED */
  return [self _jsfunc_openDocument:_array];
}

- (NSException *)_handleScriptLoadError:(NSException *)e script:(NSString *)s {
  int line;
  NSArray *lines;

#if DEBUG
  [self debugWithFormat:@"load-error: %@", e];
#endif
  
  if (![[e name] isEqualToString:@"JavaScriptError"])
    return e;
  
  if ((line = [[[e userInfo] objectForKey:@"line"] intValue]) == 0)
    return e;
  
  if ((lines = [s componentsSeparatedByString:@"\n"]) == nil)
    return e;
  if ((int)[lines count] <= line)
    return e;
  
  [self logWithFormat:@"JSERROR in script line %i:\n%@",
          line,
          [lines objectAtIndex:line]];
  
  if ((line - 2) > 0)
    [self logWithFormat:@"%2i: %@", (line - 2), [lines objectAtIndex:(line-2)]];
  if ((line - 1) > 0)
    [self logWithFormat:@"%2i: %@", (line - 1), [lines objectAtIndex:(line-1)]];
  [self logWithFormat:@"%2i: %@", line, [lines objectAtIndex:line]];
  if ((line + 1) < (int)[lines count])
    [self logWithFormat:@"%2i: %@", (line + 1), [lines objectAtIndex:(line+1)]];
  if ((line + 2) < (int)[lines count])
    [self logWithFormat:@"%2i: %@", (line + 2), [lines objectAtIndex:(line+2)]];
  
  return e;
}

- (id)_jsfunc_loadScript:(NSArray *)_array {
  NSAutoreleasePool *pool;
  unsigned count;
  NSString *path;
  NSString *scriptText;
  NSData   *data;
  id result;
  
  if ((count = [_array count]) == 0) {
    /* missing 'document' parameter */
#if DEBUG
    [self debugWithFormat:@"loadScript failed, not enough parameters .."];
#endif
    return [NSNumber numberWithBool:NO];
  }

  pool = [[NSAutoreleasePool alloc] init];
  
  path = [[_array objectAtIndex:0] stringValue];
  if ([path length] == 0) {
#if DEBUG
    [self debugWithFormat:@"loadScript failed, empty first parameter .."];
#endif
    return [NSNumber numberWithBool:NO];
  }
  
  if (![path isAbsolutePath]) {
    NSString *tmp;
    
    tmp  = [self name];
    tmp  = [tmp stringByDeletingLastPathComponent];
    path = [tmp stringByAppendingPathComponent:path];
  }
  
  if (![[self fileManager] fileExistsAtPath:path]) {
#if DEBUG
    [self debugWithFormat:@"loadScript failed, file '%@' does not exist ..",
            path];
#endif
    return [NSNumber numberWithBool:NO];
  }

  data = [[self fileManager] contentsAtPath:path];
  if ([data length] == 0) {
#if DEBUG
    [self debugWithFormat:@"loadScript failed, file '%@' has no contents ..",
            path];
#endif
    return [NSNumber numberWithBool:NO];
  }
  
  scriptText =
    [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
  AUTORELEASE(scriptText);

#if DEBUG && 0
  NSLog(@"evaluating script: %@", scriptText);
#endif

  NS_DURING {
    result = [self evaluateJavaScript:scriptText];
  }
  NS_HANDLER {
#if DEBUG
#warning to be removed ...
    fprintf(stderr, "%s: EXCEPTION ...\n", __PRETTY_FUNCTION__);
#endif
    [[self _handleScriptLoadError:localException script:scriptText] raise];
    result = nil;
  }
  NS_ENDHANDLER;

  RETAIN(result);
  RETAIN(path);
  RELEASE(pool); pool = nil;
  AUTORELEASE(result);
  AUTORELEASE(path);
  
#if DEBUG
  if (result == nil)
    [self debugWithFormat:@"evaluation of loaded script '%@' failed.", path];
  else
    [self debugWithFormat:@"  result: %@", result];
#endif
  
  return result;
}

- (id)_jsfunc_getProject:(NSArray *)_args {
  unsigned count;
  id url;
  id<SkyDocumentManager> dm;
  
  if ((count = [_args count]) == 0) {
    url = [[[self fileManager]
                  fileSystemAttributesAtPath:@"/"]
                  objectForKey:@"NSFileSystemNumber"];
    if (url == nil) {
      [self setErrorString:@"Couldn't get project-id from filemanager !"];
      return nil;
    }
  }
  else {
    url = [_args objectAtIndex:0];
  }
  
  if ((dm = [[(id)[self session] commandContext] documentManager]) == nil) {
    [self setErrorString:@"Couldn't get document manager !"];
    return nil;
  }

  return ([url isKindOfClass:[EOGlobalID class]])
    ? [dm documentForGlobalID:url]
    : [dm documentForURL:[url stringValue]];
}

@end /* SkyP4ViewerFormComponent */
