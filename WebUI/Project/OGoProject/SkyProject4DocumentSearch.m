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

/*
  SkyProject4DocumentSearch

  TODO: document what it does, what parameters it takes.
*/

@class NSString, NSMutableDictionary;
@class EOGlobalID, EOFetchSpecification, EOGlobalID;

@interface SkyProject4DocumentSearch : OGoComponent
{
  EOGlobalID          *projectId;
  NSMutableDictionary *bindings;
  NSString            *fsname;
  EOGlobalID          *fsgid;
  id                  dataSource;
  id                  fileManager;
  id                  currentFile;
}

- (EOFetchSpecification *)fetchSpecification;

@end

#include "common.h"

@implementation SkyProject4DocumentSearch

- (id)init {
  if ((self = [super init])) {
    self->bindings = [[NSMutableDictionary alloc] initWithCapacity:8];
  }
  return self;
}

- (void)dealloc {
  [self->fileManager release];
  [self->currentFile release];
  [self->dataSource  release];
  [self->bindings    release];
  [self->projectId   release];
  [self->fsname      release];
  [self->fsgid       release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self->currentFile release]; self->currentFile = nil;
  [super sleep];
}

/* accessors */

- (void)setFileManager:(id)_fm {
  ASSIGN(self->fileManager, _fm);
}
- (id)fileManager {
  return self->fileManager;
}

- (void)setProjectId:(EOGlobalID *)_gid {
  if (![self->projectId isEqual:_gid]) {
    ASSIGN(self->projectId, _gid);
    
    [self->dataSource release]; self->dataSource = nil;

    if (self->fileManager == nil) {
      self->fileManager =
        [OGoFileManagerFactory fileManagerInContext:
				 [[self session] commandContext]
                               forProjectGID:_gid];
    }
    self->dataSource =
      [[self->fileManager dataSourceForDocumentSearchAtPath:@"/"] retain];
    
    [self->dataSource setFetchSpecification:[self fetchSpecification]];
  }
}
- (EOGlobalID *)projectId {
  return self->projectId;
}

- (id)dataSource {
  [self->dataSource setFetchSpecification:[self fetchSpecification]];
  return self->dataSource;
}

- (void)setCurrentFile:(id)_file {
  ASSIGN(self->currentFile, _file);
}
- (id)currentFile {
  return self->currentFile;
}

- (NSString *)linkHref {
  NSString *linkPath;

  linkPath = [[self currentFile] valueForKey:NSFilePath];

  return [self->fileManager pathContentOfSymbolicLinkAtPath:linkPath];
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
  linkTarget = [self->fileManager
		    pathContentOfSymbolicLinkAtPath:linkPath];

  if ([self->fileManager fileExistsAtPath:linkTarget isDirectory:NULL])
    return NO;
  /* old style link */
  if ([linkTarget hasPrefix:@"/Skyrix/wa/LSWViewAction/view"])
    return NO;
  
  if ([NSURL URLWithString:linkTarget] != nil)
    return YES;
  
  return NO;
}

- (BOOL)currentFileIsCheckedOut {
  NSString *path;
  
  if ((path = [self->currentFile valueForKey:NSFilePath]) == nil)
    return NO;
  
  if (![self->fileManager supportsVersioningAtPath:path])
    return NO;
  
  return [self->fileManager isFileLockedAtPath:path];
}

- (BOOL)currentFileIsLocked {
  NSString *path;
  
  if ((path = [self->currentFile valueForKey:NSFilePath]) == nil)
    return NO;
  
  if ([self->fileManager supportsVersioningAtPath:path])
    return NO;
  if (![self->fileManager supportsLockingAtPath:path])
    return NO;

  return [self->fileManager isFileLockedAtPath:path];
}

- (BOOL)isCurrentFileFolder {
  return [[[self currentFile]
                 valueForKey:NSFileType]
                 isEqualToString:NSFileTypeDirectory];
}

- (NSString *)currentFileParentFolder {
  return [[[self currentFile]
                 valueForKey:@"NSFilePath"]
                 stringByDeletingLastPathComponent];
}

- (NSString *)fileSystemName {
  if (self->fsname == nil) {
    self->fsname = [[[self->fileManager fileSystemAttributesAtPath:@"/"]
                                        objectForKey:@"NSFileSystemName"]
                                        copy];
  }
  return self->fsname;
}

- (EOGlobalID *)fileSystemNumber {
  if (self->fsgid == nil) {
    self->fsgid = [[[self->fileManager fileSystemAttributesAtPath:@"/"]
                           objectForKey:@"NSFileSystemNumber"]
                           retain];
  }
  return self->fsgid;
}


- (NSString *)fileLinkName {
  NSString *fname;
  NSString *mType;

  fname = [self->currentFile valueForKey:@"NSFileName"];
  mType = [[self->currentFile valueForKey:@"NSFileMimeType"] stringValue];
  
  if ([mType isEqualToString:@"x-skyrix/filemanager-link"]) {
    NSArray *comps = [fname componentsSeparatedByString:@"."];
    
    return ([comps count]) ? [comps objectAtIndex:0] : fname;
  }
  return fname;
}

- (NSMutableDictionary *)bindings {
  return self->bindings;
}

- (BOOL)isAndSearch {
  return YES;
}

- (EOKeyValueQualifier *)qualifierForTitle {
  EOQualifier *q;
  NSString *s;
  NSRange  r;

  if ([(s = [self->bindings objectForKey:@"title"]) length] == 0)
    return nil;

  r = [s rangeOfString:@"*"];
  if (r.length == 0)
    s  = [[@"*" stringByAppendingString:s] stringByAppendingString:@"*"];

  q = [[EOKeyValueQualifier alloc]
	initWithKey:@"NSFileSubject" 
	operatorSelector:EOQualifierOperatorCaseInsensitiveLike 
	value:s];
  return [q autorelease];
}
- (EOQualifier *)qualifierForFileName {
  EOQualifier *q;
  NSRange  r;
  NSString *s;

  if ([(s = [self->bindings objectForKey:@"filename"]) length] == 0)
    return nil;

  r = [s rangeOfString:@"*"];
  if (r.length == 0)
    s = [[@"*" stringByAppendingString:s] stringByAppendingString:@"*"];
   
  r = [s rangeOfString:@"."];
  if (r.length == 0)
    s  = [s stringByAppendingString:@".*"];
  
  q = [[EOKeyValueQualifier alloc]
	initWithKey:@"NSFileName"
	operatorSelector:EOQualifierOperatorCaseInsensitiveLike
	value:s];
  return [q autorelease];
}
- (EOQualifier *)qualifierForExtension {
  EOQualifier *q;
  NSString *s;
  
  if ([(s = [self->bindings objectForKey:@"extension"]) length] == 0)
    return nil;

  s = [@"*." stringByAppendingString:s];
  
  q = [[EOKeyValueQualifier alloc]
	initWithKey:@"NSFileName"
	operatorSelector:EOQualifierOperatorCaseInsensitiveLike
	value:s];
  return [q autorelease];
}

- (EOQualifier *)qualifier {
  // TODO: split up method
  NSMutableArray *qualifiers;
  EOQualifier *q;
  
  qualifiers = [NSMutableArray arrayWithCapacity:4];
  
  if ((q = [self qualifierForTitle]) != nil)
    [qualifiers addObject:q];
  if ((q = [self qualifierForFileName]) != nil)
    [qualifiers addObject:q];
  if ((q = [self qualifierForExtension]) != nil)
    [qualifiers addObject:q];
  
  if ([qualifiers count] == 0)
    return nil;
  
  if ([qualifiers count] == 1)
    return [qualifiers objectAtIndex:0];
  
  q = ([self isAndSearch])
    ? [[EOAndQualifier alloc] initWithQualifierArray:qualifiers]
    : [[EOOrQualifier  alloc] initWithQualifierArray:qualifiers];
  return [q autorelease];
}

- (EOFetchSpecification *)fetchSpecification {
  EOFetchSpecification *fspec;
  NSMutableDictionary  *hints;
  
  fspec = [EOFetchSpecification fetchSpecificationWithEntityName:nil
                                qualifier:[self qualifier]
                                sortOrderings:nil];
  
  hints = [NSMutableDictionary dictionaryWithObject:
				 [NSNumber numberWithBool:YES]
                               forKey:EONoFetchWithEmptyQualifierHint];
  [hints setObject:[NSNumber numberWithBool:YES] forKey:@"fetchDeep"];
  
  [fspec setHints:hints];
  
  return fspec;
}

/* actions */

- (id)search {
  EOFetchSpecification *fspec;
  
  fspec = [self fetchSpecification];
  [[self dataSource] setFetchSpecification:fspec];
  return nil;
}

- (id)clickedFile {
  EOGlobalID *gid;
  
  gid = [[self currentFile] valueForKey:@"globalID"];
  
  return [gid isKindOfClass:[EOKeyGlobalID class]]
    ? [self activateObject:gid withVerb:@"view"]
    : [self activateObject:[self currentFile] withVerb:@"view"];
}

@end /* SkyProject4DocumentSearch */
