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

#include <OGoFoundation/OGoComponent.h>

@class NSString, NSMutableArray;
@class EOGlobalID, NGFileManager;

@interface SkyP4FolderView : OGoComponent
{
  NGFileManager  *fileManager;
  id             dataSource;
  id             currentFile; // item of table-view
  NSString       *changeDirPath;
  NSMutableArray *selectedFiles;
  NSString       *fsname;
  EOGlobalID     *fsgid;
  
  // error handling
  id       folder;
}

- (id)fileManager;
- (EOGlobalID *)fileSystemNumber;
@end

#include "OGoComponent+FileManagerError.h"
#include "NGUnixTool.h"
#include "common.h"
#include <NGExtensions/NGResourceLocator.h>
#include <NGExtensions/NSString+Ext.h>

@interface NGFileManager(SymbolicLinks)
// this is implemented by SkyFSFileManager and SkyDBFileManager
- (BOOL)isSymbolicLinkEnabledAtPath:(NSString *)_path;
@end

@implementation SkyP4FolderView

static BOOL    debugOn = NO;
static BOOL    hasZip  = NO;
static BOOL    hasEpoz = NO;
static NSArray *accessCheckFlags  = nil;
static NSArray *fileTypeGroupings = nil;

+ (void)initialize {
  static BOOL didInit = NO;
  NGResourceLocator *locator;
  NSFileManager     *fm = [NSFileManager defaultManager];
  NSString          *p;
  id tmp;

  if (didInit) return;
  didInit = YES;
  
  if ((p = [NGUnixTool pathToZipTool]) != nil) {
    hasZip = [fm fileExistsAtPath:p];
    if (!hasZip) NSLog(@"Note: did not find zip tool: '%@'", p);
  }
  else
    NSLog(@"Note: no path to zip tool is configured!");
  
  locator = [NGResourceLocator resourceLocatorForGNUstepPath:
                                 @"WebServerResources"
                               fhsPath:@"share/opengroupware.org-5.5/www"];
  p = [locator lookupFileWithName:@"epoz_script_main.js"];
  hasEpoz = [fm fileExistsAtPath:p];
  if (!hasEpoz) NSLog(@"Note: folder-view did not find Epoz.");
  
  accessCheckFlags = 
    [[NSArray alloc] initWithObjects:@"d", @"i", @"r", @"w", nil];

  tmp = [[EOKeyGrouping alloc] initWithKey:NSFileType];
  fileTypeGroupings = [[NSArray alloc] initWithObjects:&tmp count:1];
  [tmp release]; tmp = nil;
}

- (id)init {
  if ((self = [super init])) {
    self->selectedFiles = [[NSMutableArray alloc] initWithCapacity:64];
  }
  return self;
}
- (void)dealloc {
  [self->fsgid         release];
  [self->fsname        release];
  [self->dataSource    release];
  [self->changeDirPath release];
  [self->selectedFiles release];
  [self->currentFile   release];
  [self->fileManager   release];
  [self->folder        release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  /* teardown */
  [self->currentFile release]; self->currentFile = nil;
  [self->folder      release]; self->folder      = nil;
  
  // TODO: do we need to trigger synchronize manually?
  [[(OGoSession *)[self session] userDefaults] synchronize];
  [super sleep];
}

- (void)setErrorString:(NSString *)_s {
  if ([_s isNotEmpty]) {
    [(id)[[self context] page] setErrorString:_s];
    [self errorWithFormat:@"%@", _s];
  }
}

/* userdefaults + sorting (TODO: should be refactored)  */

- (NSString *)folderIdentifier {
  NSString *key;
  id       *tmp;
  
  key = [[self fileManager] currentDirectoryPath];
  tmp = [(EOKeyGlobalID *)[self fileSystemNumber] keyValues];
  
  key = [[tmp[0] stringValue] stringByAppendingString:key];
  return key;
}

- (void)setIsDescending:(BOOL)_isDescending {
  NSUserDefaults *ud;
  NSString       *key;
  
  ud  = [(OGoSession *)[self session] userDefaults];
  key = [NSString stringWithFormat:@"skyp4_filelist_%@_isdescending",
                  [self folderIdentifier]];
  
  [ud setBool:_isDescending forKey:key];
}
- (BOOL)isDescending {
  NSUserDefaults *ud;
  NSString       *key;
  
  ud  = [(OGoSession *)[self session] userDefaults];
  key = [NSString stringWithFormat:@"skyp4_filelist_%@_isdescending",
                  [self folderIdentifier]];
  
  return [ud boolForKey:key];
}

- (void)setSortedKey:(NSString *)_sortedKey {
  NSUserDefaults *ud;
  NSString       *key;
  
  ud  = [(OGoSession *)[self session] userDefaults];
  key = [NSString stringWithFormat:@"skyp4_filelist_%@_sortfield",
                  [self folderIdentifier]];

  [ud setObject:_sortedKey forKey:key];
}
- (NSString *)sortedKey {
  NSUserDefaults *ud;
  NSString       *key;
  NSString       *result;
  
  ud  = [(OGoSession *)[self session] userDefaults];
  key = [NSString stringWithFormat:@"skyp4_filelist_%@_sortfield",
                  [self folderIdentifier]];

  if ((result = [ud stringForKey:key]) == nil)
    result = [ud stringForKey:@"skyp4_filelist_sortfield"];
  
  return result;
}

/* accessors */

- (void)setCurrentFile:(id)_file {
  ASSIGN(self->currentFile, _file);
}
- (id)currentFile {
  return self->currentFile;
}

- (BOOL)currentFileIsCheckedOut {
  NSString *path;
  
  if ((path = [self->currentFile valueForKey:NSFilePath]) == nil)
    return NO;
  
  if (![self->fileManager supportsVersioningAtPath:path])
    return NO;
  
  return [(id<NGFileManagerLocking>)self->fileManager
                                       isFileLockedAtPath:path];
}
- (BOOL)currentFileIsLocked {
  NSString *path;
  
  if ((path = [self->currentFile valueForKey:NSFilePath]) == nil)
    return NO;
  
  if ([self->fileManager supportsVersioningAtPath:path])
    return NO;
  if (![self->fileManager supportsLockingAtPath:path])
    return NO;
  
  return [(id<NGFileManagerLocking>)self->fileManager isFileLockedAtPath:path];
}

- (void)setSelectedFiles:(NSMutableArray *)_sf {
  ASSIGN(self->selectedFiles, _sf);
}
- (NSMutableArray *)selectedFiles {
  return self->selectedFiles;
}

- (void)setChangeDirPath:(NSString *)_path {
  ASSIGNCOPY(self->changeDirPath, _path);
  
  if ([[[self fileManager] currentDirectoryPath] isEqualToString:_path])
    return;
  
  if (![[self fileManager] changeCurrentDirectoryPath:_path]) {
#if 0
    // this is also invoked during 'new' (where the dir doesn't exist) !
    NSString *s;

    s = [NSString stringWithFormat:@"could not change directory to: %@",
                    _path];
    
    [self setErrorString:s];
#endif
    [self->selectedFiles removeAllObjects];
  }
}
- (NSString *)changeDirPath {
  return [[self fileManager] currentDirectoryPath];
}

- (void)setFileManager:(id)_fileManager {
  if (self->fileManager == _fileManager)
    return;

  ASSIGN(self->fileManager, _fileManager);
  [self->fsname release]; self->fsname = nil;
}
- (id)fileManager {
  return self->fileManager;
}
- (void)setDataSource:(id)_ds {
  EOFetchSpecification *fspec;
  
  ASSIGN(self->dataSource, _ds);

  if ((fspec = [self->dataSource fetchSpecification]) == nil)
    fspec = [[[EOFetchSpecification alloc] init] autorelease];
  
  [fspec setGroupings:fileTypeGroupings];
  [self->dataSource setFetchSpecification:fspec];
}

- (id)dataSource {
  if (self->dataSource == nil) {
    // TODO: can this happen? (if yes, explain and disable log)
    [self logWithFormat:@"Note: autocreated datasource for cwd!"];
    self->dataSource = [[[self fileManager] dataSourceAtPath:@"."] retain];
  }
  return self->dataSource;
}

- (NSString *)fileSystemName {
  if (self->fsname == nil) {
    self->fsname = [[[[self fileManager]
                            fileSystemAttributesAtPath:@"/"]
                            objectForKey:@"NSFileSystemName"]
                            copy];
  }
  return self->fsname;
}
- (EOGlobalID *)fileSystemNumber {
  if (self->fsgid == nil) {
    self->fsgid = [[[[self fileManager]
                           fileSystemAttributesAtPath:@"/"]
                           objectForKey:@"NSFileSystemNumber"]
                           retain];
  }
  return self->fsgid;
}

- (NSString *)textFieldStyle {
  return [NSString stringWithFormat:
                     @"font-size: 10px; background-color: %@;",
                     [[self config] valueForKey:@"colors_mainButtonRow"]];
}

- (BOOL)hasGoUp {
  return [[[self fileManager] currentDirectoryPath] length] > 1 ? YES : NO;
}

- (id)folder {
  NSString *path;
  
  if (self->folder)
    return self->folder;

  path = [[self fileManager] currentDirectoryPath];
  if ([path length] == 0)
    path = @"/";
  
  self->folder = [[(NGLocalFileManager *)[self fileManager] 
					 documentAtPath:path] retain];
  return self->folder;
}

- (NSString *)fileLinkName {
  NSString *fname;
  NSString *mType;
  NSArray  *comps;

  fname = [self->currentFile valueForKey:@"NSFileName"];
  mType = [[self->currentFile valueForKey:@"NSFileMimeType"] stringValue];
  
  if (![mType isEqualToString:@"x-skyrix/filemanager-link"])
    return fname;
  
  comps = [fname componentsSeparatedByString:@"."];
  return [comps isNotEmpty] ? (NSString *)[comps objectAtIndex:0] : fname;
}

- (BOOL)isEpozEnabled {
  // TODO: should move to a WEClientCapabilities or WOContext category?
  WEClientCapabilities *cc;
  
  if (!hasEpoz)
    return NO;
  
  cc = [[[self context] request] clientCapabilities];
  if ([cc isInternetExplorer]) {
    if ([cc majorVersion] <= 4) {
      [self debugWithFormat:@"disable Epoz with IE <5"];
      return NO;
    }
    if ([cc majorVersion] == 5 && [cc minorVersion] <= 5) {
      [self debugWithFormat:@"disable Epoz with IE <5.5"];
      return NO;
    }
    [self debugWithFormat:@"enable Epoz with IE >=5.5"];
    return YES;
  }
  
  if ([cc isMozilla] || [cc isNetscape]) {
    [self debugWithFormat:@"enable Epoz with Mozilla: %@", cc];
    return YES;
  }
  
  return NO;
}

/* actions */

- (id)changeDirectory {
  NSString *newpath;
  
  newpath = self->changeDirPath;

  [self debugWithFormat:@"cd to %@", newpath];
  if (![[self fileManager] changeCurrentDirectoryPath:newpath])
    return [self printErrorWithSource:newpath destination:nil];

  return nil;
}
- (id)createNewFolder {
  NSString *newpath;
  id       fm, l;
  
  l       = [self labels];
  fm      = [self fileManager];
  newpath = self->changeDirPath;

  if (![[newpath stringByTrimmingWhiteSpaces] length]) {
    [self setErrorString:
          [NSString stringWithFormat:@"%@: %@",
                    [l valueForKey:@"error_invalidFolderName"],
                    newpath]];
    return nil;
  }
  
  [self debugWithFormat:@"create folder %@", newpath];

  if ([fm fileExistsAtPath:newpath]) {
    [self setErrorString:[l valueForKey:@"Path already exists"]];
    return nil;
  }
  
  if (![fm createDirectoryAtPath:newpath attributes:nil])
    return [self printErrorWithSource:newpath destination:nil];
    
  return nil; // return [self changeDirectory];
}
- (id)renameFolder {
  NSString *newpath;
  NSString *oldpath;
  
  newpath = self->changeDirPath;
  if (![[newpath stringByTrimmingWhiteSpaces] length]) {
    [self setErrorString:
          [NSString stringWithFormat:@"%@: %@",
                    [[self labels] valueForKey:@"error_invalidFolderName"],
                    newpath]];
    return nil;
  }  
  oldpath = [[self fileManager] currentDirectoryPath];
  
  [self debugWithFormat:@"rename folder from %@ to %@", oldpath, newpath];
  
  if (![[self fileManager] movePath:oldpath toPath:newpath handler:nil])
    return [self printErrorWithSource:oldpath destination:newpath];
  
  if (![[self fileManager] changeCurrentDirectoryPath:newpath])
    return [self printErrorWithSource:newpath destination:nil];

  return nil;
}

- (id)editAccess {
  id       page, fm, gid;
  NSString *path;

  fm   = [self fileManager];
  path = [fm currentDirectoryPath];
  gid  = [fm globalIDForPath:path];
  
  // TODO: use activation?!
  if ((page = [self pageWithName:@"SkyCompanyAccessEditor"])) {
    [page takeValue:gid              forKey:@"globalID"];
    [page takeValue:accessCheckFlags forKey:@"accessChecks"];
    return page;
  }
  [self setErrorString:@"could not find access editor !"];
  return nil;
}

- (id)deleteFolder {
  NGFileManager *fm;
  NSString *delpath;
  NSString *newpath;
  
  delpath = self->changeDirPath;
  if ([delpath isEqualToString:@"/"]) {
    [self setErrorString:@"you can't delete the root path !"];
    return nil;
  }
  newpath = [delpath stringByDeletingLastPathComponent];
  
  [self debugWithFormat:@"delete folder %@", delpath];
  
  fm = [self fileManager];

  if (![fm supportsTrashFolderAtPath:delpath]) {
    if (![fm removeFileAtPath:delpath handler:nil])
      return [self printErrorWithSource:delpath destination:nil];
    return nil;
  }
  
  if (![delpath hasPrefix:[fm trashFolderForPath:delpath]]) {
      /* outside of trash, move to trash */
    
      if (![fm trashFileAtPath:delpath handler:nil]) {
        return [self printErrorWithSource:delpath
                     destination:[fm trashFolderForPath:delpath]];
      }
      if (![fm changeCurrentDirectoryPath:newpath])
        return [self printErrorWithSource:newpath destination:nil];
  }
  else {
      /* in trash, delete physically .. */
      if ([[fm directoryContentsAtPath:delpath] count] > 0) {
        [self setErrorString:@"delete directory contents first !"];
        return nil;
      }
    
      if (![fm changeCurrentDirectoryPath:newpath])
        return [self printErrorWithSource:newpath destination:nil];
    
      if (![fm removeFileAtPath:delpath handler:nil])
        return [self printErrorWithSource:delpath destination:nil];
  }
  return nil;
}

- (id)newDocument {
  /* TODO: turn this action into a direct action */
  return [self activateObject:[[self dataSource] createObject]
               withVerb:@"edit"];
}
- (id)newDocumentInEpoz {
  /* TODO: turn this action into a direct action */
  id page;
  
  page = [self newDocument];
  [page takeValue:[NSNumber numberWithBool:YES] forKey:@"isEpozEnabled"];
  return page;
}

- (id)uploadDocument {
  /* TODO: turn this action into a direct action */
  return [self activateObject:[[self dataSource] createObject]
               withVerb:@"upload"];
}

- (id)newLink {
  /* TODO: turn this action into a direct action */
  id         page;
  EOGlobalID *gid;
  
  if ((gid = [[self fileManager] globalIDForPath:@"."]) == nil) {
    [self logWithFormat:@"could not get gid for path '.' .."];
    return nil;
  }
  
  page = [self pageWithName:@"SkyProject4NewLink"];
  
  [page takeValue:[self fileManager] forKey:@"fileManager"];
  [page takeValue:gid                forKey:@"folderId"];
  
  return page;
}

- (id)moveSelection {
  id page;

  if ((page = [self pageWithName:@"SkyProject4MovePanel"]) == nil) {
    [self setErrorString:@"missing move panel .."];
    return nil;
  }
  if ([self->selectedFiles count] == 0)
    return nil;
  
  [page takeValue:[self fileManager] forKey:@"fileManager"];
  [page takeValue:[self->selectedFiles valueForKey:NSFilePath]
        forKey:@"pathsToMove"];
  
  [self->selectedFiles removeAllObjects];
  
  return page;
}
- (id)copySelection {
  id page;

  if ((page = [self pageWithName:@"SkyProject4MovePanel"]) == nil) {
    [self setErrorString:@"missing move panel .."];
    return nil;
  }
  if ([self->selectedFiles count] == 0)
    return nil;

  [page takeValue:[self fileManager] forKey:@"fileManager"];
  [page takeValue:[self->selectedFiles valueForKey:NSFilePath]
        forKey:@"pathsToCopy"];
  
  [self->selectedFiles removeAllObjects];
  
  return page;
}

- (id)zipSelection {
  NSString *zipFile;
  NSString *current;
  id       page;

  if ((page = [self pageWithName:@"SkyP4ZipPanel"]) == nil) {
    [self setErrorString:@"missing zip panel .."];
    return nil;
  }
  if ([self->selectedFiles count] == 0)
    return nil;

  current = [[self fileManager] currentDirectoryPath];
  if ([current isEqualToString:@"/"]) {
    zipFile = [NSString stringWithFormat:@"/%@", [self fileSystemName]];
  }
  else {
    zipFile = [current stringByAppendingPathComponent:
                       [current lastPathComponent]];
  }
  
  [page takeValue:[self fileManager] forKey:@"fileManager"];
  [page takeValue:zipFile            forKey:@"zipFilePath"];
  [page takeValue:[self->selectedFiles valueForKey:NSFilePath]
        forKey:@"pathsToZip"];
  
  [self->selectedFiles removeAllObjects];
  
  return page;
}

- (id)deleteSelection {
  id       fm;
  unsigned i, count;
  NSArray  *files;
  BOOL     allOk;
  
  if ((fm = [self fileManager]) == nil) {
    [self setErrorString:@"missing filemanager .."];
    return nil;
  }
  if ((count = [self->selectedFiles count]) == 0)
    return nil;

  files = [self->selectedFiles shallowCopy];
  AUTORELEASE(files);
  
  /* move deleted files to trash, delete files already in trash */
  
  for (i = 0, allOk = YES; i < count; i++) {
    NSDictionary *info;
    NSString *path;
    NSString *trashPath;
    
    info = [files objectAtIndex:i];
    
    path = [[[info valueForKey:NSFilePath] copy] autorelease];
    if (path == nil) {
      allOk = NO;
      continue;
    }
    
    trashPath = [[[fm trashFolderForPath:path] copy] autorelease];
    
    if ([path isEqualToString:trashPath])
      continue;
    
    if ([path hasPrefix:trashPath]) {
      /* already in trash -> delete */
      if (![fm removeFileAtPath:path handler:nil]) {
        [self logWithFormat:@"delete %@ in trash failed.", path];
        allOk = NO;
      }
      else 
        [self->selectedFiles removeObjectIdenticalTo:info];
    }
    else {
      if (![fm trashFileAtPath:path handler:nil]) {
        [self logWithFormat:@"move %@ to trash failed.", path];
        allOk = NO;
      }
      else
        [self->selectedFiles removeObjectIdenticalTo:info];
    }
  }
  
  if (!allOk) {
    return [self printError];
    // [self setErrorString:@"there were errors during deletion !"];
  }
  
  return nil;
}

- (id)releaseSelection {
  id<NGFileManagerLocking,NGFileManagerVersioning> fm;
  unsigned i, count;
  NSArray  *files;
  NSMutableString *errors;
  
  if ((fm = (id)[self fileManager]) == nil) {
    [self setErrorString:@"missing filemanager .."];
    return nil;
  }
  if ((count = [self->selectedFiles count]) == 0)
    return nil;

  errors = [NSMutableString stringWithCapacity:32];  
  files = [[self->selectedFiles shallowCopy] autorelease];
  
  for (i = 0; i < count; i++) {
    NSDictionary *info;
    NSString     *path;
    
    info = [files objectAtIndex:i];

    path = [[[info valueForKey:NSFilePath] copy] autorelease];
    if (path == nil) continue;
    
    if (![fm supportsVersioningAtPath:path]) {
      [errors appendString:
              [[self labels]
                     valueForKey:@"error_versioningUnsupportedAtPath"]];
      [errors appendString:path];
      [errors appendString:@"\n"];
      continue;
    }
    else if ([fm isFileLockedAtPath:path]) {
      if ([fm releaseFileAtPath:path handler:nil])
        [self->selectedFiles removeObjectIdenticalTo:info];
    }
    else {
      [errors appendString:
              [[self labels]
                     valueForKey:@"error_fileIsNotLockedAtPath"]];
      [errors appendString:path];
      [errors appendString:@"\n"];
    }
  }

  if ([errors length]) {
    [self setErrorString:errors];
    return nil;
  }
  
  if ([selectedFiles count] > 0) {
    return [self printError];
    //[self setErrorString:@"there were errors during the release !"];
  }
  
  return nil;
}

- (BOOL)doesZipExist {
  return hasZip;
}

- (id)emptyTrash {
  NSString      *trashPath;
  NSFileManager *fm;
  NSString      *curr;

  fm        = [self fileManager];
  curr      = [fm currentDirectoryPath];
  trashPath = [fm trashFolderForPath:curr];

  if ([fm fileExistsAtPath:trashPath]) {
    NSArray *files;
    int     i, cnt;

    files = [fm directoryContentsAtPath:trashPath];
    cnt   = [files count];
    
    for (i=0; i < cnt; i++) {
      NSString *file;

      file = [files objectAtIndex:i];
      file = [trashPath stringByAppendingPathComponent:file];

      if (![fm removeFileAtPath:file handler:nil]) {
        // some error handling stuff...
        [self setErrorString:@"could not empty trash  completely"];
      }
    }
  }
  if ([curr hasPrefix:trashPath])
    [fm changeCurrentDirectoryPath:trashPath];
  
  return nil;
}

- (id)goUp {
  if (![[self fileManager] changeCurrentDirectoryPath:@".."])
    [[self fileManager] changeCurrentDirectoryPath:@"/"];
  return nil;
}

- (id)_clickedDirectory {
  [self debugWithFormat:@"clicked directory, chdir to '%@'",
          [self currentFile]];
  
  [[self fileManager] changeCurrentDirectoryPath:
                        [[self currentFile] valueForKey:NSFilePath]];
  return nil;
}

- (BOOL)isPrimaryKeyLinkTarget:(NSString *)_key {
  /* primary key links to other OGo objects are stored as numbers '9999' */
  return [_key length] > 3 && isdigit([_key characterAtIndex:0]);
}
- (BOOL)isOldSchoolLinkTarget:(NSString *)_key {
  /* in some SKYRiX versions internal links are stored as direct actions */
  /* Note: this syntax is deprecated! */
  return [_key hasPrefix:@"/Skyrix/wa/LSWViewAction/view"];
}

- (BOOL)isExternalLink {
  id       f;
  NSString *linkTarget;
  NSString *linkPath;

  f = [self currentFile];
  
  if (![[f valueForKey:NSFileType] isEqualToString:NSFileTypeSymbolicLink])
    return NO;

  linkTarget = [f valueForKey:@"SkyLinkTarget"];

  if (!([linkTarget isNotNull] && [linkTarget length] > 0))
    return NO;
      
  linkPath   = [[self currentFile] valueForKey:NSFilePath];
  linkTarget = [[self fileManager] pathContentOfSymbolicLinkAtPath:linkPath];
  
  if ([[self fileManager] fileExistsAtPath:linkTarget isDirectory:NULL])
    return NO;
  
  /* old style link */
  if ([self isOldSchoolLinkTarget:linkTarget])
    return NO;

  if ([NSURL URLWithString:linkTarget])
    return YES;
  
  return NO;
}

- (NSString *)linkHref {
  NSString *linkPath;

  linkPath = [[self currentFile] valueForKey:NSFilePath];

  return [[self fileManager] pathContentOfSymbolicLinkAtPath:linkPath];
}

- (id)_clickedInternalLink:(NSString *)_linkTarget {
  /* a pkey link */
  LSCommandContext *cmdctx;
  EOGlobalID *gid;
        
  cmdctx = [(OGoSession *)[self session] commandContext];
  gid = [[cmdctx typeManager] globalIDForPrimaryKey:_linkTarget];
  
  return [self activateObject:gid withVerb:@"view"];
}
- (id)_clickedExternalLink:(NSString *)_linkTarget {
  /* a hyperlink */
  WOResponse *response;
  NSURL      *url;
  
  if ((url = [NSURL URLWithString:_linkTarget]) == nil) {
    NSString *msg;
    
    msg = [NSString stringWithFormat:@"cannot handle link target '%@'",
                      _linkTarget];
    [self setErrorString:msg];
    return nil;
  }
  
  [self debugWithFormat:@"redirect to: %@", _linkTarget];
  
  response = [WOResponse responseWithRequest:[[self context] request]];
  [response setStatus:302 /* moved */];
  [response setHeader:_linkTarget forKey:@"location"];
  [response setHeader:@"external" forKey:@"target"];
  return response;
}
- (NSString *)_rewriteOldSchoolLink:(NSString *)_linkTarget {
  /* an old view link */
  NSRange r;
  
  [self warnWithFormat:@"encountered old-style link: %@", _linkTarget];
  
  r = [_linkTarget rangeOfString:@"="];
  return (r.length > 0)
    ? [_linkTarget substringFromIndex:(r.location + r.length)]
    : _linkTarget;
}

- (id)_clickedLink {
  NSString *linkPath;
  NSString *linkTarget;
  BOOL     isDir;

  linkPath   = [[self currentFile] valueForKey:NSFilePath];
  linkTarget = [[self fileManager] pathContentOfSymbolicLinkAtPath:linkPath];

  if ([linkTarget length] == 0) {
    [self setErrorString:@"link has no contents .."];
    return nil;
  }

  if ([linkTarget isEqualToString:linkPath]) {
    [self setErrorString:@"self-referencing symbolic link !"];
    return nil;
  }
  
  if (debugOn)
    [self debugWithFormat:@"clicked link with target '%@' ..", linkTarget];
  
  if ([[self fileManager] fileExistsAtPath:linkTarget isDirectory:&isDir]) {
    id targetDoc;
    
    if (isDir) {
      /* clicked link leading to directory */
      [[self fileManager] changeCurrentDirectoryPath:linkTarget];
      return nil;
    }
    
    if ((targetDoc = [(NGLocalFileManager *)[self fileManager] 
					    documentAtPath:linkTarget]))
      return [self activateObject:targetDoc withVerb:@"view"];
  }
  
  if ([self isOldSchoolLinkTarget:linkTarget])
    linkTarget = [self _rewriteOldSchoolLink:linkTarget];
  
  if ([self isPrimaryKeyLinkTarget:linkTarget])
    return [self _clickedInternalLink:linkTarget];
  
  return [self _clickedExternalLink:linkTarget];
}

- (id)clickedFile {
  WOComponent *page;
  NSString    *type;
  NSString    *path;
  EOGlobalID  *gid;
  id doc;
  
  if ((doc = [self currentFile]) == nil) {
    [self logWithFormat:@"missing 'currentFile' for action .."];
    [self setErrorString:@"missing document ..."];
    return nil;
  }
  
  path = [doc valueForKey:NSFilePath];
  type = [doc valueForKey:NSFileType];
  
  if ([type isEqualToString:NSFileTypeDirectory])
    return [self _clickedDirectory];

  if ([type isEqualToString:NSFileTypeSymbolicLink]) {
    if (debugOn) [self debugWithFormat:@"clicked link '%@'", path];
    return [self _clickedLink];
  }

  if (debugOn) [self debugWithFormat:@"clicked file '%@'", path];
  
  if ([doc isNew]) {
    [self logWithFormat:
              @"document %@ is 'new' "
              @"(a filelist cannot contain new documents) !!!",
              doc];
  }
  else if ((gid = [doc globalID]) == nil)
    [self logWithFormat:@"got no global id for document %@", doc];
  
  if ((page = [self activateObject:doc withVerb:@"view"]) == nil) {
    [self logWithFormat:@"could not activate document %@", doc];
    return nil;
  }
  return page;
}

- (BOOL)isSymbolicLinkEnabled {
  NSString *p;

  p = [[self fileManager] currentDirectoryPath];
  if (![self->fileManager isSymbolicLinkEnabledAtPath:p])
    return NO;
  return [[self folder] isInsertable];
}

@end /* SkyP4FolderView */
