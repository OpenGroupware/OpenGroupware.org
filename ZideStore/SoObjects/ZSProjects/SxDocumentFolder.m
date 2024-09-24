/*
  Copyright (C) 2002-2007 SKYRIX Software AG
  Copyright (C) 2006-2007 Helge Hess

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

#include "SxDocumentFolder.h"
#include "SxProjectFolder.h"
#include <OGoDocuments/NGLocalFileManager.h>
#include "common.h"
#include <time.h>

@implementation SxDocumentFolder

static BOOL debugOn = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  debugOn = [ud boolForKey:@"SxDocumentFolderDebugEnabled"];
}

- (void)dealloc {
  [self->attrCache        release];
  [self->folderDataSource release];
  [self->projectPath      release];
  [super dealloc];
}

/* folder operations */

- (BOOL)isProjectRootFolder {
  id tmp;

  if ((tmp = [self container]) == nil)
    return YES;
  
  if (![tmp isKindOfClass:[self class]])
    return YES;
  
  return NO;
}

- (EOGlobalID *)projectGlobalIDInContext:(id)_ctx {
  id tmp;
  
  if ((tmp = [self container]) == nil)
    return nil;
  if (tmp == self) /* loop?! */
    return nil;
  
  return [tmp projectGlobalIDInContext:_ctx];
}

- (id)fileManagerInContext:(id)_ctx {
  id tmp;
  
  if ((tmp = [self container]) == nil)
    return nil;
  if (tmp == self) /* loop?! */
    return nil;
  
  return [tmp fileManagerInContext:_ctx];
}
- (id)fileManager {
  return [self fileManagerInContext:nil];
}

- (EODataSource *)folderDataSourceInContext:(id)_ctx {
  NSString *p;
  
  if (self->folderDataSource)
    return self->folderDataSource;

  p = [self storagePath];
  if (debugOn) [self debugWithFormat:@"get datasource for path: '%@'", p];
  
  self->folderDataSource =
    [[[self fileManagerInContext:_ctx] dataSourceAtPath:p] retain];
  
  return self->folderDataSource;
}

- (SxProjectFolder *)projectFolder {
  if ([self isProjectRootFolder])
    return [self container];
  
  return [[self container] projectFolder];
}

- (NSString *)storagePath {
  NSMutableString *ma;
  id folder;
  
  if (self->projectPath != nil)
    return self->projectPath;
  
  if ([self isProjectRootFolder]) {
    self->projectPath = @"/";
    return self->projectPath;
  }
  
  ma = [[NSMutableString alloc] initWithCapacity:256];
  
  for (folder = self; folder != nil && ![folder isProjectRootFolder];
       folder = [folder container]) {
    [ma insertString:@"/" atIndex:0];
    [ma insertString:[folder nameInContainer] atIndex:0];
  }

  [ma insertString:@"/" atIndex:0];
  
  self->projectPath = [ma copy];
  [ma release];
  
  if (debugOn) [self debugWithFormat:@"path: %@", self->projectPath];
  return self->projectPath;
}

/* attributes */

- (NSDictionary *)fileAttributes {
  id fm;
  
  if ((fm = [self fileManager]) == nil)
    return nil;
  
  if (self->attrCache == nil) {
    self->attrCache =
      [[fm fileAttributesAtPath:[self storagePath] traverseLink:NO] copy];
    //[self debugWithFormat:@"ATTRS: %@", self->attrCache];
  }
  return self->attrCache;
}

/* child names */

- (NSArray *)_fetchFoldersOrFiles:(BOOL)_fetchFolders inContext:(id)_ctx {
  NSEnumerator *contents;
  NSMutableArray *ma;
  id       fm;
  NSString *sp, *p;

  fm = [self fileManagerInContext:_ctx];
  sp = [self storagePath];
  
  if ((contents = [[fm directoryContentsAtPath:sp] objectEnumerator]) == nil) {
    [self logWithFormat:@"no dir contents at path: '%@'", sp];
    return nil;
  }
  
  ma = [NSMutableArray arrayWithCapacity:16];
  while ((p = [contents nextObject]) != nil) {
    BOOL isDir;
    
    if (![fm fileExistsAtPath:[sp stringByAppendingString:p] 
	     isDirectory:&isDir])
      continue;
    
    if (!isDir && _fetchFolders) continue;
    if (isDir  && !_fetchFolders) continue;
    [ma addObject:p];
  }
  [ma sortUsingSelector:@selector(compare:)];
  return ma;
}

- (NSArray *)toOneRelationshipKeys {
  /* files: use DS for fetch! */
  [self debugWithFormat:@"to-one keys ..."];
  return [self _fetchFoldersOrFiles:NO inContext:nil];
}
- (NSArray *)toManyRelationshipKeys {
  /* folders: use DS for fetch! */
  return [self _fetchFoldersOrFiles:YES inContext:nil];
}

- (NSEnumerator *)davChildKeysInContext:(id)_ctx {
  /* files+folders */
  id       fm;
  NSString *p;
  NSArray  *contents;

  [self debugWithFormat:@"davChildKeysInContext:"];
  fm = [self fileManagerInContext:_ctx];
  p  = [self storagePath];
  
  contents = [fm directoryContentsAtPath:p];
  [self debugWithFormat:@"  contents: %@", 
          [contents componentsJoinedByString:@","]];
  
  return [contents objectEnumerator];
}

/* child lookup */

- (id)childForNewKey:(NSString *)_key inContext:(id)_ctx {
  /* triggered by SxFolder lookup */
  return nil; // we implement our own mechanism
}
- (Class)recordClassForKey:(NSString *)_key {
  /* triggered by SxFolder lookup */
  return nil; // we implement our own mechanism
}

- (id)folderWithName:(NSString *)_name inContext:(id)_ctx {
  id folder;
  
  folder = [[NGClassFromString(@"SxDocumentFolder") alloc] 
             initWithName:_name inContainer:self];
  return [folder autorelease];
}
- (id)fileWithName:(NSString *)_name inContext:(id)_ctx {
  id file;
  
  file = [[NGClassFromString(@"SxDocument") alloc] 
             initWithName:_name inContainer:self];
  return [file autorelease];
}

- (BOOL)isTmpFileName:(NSString *)_name inContext:(id)_ctx {
  /* 
     We have a separate store for temporary files as created by Word. We
     only do this for database projects.
     
     Files look like (Word 2003):
       ~WRD0000.tmp
     or
       ~$in%20Word%20Document.doc
  */
  if ([_name hasPrefix:@"~"])
    return YES;
  if ([_name hasSuffix:@".tmp"])
    return YES;
  if ([_name hasPrefix:@"._"]) /* this is Apple */
    return YES; // TODO: do they also use directories with the prefix?
  return NO;
}

- (id)lookupTmpName:(NSString *)_name inContext:(id)_ctx {
  /* 
     Note: we do not check whether the file already exists. Because of this
           the davCreateObject method will not be called.
  */
  id file;
  
  [self logWithFormat:@"lookup tmpfile: '%@'", _name];
  file = [[NGClassFromString(@"SxTmpDocument") alloc] 
             initWithName:_name inContainer:self];
  return [file autorelease];
}

- (BOOL)useSeparateTmpFilesWithFileManager:(id)_fm {
  return [_fm isKindOfClass:NGClassFromString(@"SkyProjectFileManager")];
}

- (id)lookupStoredName:(NSString *)_name inContext:(id)_ctx {
  id       fm;
  NSString *p;
  BOOL     isDir;
  
  [self debugWithFormat:@"lookup stored '%@'", _name];
  if ((fm = [self fileManagerInContext:_ctx]) == nil) {
    [self debugWithFormat:@"  missing filemanager ..."];
    return nil;
  }
  
  if ([self useSeparateTmpFilesWithFileManager:fm]) {
    if ([self isTmpFileName:_name inContext:_ctx])
      return [self lookupTmpName:_name inContext:_ctx];
  }
  
  if (![(p = [self storagePath]) isNotEmpty]) {
    [self debugWithFormat:@"  missing storage path ..."];
    return nil;
  }
  
  p = [p stringByAppendingString:_name];
  if (![fm fileExistsAtPath:p isDirectory:&isDir]) {
    NSException *error;
    
    if ((error = [fm lastException]) != nil)
      return error;
    [self debugWithFormat:@"  file does not exist at '%@'", p];
    return nil;
  }
  
  [self debugWithFormat:@"  found file '%@' (%s)", 
	  p, isDir ? "directory" : "file"];
  return isDir 
    ? [self folderWithName:_name inContext:_ctx]
    : [self fileWithName:_name   inContext:_ctx];
}

- (id)lookupName:(NSString *)_name inContext:(id)_ctx acquire:(BOOL)_flag {
  id tmp;
  
  if (![_name isNotEmpty]) return nil;
  
  /* first check for methods */
  
  if ((tmp = [super lookupName:_name inContext:_ctx acquire:NO]) != nil) {
    if (![tmp isKindOfClass:[NSException class]])
      return tmp;
    if ([tmp httpStatus] != 404 /* Not Found */)
      return tmp; /* object found but had some error? */
  }
  
  /* lookup name as a project file */
  
  if ((tmp = [self lookupStoredName:_name inContext:_ctx]) != nil)
    return tmp;
  
  /* and now with acquisition */
  // TODO: should we disable this or is it required for something?
  
  return [super lookupName:_name inContext:_ctx acquire:_flag];
}

/* error handling */

- (id)internalError:(NSString *)_reason {
  return [NSException exceptionWithHTTPStatus:500 /* server error */
		      reason:_reason];
}

/* permissions */

- (BOOL)isItemCreationAllowed {
  // TODO: check backend permissions
  return YES;
}
- (BOOL)isFolderCreationAllowed {
  // TODO: check backend permissions
  return YES;
}

- (BOOL)isDeletionAllowed {
  id       fm;
  NSString *p;
  
  if ((fm = [self fileManagerInContext:nil]) == nil)
    return NO;
  if ([(p = [self storagePath]) length] == 0)
    return NO;
  
  return [fm isDeletableFileAtPath:p];
}

/* creating collections */

- (NSException *)_getFM:(id *)fm_ path:(NSString **)p_
  cmdctx:(LSCommandContext **)cmdctx_
  inContext:(id)_ctx 
{
  if ((*fm_ = [self fileManagerInContext:_ctx]) == nil)
    return [self internalError:@"could not locate filemanager for project"];
  
  *p_ = [self storagePath];
  if (![*p_ isNotEmpty])
    return [self internalError:@"could not calc project relative path"];

  if ((*cmdctx_ = [self commandContextInContext:_ctx]) == nil)
    return [self internalError:@"missing command context"];
  
  return nil; /* no error */
}

- (NSException *)davCreateCollection:(NSString *)_name inContext:(id)_ctx {
  LSCommandContext *cmdctx;
  NSDictionary *dirattrs;
  NSException  *error;
  id           fm;
  NSString     *p;

  if ([_name length] == 0)
    return [super davCreateCollection:_name inContext:_ctx];

  [self debugWithFormat:@"create subfolder: %@", _name];

  if ((error = [self _getFM:&fm path:&p cmdctx:&cmdctx inContext:_ctx]))
    return error;
  
  if (![self isFolderCreationAllowed]) {
    return [NSException exceptionWithHTTPStatus:403 /* forbidden */
			reason:@"folder creation is not allowed"];
  }
  
  dirattrs = nil;
  p  = [p stringByAppendingString:_name];
  if (![fm createDirectoryAtPath:p attributes:dirattrs]) {
    if ([fm respondsToSelector:@selector(lastException)])
      error = [fm lastException];
    if (error)
      return error;
    return [self internalError:@"folder creation failed, reason unknown"];
  }

  if ([cmdctx isTransactionInProgress]) {
    if (![cmdctx commit])
      return [self internalError:@"could not commit transaction!"];
  }
  
  [self debugWithFormat:@"successfully created folder %@", _name];
  return nil; /* nil means OK */
}

- (id)PUTAction:(id)_ctx {
  LSCommandContext *cmdctx;
  NSException *error;
  NSData   *data;
  unsigned len;
  id       fm;
  NSString *p, *fname;
  
  fname = [_ctx pathInfo];
  if ([fname hasPrefix:@"._"]) {
    /* faking a successful creation seems to be more "Finder friendly" */
    // TODO: we could save the rsrcfork in a WebDAV property
#if 1
    return [NSNumber numberWithInt:201 /* Created */];
#else
    return [NSException exceptionWithHTTPStatus:404 /* not found */
			reason:@"rejecting creation of resourcefork file"];
#endif
  }
  
  [self debugWithFormat:@"put new file: %@ ...", [_ctx pathInfo]];
  
  if ((error = [self _getFM:&fm path:&p cmdctx:&cmdctx inContext:_ctx]))
    return error;
  
  if ([[fname pathExtension] length] == 0) {
    // TODO: detect path extension based on content-type!
    NSString *ext = @"txt";
    fname = [fname stringByAppendingPathExtension:ext];
  }
  p = [p stringByAppendingString:fname];
  
  if (![self isItemCreationAllowed]) {
    return [NSException exceptionWithHTTPStatus:403 /* forbidden */
			reason:@"file creation is not allowed"];
  }
  
  if ((data = [[(WOContext *)_ctx request] content]) == nil) {
    static NSData *emptyData = nil;
    if (emptyData == nil) emptyData = [[NSData alloc] init];
    data = (id)emptyData;
  }
  len = [data length];
  
  // TODO: process some DAV attributes as FS attributes
  if (![fm createFileAtPath:p contents:data attributes:nil]) {
    [self debugWithFormat:@"could not write %i bytes to %@ (fm=%@)", 
	    len, p, fm];
    
    if ([fm respondsToSelector:@selector(lastException)])
      error = [fm lastException];
    if (error)
      return error;
    return [self internalError:@"file writing failed, reason unknown"];
  }
  
  if ([cmdctx isTransactionInProgress]) {
    if (![cmdctx commit])
      return [self internalError:@"could not commit transaction!"];
  }
  
  return [NSNumber numberWithInt:201 /* Created */];
}

- (id)DELETEAction:(id)_ctx {
  LSCommandContext *cmdctx;
  NSException *error;
  id          fm;
  NSString    *p;

  if ((error = [self _getFM:&fm path:&p cmdctx:&cmdctx inContext:_ctx]))
    return error;
  
  if (![self isDeletionAllowed]) {
    return [NSException exceptionWithHTTPStatus:403 /* forbidden */
			reason:@"file deletion is not allowed"];
  }
  
  /* 
     Note: using 'self' as the handler implies that you need to implement
           certain methods!
  */
  if (![fm removeFileAtPath:p handler:nil]) {
    if ([fm respondsToSelector:@selector(lastException)])
      error = [fm lastException];
    if (error)
      return error;
    return [self internalError:@"file deleting failed, reason unknown"];
  }
  
  if ([cmdctx isTransactionInProgress]) {
    if (![cmdctx commit])
      return [self internalError:@"could not commit transaction!"];
  }
  
  return [NSNumber numberWithBool:YES];
}

- (NSException *)davMoveToTargetObject:(id)_target newName:(NSString *)_name
  inContext:(id)_ctx
{
  return [[self projectFolder] moveObject:self toTarget:_target
			       newName:_name inContext:_ctx];
}
- (NSException *)davCopyToTargetObject:(id)_target newName:(NSString *)_name
  inContext:(id)_ctx
{
  return [[self projectFolder] copyObject:self toTarget:_target
			       newName:_name inContext:_ctx];
}

/* common DAV attributes */

- (NSString *)davDisplayName {
  /* TODO: use title if available? */
  return [self nameInContainer];
}
- (BOOL)davIsCollection {
  return YES;
}
- (BOOL)davIsFolder {
  /* this can be overridden by compound documents (aka filewrappers) */
  return [self davIsCollection];
}
- (BOOL)davHasSubFolders {
  return YES;
}

- (id)davContentLength {
  return [[self fileAttributes] objectForKey:NSFileSize];
}
- (NSDate *)davLastModified {
  return [[self fileAttributes] objectForKey:NSFileModificationDate];
}

/* Blogger support */

- (NSString *)bloggerPostEntryWithTitle:(NSString *)_title
  description:(NSString *)_content creationDate:(NSCalendarDate *)_date
  inContext:(id)_ctx
{
  id<SkyDocumentFileManager> fm; // TODO: need a protocol here
  NSString     *p, *fn;
  SkyDocument  *doc;
  
  if ((fm = [self fileManagerInContext:_ctx]) == nil)
    return nil;
  
  // TODO: improve filename creation procedure ...
  fn = [NSString stringWithFormat:@"post%d.html", time(NULL)];
  p  = [self storagePath];
  if (![p hasSuffix:@"/"]) p = [p stringByAppendingString:@"/"];
  p  = [p stringByAppendingString:fn];
  
  /* first write content */

  if (![fm writeContents:[_content dataUsingEncoding:NSISOLatin1StringEncoding]
	   atPath:p]) {
    [self errorWithFormat:@"could not write to path: %@", p];
    return nil;
  }
  
  /* then set attrs */
  
  if ((doc = [fm documentAtPath:p]) == nil) {
    [self errorWithFormat:@"did not find new document: %@", p];
    return nil;
  }
  
  [doc takeValue:_title forKey:@"NSFileSubject"];
  if (![doc save]) {
    [self errorWithFormat:@"could not save document: %@", p];
    return nil;
  }

  /* commit */
  
  if ([[self commandContextInContext:_ctx] isTransactionInProgress]) {
    if (![[self commandContextInContext:_ctx] commit]) {
      [self errorWithFormat:@"could not commit transaction!"];
      [[self commandContextInContext:_ctx] rollback];
      return nil;
    }
  }
  
  /* 
     The current convention for the post IDs is Blog/Post, because post edit
     operations only transfer the post ID and _not_ the blog (so we need to
     embed the blog name).
     At least for DB projects this would not be necessary, since they can
     locate documents by DB primary key.
  */
  p = [[self nameInContainer] stringByAppendingString:@"/"];
  return [p stringByAppendingString:fn];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

- (NSString *)description {
  NSMutableString *ms = [NSMutableString stringWithCapacity:128];
  
  [ms appendFormat:@"<%p[%@]:", self, NSStringFromClass([self class])];
  
  [ms appendFormat:@" path='%@'", [self storagePath]];
  [ms appendFormat:@" name='%@'", [self nameInContainer]];
  if ([self isProjectRootFolder])
    [ms appendString:@" root"];
  
  [ms appendString:@">"];
  return ms;
}

@end /* SxDocumentFolder */
