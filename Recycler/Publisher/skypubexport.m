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
// $Id: skypubexport.m 1 2004-08-20 11:17:52Z znek $

#import <Foundation/NSDate.h>
#include <NGObjWeb/WOApplication.h>
#include <NGExtensions/NGFileManager.h>
#include <EOControl/EOQualifier.h>
#include <NGJavaScript/NGJavaScriptObjectMappingContext.h>

@class EOQualifier;

@interface SkyPubExporter : WOApplication
{
  id<NSObject,NGFileManagerDataSources> fileManager;
  NGJavaScriptObjectMappingContext *jsMapContext;
  id           commandContext;
  
  /* operation */
  NSString     *rootPath;
  NSString     *targetPath;
  WORequest    *prototypeRequest;
  EOQualifier<EOQualifierEvaluation> *query;
  
  /* profiling */
  NSDate       *startDate;
  NSDate       *endDate;
  unsigned int startVSize;
  unsigned int endVSize;

  /* caching */
  NSMutableDictionary *pathToDoc;
  NSMutableDictionary *listCache;
}

- (id)initWithLogin:(NSString *)_login password:(NSString *)_pwd
  project:(NSString *)_projectKey;

/* accessors */

- (id<NSObject,NGFileManagerDataSources>)fileManager;
- (id<NSObject,NGFileManager>)targetFileManager;
- (id)commandContext;

/* timing */

- (NSTimeInterval)exportDuration;

/* exporting */

- (BOOL)exportPath:(NSString *)_path
  toLocalPath:(NSString *)_dpath
  templateName:(NSString *)_tmpl
  qualifier:(EOQualifier *)_q;

@end

#include "SkyPubResourceManager.h"
#include "SkyPubRequestHandler.h"
#include "SkyPubFileManager.h"
#include "SkyPubDataSource.h"
#include "SkyDocument+Pub.h"
#include <NGScripting/NGScriptLanguage.h>
#include "common.h"
#include <NGExtensions/NSProcessInfo+misc.h>
#include <NGExtensions/NGFileManager.h>
#include <OGoDocuments/SkyDocuments.h>

@interface SkyPubExporter(Privates)
- (NSException *)_exportPublication:(SkyDocument *)_doc
  toTargetPath:(NSString *)_dpath;
- (unsigned int)exportVirtualMemoryConsumption;
@end

@interface NSObject(Clearing)
- (void)clearContent;
- (void)enableCache;
- (void)addDocumentToCache:(id)_cache;
@end

@interface NGFileManager(UsedPrivates)
- (id)initWithContext:(id)_ctx projectCode:(id)_pcode;
@end

@implementation SkyPubExporter

static BOOL doProf       = NO;
static BOOL debugOn      = NO;
static BOOL printTimings = NO;

+ (void)initialize {
  static BOOL didInit = NO;
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSDictionary *defs;
  if (didInit) return;
  didInit = YES;
    
  defs = [NSDictionary dictionaryWithObject:@"4000" 
		       forKey:@"PubFetchLimit"];
  [ud registerDefaults:defs];
    
  printTimings = [ud boolForKey:@"SkyPubPrintTimings"];
  debugOn      = [self isDebuggingEnabled];
}

- (id)_setupLocalFileManagerForPath:(NSString *)_projectKey {
  NGLocalFileManager *fm;
  
  fm = [[NGLocalFileManager alloc] initWithRootPath:_projectKey
				   allowModifications:NO];
  if (fm == nil)
    [self logWithFormat:@"could not create FS filemanager: '%@'", _projectKey];
  return fm;
}

- (id)_setupDBFileManagerForLogin:(NSString *)_login password:(NSString *)_pwd
  projectCode:(NSString *)_projectKey
{
  Class fmClass;
  id fm;
  
  // TODO: shouldn't that use a context factory?
  if ((self->commandContext = [[LSCommandContext alloc] init]) == nil) {
    [self logWithFormat:@"could not allocate command context .."];
    return nil;
  }
  if (![self->commandContext login:_login password:_pwd]) {
    [self logWithFormat:@"could not login '%@' user ..", _login];
    return nil;
  }
  
  /* make filemanager */
  if ((fmClass = NSClassFromString(@"SkyProjectFileManager")) == Nil) {
    [self logWithFormat:
	    @"did not find filemanager class: SkyProjectFileManager!"];
    return nil;
  }
  fm = [[fmClass alloc] initWithContext:self->commandContext
			projectCode:_projectKey];
  if (fm == nil) {
    [self logWithFormat:@"couldn't create filemanager for project: '%@'",
	    _projectKey];
  }
  return fm;
}

- (id)initWithLogin:(NSString *)_login password:(NSString *)_pwd
  project:(NSString *)_projectKey
{
  if ([_login length] == 0) {
    [self logWithFormat:@"missing login!"];
    [self release];
    return nil;
  }
  if ([_projectKey length] == 0) {
    [self logWithFormat:@"missing project specifier!"];
    [self release];
    return nil;
  }
  
  if ((self = [self init])) {
    id fm;
    id tmp;
    SkyPubResourceManager *rm;
    
#if 0 // old, before skyrix-sope-42
    self->jsMapContext = [[NGJavaScriptObjectMappingContext alloc] init];
#else
    self->jsMapContext = (id)[[NGScriptLanguage languageWithName:@"javascript"]
			       createMappingContext];
#endif    
    
    /* make default command context */
    
    if (![_login isEqualToString:@"local"]) {
      fm = [self _setupDBFileManagerForLogin:_login password:_pwd
		 projectCode:_projectKey];
    }
    else 
      fm = [self _setupLocalFileManagerForPath:_projectKey];
    
    if (fm == nil) {
      [self release];
      return nil;
    }

    self->fileManager = [[SkyPubFileManager alloc] initWithFileManager:fm];
    [fm release]; fm = nil;
    [(id)self->fileManager enableCache];
    
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
  [self->query          release];
  [self->listCache      release];
  [self->jsMapContext   release];
  [self->pathToDoc      release];
  [self->targetPath     release];
  [self->rootPath       release];
  [self->fileManager    release];
  [self->commandContext release];
  [super dealloc];
}

/* JavaScript context */

- (NGJavaScriptObjectMappingContext *)jsMapContext {
  return self->jsMapContext;
}

/* accessors */

- (id<NSObject,NGFileManagerDataSources>)fileManager {
  return self->fileManager;
}
- (id<NSObject,NGFileManager>)targetFileManager {
  return [NSFileManager defaultManager];
}
- (id)commandContext {
  return self->commandContext;
}

/* exceptions/errors */

- (WOResponse *)handleException:(NSException *)_exc
  inContext:(WOContext *)_ctx
{
  [self logWithFormat:@"EXPORT EXCEPTION: %@", [_exc reason]];
  abort();
  return nil;
}

/* sessions */

- (WOSession *)createSessionForRequest:(WORequest *)_request {
  [self debugWithFormat:@"ERROR: creating session .."];
  return nil;
  //return [super createSessionForRequest:_request];
}

/* requests */

- (void)_initPubContext:(WOContext *)_ctx {
  if (self->listCache)
    [_ctx takeValue:self->listCache forKey:@"ListCache"];
  if (self->pathToDoc)
    [_ctx takeValue:self->pathToDoc forKey:@"PathToDoc"];
}

- (WORequest *)prototypeRequest {
  if (self->prototypeRequest == nil) {
  }
  return self->prototypeRequest;
}

- (WORequest *)requestForPath:(NSString *)_path {
  WORequest *r, *proto;
  
  proto = [self prototypeRequest];
  
  r = [[WORequest alloc]
                  initWithMethod:[proto method]
                  uri:_path
                  httpVersion:[proto httpVersion]
                  headers:[proto headers]
                  content:[proto content]
                  userInfo:[proto userInfo]];
  return [r autorelease];
}

/* timing */

- (NSTimeInterval)exportDuration {
  if (self->startDate == nil || self->endDate == nil)
    return 0.0;

  return [self->endDate timeIntervalSinceDate:self->startDate];
}
- (unsigned int)exportVirtualMemoryConsumption {
  return self->endVSize - self->startVSize;
}

/* path mapping */

- (NSString *)localPathForRequestPath:(NSString *)_path {
  if ([_path hasPrefix:@"/"])
    /* make absolute path local ... */
    _path = [_path substringFromIndex:1];
  
  return [self->targetPath stringByAppendingPathComponent:_path];
}

/* export selection */

- (BOOL)shouldExportDocument:(SkyDocument *)_doc {
  NSString *docPath;
  
  if (![_doc isNotNull])
    /* doc is null ... */
    return NO;
  
  docPath = [_doc valueForKey:@"NSFilePath"];
  if ([docPath length] == 0) {
    [self logWithFormat:@"WARNING: document has no filepath !: %@", _doc];
    return NO;
  }
  
  if ([[docPath pathExtension] isEqualToString:@"xtmpl"])
    return NO;
  if ([[docPath pathExtension] isEqualToString:@"sfm"])
    return NO;
  
  //[self debugWithFormat:@"check obj: %@", _doc];
  
  if (self->query) {
    if (![self->query evaluateWithObject:_doc])
      return NO;
  }
  return YES;
}

- (BOOL)shouldExportEmptyDirectory:(NSString *)_path {
  return NO;
}

/* export configuration */

- (NSDictionary *)targetFileAttributesForPath:(NSString *)_path {
  return nil;
}
- (NSDictionary *)targetDirectoryAttributesForPath:(NSString *)_path {
  return nil;
}

/* export */

- (NSException *)_exportDocument:(SkyDocument *)_doc
  toTargetPath:(NSString *)_dpath
{
  NSAutoreleasePool *pool;
  id<NSObject,NGFileManager> tfm;
  WORequest  *request;
  WOResponse *response;
  NSDate     *date = nil;
  unsigned int vsizeStart = 0;
  BOOL       ok;
  
  if (_doc == nil) return nil;
  
  if ([[_doc valueForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
    return [self _exportPublication:_doc toTargetPath:_dpath];
  
  if (![self shouldExportDocument:_doc]) return nil;
  
#if DEBUG
  date = [NSDate date];
#endif
  
  vsizeStart = [[NSProcessInfo processInfo] virtualMemorySize];
  
  pool = [[NSAutoreleasePool alloc] init];
  
  if (debugOn) {
    [self debugWithFormat:
          @"export file:\n  from: %@\n  to:   %@",
          [_doc valueForKey:@"NSFilePath"], _dpath];
  }
  
  tfm = [self targetFileManager];
  
  if ([tfm fileExistsAtPath:_dpath]) {
    if (![tfm removeFileAtPath:_dpath handler:nil]) {
      [self logWithFormat:@"error: failed to remove existing target file '%@'",
              _dpath];
      return [NSException exceptionWithName:@"DeleteError"
                          reason:_dpath
                          userInfo:nil];
    }
  }

  request = [self requestForPath:[_doc valueForKey:@"NSFilePath"]];
  if (request == nil) {
    return [NSException exceptionWithName:@"RequestCreationError"
                        reason:[_doc valueForKey:@"NSFilePath"]
                        userInfo:nil];
  }
  
  if (doProf) {
    fprintf(stderr, "  req:  %.3fs\n",
            [[NSDate date] timeIntervalSinceDate:date]);
  }

  response = [self dispatchRequest:request];
  
  if (doProf) {
    fprintf(stderr, "  disp: %.3fs\n",
            [[NSDate date] timeIntervalSinceDate:date]);
  }
  
  /* reset DOM structure */
  if ([_doc respondsToSelector:@selector(clearContent)]) {
    [_doc clearContent];
  }
  
  if (doProf) {
    fprintf(stderr, "  clear: %.3fs\n",
            [[NSDate date] timeIntervalSinceDate:date]);
  }

  if (response == nil) {
    return [NSException exceptionWithName:@"MissingResponse"
                        reason:_dpath
                        userInfo:nil];
  }
  
  ok = [tfm createFileAtPath:_dpath
            contents:[response content]
            attributes:
              [self targetFileAttributesForPath:
                      [_doc valueForKey:@"NSFilePath"]]];
  //[self debugWithFormat:@"  doc=%@", _doc];
  if (!ok) {
    return [NSException exceptionWithName:@"FileCreationError"
                        reason:_dpath
                        userInfo:nil];
  }
  
  [pool release];
  
  if (printTimings) {
    if ([[self class] isDebuggingEnabled]) {
      unsigned vsize = [[NSProcessInfo processInfo] virtualMemorySize];
      fprintf(stderr, "  size: %d bytes (file=%d, total=%dMB)\n",
              vsize - vsizeStart,
              [[_doc valueForKey:NSFileSize] intValue],
              vsize / 1024 / 1024);
      fprintf(stderr, "  time: %.3fs\n",
              [[NSDate date] timeIntervalSinceDate:date]);
    }
  }
  return nil;
}

- (NSException *)_exportPublication:(SkyDocument *)_doc
  toTargetPath:(NSString *)_dpath
{
  id<NSObject,NGFileManager> tfm;
  NSAutoreleasePool *pool;
  NSArray      *dirContents;
  NSEnumerator *dir;
  NSString     *filename;
  BOOL         didExportDir, isDir;
  NSMutableArray *errors;
  
  if (_doc == nil) return nil;
  
  if ([(NSString *)[_doc valueForKey:@"NSFilePath"] hasPrefix:@"/trash"])
    /* trash isn't exported ... */
    return nil;
  
  pool = [[NSAutoreleasePool alloc] init];
  
  didExportDir = NO;
  errors = nil;
  if (debugOn) {
    [self debugWithFormat:@"export directory: %@", 
	    [_doc valueForKey:@"NSFilePath"]];
  }
  
  tfm = [self targetFileManager];
  
  didExportDir = [tfm fileExistsAtPath:_dpath isDirectory:&isDir];
  if (didExportDir && !isDir) {
    [self logWithFormat:
            @"error: target directory '%@' already exists as a file !",
            _dpath];
    return [NSException exceptionWithName:@"DirectoryExistsAsFileError"
                        reason:_dpath
                        userInfo:nil];
  }
  else if (didExportDir)
    [self debugWithFormat:@"warning: directory '%@' already exists !", _dpath];
  
  dirContents = [[self fileManager] directoryContentsAtPath:
				      [_doc valueForKey:@"NSFilePath"]];
  
  dir = [dirContents objectEnumerator];
  while ((filename = [dir nextObject])) {
    NSString       *filepath;
    NSString       *dfilepath;
    NSException    *error;
    SkyDocument *childDoc;
    
    [self debugWithFormat:@"filename: %@", filename];
    filepath = [_doc valueForKey:@"NSFilePath"];
    [self debugWithFormat:@"    base: %@", filepath];
    filepath = [filepath stringByAppendingPathComponent:filename];
    [self debugWithFormat:@"    path: %@", filepath];
    
    if (![self shouldExportDocument:_doc])
      continue;
    
    if ((dfilepath = [self localPathForRequestPath:filepath]) == nil)
      continue;
    
    if (!didExportDir) {
      didExportDir = [tfm createDirectoryAtPath:_dpath
                          attributes:
                            [self targetDirectoryAttributesForPath:
                                    [_doc valueForKey:@"NSFilePath"]]];
    }
    
    if ((childDoc = [self->pathToDoc objectForKey:filepath]) == nil) {
      [self logWithFormat:@"did not find document for child path '%@' ..",
              filepath];
      continue;
    }
    
    if (![self shouldExportDocument:_doc])
      continue;
    
    if ((error = [self _exportDocument:childDoc toTargetPath:dfilepath])) {
      if (errors == nil) errors = [[NSMutableArray alloc] init];
      [errors addObject:error];
    }
  }
  
  if (!didExportDir && [self shouldExportEmptyDirectory:
			       [_doc valueForKey:@"NSFilePath"]]) {
    didExportDir = [[self targetFileManager]
                          createDirectoryAtPath:_dpath
                          attributes:
                            [self targetDirectoryAttributesForPath:
                                    [_doc valueForKey:@"NSFilePath"]]];
  }

  [pool release];
  
  if ([errors count] == 0)
    return nil;
  
  return [errors objectAtIndex:0];
}

- (SkyPubDataSource *)dataSourceConfiguredForTemplatesAndDirs {
  SkyPubDataSource     *ds;
  NSDictionary         *hints;
  EOFetchSpecification *fs;
  EOQualifier          *q;
  NSString *pq, *qs;
  
  pq = [[NSUserDefaults standardUserDefaults] stringForKey:@"prequery"];
  
  qs = @"(NSFileType = 'NSFileTypeDirectory') OR (NSFileName like '*.xtmpl')";
  if ([pq length] > 0) {
    qs = [qs stringByAppendingString:@" OR "];
    qs = [qs stringByAppendingString:pq];
  }
  
  if ((q = [EOQualifier qualifierWithQualifierFormat:qs]) == nil) {
    [self logWithFormat:@"ERROR: couldn't create prefetch qualifier: '%@'",qs];
    return nil;
  }
  
  hints = [NSDictionary dictionaryWithObject:
                          [NSNumber numberWithBool:YES]
                        forKey:@"fetchDeep"];
  
  fs = [EOFetchSpecification fetchSpecificationWithEntityName:@"/"
                             qualifier:q
                             sortOrderings:nil];
  [fs setFetchLimit:
        [[[NSUserDefaults standardUserDefaults]
                          objectForKey:@"PubFetchLimit"]
                          intValue]];
  [fs setHints:hints];
  if (fs == nil)
    return nil;

  ds = (id)[[self fileManager] dataSourceAtPath:@"/"];
  [ds setFetchSpecification:fs];
  return ds;
}

- (SkyPubDataSource *)dataSourceConfiguredForPath:(NSString *)_path
  qualifier:(EOQualifier *)_extraQual
{
  EOQualifier          *q;
  NSArray              *sortOrderings;
  NSDictionary         *hints;
  EOFetchSpecification *fs;
  SkyPubDataSource     *ds;
  NSString *pq;
  
  pq = [_path stringByAppendingString:@"*"];
  
  q = [EOQualifier qualifierWithQualifierFormat:
                     @"(NOT (NSFilePath like '/trash*')) AND "
                     @"(NSFilePath like %@) AND "
                     @"(NOT (NSFileName like '*.xtmpl')) AND "
                     @"(NOT (NSFileName like '*.sfm'))", pq];
  
  if (_extraQual) {
    q = [[[EOAndQualifier alloc]
                          initWithQualifiers:q, _extraQual, nil]
                          autorelease];
  }
  
  if (debugOn) [self debugWithFormat:@"source qualifier:\n  %@", q];
  
  hints = [NSDictionary dictionaryWithObject:
                          [NSNumber numberWithBool:YES]
                        forKey:@"fetchDeep"];
  
  sortOrderings = [NSArray arrayWithObjects:
                             [EOSortOrdering sortOrderingWithKey:@"NSFileType"
                                             selector:EOCompareAscending],
                             [EOSortOrdering sortOrderingWithKey:@"NSFilePath"
                                             selector:EOCompareAscending],
                             nil];
  
  fs = [EOFetchSpecification fetchSpecificationWithEntityName:_path
                             qualifier:q
                             sortOrderings:sortOrderings];
  [fs setFetchLimit:
        [[[NSUserDefaults standardUserDefaults]
                          objectForKey:@"PubFetchLimit"]
                          intValue]];
  [fs setHints:hints];
  if (fs == nil)
    return nil;
  
  ds = (id)[[self fileManager] dataSourceAtPath:@"/"];
  [ds setFetchSpecification:fs];
  return ds;
}

- (BOOL)exportPath:(NSString *)_path
  toLocalPath:(NSString *)_dpath
  templateName:(NSString *)_tmpl
  qualifier:(EOQualifier *)_qual
{
  SkyPubDataSource *ds;
  BOOL        result;
  NSException *error;

  if (debugOn) {
    [self debugWithFormat:
	    @"export: '%@'\n  to: %@\n  template: %@\n  qualifier: %@", 
	    _path, _dpath, _tmpl, _qual];
  }
  
  if (![[self targetFileManager] changeCurrentDirectoryPath:_dpath]) {
    [self logWithFormat:@"couldn't cd to target directory: '%@'", _dpath];
    return NO;
  }
  
  [self->jsMapContext pushContext];
  
  if (self->pathToDoc == nil)
    self->pathToDoc = [[NSMutableDictionary alloc] initWithCapacity:4096];
  else
    [self->pathToDoc removeAllObjects];
  if (self->listCache == nil)
    self->listCache = [[NSMutableDictionary alloc] initWithCapacity:256];
  else
    [self->listCache removeAllObjects];
  
  if ([_tmpl length] > 0)
    [(id)[self resourceManager] setMasterTemplateName:_tmpl];
  
  ASSIGNCOPY(self->rootPath,   _path);
  ASSIGNCOPY(self->targetPath, _dpath);
  ASSIGN(self->query, _qual);
  [self->startDate release]; self->startDate = nil;
  [self->endDate   release]; self->endDate   = nil;
  
  self->startVSize = [[NSProcessInfo processInfo] virtualMemorySize];
  self->startDate  = [[NSDate alloc] init];
  
  /* fill cache with directory documents and templates */

  if ((ds = [self dataSourceConfiguredForTemplatesAndDirs])) {
    NSArray        *docs;
    NSEnumerator   *e;
    SkyDocument *doc;
    
    [self debugWithFormat:@"filling dir and templates document cache ..."];
    [self debugWithFormat:@"  datasource: %@", ds];
    
    docs = [ds fetchObjects];
    [self debugWithFormat:@"  %i dirs and templates", [docs count]];

    /* collect documents */

    e = [docs objectEnumerator];
    while ((doc = [e nextObject])) {
      NSString *p;

      p = [doc valueForKey:@"NSFilePath"];
      if ([p length] == 0)
        continue;
      
      if ([p hasSuffix:@"/"] && ([p length] > 1))
        p = [p substringToIndex:([p length] - 1)];
      
      [self debugWithFormat:@"T[0x%08X]: %@", doc, p];
      [self->pathToDoc   setObject:doc forKey:p];
      [(id)self->fileManager addDocumentToCache:doc];
    }
  }
  
  /* fetch objects to be exported */
  
  ds = [self dataSourceConfiguredForPath:_path qualifier:self->query];
  {
    NSArray      *docs;
    NSEnumerator *e;
    SkyDocument  *doc;
    
    [self debugWithFormat:@"got datasource:\n  %@", ds];
    
    docs = [ds fetchObjects];
    [self debugWithFormat:@"number of matching documents: %i", [docs count]];
    
    /* collect documents */

    e = [docs objectEnumerator];
    while ((doc = [e nextObject])) {
      NSString *p;
      
      p = [doc valueForKey:@"NSFilePath"];
      if ([p length] == 0)
        continue;
      
      if ([p hasSuffix:@"/"] && ([p length] > 1))
        p = [p substringToIndex:([p length] - 1)];
      
      [self debugWithFormat:@"P[0x%08X]: %@", doc, p];
      
      [self->pathToDoc setObject:doc forKey:p];
      [(id)self->fileManager addDocumentToCache:doc];
    }

    /* export documents */

    error = nil;
    e = [docs objectEnumerator];
    while ((doc = [e nextObject]) && (error == nil)) {
      NSString *p, *tp;
      
      p = [doc valueForKey:@"NSFilePath"];
      if ([p length] == 0) {
        [self debugWithFormat:@"missing path of document: %@", doc];
        continue;
      }
      
      if ([p hasSuffix:@"/"] && ([p length] > 1))
        p = [p substringToIndex:([p length] - 1)];
      
      if (![self shouldExportDocument:doc]) {
        //[self debugWithFormat:@"do not export document: %@", doc];
        continue;
      }
      
      tp = [self localPathForRequestPath:p];
      if ([tp length] == 0) {
        [self debugWithFormat:@"couldn't get local path: %@", p];
        continue;
      }
      
      [self debugWithFormat:@"E: %@", p];
      error = [self _exportDocument:doc toTargetPath:tp];
    }
  }
  
  result = (error == nil);
  
  self->endDate  = [[NSDate alloc] init];
  self->endVSize = [[NSProcessInfo processInfo] virtualMemorySize];
  
  RELEASE(self->rootPath);   self->rootPath   = nil;
  RELEASE(self->targetPath); self->targetPath = nil;
  
  [self->pathToDoc removeAllObjects];
  
  [self->jsMapContext popContext];
  
  return result;
}

@end /* SkyPubExporter */

void usage(int exitCode) {
  printf("usage: skypubexport\n"
         "  -login <login>\n"
         "  -password  <pwd>\n"
         "  -project   <project-num>        SKYRiX project code\n"
         "  -target    <destination-path>   export destination\n"
         "  [-source   <source-path>]       (default: '/')\n"
         "  [-template <template-name>]     (default: 'Main')\n"
         "  [-query    <EOQualifier query>] restrict set of exported docs\n"
         "  [-prequery <EOQualifier query>] prefetch matching docs\n"
         );
  exit(exitCode);
}

int main(int argc, char **argv, char **env) {
  NSAutoreleasePool *pool;
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
  [NSAutoreleasePool enableDoubleReleaseCheck:NO];
#endif

  pool = [NSAutoreleasePool new];
  {
    NSUserDefaults *ud;
    SkyPubExporter *exporter;
    NSString    *projectKey, *login, *pwd, *path, *dpath, *mtmpl, *queryString;
    EOQualifier *q;
    
    ud          = [NSUserDefaults standardUserDefaults];
    login       = [ud stringForKey:@"login"];
    pwd         = [ud stringForKey:@"password"];
    projectKey  = [ud stringForKey:@"project"];
    path        = [ud stringForKey:@"source"];
    dpath       = [ud stringForKey:@"target"];
    mtmpl       = [ud stringForKey:@"template"];
    queryString = [ud stringForKey:@"query"];
    
    if ([login      length] == 0) usage(1);
    if ([pwd        length] == 0) pwd = @""; //usage(2);
    if ([projectKey length] == 0) usage(3);
    if ([dpath      length] == 0) usage(4);
    
    if ([path  length] == 0) path = @"/";
    if ([mtmpl length] == 0) mtmpl = @"Main";
    
    exporter =
      [[SkyPubExporter alloc] initWithLogin:login password:pwd
                              project:projectKey];
    
    if (![WOApplication isCachingEnabled]) {
      [exporter debugWithFormat:
                  @"WARNING: component caching is not enabled, "
                  @"export will be slow !"];
    }
    else {
      [exporter logWithFormat:
                  @"WARNING: component caching is enabled, "
                  @"export will consume a lot of memory !"];
    }

    q = ([queryString length] > 0)
      ? [EOQualifier qualifierWithQualifierFormat:queryString]
      : nil;
    
    [exporter debugWithFormat:@"got query: %@", q];
    
    if (![exporter exportPath:path
                   toLocalPath:dpath
                   templateName:mtmpl
                   qualifier:q]) {
      [exporter logWithFormat:@"export failed !"];
    }

    if (printTimings) {
      unsigned mem;
      NSTimeInterval secs;

      mem  = [exporter exportVirtualMemoryConsumption];
      secs = [exporter exportDuration];
      
      [exporter logWithFormat:@"  export duration: %.3fs (%.3fm), vmem=%d",
                  secs, (secs / 60), mem];
    }
    
    [exporter release];
  }
  [pool release];
  
  exit(0);
  return 0;
}
