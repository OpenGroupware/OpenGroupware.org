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

#include "SkyProjectFolderDataSource.h"
#include <NGExtensions/NGExtensions.h>
#include <NGExtensions/EOQualifier+CtxEval.h>
#include "common.h"
#include "SkyProjectDocument.h"
#include "SkyProjectFileManager.h"
#include "SkySimpleProjectFolderDataSource.h"

static inline BOOL _showUnknownFiles(id self) {
  static BOOL showUnknownFiles_value = NO;
  static BOOL showUnknownFiles_flag  = NO;
  
 if (!showUnknownFiles_flag) {
   NSUserDefaults *ud;
   
   ud = [NSUserDefaults standardUserDefaults];
   showUnknownFiles_flag  = YES;
   showUnknownFiles_value = 
     [ud boolForKey:@"SkyProjectFileManager_show_unknown_files"];
  }
  return showUnknownFiles_value;
}

@interface SkyProjectFileManager(Internals)

- (void)_checkCWDFor:(NSString *)_source;
- (id)_project;
- (NSString *)_defaultCompleteProjectDocumentNamespace;
- (NSArray *)subDirectoryNamesForPath:(NSString *)_path;
- (NSString *)_makeAbsolute:(NSString *)_path;
- (void)_subpathsAtPath:(NSString *)_path array:(NSMutableArray *)_array;
- (BOOL)_copyPath:(NSString*)_src toPath:(NSString*)_dest handler:(id)_handler;

- (BOOL)moveDir:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_dirName
  extension:(NSString *)_dirExt
  handler:(id)_handleru;

- (BOOL)moveLink:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_linkName
  extension:(NSString *)_linkExt
  handler:(id)_handler;

- (BOOL)moveFile:(EOGenericRecord *)_srcGen
  toPath:(EOGenericRecord *)_destGen
  name:(NSString *)_fileName
  extension:(NSString *)_fileExt
 handler:(id)_handler;

@end /* SkyProjectFileManager(Internals) */

@interface SkyProjectFileManager(Extensions_Internals)
- (NSArray *)searchChildsForFolder:(NSString *)_path
  deep:(BOOL)_deep
  qualifier:(EOQualifier *)_qualifier;
@end /* SkyProjectFileManager(Extensions_Internals) */

@interface SkyProjectFileManager(Documents_Internals)
- (NSArray *)readOnlyDocumentKeys;
- (NSArray *)documentsForObjects:(NSArray *)_objs
  withAttributes:(NSArray *)_attrs;
@end /* SkyProjectFileManager(Documents_Internals) */

@interface SkyProjectDocument(Internals)
- (void)_setFileAttributes:(NSDictionary *)_attrs;
- (void)setDataSource:(SkyProjectFolderDataSource *)_ds;
@end /* SkyProjectDocument(Internals) */

@interface NSObject(Private)
- (EOGlobalID *)globalID;
@end /* NSObject(Private) */

#include "SkyProjectFileManager.h"


@interface SkyProjectFolderDataSource(Internals)
- (void)_unvalidate:(id)_obj;
- (SkyProjectFileManager *)_fileManager;
- (EOGlobalID *)_folderGID;
- (EOGlobalID *)_projectGID;
@end /* SkyProjectFolderDataSource(Internals) */

@implementation SkyProjectFolderDataSource

- (id)init {
  NSLog(@"ERROR(%s): wrong initializer use initWithContext:"
        @"folderGID:projectGID:", __PRETTY_FUNCTION__);
  [self release];
  return nil;
}

- (id)initWithContext:(id)_ctx
  folderGID:(EOGlobalID *)_fgid
  projectGID:(EOGlobalID *)_pgid
  path:(NSString *)_path
  fileManager:(SkyProjectFileManager *)_fm
{
  if ((self = [super init])) {
    self->context     = [_ctx retain];
    self->folderGID   = [_fgid retain];
    self->projectGID  = [_pgid retain];
    self->path        = [_path copy];
    self->fileManager = [_fm retain];    
    self->isValid     = YES;
    
    NSAssert(self->fileManager, @"missing file-manager");
    NSAssert(self->folderGID,   @"missing folder global id");

    if (self->path == nil)
      self->path = [[self->fileManager pathForGlobalID:_fgid] copy];
    
    [self->fileManager registerObject:self selector:@selector(_unvalidate:)
         forUnvalidateOnPath:self->path];
    [self->fileManager registerObject:self
         selector:@selector(postDataSourceChangedNotification)
         forChangeOnPath:self->path];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->fileManager release];
  [self->path        release];
  [self->context     release];
  [self->folderGID   release];
  [self->projectGID  release];
  [self->fetchSpecification release];
  [super dealloc];
}

/* accessors */

- (BOOL)isValid {
  return self->isValid;
}

- (void)setFetchSpecification:(EOFetchSpecification *)_fspec {
  if ([self->fetchSpecification isEqual:_fspec])
    return;

  ASSIGNCOPY(self->fetchSpecification, _fspec);
  [self postDataSourceChangedNotification];
}
- (EOFetchSpecification *)fetchSpecification {
  return [[self->fetchSpecification copy] autorelease];
}

- (BOOL)isDeepFetchSpecification {
  return [[[[self fetchSpecification] hints] objectForKey:@"fetchDeep"] 
	   boolValue];;
}

/* fetching */

- (NSArray *)_sortObjects:(NSArray *)objects {
  NSArray *so = nil;
    
  if ((so = [self->fetchSpecification sortOrderings]) == nil)
    return objects;
  
  return [objects sortedArrayUsingKeyOrderArray:so];
}

- (void)_registerForNotifications:(NSArray *)objects 
  name:(NSString *)attrNotify
{
  NSNotificationCenter *nc;
  NSEnumerator *enumerator;
  id           obj;
  
  nc = [NSNotificationCenter defaultCenter];

  enumerator = [objects objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil) {
    // TODO: possibly a notification bug      
      
    [nc addObserver:self
	selector:@selector(postDataSourceChangedNotification)
	name:attrNotify object:[obj globalID]];
  }
}

- (NSArray *)_fetchWithSimpleDataSource {
  SkyAttributeDataSource           *ads;
  SkySimpleProjectFolderDataSource *sds;
  EOFetchSpecification             *fs;
  NSDictionary *hints;
  NSString     *resStr;
  EOEntity     *docEnt;
  EOAttribute  *attr;
  NSArray      *dsAttrs;
  EOQualifier  *qualifier;
  
  qualifier = [self->fetchSpecification qualifier];
  
  sds = [[SkySimpleProjectFolderDataSource alloc]
	  initWithFolderDataSource:self];
  ads = [[SkyAttributeDataSource alloc] initWithDataSource:sds
					context:self->context];
  fs  = [[EOFetchSpecification alloc] initWithEntityName:@"Doc"
				      qualifier:qualifier sortOrderings:nil
				      usesDistinct:YES isDeep:NO hints:nil];

  docEnt = [[self->context valueForKey:LSDatabaseKey] entityNamed:@"Doc"];

  if ([self isDeepFetchSpecification]) {
    attr   = [docEnt attributeNamed:@"projectId"];
    resStr = [NSString stringWithFormat:@"%@ = %@",
                           [attr columnName],
                           [(id)self->projectGID keyValues][0]];
  }
  else {
    attr   = [docEnt attributeNamed:@"parentDocumentId"];
    resStr = [NSString stringWithFormat:@"%@ = %@",
                           [attr columnName],
                           [(id)self->folderGID keyValues][0]];
  }
  hints  = [NSDictionary dictionaryWithObjectsAndKeys:
			   resStr, @"restrictionQualifierString",
                           [NSNumber numberWithBool:
				       [self isDeepFetchSpecification]], 
			   @"fetchDeep",
                           @"Doc", @"restrictionEntityName", nil];

  [fs setHints:hints];

  [ads setFetchSpecification:fs];
  [ads setDefaultNamespace:
         [self->fileManager defaultProjectDocumentNamespace]];
  [ads setDbKeys:[self->fileManager readOnlyDocumentKeys]];
  /*
      SkyProjectFolderDataSource needs only globals ids, therefore it does 
      not need to -verifyIds
  */
    
  dsAttrs = [ads fetchObjects];
    
  [fs  release]; fs  = nil;
  [ads release]; ads = nil;
  [sds release]; sds = nil;

  return dsAttrs;
}

- (NSArray *)_fetchDocumentsForObjects:(NSArray *)dsAttrs {
  NSArray *fetchKeys;
  NSArray *ns;
    
  fetchKeys = [[self->fetchSpecification hints] objectForKey:@"fetchKeys"];
  if (fetchKeys != nil) {
    return [self->fileManager documentsForObjects:dsAttrs
		withAttributes:fetchKeys];
  }
  
  ns = [NSArray arrayWithObject:
		  [self->fileManager defaultProjectDocumentNamespace]];
  return [self->fileManager documentsForObjects:dsAttrs withAttributes:ns];
}

- (NSArray *)_applyFetchLimit:(NSArray *)objects {
  unsigned fetchLimit;
    
  if ((fetchLimit = [self->fetchSpecification fetchLimit]) == 0)
    return objects;

  if ([objects count] <= fetchLimit)
    return objects;
  
  [self logWithFormat:@"%@: fetch limit reached (limit=%d, count=%d)",
              self, fetchLimit, [objects count]];
  return [objects subarrayWithRange:NSMakeRange(0, fetchLimit)];
}

- (NSArray *)_fetchObjects {
  NSString              *attrNotify;
  NSArray               *dsAttrs, *objects;
  EOQualifier           *qualifier;
  NSNotificationCenter  *nc;
  BOOL                  fetchDeep;
  
  fetchDeep  = [self isDeepFetchSpecification];
  nc         = [NSNotificationCenter defaultCenter];
  attrNotify = [[self->context propertyManager]
                               modifyPropertiesForGIDNotificationName];
  if (fetchDeep) {
    if (![self->path isEqualToString:@"/"]) {
      // TODO: avoid raising exceptions
      [NSException raise:NSInvalidArgumentException
		   format:@"fetchdeep is only allowed on root folders"];
    }
  }
  
  [nc removeObserver:self name:attrNotify object:nil];

  qualifier = [self->fetchSpecification qualifier];

  if ([SkyProjectFileManager supportQualifier:qualifier]) {
    NSString *folder;

    folder  = self->path;
    dsAttrs = [self->fileManager searchChildsForFolder:folder
                   deep:fetchDeep qualifier:qualifier];
  }
  else
    dsAttrs = [self _fetchWithSimpleDataSource];
  
  objects = [self _fetchDocumentsForObjects:dsAttrs];
  objects = [self _applyFetchLimit:objects];
  objects = [self _sortObjects:objects];
  
  [self _registerForNotifications:objects name:attrNotify];
  return objects;
}

- (NSArray *)fetchObjects {
  NSAutoreleasePool *pool;
  NSArray      *result, *sortOrderings;
  NSDictionary *hints;
  
  if (!self->isValid) {
    NSLog(@"WARNING[%s]: fetch from invalid FolderDataSource %@",
          __PRETTY_FUNCTION__, self);
    return nil;
  }

  hints = [self->fetchSpecification hints];
  pool  = [[NSAutoreleasePool alloc] init];
  
  if ([self->fetchSpecification qualifier] == nil) {
    if ([[hints objectForKey:EONoFetchWithEmptyQualifierHint] boolValue]) {
      [pool release];
      return [NSArray array];
    }
  }
  if ([[[self->fetchSpecification hints] objectForKey:@"onlySubFolderNames"]
                                  boolValue]) {
    result = [self->fileManager subDirectoryNamesForPath:self->path];
  }
  else {
    if (![self->fileManager isReadableFileAtPath:self->path])
      result = [NSArray array];
    else {
      //    [self->fileManager flush];
      result = [self _fetchObjects];
    }
  }
  if ((sortOrderings = [self->fetchSpecification sortOrderings])) {
    result = [result sortedArrayUsingKeyOrderArray:sortOrderings];
  }

  if (!_showUnknownFiles(self)) {
    NSEnumerator   *enumerator;
    NSMutableArray *array;
    id             obj;

    array = [NSMutableArray arrayWithCapacity:[result count]];

    enumerator = [result objectEnumerator];

    while ((obj = [enumerator nextObject])) {
      if (![[obj valueForKey:NSFileType] isEqualToString:NSFileTypeUnknown])
        [array addObject:obj];
    }
    result = array;
  }
  result = [result shallowCopy];
  [pool release];
  return [result autorelease];
}

/* modification operations */

- (id)createObject {
  SkyProjectDocument *doc = nil;
  
  doc = [[SkyProjectDocument alloc] initWithGlobalID:nil
                                    fileManager:self->fileManager];
  [doc setDataSource:self];
  //hh?? using this save does not work ...:
  /// [doc takeValue:self->path forKey:NSFilePath];
  return [doc autorelease];
}

- (void)insertObject:(id)_obj {
  if (![_obj isKindOfClass:[SkyProjectDocument class]])
    return;

  [(SkyProjectDocument *)_obj setDataSource:self];
  [_obj save];
  [self postDataSourceChangedNotification];
}

- (void)deleteObject:(id)_obj {
  [self->fileManager deleteDocument:_obj];
  [self postDataSourceChangedNotification];
}

- (void)updateObject:(id)_obj {
  [self->fileManager updateDocument:_obj];
  [self postDataSourceChangedNotification];
}

/* description */

- (void)appendAttributesToDescription:(NSMutableString *)ms {
  if (self->context)     [ms appendFormat:@" ctx=0x%08X", self->context];
  if (self->projectGID)  [ms appendFormat:@" pgid=%@", self->projectGID];
  if (self->folderGID)   [ms appendFormat:@" fgid=%@", self->folderGID];
  if (self->path)        [ms appendFormat:@" path='%@'", self->path];
  if (!self->isValid)    [ms appendString:@" INVALID"];
  if (self->fileManager) [ms appendFormat:@" fm=%@", self->fileManager];
}
- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:128];
  [ms appendFormat:@"<0x%08X[%@]:", self, NSStringFromClass([self class])];
  [self appendAttributesToDescription:ms];
  [ms appendString:@">"];
  return ms;
}

/* Internals */

- (void)_unvalidate:(id)_obj {
  self->isValid = NO;
  [self postDataSourceChangedNotification];
}

- (SkyProjectFileManager *)_fileManager {
  return self->fileManager;
}

- (EOGlobalID *)_folderGID {
  return self->folderGID;
}

- (EOGlobalID *)_projectGID {
  return self->projectGID;
}

- (NSString *)path {
  return self->path;
}

@end /* SkyProjectFolderDataSource */
