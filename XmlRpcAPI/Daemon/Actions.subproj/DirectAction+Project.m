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

#include <EOControl/EOControl.h>
#include <OGoProject/SkyProject.h>
#include "DirectAction.h"
#include "EOControl+XmlRpcDirectAction.h"
#include "NSObject+EKVC.h"
#include "Session.h"
#include "common.h"

#include <OGoProject/SkyProjectDataSource.h>
#include <OGoDatabaseProject/SkyProjectFileManager.h>
#include "NGFileManagerZipTool+Project.h"

// TODO: this source needs serious cleanups
//       - eg most fileops are always loops over the parameters ...

@implementation DirectAction(Project)

- (void)_takeValuesDict:(NSDictionary *)_from
  toProject:(SkyProject **)_to
{
  /* TODO: why do we have a ptr to a ptr here? hh */
  [*_to takeValuesFromObject:_from
        keys:@"ownerId",
             @"teamId",
             @"name",
             @"number",
             @"startDate",
             @"endDate",
             @"status",
             @"kind",
             @"url",
             @"comment",
          nil];
}

- (id)_projectForProjectCode:(NSString *)_code {
  // TODO: we could support NSNumber projectIDs? (primary keys)
  EOFetchSpecification *fspec     = nil;
  EOQualifier          *qualifier = nil;
  NSArray              *projects  = nil;
  id                   pds        = nil;
  NSDictionary         *hints;

  qualifier = [EOQualifier qualifierWithQualifierFormat:@"number=%@",
                           _code];

  hints = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                        forKey:@"SearchAllProjects"];
  fspec = [[EOFetchSpecification alloc] initWithEntityName:nil
                                        qualifier:qualifier
                                        sortOrderings:nil
                                        usesDistinct:YES isDeep:NO 
					hints:hints];
  pds = [self projectDataSource];
  [pds setFetchSpecification:fspec];
  [fspec release]; fspec = nil;
  
  projects = [pds fetchObjects];
  
  if ([projects count] == 1)
    return [projects objectAtIndex:0];
  
  if ([projects count] > 1) {
    [self logWithFormat:@"Note: more than one result for project code, "
	    @"returning nothing: %@", _code];
    return nil;
  }
  
  return nil;
}

/* faults */

- (id)_missingFileManagerForProjectIDFault:(id)_pid {
  NSString     *r;
  NSDictionary *ui = nil;
  
  r = [_pid isNotNull]
    ? [NSString stringWithFormat:@"Unknown project ID: %@", _pid]
    : @"Invalid project ID";
  return [NSException exceptionWithName:@"InvalidProjectID"
		      reason:r userInfo:ui];
}

- (id)_projectMethodTooManyArgumentsFault {
  return [NSException exceptionWithName:@"TooManyArguments"
		      reason:@"too many arguments for method!"
		      userInfo:nil];
}

/* methods */

- (NSArray *)project_fetchAction:(id)_arg {
  EOFetchSpecification *fspec;
  EODataSource         *projectDS;
  
  projectDS = [self projectDataSource];
  fspec = [[[EOFetchSpecification alloc] initWithBaseValue:_arg] autorelease];
  [fspec setEntityName:@"Project"];

  [projectDS setFetchSpecification:fspec];
  
  return [projectDS fetchObjects];
}

- (id)project_addAccountAction:(NSString *)_projectID
                              :(NSString *)_login
                              :(NSString *)_rights
{
  // TODO: we could support NSNumber projectIDs? (primary keys)
  LSCommandContext *ctx;

  if ((ctx = [self commandContext]) != nil) {
    id owner;
    id project = nil;
    id account = nil;
    id loginGID = nil;
    NSNumber *uid;
    
    project = [self _projectForProjectCode:_projectID];
    
    if (project == nil) {
      [self logWithFormat:@"ERROR: no project for code '%@' found",
            _projectID];
      return [NSNumber numberWithBool:NO];
    }

    owner = [ctx runCommand:@"project::get-owner",
                 @"project", project,
                 nil];

    loginGID = [[[[self session]
                        commandContext]
                        valueForKey:LSAccountKey]
                        globalID];

    uid = [[loginGID keyValuesArray] objectAtIndex:0];
    
    if (![self isCurrentUserRoot] &&
        ![loginGID isEqual:[[project valueForKey:@"leader"] globalID]])
    {
      NSLog(@"ERROR: Only the project leader is allowed to add accounts");
      return [NSNumber numberWithBool:NO];
    }
    
    account = [ctx runCommand:@"account::get-by-login",
                   @"login", _login,
                   nil];

    if (account == nil) {
      [self logWithFormat:@"ERROR: no account matching login '%@' found",
            _login];
      return [NSNumber numberWithBool:NO];
    }

    [account setObject:_rights forKey:@"accessRight"];

    [ctx runCommand:@"project::assign-accounts",
         @"project", project,
         @"companies",[NSArray arrayWithObject:account],
         @"hasAccess",[NSNumber numberWithBool:YES],
         nil];

    return [NSNumber numberWithBool:YES];
  }
  return [NSNumber numberWithBool:NO];
}

- (id)project_getAccountsAction:(id)_projectID {
  id ctx;

  if ((ctx = [self commandContext]) != nil) {
    id project = nil;
    
    project = [self _projectForProjectCode:_projectID];
    
    if (project == nil) {
      [self logWithFormat:@"ERROR: no project for code '%@' found",
            _projectID];
      return [NSNumber numberWithBool:NO];
    }

    return [ctx runCommand:@"project::get-accounts",
                @"project", project,
                nil];
  }
  return [NSNumber numberWithBool:NO];
}

- (id)project_insertAction:(id)_arg {
  EODataSource *projectDS;
  SkyProject   *project   = nil;
 
  projectDS = [self projectDataSource];
  
  project = [projectDS createObject];
  NSAssert(project, @"couldn't create project");
  
  [self _takeValuesDict:_arg toProject:&project];

  [projectDS insertObject:project];
  
  return project;
}

- (id)project_updateAction:(id)_arg {
  SkyProject *project = nil;

  project = (SkyProject *)[self getDocumentByArgument:_arg];
  if (project) {
    [self _takeValuesDict:_arg toProject:&project];
    [[self projectDataSource] updateObject:project];
  }
  return project;
}

- (id)project_deleteAction:(id)_arg {
  SkyProject *project = nil;

  project = (SkyProject *)[self getDocumentByArgument:_arg];
  
  if (project) [[self projectDataSource] deleteObject:project];

  return nil;
}

- (NSData *)_dataForContent:(id)_cont {
  if (_cont == nil) {
    _cont = [[[NSData alloc] init] autorelease];
  }
  else if (![_cont isKindOfClass:[NSData class]]) {
    _cont = [_cont stringValue];
    _cont = [_cont dataUsingEncoding:[NSString defaultCStringEncoding]];
  }
  return _cont;
}

- (id)project_newDocumentAction:(id)_pid:(id)_path:(id)_cont:(id)_at { 
  NSException *ex;
  id   fm;
  BOOL ok;
  
  if ((fm = [self fileManagerForCode:_pid]) == nil)
    return [self _missingFileManagerForProjectIDFault:_pid];

  _cont = [self _dataForContent:_cont];
  if ([fm respondsToSelector:
	    @selector(createDocumentAtPath:contents:attributes:)]) {
    ok = [fm createDocumentAtPath:[_path stringValue] 
	     contents:_cont attributes:_at] ? YES : NO;
    if (!ok && ((ex = [fm lastException]) != nil))
      return ex;
  }
  else if ([fm respondsToSelector:
		 @selector(createFileAtPath:contents:attributes:)]) {
    ok = [fm createFileAtPath:[_path stringValue] 
	     contents:_cont attributes:_at] ? YES : NO;
    if (!ok && ((ex = [fm lastException]) != nil))
      return ex;
  }
  else {
    return [NSException exceptionWithName:@"UnsupportedOperation"
			reason:@"file manager does not suport file creation"
			userInfo:nil];
  }
  
  return [NSNumber numberWithBool:ok];
}

- (NSString *)project_loadDocumentAction:(id)_pid:(NSString *)_path {
  /* Note: this really does not use the <base64> type of XML-RPC! */
  id fm;
  
  if ((fm = [self fileManagerForCode:_pid]) == nil)
    return [self _missingFileManagerForProjectIDFault:_pid];
  
  return [[fm contentsAtPath:[_path stringValue]] stringByEncodingBase64];
}

- (NSNumber *)project_saveDocumentAction:(id)_pid:(NSString *)_path:(id)_cont {
  id   fm;
  BOOL ok;
  
  if ((fm = [self fileManagerForCode:_pid]) == nil)
    return [self _missingFileManagerForProjectIDFault:_pid];
  
  _cont = [self _dataForContent:_cont];
  ok = [fm writeContents:_cont atPath:[_path stringValue] handler:nil];
  return [NSNumber numberWithBool:ok];
}

- (NSString *)project_cwdAction:(id)_pid {
  id fm;

  if ((fm = [self fileManagerForCode:_pid]) == nil)
    return [self _missingFileManagerForProjectIDFault:_pid];
  
  return [fm currentDirectoryPath];
}

- (NSNumber *)project_cdAction:(id)_pid:(NSString *)_path {
  id fm;

  if ((fm = [self fileManagerForCode:_pid]) == nil)
    return [self _missingFileManagerForProjectIDFault:_pid];
  
  return [NSNumber numberWithBool:
		     [fm changeCurrentDirectoryPath:[_path stringValue]]]; 
}

- (id)project_lsAction:(id)_pid:(id)_args {
  NSMutableDictionary   *dict;
  SkyProjectFileManager *fileManager;
  id       fm;
  unsigned i, count;
  
  if ((fm = [self fileManagerForCode:_pid]) == nil)
    return [self _missingFileManagerForProjectIDFault:_pid];
  
  if ([_args isKindOfClass:[NSString class]])
    _args = [NSArray arrayWithObject:_args];
  
  if ((count = [_args count]) == 0)
    return [fm directoryContentsAtPath:@"."];
  
  if (count == 1)
    return [fm directoryContentsAtPath:[[_args objectAtIndex:0] stringValue]];
  
  fileManager = fm;
  dict = [NSMutableDictionary dictionaryWithCapacity:count];
  for (i = 0; i < count; i++) {
      NSString *path;
      NSArray  *contents;

      path = [_args objectAtIndex:i];
      contents = [fileManager directoryContentsAtPath:path];

      if (contents)
        [dict setObject:contents forKey:path];
  }
  return dict;
}

- (NSNumber *)project_mkdirAction:(id)_pid:(NSArray *)_args {
  SkyProjectFileManager *fileManager;
  unsigned i, count;

  if ([_args isKindOfClass:[NSString class]])
    _args = [NSArray arrayWithObject:_args];
  
  if ((count = [_args count]) == 0)
    return [NSNumber numberWithBool:NO];
  
  if ((fileManager = [self fileManagerForCode:_pid]) == nil)
    return [self _missingFileManagerForProjectIDFault:_pid];
  
  for (i = 0; i < count; i++) {
    NSString *path;
    
    path = [_args objectAtIndex:i];
    if (![fileManager createDirectoryAtPath:path attributes:nil])
      return [NSNumber numberWithBool:NO];
  }
  return [NSNumber numberWithBool:YES];
}

- (NSNumber *)project_rmdirAction:(id)_pid:(NSArray *)_args {
  SkyProjectFileManager *fileManager;
  unsigned i;
  unsigned count;

  if ((count = [_args count]) == 0)
    return [NSNumber numberWithBool:NO];

  if ((fileManager = [self fileManagerForCode:_pid]) == nil)
    return [self _missingFileManagerForProjectIDFault:_pid];
  
  for (i = 0; i < count; i++) {
      NSString *path;
      BOOL isDir;

      path = [_args objectAtIndex:i];

      if (![fileManager fileExistsAtPath:path isDirectory:&isDir])
        return [NSNumber numberWithBool:NO];

      if (!isDir)
        return [NSNumber numberWithBool:NO];

      if ([[fileManager directoryContentsAtPath:path] count] > 0)
        return [NSNumber numberWithBool:NO];
     
      if (![fileManager removeFileAtPath:path handler:nil])
        return [NSNumber numberWithBool:NO];
  }
  return [NSNumber numberWithBool:YES];
}

- (NSNumber *)project_rmAction:(id)_pid:(NSArray *)_args {
  SkyProjectFileManager *fileManager;
  unsigned count;
  unsigned i;

  if ((count = [_args count]) == 0)
    return [NSNumber numberWithBool:NO];

  if ((fileManager = [self fileManagerForCode:_pid]) == nil)
    return [self _missingFileManagerForProjectIDFault:_pid];
  
  for (i = 0; i < count; i++) {
      NSString *path;
      BOOL isDir;
      
      path = [_args objectAtIndex:i];
      
      if (![fileManager fileExistsAtPath:path isDirectory:&isDir])
        return [NSNumber numberWithBool:NO];

      if (isDir) {
        if ([[fileManager directoryContentsAtPath:path] count] > 0)
          return [NSNumber numberWithBool:NO];
      }
      
      if (![fileManager removeFileAtPath:path handler:nil])
        return [NSNumber numberWithBool:NO];
  }
  return [NSNumber numberWithBool:YES];
}

- (id)project_attrAction:(id)_pid:(NSArray *)_args {
  NSMutableDictionary   *dict;
  SkyProjectFileManager *fileManager;
  id       fm;
  unsigned count;
  unsigned i;

  if ((count = [_args count]) == 0)
    return [NSNumber numberWithBool:NO];

  if ((fm = [self fileManagerForCode:_pid]) == nil)
    return [self _missingFileManagerForProjectIDFault:_pid];
  
  if (count == 1) {
    return [fm fileAttributesAtPath:[[_args objectAtIndex:0] stringValue] 
	       traverseLink:NO];
  }

  fileManager = fm;
  dict = [NSMutableDictionary dictionaryWithCapacity:count];
  
  for (i = 0; i < count; i++) {
    NSString            *path;
    NSMutableDictionary *attribs;

    path = [_args objectAtIndex:i];
    attribs = [[fileManager fileAttributesAtPath:path traverseLink:NO]
                mutableCopy];
    
    if (attribs == nil)
      continue;
    
    if (![attribs objectForKey:@"NSFileMimeType"]) {
      NSString *mimeType;
      mimeType = [[[NSUserDefaults standardUserDefaults] 
                                   dictionaryForKey:@"LSMimeTypes"]
                                   valueForKey:[path pathExtension]];
          
      if (mimeType)
        [attribs setObject:mimeType forKey:@"NSFileMimeType"];
      else
        [attribs setObject:@"application/octet-stream" 
                 forKey:@"NSFileMimeType"];
    }
    [dict setObject:attribs forKey:path];
    [attribs release]; attribs = nil;
  }
  return dict;
}

- (NSNumber *)project_cpAction:(id)_pid:(NSArray *)_args {
  unsigned i;
  NSString *destination;
  BOOL isDir;
  SkyProjectFileManager *fileManager;
  unsigned count;

  /* preconditions */
  
  if ((count = [_args count]) == 0)
    return [NSNumber numberWithBool:NO];
  
  if (count == 1)
    return [NSNumber numberWithBool:NO];

  /* process */
  
  if ((fileManager = [self fileManagerForCode:_pid]) == nil)
    return [self _missingFileManagerForProjectIDFault:_pid];
  
  destination = [_args objectAtIndex:(count - 1)];
  
  if (![fileManager fileExistsAtPath:destination isDirectory:&isDir])
    isDir = NO;

  for (i = 0; i < count - 1; i++) {
    NSString *path, *dest;
      
    path = [_args objectAtIndex:i];

    dest = isDir
      ? [destination stringByAppendingPathComponent:[path lastPathComponent]]
      : destination;
      
    if (![fileManager copyPath:path toPath:dest handler:nil])
      return [NSNumber numberWithBool:NO];
  }
  return [NSNumber numberWithBool:YES];
}

- (NSNumber *)project_cpAction:(id)_pid
                              :(NSString *)_src
                              :(NSString *)_dest 
{
  NSArray *args;
  
  args = [NSArray arrayWithObjects:_src, _dest, nil];
  return [self project_cpAction:_pid:args];
}

- (NSNumber *)project_mvAction:(id)_pid:(NSArray *)_args {
  NSString *destination;
  BOOL isDir;
  SkyProjectFileManager *fileManager;
  unsigned i;
  unsigned count;

  if ((count = [_args count]) == 0)
    return [NSNumber numberWithBool:NO];
  if (count == 1)
    return [NSNumber numberWithBool:NO];
  

  if ((fileManager = [self fileManagerForCode:_pid]) == nil)
    return [self _missingFileManagerForProjectIDFault:_pid];
  
  destination = [_args objectAtIndex:(count - 1)];

  if (![fileManager fileExistsAtPath:destination isDirectory:&isDir])
    isDir = NO;

  for (i = 0; i < count - 1; i++) {
      NSString *path, *dest;

      path = [_args objectAtIndex:i];

      dest = isDir
        ? [destination stringByAppendingPathComponent:[path lastPathComponent]]
        : destination;

      if (![fileManager movePath:path toPath:dest handler:nil])
        return [NSNumber numberWithBool:NO];
  }
  return [NSNumber numberWithBool:YES];
}

- (NSNumber *)project_mvAction:(id)_pid
                              :(NSString *)_src
                              :(NSString *)_dest 
{
  NSArray *args;

  args = [NSArray arrayWithObjects:_src, _dest, nil];
  return [self project_mvAction:_pid:args];
}

- (NSNumber *)project_lnAction:(id)_pid:(NSArray *)_args {
  unsigned count;
  NSString *source, *target;
  id       fm;
  BOOL     ok;
  
  if ((count = [_args count]) == 0)
    return [NSNumber numberWithBool:NO];
  
  if (count == 1)
    return [NSNumber numberWithBool:NO];
  
  if ((fm = [self fileManagerForCode:_pid]) == nil)
    return [self _missingFileManagerForProjectIDFault:_pid];
  
  source = [[_args objectAtIndex:0] stringValue];
  target = [[_args objectAtIndex:1] stringValue];

  ok = [fm createSymbolicLinkAtPath:target pathContent:source];
  return [NSNumber numberWithBool:ok];
}

- (NSNumber *)project_lnAction:(id)_pid
                              :(NSString *)_src
                              :(NSString *)_dest 
{
  NSArray *args;
  
  args = [NSArray arrayWithObjects:_src, _dest, nil];
  return [self project_lnAction:_pid:args];
}

- (NSNumber *)project_existsAction:(id)_pid:(NSArray *)_args {
  SkyProjectFileManager *fileManager;
  unsigned i, count;

  if ((count = [_args count]) == 0)
    return [NSNumber numberWithBool:YES];

  if ((fileManager = [self fileManagerForCode:_pid]) == nil)
    return [self _missingFileManagerForProjectIDFault:_pid];
  
  for (i = 0; i < count; i++) {
    NSString *path;

    path = [_args objectAtIndex:i];

    if (![fileManager fileExistsAtPath:path])
      return [NSNumber numberWithBool:NO];
  }
  return [NSNumber numberWithBool:YES];
}

- (NSNumber *)project_isdirAction:(id)_pid:(NSArray *)_args {
  SkyProjectFileManager *fileManager;
  unsigned i, count;

  if ((count = [_args count]) == 0)
    return [NSNumber numberWithBool:YES];

  if ((fileManager = [self fileManagerForCode:_pid]) == nil)
    return [self _missingFileManagerForProjectIDFault:_pid];
  
  for (i = 0; i < count; i++) {
      NSString *path;
      BOOL isDir;

      path = [_args objectAtIndex:i];

      if (![fileManager fileExistsAtPath:path isDirectory:&isDir])
        return [NSNumber numberWithBool:NO];

      if (!isDir)  
        return [NSNumber numberWithBool:NO];
  }
  return [NSNumber numberWithBool:YES];
}

- (NSNumber *)project_islinkAction:(id)_pid:(NSArray *)_args {
  SkyProjectFileManager *fileManager;
  unsigned i, count;

  if ((count = [_args count]) == 0)
    return [NSNumber numberWithBool:YES];
  
  if ((fileManager = [self fileManagerForCode:_pid]) == nil)
    return [self _missingFileManagerForProjectIDFault:_pid];
  
  for (i = 0; i < count; i++) {
      NSString     *path;
      BOOL         isDir;
      NSDictionary *attrs;
      
      path = [_args objectAtIndex:i];
      
      if (![fileManager fileExistsAtPath:path isDirectory:&isDir])
        return [NSNumber numberWithBool:NO];
      
      if (isDir)
        return [NSNumber numberWithBool:NO];

      if ((attrs = [fileManager fileAttributesAtPath:path 
                                traverseLink:NO])==nil)
        return [NSNumber numberWithBool:NO];

      if (![[attrs objectForKey:NSFileType] 
             isEqualToString:NSFileTypeSymbolicLink])
        return [NSNumber numberWithBool:NO];
  }
  return [NSNumber numberWithBool:YES];
}

- (id)project_flushAction:(id)_pid {
  SkyProjectFileManager *fm;

  if ((fm = [self fileManagerForCode:_pid]) == nil)
    return [self _missingFileManagerForProjectIDFault:_pid];
  
  if ([fm respondsToSelector:@selector(flush)])
    [fm flush];
  return nil;
}

- (id)project_zipAction:(id)_pid:(NSArray *)_args {
  SkyProjectFileManager *fileManager;
  NGFileManagerZipTool  *zipTool;
  NSData                *zipData;
  unsigned i, count;

  // nothing to zip
  if ((count = [_args count]) == 0)
    return [NSNumber numberWithBool:NO];
  
  if ((fileManager = [self fileManagerForCode:_pid]) == nil)
    return [self _missingFileManagerForProjectIDFault:_pid];
  
  zipTool = [[NGFileManagerZipTool alloc] init];
  for (i = 0; i < count; i++) {
      NSString *path;

      path = [_args objectAtIndex:i];
      if (![fileManager fileExistsAtPath:path])
        return [NSNumber numberWithBool:NO];
    }
  
  zipData = [zipTool zipProjectPaths:_args 
                     fileManager:fileManager 
                     compressionLevel:6];
  [zipTool release];  
  return zipData;
}

- (id)project_subPathsAtPathAction:(id)_pid:(NSArray *)_args {
  unsigned count;
  id fm;

  if ([_args isKindOfClass:[NSString class]])
    _args = [NSArray arrayWithObject:_args];

  if ((fm = [self fileManagerForCode:_pid]) == nil)
    return [self _missingFileManagerForProjectIDFault:_pid];
  
  if ((count = [_args count]) == 0)
    return [fm subpathsAtPath:@"/"];
  
  if (count > 1)
    return [self _projectMethodTooManyArgumentsFault];
  
  return [fm subpathsAtPath:[[_args objectAtIndex:0] stringValue]];
}

- (id)project_fileAttributesAtDirectoryAction:(id)_pid:(NSArray *)_args {
  unsigned count;
  id fm;

  if ((count = [_args count]) == 0)
    return [NSNumber numberWithBool:NO];
  
  if (count > 1)
    return [self _projectMethodTooManyArgumentsFault];

  if ((fm = [self fileManagerForCode:_pid]) == nil)
    return [self _missingFileManagerForProjectIDFault:_pid];

  return [[[fm dataSourceAtPath:[_args objectAtIndex:0]]
               fetchObjects] map:@selector(fileAttributes)];
}

@end /* DirectAction(Project) */
