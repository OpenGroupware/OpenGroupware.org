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

#include <OGoPalmUI/SkyPalmAssignEntry.h>
#include <OGoDocuments/SkyDocumentFileManager.h>

@class NSString, NSMutableArray;

@interface SkyPalmAssignMemo : SkyPalmAssignEntry
{
  id<NSObject,SkyDocumentFileManager> fileManager;
  id       projectGID;
  id       project;
  id       privateProjects;
  id       publicProjects;
  id       files;
  BOOL     createNewFileCond;
  NSString *filename;

  // for multiple selections
  NSMutableArray *filenames;
}

- (id)projectGID;

@end /* SkyPalmAssignMemo */

#include <OGoFileSystemProject/SkyFSGlobalID.h>
#include <OGoPalm/SkyPalmEntryDataSource.h>
#include <OGoProject/OGoFileManagerFactory.h>

#include "common.h"
#include <OGoPalm/SkyPalmConstants.h>
#include <OGoPalm/SkyPalmMemoDocument.h>

@interface EODataSource(SkyDataSource)

- (id)initWithContext:(id)_ctx;
- (id)initWithContext:(id)_ctx
  folderGID:(EOGlobalID *)_fgid
  projectGID:(EOGlobalID *)_pgid
  path:(NSString *)_path
  fileManager:(id)_fm;

- (void)setFetchSpecification:(EOFetchSpecification *)_fs;

@end

@interface NSObject(SkyProjectFileManager)

- (id)initWithContext:(id)_ctx projectGlobalID:(EOGlobalID *)_gid;
- (EOGlobalID *)projectGlobalIDForDocumentGlobalID:(EOGlobalID *)_docGid
  context:(id)_ctx;

- (id)initWithGlobalID:(EOGlobalID *)_gid fileManager:(id)_fm;

- (id)createDocumentAtPath:(NSString *)_path contents:(NSData *)_contents
  attributes:(NSDictionary *)_attrs;

@end

@implementation SkyPalmAssignMemo

static EOQualifier *privateDBProjectsQualifier = nil;
static EOQualifier *commonDBProjectsQualifier  = nil;
static EOQualifier *regularFilesQualifier      = nil;
static NSArray     *nameSortOrderings          = nil;
static NSArray     *filenameSortOrderings      = nil;

+ (void)initialize {
  EOQualifier    *q;
  EOSortOrdering *so;

  /* qualifiers */
  
  q = [EOQualifier qualifierWithQualifierFormat:
		     @"type='private' AND NOT (url hasPrefix: 'file://')"];
  privateDBProjectsQualifier = [q retain];

  q = [EOQualifier qualifierWithQualifierFormat:
		     @"type='common' AND NOT (url hasPrefix: 'file://')"];
  commonDBProjectsQualifier = [q retain];

  q = [EOQualifier qualifierWithQualifierFormat:@"%@=%@",
		   NSFileType, NSFileTypeRegular];
  regularFilesQualifier = [q retain];

  /* sort orderings */
  
  so = [EOSortOrdering sortOrderingWithKey:@"name" 
		       selector:EOCompareAscending];
  nameSortOrderings = [[NSArray alloc] initWithObjects:&so count:1];

  so = [EOSortOrdering sortOrderingWithKey:@"filename" 
		       selector:EOCompareAscending];
  filenameSortOrderings = [[NSArray alloc] initWithObjects:&so count:1];
}

- (void)dealloc {
  [self->fileManager     release];
  [self->projectGID      release];
  [self->project         release];
  [self->privateProjects release];
  [self->publicProjects  release];
  [self->filename        release];
  [self->filenames       release];
  [self->files           release];
  [super dealloc];
}

/* notifications */

- (void)syncSleep {
  RELEASE(self->privateProjects); self->privateProjects = nil;
  RELEASE(self->publicProjects);  self->publicProjects  = nil;
  RELEASE(self->files);           self->files = nil;
  [super syncSleep];
}

/* accessors */

- (Class)projectFileManagerClass {
  static Class fmClass = Nil;
  if (fmClass == Nil) fmClass = NSClassFromString(@"SkyProjectFileManager");
  return fmClass;
}
- (Class)projectDataSourceClass {
  static Class dsClass = Nil;
  if (dsClass == Nil) dsClass = NSClassFromString(@"SkyProjectDataSource");
  return dsClass;
}
#if 0
- (Class)folderDataSourceClass {
  static Class dsClass = Nil;
  if (dsClass == Nil) 
    dsClass = NSClassFromString(@"SkyProjectFolderDataSource");
  return dsClass;
}
#endif

- (void)setFileManager:(id<NSObject,SkyDocumentFileManager>)_fm {
  ASSIGN(self->fileManager,_fm);
}
- (id<NSObject,SkyDocumentFileManager>)fileManager {
  if (self->fileManager == nil) {
    if ([self projectGID] != nil) {
      self->fileManager =
        [[OGoFileManagerFactory sharedFileManagerFactory]
	  fileManagerInContext:[(id)[self session] commandContext]
	  forProjectGID:[self projectGID]];
      self->fileManager = [self->fileManager retain];
    }
  }
  return self->fileManager;
}

- (void)setProjectGID:(id)_p {
  ASSIGN(self->projectGID,_p);
}
- (id)projectGID {
  id sId;
  
  if (self->projectGID != nil)
    return self->projectGID;

  if ([self skyrixRecord] == nil)
    return nil;

  sId = [(SkyPalmDocument *)[self skyrixRecord] globalID];

  // not yet supported
  //if ([sId isKindOfClass:[SkyFSGlobalID class]]) {
  //  sId = [(SkyFSGlobalID *)sId projectGID];
  //}
  //else
  if ([sId isKindOfClass:[EOKeyGlobalID class]]) {
    sId = [[self projectFileManagerClass]
	    projectGlobalIDForDocumentGlobalID:sId
	    context:[(id)[self session] commandContext]];
  }
  else {
    NSLog(@"%s: unsupported projectGID: %@",
	  __PRETTY_FUNCTION__, sId);
    sId = nil;
  }

  if (sId != nil)
    [self setProjectGID:sId];
  
  return self->projectGID;
}

#if 0
- (id)file {
  return [self skyrixRecord];
}
#endif

- (EODataSource *)_projectDS {
  EODataSource *lds;
  
  lds = [[self projectDataSourceClass] alloc];
  lds = [lds initWithContext:(id)[(id)[self session] commandContext]];
  return [lds autorelease];
}
- (EOFetchSpecification *)_projectFetchSpecForGID:(id)_gid {
  EOQualifier *qual;

  // TODO: make that a binding
  qual =
    [EOQualifier qualifierWithQualifierFormat:
                 @"projectId=%@ AND NOT (url hasPrefix: 'file://')",
                 [[_gid keyValuesArray] objectAtIndex:0]];
  return [EOFetchSpecification fetchSpecificationWithEntityName:
                               [_gid entityName]
                               qualifier:qual
                               sortOrderings:nil];
}
- (id)_fetchProject {
  EODataSource *das = nil;
  id p = nil;
  id pGID = [self projectGID];

  if (pGID == nil)
    return nil;
    
  das = [self _projectDS];
  [das setFetchSpecification:[self _projectFetchSpecForGID:pGID]];
  p   = [das fetchObjects];
  p   = [p lastObject];
  return p;
}
- (void)setProject:(id)_p {
  ASSIGN(self->project,_p);
}
- (id)project {
  if (self->project == nil) {
    if ([self projectGID] != nil) {
      [self setProject:[self _fetchProject]];
    }
  }
  return self->project;
}

- (void)setCreateNewFileCond:(BOOL)_flag {
  self->createNewFileCond = _flag;
}
- (BOOL)createNewFileCond {
  return self->createNewFileCond;
}

- (void)setFilename:(NSString *)_name {
  ASSIGN(self->filename,_name);
}
- (NSString *)filename {
  if (self->filename == nil) {
    NSString *n;

    n = [[self doc] description];
    n = [n stringByAppendingString:@".txt"];
    [self setFilename:n];
  }
  return self->filename;
}

- (NSArray *)filenames {
  return self->filenames;
}
- (void)setFilenamesItem:(NSString *)_fn {
  [self->filenames replaceObjectAtIndex:[self index] withObject:_fn];
}
- (NSString *)filenamesItem {
  return [self->filenames objectAtIndex:[self index]];
}

// overwriting
- (void)setPalmRecords:(NSMutableArray *)_palmRecs {
  NSMutableArray *fns;
  NSEnumerator   *e   = nil;
  id             one  = nil;

  fns = [NSMutableArray arrayWithCapacity:[_palmRecs count]];
  e = [_palmRecs objectEnumerator];
  while ((one = [e nextObject]) != nil) {
    NSString *n;
    
    n = [one description];
    if (![n isNotNull]) continue;
    n = [n stringByAppendingString:@".txt"];
    [fns addObject:n];
  }
  ASSIGN(self->filenames,fns);
  [super setPalmRecords:_palmRecs];
}

// wod accessors
- (BOOL)hasFile {
  if (self->createNewFileCond)
    return YES;
  return (([self skyrixRecord] != nil) || ([[self skyrixRecords] count]))
    ? YES : NO;
}
- (BOOL)listProjects {
  return ([self projectGID] == nil) ? YES : NO;
}
- (BOOL)listFiles {
  if (self->createNewFileCond)
    return NO;

  return (([self projectGID] != nil) && (![self hasFile])) ? YES : NO;
}
- (BOOL)hasProject {
  return ([self projectGID] != nil) ? YES : NO;
}

- (NSArray *)_sortOrderings {
  return nameSortOrderings;
}

- (EOFetchSpecification *)_projectFetchSpecForPrivateList {
  return [EOFetchSpecification fetchSpecificationWithEntityName:@"project"
                               qualifier:privateDBProjectsQualifier
                               sortOrderings:[self _sortOrderings]];
}
- (EOFetchSpecification *)_projectFetchSpecForPublicList {
  return [EOFetchSpecification fetchSpecificationWithEntityName:@"project"
                               qualifier:commonDBProjectsQualifier
                               sortOrderings:[self _sortOrderings]];
}
- (NSArray *)privateProjects {
  EODataSource *das;
  NSArray *ps;
  
  if (self->privateProjects != nil)
    return self->privateProjects;

  das = [self _projectDS];
  [das setFetchSpecification:[self _projectFetchSpecForPrivateList]];

  ps  = [das fetchObjects];
  self->privateProjects = [ps retain];
  return self->privateProjects;
}
- (NSArray *)publicProjects {
  EODataSource *das = nil;
  NSArray *ps  = nil;
  
  if (self->publicProjects != nil)
    return self->publicProjects;

  das = [self _projectDS];
  [das setFetchSpecification:[self _projectFetchSpecForPublicList]];

  ps = [das fetchObjects];
  self->publicProjects = [ps retain];
  return self->publicProjects;
}

- (NSString *)projectTitle {
  return [[self project] valueForKey:@"name"];
}

- (id)_folderDS {
  id<NSObject,SkyDocumentFileManager> fm;
  NSString *folder;
  
  fm     = [self fileManager];
  folder = [fm currentDirectoryPath];
  
  return [(id)fm dataSourceAtPath:folder];
}

- (NSArray *)_fileSortOrderings {
  return filenameSortOrderings; // TODO: do we need a method here?
}

- (EOFetchSpecification *)_onlyFilesFetchSpec {
  return [EOFetchSpecification fetchSpecificationWithEntityName:@"doc"
                               qualifier:regularFilesQualifier
                               sortOrderings:[self _fileSortOrderings]];
}
- (NSArray *)files {
  EODataSource *das;
  
  if (self->files != nil) return self->files;
  
  das = [self _folderDS];
  [das setFetchSpecification:[self _onlyFilesFetchSpec]];
  self->files = [[das fetchObjects] retain];
  return self->files;
}

- (BOOL)mustFileBeReadable {
  return [self createFromRecord] ? YES : NO;
}

- (NSArray *)validSyncTypes {
  NSMutableArray *all;
  
  all = [NSMutableArray arrayWithCapacity:4];
  // sync do nothing
  [all addObject:[NSNumber numberWithInt:0]];
  
  if ([[self skyrixRecord] isReadable])
    [all addObject:[NSNumber numberWithInt:1]];
  
  if ([[self skyrixRecord] isWriteable])
    [all addObject:[NSNumber numberWithInt:2]];
  
  return all;
}

// actions
- (id)selectProject {
  [self setProjectGID:[[self item] valueForKey:@"globalID"]];

  return nil;
}
- (id)selectFile {
  if ([[self item] isReadable])
    [self setSkyrixRecord:[self item]];
  else
    [self logWithFormat:@"%s File is not readable!!!", __PRETTY_FUNCTION__];

  return nil;
}
- (id)selectFiles {
  [self setSkyrixRecord:nil];
  return nil;
}
- (id)createNewFile {
  [self setCreateNewFileCond:YES];

  return nil;
}

- (id)changeProject {
  [self setProjectGID:nil];
  [self setProject:nil];
  [self setFileManager:nil];
  [self setSkyrixRecord:nil];
  [self setCreateNewFileCond:NO];
  [self setFilename:nil];
  return nil;
}
- (id)changeFile {
  [self setSkyrixRecord:nil];
  [self setCreateNewFileCond:NO];
  [self setFilename:nil];
  [self->skyrixRecords removeAllObjects];
  return nil;
}


// super class over writing
- (id)fetchSkyrixRecord {
  return [[self doc] skyrixRecord];
}

- (id)searchSkyrixRecord {
  // do nothing
  return nil;
}

- (NSString *)primarySkyKey {
  return @"documentId";
}

- (id)_newSkyrixRecordWithFilename:(NSString *)_fn palmDoc:(id)_doc {
  NSData       *contents;
  NSDictionary *attrs;
  NSString     *path;
  id f;
  
  contents = [[_doc memo] dataUsingEncoding:NSISOLatin1StringEncoding];
  path     = [[[self fileManager] currentDirectoryPath]
                     stringByAppendingPathComponent:_fn];
  attrs    = [NSDictionary dictionary];
    
  f = [(id)[self fileManager]
             createDocumentAtPath:path
             contents:contents
             attributes:attrs];
  return f;
}

- (id)save {
  if (self->createNewFileCond) {
    [self setSkyrixRecord:[self _newSkyrixRecordWithFilename:self->filename
                                palmDoc:[self doc]]];
    [self setSyncType:SYNC_TYPE_PALM_OVER_SKY];
  }
  return [super save];
}

// overwriting // TODO: explain the comment!
- (SkyPalmMemoDocument *)newPalmDoc {
  return (SkyPalmMemoDocument *)[[self dataSource] newDocument];
}

- (id)newSkyrixRecordForPalmDoc:(SkyPalmDocument *)_doc {
  int      idx;
  NSString *fn;
  
  idx = [self->palmRecords indexOfObject:_doc];
  fn  = [self->filenames objectAtIndex:idx];
  return [self _newSkyrixRecordWithFilename:fn palmDoc:_doc];
}

@end /* SkyPalmAssignMemo */
