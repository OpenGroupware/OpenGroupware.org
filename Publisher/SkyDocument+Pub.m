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

#include "SkyDocument+Pub.h"
#include "SkyPubFileManager.h"
#include "common.h"

@interface SkyDocument(DocFM)
- (id)fileManager;
- (NSURL *)urlForPath:(NSString *)_path;
@end

@implementation SkyDocument(Pub)

static BOOL debugLinkChecker = NO;
static BOOL logPathOps       = NO;

/* environment */

- (id<NSObject,SkyDocumentFileManager>)pubFileManager {
  id<NSObject,SkyDocumentFileManager> fm = nil;
  
  if ([self respondsToSelector:@selector(fileManager)])
    fm = [self fileManager];
  else
    NSLog(@"%@: document has no filemanager !", self);
  
  fm = [(id)fm asPubFileManager];
  
  if (![fm conformsToProtocol:@protocol(SkyDocumentFileManager)]) {
    NSLog(@"%@: filemanager %@ is not a SkyDocumentFileManager !",
          self, fm);
    fm = nil;
  }
  
  return fm;
}

- (EODataSource *)pubChildDataSource {
  id<NSObject,SkyDocumentFileManager> fm = nil;
  NSString *p;
  
  if ((fm = [self pubFileManager]) == nil)
    return nil;

  p = [self pubPath];
  if ([p length] == 0) return nil;

  if (![fm supportsFeature:NGFileManagerFeature_DataSources atPath:p])
    fm = nil;
  
  return [(id<NGFileManagerDataSources>)fm dataSourceAtPath:p];
}

/* paths */

- (NSURL *)pubURL {
  return [self urlForPath:[self pubPath]];
}
- (NSString *)pubPath {
  NSString *p;
  
  if ((p = [self valueForKey:@"NSFilePath"]) == nil)
    return nil;

  if (![p hasSuffix:@"/"]) {
    if ([[self valueForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
      p = [p stringByAppendingString:@"/"];
  }
  return p;
}

- (NSString *)pubStandardizePath:(NSString *)_path {
  NGFileManager *fm;
  NSString *result;
  
  if (logPathOps) [self logWithFormat:@"pub standardize path: %@", _path];
  
  if ((fm = (NGFileManager *)[self pubFileManager]) == nil) {
    if (logPathOps)
      [self logWithFormat:@"  missing filemanager, cannot standardize !"];
    return _path;
  }
  
  result = [fm standardizePath:_path];
  if (logPathOps) {
    [self logWithFormat:@"  pub fm: %@", fm];
    [self logWithFormat:@"  pub standardized: %@", result];
  }
  return result;
}

- (NSString *)pubMakeAbsolutePath:(NSString *)_otherDocPath {
  NSString *docPath;
  NSString *docType;
  
  if ([_otherDocPath isAbsolutePath])
    return [self pubStandardizePath:_otherDocPath];
  
  docPath = [self pubPath];
  docType = [self valueForKey:NSFileType];
  
  if ([docType isEqualToString:NSFileTypeDirectory])
    docPath = [docPath stringByAppendingPathComponent:_otherDocPath];
  else {
    docPath = [[docPath stringByDeletingLastPathComponent]
                        stringByAppendingPathComponent:_otherDocPath];
  }
  return [self pubStandardizePath:docPath];
}

- (NSString *)pubMakeRelativePath:(NSString *)_otherDocPath {
  NSString *otherAbsPath;
  NSString *ownPath;
  NSString *ownDir, *otherDir, *cprefix, *tmp;
  NSMutableString *newdir;
  int  i, goUp;
  BOOL ownIsDir, otherIsDir;
  
  ownPath      = [self pubPath];
  otherAbsPath = [self pubMakeAbsolutePath:_otherDocPath];
  
  ownIsDir =
    [[self valueForKey:NSFileType] isEqualToString:NSFileTypeDirectory];
  
  if (![ownPath isAbsolutePath] || ![otherAbsPath isAbsolutePath]) {
    NSLog(@"%s: missing absolute pathes ...", __PRETTY_FUNCTION__);
    return nil;
  }
  if (![[self fileManager] fileExistsAtPath:otherAbsPath
                           isDirectory:&otherIsDir]) {
    NSLog(@"%s: path '%@' doesn't exist relative to %@ ...",
          __PRETTY_FUNCTION__, _otherDocPath, self);
    return nil;
  }

  if (ownIsDir && ![ownPath hasSuffix:@"/"])
    ownPath = [ownPath stringByAppendingString:@"/"];
  if (otherIsDir && ![otherAbsPath hasSuffix:@"/"])
    otherAbsPath = [otherAbsPath stringByAppendingString:@"/"];
  
  if ([ownPath isEqualToString:otherAbsPath]) {
    /* self-link */
    if ([ownPath isEqualToString:@"/"])
      return ownPath;

#if DEBUG && 0
    NSLog(@"%s: ownpath '%@' == otherpath '%@'(%@)",
          __PRETTY_FUNCTION__, ownPath, otherAbsPath, _otherDocPath);
#endif
    
    return ownIsDir
      ? [@"../" stringByAppendingString:[ownPath lastPathComponent]]
      : [ownPath lastPathComponent];
  }
  
  ownDir   = [ownPath stringByDeletingLastPathComponent];
  otherDir = [otherAbsPath stringByDeletingLastPathComponent];
  
  if (![ownDir   hasSuffix:@"/"])
    ownDir = [ownDir stringByAppendingString:@"/"];
  if (![otherDir hasSuffix:@"/"])
    otherDir = [otherDir stringByAppendingString:@"/"];
  
  if ([ownDir isEqualToString:otherDir]) {
    /*
      Same parent directory.

      source: /de/news/wap.html
      target: /de/news/
      =>:     ../news/

      source: /de/news/blah.html
      target: /de/news/wap.html
      =>:     wap.html

      source: /de/news/
      target: /de/news/wap.html
      =>:     wap.html
      
      source: /de/news/a/
      target: /de/news/wap.html
      =>:     ../wap.html
      
      source: /de/news/a/
      target: /de/news/
      =>:     ../

      .. ?
    */
    //#warning fixme, maybe not all combinations work yet ...
    tmp = [otherAbsPath lastPathComponent];
    if (ownIsDir) tmp = [@"../" stringByAppendingString:tmp];
    
#if DEBUG && 0
    NSLog(@"same dir '%@' other '%@' relative '%@'\n  "
          @"  owndir '%@' other '%@'",
          [self path], _otherDocPath, [otherAbsPath lastPathComponent],
          ownDir, otherDir);
#endif
    
    return tmp;
  }

  /*
    constellation which would lead to empty pathes with usual processing:
      own      '/de/news/wap.html' /de/news
      other    '/de/news/'         /de
      relative ''
      cprefix  '/de/news'
      up       0
  */
  if (otherIsDir && [ownDir isEqualToString:otherAbsPath]) {
    NSString *relpath;

    relpath = [[@"../" stringByAppendingString:
                 [otherAbsPath lastPathComponent]]
                       stringByAppendingString:@"/"];

    if (ownIsDir)
      relpath = [@"../" stringByAppendingString:relpath];
    
#if DEBUG && 0
    NSLog(@"%s: other '%@' is-dir and equal to ownDir '%@' => '%@'",
          __PRETTY_FUNCTION__, otherAbsPath, ownDir, relpath);
#endif
    return relpath;
  }
  
  /* process path */
  
  goUp = 0;
  for (cprefix = ownDir, goUp = 0;
       ![otherAbsPath hasPrefix:cprefix];
       cprefix = [cprefix stringByDeletingLastPathComponent]) {
    goUp++;
  }
  
  newdir = [NSMutableString stringWithCapacity:32];
  
  if (ownIsDir)
    [newdir appendString:@"../"];
  
  for (i = 0; i < goUp; i++)
    [newdir appendString:@"../"];
  
  tmp = [otherAbsPath substringFromIndex:[cprefix length]];
  if ([tmp hasPrefix:@"/"])
    tmp = [tmp substringFromIndex:1];
  
  [newdir appendString:tmp];
  
#if DEBUG && 0
  NSLog(@"own '%@'(%@) other '%@'(%@) relative '%@' cprefix='%@' up=%i",
        [self path], ownDir,
        otherAbsPath, otherDir,
        newdir, cprefix, goUp);
#endif
  
  return newdir;
}

/* links */

- (BOOL)pubIsValidLink:(NSString *)_link {
  id<NGFileManager,SkyDocumentFileManager> fm;
  BOOL     isDir;
  NSString *absPath;
  NSRange  r;
  
  if (debugLinkChecker)
    [self logWithFormat:@"IsValidLink: %@", _link];
  
  if ([_link length] == 0)   return NO;
  if ([_link isAbsoluteURL]) return YES;
  
  if ([_link hasPrefix:@"#"]) {
    /* a fragment link, not checked for validity */
    return YES;
  }
  
  r = [_link rangeOfString:@"#"];
  if (r.length > 0) {
    /* a fragment appended, check the link before */
    absPath = [self pubMakeAbsolutePath:[_link substringToIndex:r.location]];
    if (absPath == nil) {
      /* couldn't get absolute path for link ... */
#if DEBUG
      NSLog(@"%@: couldn't get absolute path for '%@'",
            self, _link);
#endif
      return NO;
    }
  }
  else if ((absPath = [self pubMakeAbsolutePath:_link]) == nil) {
    /* couldn't get absolute path for link ... */
#if DEBUG
    NSLog(@"%@: couldn't get absolute path for '%@'",
          self, _link);
#endif
    return NO;
  }
  
  if ((fm = [self pubFileManager]) == nil) {
#if DEBUG && 0
    NSLog(@"%@: couldn't get filemanager ...", self);
#endif
    return NO;
  }
  
  if (debugLinkChecker)
    [self logWithFormat:@"  check path: %@", absPath];
  
  if (![fm fileExistsAtPath:absPath isDirectory:&isDir]) {
    /* target doesn't exist */
    if (debugLinkChecker)
      [self logWithFormat:@"  %@ path does not exist: %@", fm, absPath];
    return NO;
  }

  if (isDir) {
    /* check whether index file exists ... */
    SkyDocument *targetDoc;
    
    if ((targetDoc = [fm documentAtPath:absPath]) == nil)
      /* couldn't get target folder ... */
      return NO;
    
    return [targetDoc pubIndexFilePath] != nil ? YES : NO;
  }

  return YES;
}

- (NSString *)pubRelativeTargetPathForLink:(NSString *)_link {
  id<NGFileManager,SkyDocumentFileManager> fm;
  BOOL     isDir;
  NSString *absPath;
  NSRange  r;
  NSString *fragment = nil;
  
  if ([_link isAbsoluteURL])
    /* no relative link is possible */
    return nil;
  if ([_link hasPrefix:@"#"])
    /* fragment link, is already relative ... */
    return _link;

  r = [_link rangeOfString:@"#"];
  if (r.length > 0) {
    /* fragment appended */
    fragment = [_link substringFromIndex:r.location];
    absPath  = [self pubMakeAbsolutePath:[_link substringToIndex:r.location]];
    /* couldn't get absolute path for link ... */
    if (absPath == nil)
      return nil;
  }
  else if ((absPath = [self pubMakeAbsolutePath:_link]) == nil)
    /* couldn't get absolute path for link ... */
    return nil;

  if ((fm = [self pubFileManager]) == nil)
    return nil;
  
  if (![fm fileExistsAtPath:absPath isDirectory:&isDir])
    /* target doesn't exist */
    return nil;
  
  if (isDir) {
    /* create link to index file ... */
    SkyDocument *targetDoc;
    
    if ((targetDoc = [fm documentAtPath:absPath]) == nil)
      /* couldn't get target folder ... */
      return nil;
    
    if ((absPath = [targetDoc pubIndexFilePath]) == nil)
      return nil;
    
    return (fragment != nil)
      ? [[self pubMakeRelativePath:absPath] stringByAppendingString:fragment]
      : [self pubMakeRelativePath:absPath];
  }
  else {
    /* usual document, return link */
    return (fragment != nil)
      ? [[self pubMakeRelativePath:absPath] stringByAppendingString:fragment]
      : [self pubMakeRelativePath:absPath];
  }
}

- (NSString *)pubAbsoluteTargetPathForLink:(NSString *)_link {
  id<NGFileManager,SkyDocumentFileManager> fm;
  BOOL     isDir;
  NSString *absPath;
  NSString *fragment = nil;
  NSRange  r;
  
  if ([_link isAbsoluteURL])
    /* no (host) relative link is possible */
    return nil;
  
  r = [_link rangeOfString:@"#"];
  if (r.length > 0 && r.location == 0) {
    /* fragment link, absolute link is self + #link */
    absPath  = [self pubPath];
    fragment = _link;
  }
  else if (r.length > 0) {
    /* fragment link, absolute link is _link[0..idx] + #fragment */
    fragment = [_link substringFromIndex:r.location];
    absPath  = [self pubMakeAbsolutePath:[_link substringToIndex:r.location]];
    
    if (absPath == nil)
      /* couldn't get absolute path for link */
      return nil;
  }
  else if ((absPath = [self pubMakeAbsolutePath:_link]) == nil)
    /* couldn't get absolute path for link ... */
    return nil;
  
  if ((fm = [self pubFileManager]) == nil)
    return nil;
  
  if (![fm fileExistsAtPath:absPath isDirectory:&isDir])
    /* target doesn't exist */
    return nil;
  
  if (isDir) {
    /* create link to index file ... */
    SkyDocument *targetDoc;
    
    if ((targetDoc = [fm documentAtPath:absPath]) == nil)
      /* couldn't get target folder ... */
      return nil;
    
    if ((absPath = [targetDoc pubIndexFilePath]) == nil)
      return nil;

    if (fragment != nil)
      absPath = [absPath stringByAppendingString:fragment];
    return absPath;
  }
  else {
    /* usual document, return link */
    if (fragment != nil)
      absPath = [absPath stringByAppendingString:fragment];
    return absPath;
  }
}

/* documents */

- (SkyDocument *)parentDocument {
  id<NSObject,SkyDocumentFileManager> fm = nil;
  NSString *p;
  
  p = [self pubPath];
  
  if ((fm = [self pubFileManager]) == nil)
    return nil;
  
  if ([p isEqualToString:@"/"] || [p length] == 0)
    return nil;
  
  p = [p stringByDeletingLastPathComponent];
  
  return [fm documentAtPath:p];
}

- (SkyDocument *)nextDocument {
  id<NSObject,SkyDocumentFileManager> fm = nil;
  NSString *p, *n;
  NSArray  *dir;
  unsigned idx, count;
  
  p = [self pubPath];
  
  if ((fm = [self pubFileManager]) == nil)
    return nil;
  
  if ([p isEqualToString:@"/"] || [p length] == 0)
    return nil;
  
  n = [p lastPathComponent];
  p = [p stringByDeletingLastPathComponent];
  
  dir   = [[fm directoryContentsAtPath:p]
               sortedArrayUsingSelector:@selector(compare:)];
  count = [dir count];
  
  if (((idx = [dir indexOfObject:n]) == NSNotFound) || (count == 0)) {
    NSLog(@"WARNING(%s): document %@ not found in parent folder '%@' ?!",
          __PRETTY_FUNCTION__, self, p);
    return nil;
  }

  idx++; // go to next document
  if (idx >= count)
    /* reached end, last document */
    return nil;
  
  n = [dir objectAtIndex:idx];
  p = [p stringByAppendingPathComponent:n];
  
  return [fm documentAtPath:p];
}
- (SkyDocument *)previousDocument {
  id<NSObject,SkyDocumentFileManager> fm = nil;
  NSString *p, *n;
  NSArray  *dir;
  unsigned idx, count;
  
  p = [self pubPath];
  
  if ((fm = [self pubFileManager]) == nil)
    return nil;
  
  if ([p isEqualToString:@"/"] || [p length] == 0)
    return nil;
  
  n = [p lastPathComponent];
  p = [p stringByDeletingLastPathComponent];
  
  dir   = [[fm directoryContentsAtPath:p]
               sortedArrayUsingSelector:@selector(compare:)];
  count = [dir count];
  
  if (((idx = [dir indexOfObject:n]) == NSNotFound) || (count == 0)) {
    NSLog(@"WARNING(%s): document %@ not found in parent folder '%@' ?!",
          __PRETTY_FUNCTION__, self, p);
    return nil;
  }
  
  if (idx == 0)
    /* reached start, first document */
    return nil;
  
  idx--; // go to prev document
  n = [dir objectAtIndex:idx];
  p = [p stringByAppendingPathComponent:n];
  
  return [fm documentAtPath:p];
}

- (SkyDocument *)pubDocumentAtPath:(NSString *)_path {
  id<NSObject,SkyDocumentFileManager> fm = nil;
  
  _path = [self pubMakeAbsolutePath:_path];
  if ([_path length] == 0)
    return nil;
  
  if ((fm = [self pubFileManager]) == nil)
    return nil;
  
  return [fm documentAtPath:_path];
}

- (NSString *)pubIndexFilePath {
  NSString *indexPath;
  id       ftype;
  id<NSObject,SkyDocumentFileManager> fm = nil;
  BOOL     isDir = NO;
  
  if ((ftype = [self valueForKey:NSFileType]) == nil)
    return nil;
  if (![ftype isEqualToString:NSFileTypeDirectory])
    return nil;
  
  if ((fm = [self pubFileManager]) == nil)
    return nil;
  
  if ((indexPath = [self valueForKey:@"IndexFile"])) {
    indexPath = [self pubMakeAbsolutePath:indexPath];
    
    if (![fm fileExistsAtPath:indexPath isDirectory:&isDir])
      /* file specified in 'IndexFile' attribute does not exist */
      return nil;
    if (isDir)
      /* file specified in 'IndexFile' attribute is a directory ! */
      return nil;
    return indexPath;
  }
  
  indexPath = [self pubMakeAbsolutePath:@"index.xhtml"];
  if ([fm fileExistsAtPath:indexPath isDirectory:&isDir]) {
    if (!isDir)
      return indexPath;
  }
  
  indexPath = [self pubMakeAbsolutePath:@"index.html"];
  if ([fm fileExistsAtPath:indexPath isDirectory:&isDir]) {
    if (!isDir)
      return indexPath;
  }
  
  return nil;
}
- (SkyDocument *)pubIndexDocument {
  NSString *indexPath;
  id       ftype;
  id<NSObject,SkyDocumentFileManager> fm = nil;
  BOOL     isDir = NO;
  
  if ((ftype = [self valueForKey:NSFileType]) == nil)
    return nil;
  if (![ftype isEqualToString:NSFileTypeDirectory])
    return nil;
  
  if ((fm = [self pubFileManager]) == nil)
    return nil;
  
  if ((indexPath = [self valueForKey:@"IndexFile"])) {
    indexPath = [self pubMakeAbsolutePath:indexPath];
    
    if (![fm fileExistsAtPath:indexPath isDirectory:&isDir])
      /* file specified in 'IndexFile' attribute does not exist */
      return nil;
    if (isDir)
      /* file specified in 'IndexFile' attribute is a directory ! */
      return nil;
    return [fm documentAtPath:indexPath];
  }
  
  indexPath = [self pubMakeAbsolutePath:@"index.xhtml"];
  if ([fm fileExistsAtPath:indexPath isDirectory:&isDir]) {
    if (!isDir)
      return [fm documentAtPath:indexPath];
  }
  
  indexPath = [self pubMakeAbsolutePath:@"index.html"];
  if ([fm fileExistsAtPath:indexPath isDirectory:&isDir]) {
    if (!isDir)
      return [fm documentAtPath:indexPath];
  }
  
  return nil;
}

/* lists */

- (NSArray *)pubChildListDocuments {
  EODataSource *ds;
  
  /* this is suspect */
  if (![[self valueForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
    return [[self parentDocument] pubChildListDocuments];
  
  if ((ds = [self pubChildDataSource]) == nil)
    return nil;
  
  return [ds fetchObjects];
}

- (NSArray *)pubAllDocuments {
  EODataSource         *ds;
  EOFetchSpecification *fspec;
  NSDictionary *hints;
  id fm;
  
  /* this is suspect */
  if (![[self valueForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
    return [[self parentDocument] pubAllDocuments];
  
  if ((fm = [self pubFileManager]) == nil)
    return nil;
  
  if (![fm supportsFeature:NGFileManagerFeature_DataSources atPath:@"/"])
    fm = nil;
  
  ds = [(id<NGFileManagerDataSources>)fm dataSourceAtPath:@"/"];

  hints = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                        forKey:@"fetchDeep"];
  
  fspec = [EOFetchSpecification fetchSpecificationWithEntityName:@"*"
                                qualifier:nil
                                sortOrderings:nil];
  [fspec setHints:hints];
  
  [ds setFetchSpecification:fspec];
  
  return [ds fetchObjects];
}

- (NSArray *)pubAllFromDataSourceOfClass:(Class)_class {
  EODataSource *ds;
  NSArray *a;
  
  if (_class == Nil) return nil;
  ds = [[_class alloc] initWithContext:[self context]];
  if (ds == nil) return nil;
  a = [[[ds fetchObjects] retain] autorelease];
  [ds release];
  return a;
}
- (NSArray *)pubAllPersons {
  return [self pubAllFromDataSourceOfClass:
                 NSClassFromString(@"SkyPersonDataSource")];
}
- (NSArray *)pubAllEnterprises {
  return [self pubAllFromDataSourceOfClass:
                 NSClassFromString(@"SkyEnterpriseDataSource")];
}
- (NSArray *)pubAllAccounts {
  return [self pubAllFromDataSourceOfClass:
                 NSClassFromString(@"SkyAccountDataSource")];
}
- (NSArray *)pubAllJobs {
  return [self pubAllFromDataSourceOfClass:
                 NSClassFromString(@"SkyJobDataSource")];
}
- (NSArray *)pubAllAppointments {
  return [self pubAllFromDataSourceOfClass:
                 NSClassFromString(@"SkyAppointmentDataSource")];
}
- (NSArray *)pubAllProjects {
  return [self pubAllFromDataSourceOfClass:
                 NSClassFromString(@"SkyProjectDataSource")];
}
- (NSArray *)pubAllTeams {
  return [self pubAllFromDataSourceOfClass:
                 NSClassFromString(@"SkyTeamDataSource")];
}

- (NSArray *)pubTocListDocuments {
  EODataSource         *ds;
  EOFetchSpecification *fspec;
  static EOQualifier   *q = nil;
  
  /* this is suspect */
  if (![[self valueForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
    return [[self parentDocument] pubTocListDocuments];
  
  if ((ds = [self pubChildDataSource]) == nil)
    return nil;

  if (q == nil) {
    q = [EOQualifier qualifierWithQualifierFormat:
                       @"(NSFileType='NSFileTypeDirectory' OR "
                       @"NSFileType='NSFileTypeRegular') AND "
                       @"NOT (NSFileName like '*.xtmpl')"];
    RETAIN(q);
  }
  fspec = [EOFetchSpecification fetchSpecificationWithEntityName:
                                  [self pubPath]
                                qualifier:q
                                sortOrderings:nil];
  
  [ds setFetchSpecification:fspec];
  
  return [ds fetchObjects];
}

- (NSArray *)pubRelatedLinkDocuments {
  EODataSource         *ds;
  EOFetchSpecification *fspec;
  static EOQualifier   *q = nil;
  
  /* this is suspect */
  if (![[self valueForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
    return [[self parentDocument] pubTocListDocuments];
  
  if ((ds = [self pubChildDataSource]) == nil)
    return nil;
  
  if (q == nil) {
    q = [EOQualifier qualifierWithQualifierFormat:
                       @"NSFileType='NSFileTypeSymbolicLink'"];
    RETAIN(q);
  }
  fspec = [EOFetchSpecification fetchSpecificationWithEntityName:
                                  [self pubPath]
                                qualifier:q
                                sortOrderings:nil];
  
  [ds setFetchSpecification:fspec];
  
  return [ds fetchObjects];
}

- (NSArray *)pubFolderDocumentsToRoot {
  NSMutableArray *array;
  SkyDocument    *doc;
  NSArray        *result;
  
  array = [[NSMutableArray alloc] initWithCapacity:16];
  
  if ([[self valueForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
    [array addObject:self];
  
  for (doc = self; (doc = [doc parentDocument]);)
    [array addObject:doc];

  result = [array copy];
  [array release];
  return [result autorelease];
}

@end /* SkyDocument(Pub) */
