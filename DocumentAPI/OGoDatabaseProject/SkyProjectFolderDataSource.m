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

@interface SkySimpleProjectFolderDataSource : EODataSource
{
@protected
  SkyProjectFolderDataSource *source;
  EOFetchSpecification       *fetchSpecification;
}
@end

@implementation SkySimpleProjectFolderDataSource

- (id)initWithFolderDataSource:(SkyProjectFolderDataSource *)_ds {
  if ((self = [super init])) {
    ASSIGN(self->source, _ds);
    self->fetchSpecification = nil;
  }
  return self;
}

- (void)dealloc {
  [self->source             release];
  [self->fetchSpecification release];
  [super dealloc];
}

/* accessors */

- (void)setFetchSpecification:(EOFetchSpecification *)_fs {
  if ([_fs isEqual:self->fetchSpecification])
    return;
  
  ASSIGNCOPY(self->fetchSpecification, _fs);
  [self postDataSourceChangedNotification];
}
- (EOFetchSpecification *)fetchSpecification {
  return self->fetchSpecification;
}

/* fetching */

- (NSArray *)fetchObjects {
  NSAutoreleasePool     *pool;
  NSArray               *result;
  NSString              *folder;
  BOOL                  fetchDeep;
  SkyProjectFileManager *fileManager;
  EOQualifier           *qual;
  unsigned fetchLimit;

  pool = [[NSAutoreleasePool alloc] init];
  
  fetchLimit = [self->fetchSpecification fetchLimit];
  
  fileManager = [self->source _fileManager];
  qual        = [self->fetchSpecification qualifier];
  folder      = [fileManager pathForGlobalID:[source _folderGID]];
  
  fetchDeep   = [[[self->fetchSpecification hints] objectForKey:@"fetchDeep"]
                                            boolValue];
  
  result      = [fileManager searchChildsForFolder:folder
                             deep:fetchDeep
                             qualifier:[self->fetchSpecification qualifier]];

  /* apply fetch limit */
  if ((fetchLimit != 0) && ([result count] > fetchLimit)) {
    NSLog(@"%@: fetch limit reached (limit=%d, count=%d)",
          self, fetchLimit, [result count]);
    
    result = [result subarrayWithRange:NSMakeRange(0, fetchLimit)];
  }
  
  /* apply sort orderings */
  {
    NSArray *so;
    
    if ((so = [self->fetchSpecification sortOrderings]) != nil)
      result = [result sortedArrayUsingKeyOrderArray:so];
  }
  
  result = [result shallowCopy];
  [pool release];
  return [result autorelease];
}

@end /* SkySimpleProjectFolderDataSource */

@implementation SkyProjectFolderDataSource

- (id)init {
  NSLog(@"ERROR[%s] wrong initializer use initWithContext:"
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
    ASSIGN(self->context,    _ctx);
    ASSIGN(self->folderGID,  _fgid);
    ASSIGN(self->projectGID, _pgid);
    ASSIGN(self->path, _path);
    ASSIGN(self->fileManager, _fm);    
    self->isValid             = YES;
    self->fetchSpecification  = nil;

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

- (EOFetchSpecification *)fetchSpecification {
  return [[self->fetchSpecification copy] autorelease];
}

- (void)setFetchSpecification:(EOFetchSpecification *)_fspec {
  if ([self->fetchSpecification isEqual:_fspec])
    return;

  ASSIGNCOPY(self->fetchSpecification, _fspec);
  [self postDataSourceChangedNotification];
}

/* actions */

- (NSArray *)_fetchObjects {
  NSString              *attrNotify;
  NSArray               *dsAttrs, *objects;
  EOQualifier           *qualifier;
  NSNotificationCenter  *nc;
  BOOL                  fetchDeep;

  fetchDeep  = [[[[self fetchSpecification] hints]
                        objectForKey:@"fetchDeep"] boolValue];
  nc         = [NSNotificationCenter defaultCenter];
  attrNotify = [[self->context propertyManager]
                               modifyPropertiesForGIDNotificationName];
  if (fetchDeep) {
    if (![self->path isEqualToString:@"/"]) {
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
  else {
    SkyAttributeDataSource           *ads;
    SkySimpleProjectFolderDataSource *sds;
    EOFetchSpecification             *fs;

    sds = [[SkySimpleProjectFolderDataSource alloc]
                                             initWithFolderDataSource:self];
    ads = [[SkyAttributeDataSource alloc] initWithDataSource:sds
                                          context:self->context];
    fs  = [[EOFetchSpecification alloc] initWithEntityName:@"Doc"
                                        qualifier:qualifier sortOrderings:nil
                                        usesDistinct:YES isDeep:NO hints:nil];
    {
      NSDictionary *hints;
      NSString     *resStr;
      EOEntity     *docEnt;
      EOAttribute  *attr;

      docEnt = [[self->context valueForKey:LSDatabaseKey] entityNamed:@"Doc"];

      if (fetchDeep) {
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
                             [NSNumber numberWithBool:fetchDeep], @"fetchDeep",
                             @"Doc", @"restrictionEntityName", nil];

      [fs setHints:hints];
    }
    [ads setFetchSpecification:fs];
    [ads setDefaultNamespace:
         [self->fileManager defaultProjectDocumentNamespace]];
    [ads setDbKeys:[self->fileManager readOnlyDocumentKeys]];
    /*
      SkyProjectFolderDataSource needs only globals ids, therefore it doesn`t need
      to -verifyIds
    */

    dsAttrs = [ads fetchObjects];
    
    [fs  release]; fs  = nil;
    [ads release]; ads = nil;
    [sds release]; sds = nil;
  }
  
  {
    NSArray *fetchKeys = nil;
    
    fetchKeys = [[self->fetchSpecification hints] objectForKey:@"fetchKeys"];
    if (fetchKeys != nil) {
      objects = [self->fileManager documentsForObjects:dsAttrs
                     withAttributes:fetchKeys];
    }
    else {
      NSArray *ns = nil;
      
      ns      = [NSArray arrayWithObject:
                         [self->fileManager defaultProjectDocumentNamespace]];
      objects = [self->fileManager documentsForObjects:dsAttrs
                                   withAttributes:ns];
    }
  }

  /* apply limit */
  {
    unsigned fetchLimit;
    
    if ((fetchLimit = [self->fetchSpecification fetchLimit]) > 0) {
      if ([objects count] > fetchLimit) {
        NSLog(@"%@: fetch limit reached (limit=%d, count=%d)",
              self, fetchLimit, [objects count]);
        
        objects = [objects subarrayWithRange:NSMakeRange(0, fetchLimit)];
      }
    }
  }
  
  /* apply sort orderings */
  {
    NSArray *so = nil;

    if ((so = [self->fetchSpecification sortOrderings]) != nil)
      objects = [objects sortedArrayUsingKeyOrderArray:so];
  }
  
  { /* register for notifications */
    NSEnumerator *enumerator = nil;
    id           obj         = nil;

    enumerator = [objects objectEnumerator];
    while ((obj = [enumerator nextObject])) {
      // TODO: possibly a notification bug      
      
      [nc addObserver:self
          selector:@selector(postDataSourceChangedNotification)
          name:attrNotify object:[obj globalID]];
    }
  }
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

- (id)createObject {
  SkyProjectDocument *doc = nil;
  
  doc = [[SkyProjectDocument alloc] initWithGlobalID:nil
                                    fileManager:self->fileManager];
  [doc setDataSource:self];
  //hh?? dann geht speichern nicht ...:
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

- (NSString *)description {
  NSMutableString *ms;

  ms = [NSMutableString stringWithCapacity:128];
  [ms appendFormat:@"<0x%08X[%@]:", self, NSStringFromClass([self class])];
  if (self->context)     [ms appendFormat:@" ctx=0x%08X", self->context];
  if (self->projectGID)  [ms appendFormat:@" pgid=%@", self->projectGID];
  if (self->folderGID)   [ms appendFormat:@" fgid=%@", self->folderGID];
  if (self->path)        [ms appendFormat:@" path='%@'", self->path];
  if (!self->isValid)    [ms appendString:@" INVALID"];
  if (self->fileManager) [ms appendFormat:@" fm=%@", self->fileManager];
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

@end /* Internals */
