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

#include "NGFileManagerCopyTool.h"
#include <OGoDocuments/SkyDocumentFileManager.h>
#include <OGoProject/SkyProject.h>
#include <LSFoundation/SkyObjectPropertyManager.h>
#include <EOControl/EODataSource.h>
#include "common.h"
#include "SkyContentHandler.h"

#if LIB_FOUNDATION_LIBRARY
extern NSDictionary *NSParseDictionaryFromData(NSData *);
#else
#  include <NGExtensions/NGPropertyListParser.h>
#endif

@interface NSObject(PreventWarnings)
- (NSDictionary *)attributes;
- (NSArray *)documentAtPath:(NSString *)_path;
- (id)context;
- (BOOL)createFiles:(NSDictionary *)_f atPath:(NSString *)_p;
@end /* PreventWarnings */

@implementation NGFileManagerCopyTool

- (id)init {
  if ((self = [super init])) {
    self->recursive = YES;
    self->overwrite = YES;
  }
  return self;
}

- (void)dealloc {
  [self->targetFileManager release];
  [self->excludeQualifier  release];
  [self->includeQualifier  release];
  [super dealloc];
}

/* accessors */

- (void)setSourceFileManager:(id<NSObject,NGFileManager>)_fm {
  [self setFileManager:_fm]; // -setFileManager is an inherited method
}
- (id<NSObject,NGFileManager>)sourceFileManager {
  return [self fileManager];
}

- (void)setTargetFileManager:(id<NSObject,NGFileManager>)_fm {
  ASSIGN(self->targetFileManager, _fm);
}
- (id<NSObject,NGFileManager>)targetFileManager {
  return self->targetFileManager;
}

- (void)setRecursive:(BOOL)_rec {
  self->recursive = _rec;
}
- (BOOL)recursive {
  return self->recursive;
}

- (void)setSaveAttributes:(BOOL)_save {
  self->saveAttributes = _save;
}
- (BOOL)saveAttributes {
  return self->saveAttributes;
}

- (void)setRestoreAttributes:(BOOL)_restore {
  self->restoreAttributes = _restore;
}
- (BOOL)restoreAttributes {
  return self->restoreAttributes;
}

- (void)setOverwrite:(BOOL)_overwrite {
  self->overwrite = _overwrite;
}
- (BOOL)overwrite {
  return self->overwrite;
}

- (void)setExcludeQualifier:(EOQualifier *)_qual {
  ASSIGN(self->excludeQualifier, _qual);
}
- (EOQualifier *)excludeQualifier {
  return self->excludeQualifier;
}

- (void)setIncludeQualifier:(EOQualifier *)_qual {
  ASSIGN(self->includeQualifier, _qual);
}
- (EOQualifier *)includeQualifier {
  return self->includeQualifier;
}

- (void)setVerbose:(BOOL)_verbose {
  if (_verbose)
    [self logWithFormat:@"verbose logging enabled ..."];
  else if (self->verbose)
    [self logWithFormat:@"verbose logging disabled ..."];
  self->verbose = _verbose;
}
- (BOOL)verbose {
  return self->verbose;
}

/* operations */

- (NSException *)copyPath:(NSString *)_srcPath
  toPath:(NSString *)_toPath
  handler:(id)_handler
{
  NGFileManagerCopyToolHandler *copyHandler = nil;

  if (handler == nil) {
    copyHandler = [[[NGFileManagerCopyToolHandler alloc] init] autorelease];
    [copyHandler setTargetFileManager:[self targetFileManager]];
    [copyHandler setTargetDirectory:  _toPath];
    [copyHandler setRecursive:        [self recursive]];
    [copyHandler setSaveAttributes:   [self saveAttributes]];
    [copyHandler setRestoreAttributes:[self restoreAttributes]];
    [copyHandler setOverwrite:        [self overwrite]];
    [copyHandler setExcludeQualifier: [self excludeQualifier]];
    [copyHandler setIncludeQualifier: [self includeQualifier]];
    [copyHandler setVerbose:          [self verbose]];
  }
  else {
    copyHandler = _handler;
  }

  if ([[_srcPath lastPathComponent] isEqualToString:@"*"]) {
    NSEnumerator *enumer   = nil;
    NSString     *srcPath2 = nil; // part before asterisk (*)
    NSString     *srcPath3 = nil; // that, what is represented by asterisk

    srcPath2 = [_srcPath stringByDeletingLastPathComponent];
    if ([srcPath2 length] == 0) {
      enumer = [[[self sourceFileManager] directoryContentsAtPath:@"."]
                       objectEnumerator];
      srcPath2 = nil;
    }
    else {
      enumer = [[[self sourceFileManager] directoryContentsAtPath:srcPath2]
                       objectEnumerator];
    }

    while ((srcPath3 = [enumer nextObject])) {
      NSString *srcPath4 = nil; // srcPath2 + srcPath3

      if (srcPath2)
        srcPath4 = [srcPath2 stringByAppendingPathComponent:srcPath3];
      else
        srcPath4 = srcPath3;

      [self processPath:srcPath4 handler:copyHandler];
    }
  } // if _srcPath has prefix "*"
  else {
    [self processPath:_srcPath handler:copyHandler];
  }

  return nil;
}

@end /* NGFileManagerCopyTool */

@implementation NGFileManagerCopyToolHandler

- (id)init {
  if ((self = [super init])) {
    self->fileAttributes = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)dealloc {
  [self->fileAttributes    release];
  [self->targetFileManager release];
  [self->targetDirectory   release];
  [self->excludeQualifier  release];
  [self->includeQualifier  release];
  [super dealloc];
}

/* accessors */

- (void)setTargetFileManager:(id<NSObject,NGFileManager>)_fm {
  ASSIGN(self->targetFileManager, _fm);
}
- (id<NSObject,NGFileManager>)targetFileManager {
  return self->targetFileManager;
}

- (void)setTargetDirectory:(NSString *)_target {
  ASSIGN(self->targetDirectory, _target);
}
- (NSString *)targetDirectory {
  return self->targetDirectory;
}

- (void)setRecursive:(BOOL)_rec {
  self->recursive = _rec;
}
- (BOOL)recursive {
  return self->recursive;
}

- (void)setSaveAttributes:(BOOL)_save {
  self->saveAttributes = _save;
}
- (BOOL)saveAttributes {
  return self->saveAttributes;
}

- (void)setRestoreAttributes:(BOOL)_restore {
  self->restoreAttributes = _restore;
}
- (BOOL)restoreAttributes {
  return self->restoreAttributes;
}

- (void)setOverwrite:(BOOL)_overwrite {
  self->overwrite = _overwrite;
}
- (BOOL)overwrite {
  return self->overwrite;
}

- (void)setExcludeQualifier:(EOQualifier *)_qual {
  ASSIGN(self->excludeQualifier, _qual);
}
- (EOQualifier *)excludeQualifier {
  return self->excludeQualifier;
}

- (void)setIncludeQualifier:(EOQualifier *)_qual {
  ASSIGN(self->includeQualifier, _qual);
}
- (EOQualifier *)includeQualifier {
  return self->includeQualifier;
}

- (void)setVerbose:(BOOL)_verbose {
  if (_verbose)
    [self logWithFormat:@"verbose logging enabled ..."];
  else if (self->verbose)
    [self logWithFormat:@"verbose logging disabled ..."];
  self->verbose = _verbose;
}
- (BOOL)verbose {
  return self->verbose;
}

/* operations */

- (NSException *)tool:(NGFileManagerProcessingTool *)_tool
  processDirectoryPath:(NSString *)_directoryPath
{
  // TODO: split up this huge method!
  NSAutoreleasePool *pool;
  NSString          *lastPathComponent = nil;
  NSString          *newTarget         = nil;
  NSString          *oldTarget         = nil;
  NSString          *newDir            = nil;
  NSArray           *files;
  BOOL              isDir;
  id                tfm, sfm;
  EODataSource      *ds;
  EOQualifier<EOQualifierEvaluation> *include;
  EOQualifier<EOQualifierEvaluation> *exclude;

  if (self->verbose)
    [self logWithFormat:@"process dir: %@", _directoryPath];
  
  include = (EOQualifier<EOQualifierEvaluation>*)[self includeQualifier];
  exclude = (EOQualifier<EOQualifierEvaluation>*)[self excludeQualifier];

  if (include != nil || exclude != nil) {
    NSDictionary *a;
    
    a = [self fileAttributesAtPath:_directoryPath tool:_tool];
    
    if ((exclude != nil) && [exclude evaluateWithObject:a])
      return nil;
    if ((include != nil) && [include evaluateWithObject:a] == NO)
      return nil;
  }
  
  sfm = [_tool fileManager];
  tfm = [self targetFileManager];

  lastPathComponent = [_directoryPath lastPathComponent];
  newDir =
    [[self targetDirectory] stringByAppendingPathComponent:lastPathComponent];

  if (![tfm fileExistsAtPath:newDir isDirectory:&isDir] || !isDir) {
    if ([tfm createDirectoryAtPath:newDir attributes:nil] == NO) {
      if ([self verbose]) {
        fprintf(stderr, "can not create directory %s\n", [newDir cString]);
      }
      return [NSException exceptionWithName:@"directoryNotCreatable"
                          reason:@"can not create directory"
                          userInfo:nil];
    }

    if ([tfm respondsToSelector:@selector(context)]) {
      id ctx;
      
      ctx = [(id)tfm context];
      if ([ctx respondsToSelector:@selector(commit)]) {
        if (![ctx commit]) {
          NSLog(@"%s: couldn't commit context %@ !!!", __PRETTY_FUNCTION__,
                ctx);
        }
      }
    }
    if ([self verbose]) {
      printf("copy %s to %s\n", [_directoryPath cString], [newDir cString]);
    }
  }
  
  if ([self recursive] == NO) return nil;
  
  pool = [[NSAutoreleasePool alloc] init];
  
  ds = ([sfm supportsFolderDataSourceAtPath:_directoryPath])
    ? [(id<NGFileManagerDataSources>)sfm dataSourceAtPath:_directoryPath]
    : (EODataSource *)nil;
  
  oldTarget = [self targetDirectory];
  newTarget = [[self targetDirectory]
                     stringByAppendingPathComponent:lastPathComponent];
  [self setTargetDirectory:newTarget];

  // TODO: split up
  if (ds) {
    NSMutableDictionary *pathToAttributes = nil;
    NSArray             *docs             = nil;
    NSEnumerator        *enumer2          = nil;
    id                  doc               = nil;

    docs             = [ds fetchObjects];
    pathToAttributes = [[NSMutableDictionary alloc] init];

    if ([docs count] > 0) {
      enumer2 = [docs objectEnumerator];
      while ((doc = [enumer2 nextObject])) {
        NSString            *filename = nil;
        NSString            *filepath = nil;
        NSMutableDictionary *attr     = nil;
        NSString            *subject  = nil;
        id                  mimeType  = nil;
        NSMutableDictionary *allAttr = nil;

        if ([[doc valueForKey:@"NSFileType"]
                  isEqualToString:@"NSFileTypeUnknown"])
          continue;
        
        filename = [doc valueForKey:@"NSFileName"];
        filepath = [doc valueForKey:@"NSFilePath"];
        attr     = [[NSMutableDictionary alloc] init];
        
        if ([doc isKindOfClass:[NSDictionary class]]) {
	  NSDictionary *d = doc;
	  
          subject  = [[d objectForKey:@"NSFileSubject"]  stringValue];
          mimeType = [[d objectForKey:@"NSFileMimeType"] stringValue];
          
          if ([subject length] > 0) 
            [attr setObject:subject forKey:@"NSFileSubject"];
          
          if ([mimeType length] > 0)
            [attr setObject:mimeType forKey:@"NSFileMimeType"];
          
          allAttr = doc;
        }
        else {
          subject  = [[doc valueForKey:@"NSFileSubject"]  stringValue];
          mimeType = [[doc valueForKey:@"NSFileMimeType"] stringValue];
          
          if ([subject length] > 0)
            [attr setObject:subject forKey:@"NSFileSubject"];
          if ([mimeType length] > 0) 
            [attr setObject:mimeType forKey:@"NSFileMimeType"];

          if ([doc respondsToSelector:@selector(attributes)]) {
            NSDictionary *attrs;

            attrs = [(NSObject *)doc attributes];
            
            [attr addEntriesFromDictionary:attrs];
            allAttr = [NSMutableDictionary dictionaryWithDictionary:attrs];
            
            if ([doc respondsToSelector:@selector(fileAttributes)])
              [allAttr addEntriesFromDictionary:[doc fileAttributes]];
          }
        }
        
        [self->fileAttributes setObject:allAttr forKey:filepath];
        if ([self saveAttributes]) {
          if ([attr count] > 0) {
            [pathToAttributes setObject:attr forKey:filename];
          }
        }
        RELEASE(attr);
      }
      if ([pathToAttributes count] > 0) {
        [tfm createFileAtPath:
               [newDir stringByAppendingPathComponent:@".attributes.plist"]
             contents:[self dataFromDictionary:pathToAttributes]
             attributes:nil];
      }
      RELEASE(pathToAttributes);
    }
    files = [docs valueForKey:@"NSFileName"];
  }
  else {
    files = [sfm directoryContentsAtPath:_directoryPath];
  }

  [_tool processFileNames:files atPath:_directoryPath handler:self];
  
  [self setTargetDirectory:oldTarget];

  [pool release];
  
  [self handleSaveRestoreAttributesForPath:_directoryPath newPath:newDir
        tool:_tool];
  return nil;
}

- (NSException *)tool:(NGFileManagerProcessingTool *)_tool
  processFilePath:(NSString *)_filePath
{
  // TODO: split up method
  NSString *lastPathComponent = nil;
  NSString *newFile           = nil;
  NSData   *contents          = nil;
  BOOL     isDir;
  id       tfm;
  EOQualifier<EOQualifierEvaluation> *include;
  EOQualifier<EOQualifierEvaluation> *exclude;
  
  if (self->verbose)
    [self logWithFormat:@"process file: %@", _filePath];
  
  include = (EOQualifier<EOQualifierEvaluation>*)[self includeQualifier];
  exclude = (EOQualifier<EOQualifierEvaluation>*)[self excludeQualifier];

  if (include != nil || exclude != nil) {
    NSDictionary *a;
    
    a = [self fileAttributesAtPath:_filePath tool:_tool];
    if ((exclude != nil) && [exclude evaluateWithObject:a])
      return nil;
    if ((include != nil) && [include evaluateWithObject:a] == NO)
      return nil;
  }

  lastPathComponent = [_filePath lastPathComponent];
  tfm = [self targetFileManager];

  // do not copy attributes file
  if ([lastPathComponent hasPrefix:@".attributes."] &&
      [lastPathComponent hasSuffix:@".plist"])
    return nil;

  newFile  = [[self targetDirectory]
                    stringByAppendingPathComponent:lastPathComponent];
  contents = [[_tool fileManager] contentsAtPath:_filePath];

  if ([tfm fileExistsAtPath:newFile isDirectory:&isDir]) {
    if (isDir) {
      if ([self verbose]) {
        fprintf(stderr, "file %s already exists and is a directory\n",
                [newFile cString]);
      }
      return [NSException exceptionWithName:@"fileIsADirectory"
                          reason:@"file already exists and is a directory"
                          userInfo:nil];
    }

    if ([self overwrite] == NO) {
      return nil;
    }
    else {
      if ([tfm isWritableFileAtPath:newFile]) {
        if (![tfm writeContents:contents atPath:newFile]) {
          if ([self verbose]) {
            fprintf(stderr, "can not write to file %s\n", [newFile cString]);
          }
          return [NSException exceptionWithName:@"writeToFileFailed"
                              reason:@"can not write to file" userInfo:nil];
        }
        if ([tfm respondsToSelector:@selector(context)]) {
          id ctx;
          
          ctx = [tfm context];
          if ([ctx respondsToSelector:@selector(commit)])
            [ctx commit];
        }
        if ([self verbose]) {
          printf("copy %s to %s\n", [_filePath cString], [newFile cString]);
        }
      }
      else {
        if ([self verbose]) {
          fprintf(stderr, "file '%s' is not writable\n", [newFile cString]);
        }
        return [NSException exceptionWithName:@"fileNotWritable"
                            reason:@"file is not writable" userInfo:nil];
      }
    }
  }
  else {
    if (![[newFile pathExtension] length]) {
      NSLog(@"%s: missing path extension for %@ append .???",
            __PRETTY_FUNCTION__, newFile);
      newFile = [newFile stringByAppendingPathExtension:@"???"];
    }
    if (![tfm createFileAtPath:newFile contents:contents attributes:nil]) {
      if ([self verbose]) {
        fprintf(stderr, "can not create file '%s'\n", [newFile cString]);
      }
      return [NSException exceptionWithName:@"fileNotCreatable"
                          reason:@"can not create file" userInfo:nil];
    }
    if ([tfm respondsToSelector:@selector(context)]) {
      id ctx;

      ctx = [tfm context];
      if ([ctx respondsToSelector:@selector(commit)]) {
        if (![ctx commit]) {
          NSLog(@"%s: failed to commit ctx %@ !!!",
                __PRETTY_FUNCTION__, ctx);
        }
      }
    }
    if ([self verbose]) {
      printf("copy %s to %s\n", [_filePath cString], [newFile cString]);
    }
  }

  [self handleSaveRestoreAttributesForPath:_filePath newPath:newFile
        tool:_tool];
  return nil;
}

- (NSException *)tool:(NGFileManagerProcessingTool *)_tool
  processFiles:(NSArray *)_files atPath:(NSString *)_path
{
  // TODO: split method
  NSMutableDictionary *mdict;
  NSEnumerator        *enumerator;
  NSString            *file;

  if (self->verbose)
    [self logWithFormat:@"process files (%i) at %@", [_files count], _path];
  
  /* all file attrs/content..  in dir und speichern */
  mdict = [NSMutableDictionary dictionaryWithCapacity:[_files count]];
  enumerator = [_files objectEnumerator];

  while ((file = [enumerator nextObject])) {
    NSString *lastPathComponent = nil;
    NSString *newFile           = nil;
    BOOL     isDir;
    id<NGFileManager,NSObject> tfm;
    EOQualifier<EOQualifierEvaluation> *include;
    EOQualifier<EOQualifierEvaluation> *exclude;
    NSString *_filePath;

    _filePath = [_path stringByAppendingPathComponent:file];
    
    if (self->verbose)
      [self logWithFormat:@"  process: %@", _filePath];
    
    include = (EOQualifier<EOQualifierEvaluation>*)[self includeQualifier];
    exclude = (EOQualifier<EOQualifierEvaluation>*)[self excludeQualifier];

    if (include != nil || exclude != nil) {
      NSDictionary *a;
    
      a = [self fileAttributesAtPath:_filePath tool:_tool];
      if ((exclude != nil) && [exclude evaluateWithObject:a])
        continue;
      if ((include != nil) && [include evaluateWithObject:a] == NO)
        continue;
    }
    lastPathComponent = [_filePath lastPathComponent];
    tfm = [self targetFileManager];

    // do not copy attributes file
    if ([lastPathComponent hasPrefix:@".attributes."] &&
        [lastPathComponent hasSuffix:@".plist"])
      continue;

    newFile  = [[self targetDirectory]
                      stringByAppendingPathComponent:lastPathComponent];

    if ([tfm fileExistsAtPath:newFile isDirectory:&isDir]) {
      if (isDir) {
        if ([self verbose]) {
          fprintf(stderr, "file %s already exists and is a directory\n",
                  [newFile cString]);
        }
        continue;
      }
      if ([self overwrite] == NO) {
        continue;
      }
    }
    {
      // TODO: I guess 'd' should be some higher level object?
      NSDictionary *d;
      id fm;
	
      fm = [_tool fileManager];
      if ([fm respondsToSelector:@selector(supportsBlobHandler)] &&
	  [fm supportsBlobHandler]) {
	id data = [fm blobHandlerAtPath:_filePath];
	d = [NSDictionary dictionaryWithObject:data forKey:@"contentHandler"];
      }
      else {
	NSData *data = [fm contentsAtPath:_filePath];
	d = [NSDictionary dictionaryWithObject:data forKey:@"contents"];
      }
      [mdict setObject:d forKey:file];
    }
  }
  {
    id   tfm;
    BOOL ok;

    ok  = NO;
    tfm = [self targetFileManager];

    if ([tfm respondsToSelector:@selector(createFiles:atPath:)]) {
      ok = [tfm createFiles:mdict atPath:[self targetDirectory]];
    }
    else {
      NSEnumerator *enumerator;
      id           str;
      NSString     *tPath;
      ok = YES;

      tPath = [self targetDirectory];
      enumerator = [mdict keyEnumerator];
      while ((str = [enumerator nextObject])) {
        id handler, content;

        if (![str length])
          continue;

        handler = [mdict objectForKey:@"contentHandler"];

        if (handler) {
          content = [handler blob];
        }
        else {
          content = [mdict objectForKey:@"contents"];
        }
        if (!(ok = [tfm createFileAtPath:[tPath stringByAppendingPathComponent:str]
                        contents:content attributes:nil]))
          break;
      }
      if (!ok) {
        NSLog(@"%s: couldn`t create file <%@>", __PRETTY_FUNCTION__, str);
        return nil;
      }
    }
    {
      NSEnumerator *enumerator;
      id           str;

      enumerator = [mdict keyEnumerator];
      while ((str = [enumerator nextObject])) {
        [self handleSaveRestoreAttributesForPath:
              [_path stringByAppendingPathComponent:str]
              newPath:[[self targetDirectory] stringByAppendingPathComponent:str]
              tool:_tool];
      }
    }
  }
  return nil;
}

 
- (NSException *)tool:(NGFileManagerProcessingTool *)_tool
  processLinkPath:(NSString *)_linkPath
{
  NSString *newLink           = nil;
  NSString *content           = nil;
  NSString *lastPathComponent = nil;
  BOOL     isDir;
  id       tfm;
  EOQualifier<EOQualifierEvaluation> *include;
  EOQualifier<EOQualifierEvaluation> *exclude;

  if (self->verbose)
    [self logWithFormat:@"process link: %@", _linkPath];

  include = (EOQualifier<EOQualifierEvaluation>*)[self includeQualifier];
  exclude = (EOQualifier<EOQualifierEvaluation>*)[self excludeQualifier];

  if (include != nil || exclude != nil) {
    NSDictionary *a = [self fileAttributesAtPath:_linkPath tool:_tool];

    if (exclude != nil && [exclude evaluateWithObject:a])
      return nil;
    if (include != nil && [include evaluateWithObject:a] == NO)
      return nil;
  }

  lastPathComponent = [_linkPath lastPathComponent];
  tfm = [self targetFileManager];

  // do not copy attributes file
  if ([lastPathComponent hasPrefix:@".attributes."] &&
      [lastPathComponent hasSuffix:@".plist"])
    return nil;

  newLink = [[self targetDirectory] stringByAppendingPathComponent:
                                    lastPathComponent];

  content = [[_tool fileManager] pathContentOfSymbolicLinkAtPath:_linkPath];

  if ([tfm fileExistsAtPath:newLink isDirectory:&isDir]) {
    if (isDir) {
      if ([self verbose]) {
        fprintf(stderr, "%s already exists and is a directory \n",
                [newLink cString]);
      }
      return [NSException exceptionWithName:@"fileIsADirectory"
                          reason:@"file already exists and is a directory"
                          userInfo:nil];
    }

    if ([self overwrite] == NO) {
      return nil;
    }
    else {
      if (![tfm removeFileAtPath:newLink handler:nil]) {
        if ([self verbose]) {
          fprintf(stderr, "%s already exists and can not be deleted\n",
                  [newLink cString]);
        }
        return [NSException exceptionWithName:@"linkNotDeletable"
                            reason:@"can not delete link" userInfo:nil];
      }
    }
  }

  if ([tfm createSymbolicLinkAtPath:content pathContent:newLink] == NO) {
    if ([self verbose]) {
      fprintf(stderr, "can not create symlink %s\n", [newLink cString]);
    }
    return [NSException exceptionWithName:@"notLinkable"
                        reason:@"can not create symlink" userInfo:nil];
  }

  if ([tfm respondsToSelector:@selector(context)]) {
    id ctx;

    ctx = [tfm context];
    if ([ctx respondsToSelector:@selector(commit)]) {
      if (![ctx commit]) {
        NSLog(@"%s: failed to commit ctx %@", __PRETTY_FUNCTION__, ctx);
      }
    }
  }
  if ([self verbose]) {
    printf("copy %s to %s\n", [_linkPath cString], [newLink cString]);
  }
  
  [self handleSaveRestoreAttributesForPath:_linkPath newPath:newLink
        tool:_tool];
  return nil;
}

/* misc */

- (NSException *)handleSaveRestoreAttributesForPath:(NSString *)_path
  newPath:(NSString *)_newPath
  tool:(NGFileManagerProcessingTool *)_tool
{
  id           tfm;
  id           toolFm;
  NSData       *attributesData = nil;
  NSException  *result         = nil;
  NSString     *plpc           = nil;
  NSString     *filepath       = nil;

  if ([_path length] == 0)
    return nil;

  plpc = [_path lastPathComponent];

  tfm    = [self targetFileManager];
  toolFm = [_tool fileManager];

  filepath = [[toolFm currentDirectoryPath]
                      stringByAppendingPathComponent:_path];
  
  if ([self saveAttributes]) {
    if ([[self->fileAttributes allKeys] containsObject:filepath]) {
      NSString            *attributesFile = nil;
      NSMutableDictionary *attributes     = nil;
      NSString            *subject        = nil;
      NSDictionary        *fileAttr       = nil;
      id                  mimeType        = nil;

      attributesFile =
        [[self targetDirectory] stringByAppendingPathComponent:
                                [NSString stringWithFormat:
                                          @".attributes.%@.plist",
                                          [_path lastPathComponent]]];

      attributes  = [NSMutableDictionary dictionaryWithCapacity:8];
      fileAttr    = [toolFm fileAttributesAtPath:_path traverseLink:NO];
      subject     = [fileAttr objectForKey:@"NSFileSubject"];
      mimeType    = [fileAttr objectForKey:@"NSFileMimeType"];
      if ((subject)) {
        [attributes setObject:subject forKey:@"NSFileSubject"];
      }
      if ((mimeType)) {
        [attributes setObject:mimeType forKey:@"NSFileMimeType"];
      }

      if ([toolFm supportsFeature:NGFileManagerFeature_Documents
                  atPath:_path]) {
        id doc;
        
        doc = [(id<SkyDocumentFileManager>)toolFm documentAtPath:_path];
        
        [attributes addEntriesFromDictionary:[(NSObject *)doc attributes]];
      }
      attributesData = [self dataFromDictionary:attributes];
      [tfm createFileAtPath:attributesFile contents:attributesData
           attributes:nil];
    }
  }

  if ([self restoreAttributes]) {
    NSString     *attributesFile  = nil;
    NSDictionary *attributes      = nil;

    attributesFile = 
      [[_path stringByDeletingLastPathComponent]
                 stringByAppendingPathComponent:
                 [NSString stringWithFormat:@".attributes.%@.plist",
                           [_path lastPathComponent]]];
    attributesData = [[_tool fileManager] contentsAtPath:attributesFile];

    if ([attributesData length] > 0) {
      attributes = [self dictionaryFromData:attributesData];
    }
    else {
      NSString *file2;
      NSData   *data2;
      NSDictionary *dict2;

      file2 = [[_path stringByDeletingLastPathComponent]
                      stringByAppendingPathComponent:@".attributes.plist"];
      data2 = [[_tool fileManager] contentsAtPath:file2];
      dict2 = [self dictionaryFromData:data2];
      attributes = [dict2 objectForKey:[_newPath lastPathComponent]];
    }
    
    if ([attributes count] > 0) {
      static Class SkyProjectFileManagerClass = NULL;

      if (!SkyProjectFileManagerClass)
        SkyProjectFileManagerClass =
          NSClassFromString(@"SkyProjectFileManager");
      
      [tfm changeFileAttributes:attributes atPath:_newPath];

      if (SkyProjectFileManagerClass) {
        if ([tfm isKindOfClass:SkyProjectFileManagerClass]) {
          SkyObjectPropertyManager *pm         = nil;
          EOGlobalID               *gid        = nil;
          NSEnumerator             *enumer     = nil;
          NSMutableDictionary      *properties = nil;
          NSString                 *key        = nil;

          properties = [[NSMutableDictionary alloc] init];
          enumer     = [attributes keyEnumerator];
          while ((key = [enumer nextObject])) {
            NSString *nk;
          
            if ([key isEqualToString:@"NSFileSubject"]) continue;
            if ([key isEqualToString:@"NSFileMimeType"]) continue;

            nk = [NSString stringWithFormat:@"{%@}%@",
                           XMLNS_PROJECT_DOCUMENT, key];
            [properties setObject:[attributes objectForKey:key]
                        forKey:nk];
          }
          if ([properties count] > 0) {
            gid = [tfm globalIDForPath:_newPath];
            pm  = [[tfm context] propertyManager];
            [[pm takeProperties:properties globalID:gid] raise];
          }
          [properties release]; properties = nil;
        }
      }
    }
  }
  return result;
}

- (NSDictionary *)fileAttributesAtPath:(NSString *)_path
  tool:(NGFileManagerProcessingTool *)_tool
{
  id            fm;
  NSString     *p;
  NSDictionary *a;

  fm = [_tool fileManager];
  p = [fm currentDirectoryPath];
  p = [p stringByAppendingPathComponent:_path];
  p = [fm standardizePath:p];
  a = [self->fileAttributes objectForKey:p];
  if (a == nil)
    a = [fm fileAttributesAtPath:p traverseLink:NO];
  return a;
}

- (NSData *)dataFromDictionary:(NSDictionary *)_dict {
  NSMutableDictionary *tmp;
  NSEnumerator        *enumer;
  NSString            *key;
  
  tmp = [[NSMutableDictionary alloc] init];
  
  enumer = [_dict keyEnumerator];
  while ((key = [enumer nextObject])) {
    id value;
    
    value = [_dict objectForKey:key];
    
    if ([value isNotNull])
      [tmp setObject:value forKey:key];
  }
  
  key = [tmp description];
  [tmp release];
  
  return [key dataUsingEncoding:[NSString defaultCStringEncoding]];
}

- (NSException *)handleException:(NSException *)_exception {
  NSLog(@"%s: catched exception %@", __PRETTY_FUNCTION__, _exception);
  return nil;
}

- (NSDictionary *)dictionaryFromData:(NSData *)_data {
  NSDictionary *d;
  
  if ([_data length] == 0)
    return nil;

  NS_DURING {
#if LIB_FOUNDATION_LIBRARY
    d = NSParseDictionaryFromData(_data);
#else
    d = NGParseDictionaryFromData(_data);
#endif
  }
  NS_HANDLER {
    [[self handleException:localException] raise];
    d = nil;
  }
  NS_ENDHANDLER;
  
  return d;
}

@end /* NGFileManagerCopyToolHandler */

@implementation NSObject(NGFileManagerCopyToolHandler)

- (NSException *)tool:(NGFileManagerProcessingTool *)_tool
  processDirectoryPath:(NSString *)_directoryPath
{
  NSEnumerator *enumer = nil;
  NSString     *path   = nil;
  NSException  *exc;

#if DEBUG
  NSLog(@"%s: directory: %@", __PRETTY_FUNCTION__, _directoryPath);
#endif

  enumer = [[[_tool fileManager] directoryContentsAtPath:_directoryPath]
                    objectEnumerator];
#if 1  /* bulk copy */
  {
    NSMutableArray *fileNames;

    fileNames = [NSMutableArray arrayWithCapacity:256];
    while ((path = [enumer nextObject])) {
      [fileNames addObject:path];
    }
    exc = [_tool processFileNames:fileNames atPath:_directoryPath handler:self];
  }
#else
  while ((path = [enumer nextObject])) {
    NSString *path2 = nil;

    path2 = [_directoryPath stringByAppendingPathComponent:path];
    [_tool processPath:path2 handler:self];
  }
#endif
  return exc;
}

- (NSException *)tool:(NGFileManagerProcessingTool *)_tool
  processFilePath:(NSString *)_filePath
{
#if DEBUG
  NSLog(@"%s: file: %@", __PRETTY_FUNCTION__, _filePath);
#endif
  return nil;
}

- (NSException *)tool:(NGFileManagerProcessingTool *)_tool
  processLinkPath:(NSString *)_linkPath
{
#if DEBUG
  NSLog(@"%s: link: %@", __PRETTY_FUNCTION__, _linkPath);
#endif
  return nil;
}

@end /* NSObject(NGFileManagerCopyToolHandler) */

#if 0
@implementation NSData(Pr)
- (NSString *)description {
  return [NSString stringWithFormat:@"<Length: %d>", [self length]];
}
@end
#endif

@implementation NSFileManager(BulkCopy)
- (BOOL)createFiles:(NSDictionary *)_dic atPath:(NSString *)_path {
  NSEnumerator *enumerator;
  id           str;
  BOOL         ok;

  ok         = YES;
  enumerator = [_dic keyEnumerator];
  
  while ((str = [enumerator nextObject])) {
    id           handler, content;
    NSDictionary *d;

    d = [_dic objectForKey:str];
    
    if (![str length])
      continue;

    handler = [d objectForKey:@"contentHandler"];

    if (handler) {
      content = [handler blob];
    }
    else {
      content = [d objectForKey:@"contents"];
    }
    if (!(ok = [self createFileAtPath:[_path stringByAppendingPathComponent:str]
                    contents:content attributes:nil]))
      break;
  }
  if (!ok) {
    NSLog(@"%s: couldn`t create file <%@>", __PRETTY_FUNCTION__, str);
    return NO;
  }
  return YES;
}
@end
